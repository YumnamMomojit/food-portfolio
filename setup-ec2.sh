#!/bin/bash

# EC2 Instance Setup Script for Food Portfolio Deployment
# Run this script on a fresh Amazon Linux 2 EC2 instance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Update system
log "Updating system packages..."
sudo yum update -y

# Install Docker
log "Installing Docker..."
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install Docker Compose
log "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Git
log "Installing Git..."
sudo yum install git -y

# Install Node.js and npm (optional, for local builds)
log "Installing Node.js..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install node
nvm use node

# Install additional useful tools
log "Installing additional tools..."
sudo yum install -y htop curl wget unzip jq

# Install AWS CLI v2
log "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

# Install fail2ban for security
log "Installing fail2ban..."
sudo yum install -y fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Create backup directory
log "Creating directories..."
mkdir -p /home/ec2-user/backups
mkdir -p /home/ec2-user/logs

# Configure firewall (if enabled)
if command -v firewall-cmd &> /dev/null; then
    log "Configuring firewall..."
    sudo firewall-cmd --permanent --add-port=22/tcp
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --permanent --add-port=443/tcp
    sudo firewall-cmd --permanent --add-port=5000/tcp
    sudo firewall-cmd --reload
fi

# Set up log rotation for application logs
log "Setting up log rotation..."
sudo tee /etc/logrotate.d/food-portfolio << EOF
/home/ec2-user/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 0644 ec2-user ec2-user
}
EOF

# Create systemd service for automatic startup (optional)
log "Creating systemd service..."
sudo tee /etc/systemd/system/food-portfolio.service << EOF
[Unit]
Description=Food Portfolio Docker Container
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker start food-portfolio-app
ExecStop=/usr/bin/docker stop food-portfolio-app
User=ec2-user

[Install]
WantedBy=multi-user.target
EOF

# Set up basic monitoring script
log "Creating monitoring script..."
tee /home/ec2-user/monitor.sh << 'EOF'
#!/bin/bash

# Simple monitoring script for Food Portfolio
LOG_FILE="/home/ec2-user/logs/monitor.log"

check_container() {
    if docker ps | grep -q "food-portfolio-app"; then
        echo "$(date): Container is running" >> "$LOG_FILE"
    else
        echo "$(date): Container is not running - attempting restart" >> "$LOG_FILE"
        docker start food-portfolio-app || echo "$(date): Failed to start container" >> "$LOG_FILE"
    fi
}

check_disk_space() {
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 80 ]; then
        echo "$(date): WARNING - Disk usage is ${DISK_USAGE}%" >> "$LOG_FILE"
    fi
}

check_container
check_disk_space
EOF

chmod +x /home/ec2-user/monitor.sh

# Set up cron job for monitoring
log "Setting up monitoring cron job..."
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ec2-user/monitor.sh") | crontab -

# Create deployment directory
log "Creating deployment directory..."
mkdir -p /home/ec2-user/food-portfolio
cd /home/ec2-user/food-portfolio

# Download deployment script (if not already present)
if [ ! -f "deploy.sh" ]; then
    log "Creating deploy script..."
    # The deploy.sh content would be embedded here or downloaded
    # For now, we'll create a placeholder
    echo "# Deployment script placeholder" > deploy.sh
    chmod +x deploy.sh
fi

# Set up environment file template
log "Creating environment template..."
tee /home/ec2-user/food-portfolio/.env.template << EOF
# Production Environment Configuration
NODE_ENV=production
PORT=5000
FRONTEND_URL=http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Supabase Configuration - UPDATE THESE VALUES
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# Gemini AI Configuration - UPDATE THIS VALUE
GEMINI_API_KEY=your_gemini_api_key_here
EOF

# Display setup completion message
log "EC2 setup completed successfully!"

echo -e "\n${YELLOW}=== Setup Summary ===${NC}"
echo -e "${GREEN}✓${NC} System updated"
echo -e "${GREEN}✓${NC} Docker installed and configured"
echo -e "${GREEN}✓${NC} Docker Compose installed"
echo -e "${GREEN}✓${NC} Git installed"
echo -e "${GREEN}✓${NC} Node.js installed"
echo -e "${GREEN}✓${NC} AWS CLI v2 installed"
echo -e "${GREEN}✓${NC} Security tools installed"
echo -e "${GREEN}✓${NC} Monitoring set up"
echo -e "${GREEN}✓${NC} Directories created"

echo -e "\n${BLUE}=== Next Steps ===${NC}"
echo "1. Logout and log back in for Docker group changes to take effect"
echo "2. Upload your application code to /home/ec2-user/food-portfolio"
echo "3. Update the .env file with your actual credentials"
echo "4. Run the deployment script: ./deploy.sh"
echo "5. Configure your domain and SSL certificate (if needed)"

echo -e "\n${YELLOW}=== Important Notes ===${NC}"
echo "• Your public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "• Environment template: /home/ec2-user/food-portfolio/.env.template"
echo "• Monitoring logs: /home/ec2-user/logs/monitor.log"
echo "• Backup directory: /home/ec2-user/backups"

echo -e "\n${GREEN}Reboot recommended to ensure all changes take effect.${NC}"