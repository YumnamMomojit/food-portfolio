# EC2 Docker Deployment Guide

## Overview
This guide will help you deploy the Food Portfolio Website to an AWS EC2 instance using Docker containers.

## Prerequisites

### Local Requirements
- Docker installed on your local machine
- AWS CLI installed and configured
- Git installed
- SSH client

### AWS Requirements
- AWS Account with EC2 access
- Key pair for EC2 instance access
- Security group with appropriate ports open

## Step 1: Set Up AWS EC2 Instance

### 1.1 Launch EC2 Instance
```bash
# Create a new EC2 instance (recommended: t3.small or larger)
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1d0 \
  --instance-type t3.small \
  --key-name your-key-pair \
  --security-group-ids sg-yoursgid \
  --subnet-id subnet-yourid \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=food-portfolio-server}]'
```

### 1.2 Configure Security Group
Ensure your security group allows:
- SSH (port 22) from your IP
- HTTP (port 80) from anywhere (0.0.0.0/0)
- HTTPS (port 443) from anywhere (0.0.0.0/0)
- Custom port 5000 from anywhere (for direct app access)

### 1.3 Connect to EC2 Instance
```bash
ssh -i /path/to/your-key.pem ec2-user@your-ec2-public-ip
```

## Step 2: Prepare EC2 Instance

### 2.1 Update System and Install Docker
```bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install docker -y

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

### 2.2 Install Git and Node.js (optional for building locally)
```bash
# Install Git
sudo yum install git -y

# Install Node.js (for local builds if needed)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install node
nvm use node
```

## Step 3: Deploy Application

### 3.1 Clone Repository
```bash
# Clone your repository
git clone https://github.com/yourusername/food-portfolio.git
cd food-portfolio

# Or upload your local files
scp -i /path/to/your-key.pem -r /local/path/to/project ec2-user@your-ec2-ip:~/
```

### 3.2 Set Up Environment Variables
```bash
# Copy environment template
cp .env.production .env

# Edit environment variables
nano .env
```

Update the `.env` file with your production values:
```bash
# Production Environment
NODE_ENV=production
PORT=5000
FRONTEND_URL=http://your-ec2-public-ip

# Your Supabase credentials
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# Your Gemini API key
GEMINI_API_KEY=your_gemini_api_key_here
```

### 3.3 Build and Deploy with Docker
```bash
# Build the Docker image
docker build -t food-portfolio .

# Run the container (simple deployment)
docker run -d \
  --name food-portfolio-app \
  --restart unless-stopped \
  -p 5000:5000 \
  --env-file .env \
  food-portfolio

# OR use Docker Compose for production deployment with Nginx
docker-compose --profile production up -d --build
```

### 3.4 Verify Deployment
```bash
# Check container status
docker ps

# Check application logs
docker logs food-portfolio-app

# Test the application
curl http://localhost:5000/api/health
```

## Step 4: Set Up Domain and SSL (Optional)

### 4.1 Configure Domain
1. Point your domain to the EC2 instance's Elastic IP
2. Update FRONTEND_URL in .env file
3. Update nginx.conf with your domain name

### 4.2 Set Up SSL with Let's Encrypt
```bash
# Install certbot
sudo yum install certbot python3-certbot-nginx -y

# Get SSL certificate
sudo certbot --nginx -d yourdomain.com

# Test SSL renewal
sudo certbot renew --dry-run
```

## Step 5: Monitoring and Maintenance

### 5.1 Set Up Log Monitoring
```bash
# View application logs
docker logs -f food-portfolio-app

# View nginx logs (if using compose)
docker logs -f food-portfolio-nginx
```

### 5.2 Set Up Automated Updates
Create a update script:
```bash
#!/bin/bash
# update-app.sh

cd /home/ec2-user/food-portfolio

# Pull latest code
git pull origin main

# Rebuild and restart containers
docker-compose down
docker-compose --profile production up -d --build

echo "Application updated successfully!"
```

### 5.3 Backup Strategy
```bash
# Create backup script
#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/ec2-user/backups"

mkdir -p $BACKUP_DIR

# Backup application files
tar -czf $BACKUP_DIR/food-portfolio-$DATE.tar.gz /home/ec2-user/food-portfolio

# Keep only last 7 backups
find $BACKUP_DIR -name "food-portfolio-*.tar.gz" -mtime +7 -delete

echo "Backup completed: food-portfolio-$DATE.tar.gz"
```

## Troubleshooting

### Common Issues

1. **Container won't start**
   ```bash
   # Check logs
   docker logs food-portfolio-app
   
   # Check environment variables
   docker exec -it food-portfolio-app env
   ```

2. **Port access issues**
   ```bash
   # Check if port is open
   sudo netstat -tlnp | grep :5000
   
   # Check security group settings in AWS console
   ```

3. **Database connection issues**
   ```bash
   # Test Supabase connection
   docker exec -it food-portfolio-app node -e "
   const { createClient } = require('@supabase/supabase-js');
   const client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
   console.log('Supabase client created successfully');
   "
   ```

4. **Memory issues**
   ```bash
   # Check system resources
   free -h
   df -h
   
   # Consider upgrading instance type if needed
   ```

### Performance Optimization

1. **Use Elastic IP** for consistent IP address
2. **Set up CloudFront** for CDN
3. **Use RDS** instead of Supabase for better performance (optional)
4. **Set up Auto Scaling Group** for high availability
5. **Use Application Load Balancer** for multiple instances

## Security Best Practices

1. **Regular Updates**
   ```bash
   # Update system packages
   sudo yum update -y
   
   # Update Docker images
   docker-compose pull
   docker-compose up -d
   ```

2. **Firewall Configuration**
   ```bash
   # Install and configure fail2ban
   sudo yum install fail2ban -y
   sudo systemctl start fail2ban
   sudo systemctl enable fail2ban
   ```

3. **SSH Hardening**
   - Change default SSH port
   - Disable root login
   - Use key-based authentication only

## Cost Optimization

1. **Right-size your instance** based on usage
2. **Use Reserved Instances** for long-term deployments
3. **Set up CloudWatch alarms** for cost monitoring
4. **Stop instances** during non-business hours if applicable

## Next Steps

After successful deployment:
1. Set up monitoring with CloudWatch
2. Implement CI/CD pipeline
3. Set up automated backups
4. Configure logging aggregation
5. Implement health checks and alerting

For questions or issues, refer to the main project documentation or create an issue in the project repository.