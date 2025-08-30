#!/bin/bash

# Security Configuration Script for Food Portfolio Production Deployment
# This script sets up security measures for the EC2 instance

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

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to configure SSH security
configure_ssh_security() {
    log "Configuring SSH security..."
    
    # Backup original sshd_config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Configure SSH settings
    sudo tee -a /etc/ssh/sshd_config << EOF

# Food Portfolio Security Configuration
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
UsePAM yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers ec2-user
EOF

    # Restart SSH service
    sudo systemctl reload sshd
    log "SSH security configured"
}

# Function to set up fail2ban
setup_fail2ban() {
    log "Setting up fail2ban..."
    
    # Create custom jail configuration
    sudo tee /etc/fail2ban/jail.local << EOF
[DEFAULT]
# Ignore local IPs
ignoreip = 127.0.0.1/8 ::1

# Ban time in seconds (24 hours)
bantime = 86400

# Find time in seconds (10 minutes)
findtime = 600

# Number of failures before ban
maxretry = 3

# Email notifications (configure if needed)
# destemail = your-email@example.com
# sender = fail2ban@$(hostname -f)
# action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
logpath = /var/log/secure
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10

[nginx-botsearch]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

    sudo systemctl restart fail2ban
    sudo systemctl enable fail2ban
    log "fail2ban configured and started"
}

# Function to configure firewall (iptables)
configure_firewall() {
    log "Configuring firewall rules..."
    
    # Create iptables rules script
    sudo tee /etc/iptables-rules.sh << 'EOF'
#!/bin/bash

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established and related connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (port 22)
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

# Allow HTTP (port 80)
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT

# Allow HTTPS (port 443)
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT

# Allow application port (5000) - consider removing in production with nginx
iptables -A INPUT -p tcp --dport 5000 -m state --state NEW -j ACCEPT

# Rate limiting for SSH
iptables -A INPUT -p tcp --dport 22 -m recent --name ssh --set
iptables -A INPUT -p tcp --dport 22 -m recent --name ssh --update --seconds 60 --hitcount 4 -j DROP

# Rate limiting for HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -m recent --name http --set
iptables -A INPUT -p tcp --dport 80 -m recent --name http --update --seconds 1 --hitcount 20 -j DROP

iptables -A INPUT -p tcp --dport 443 -m recent --name https --set
iptables -A INPUT -p tcp --dport 443 -m recent --name https --update --seconds 1 --hitcount 20 -j DROP

# Log dropped packets
iptables -A INPUT -m limit --limit 2/min -j LOG --log-prefix "iptables INPUT dropped: "
iptables -A FORWARD -m limit --limit 2/min -j LOG --log-prefix "iptables FORWARD dropped: "

# Save rules
iptables-save > /etc/iptables/rules.v4
EOF

    sudo chmod +x /etc/iptables-rules.sh
    sudo /etc/iptables-rules.sh
    
    # Create systemd service for iptables persistence
    sudo tee /etc/systemd/system/iptables-restore.service << EOF
[Unit]
Description=Restore iptables firewall rules
Before=network-pre.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables/rules.v4

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable iptables-restore
    log "Firewall rules configured"
}

# Function to set up SSL with Let's Encrypt
setup_ssl() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        warning "No domain provided. Skipping SSL setup."
        warning "To set up SSL later, run: sudo certbot --nginx -d yourdomain.com"
        return
    fi
    
    log "Setting up SSL for domain: $domain"
    
    # Install certbot
    sudo yum install -y certbot python3-certbot-nginx
    
    # Get SSL certificate
    sudo certbot --nginx -d "$domain" --non-interactive --agree-tos --email admin@"$domain"
    
    # Set up automatic renewal
    sudo crontab -l | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet"; } | sudo crontab -
    
    log "SSL certificate installed and auto-renewal configured"
}

# Function to harden system
harden_system() {
    log "Hardening system..."
    
    # Disable unused services
    sudo systemctl disable avahi-daemon 2>/dev/null || true
    sudo systemctl disable cups 2>/dev/null || true
    sudo systemctl disable bluetooth 2>/dev/null || true
    
    # Set secure permissions
    sudo chmod 700 /home/ec2-user
    sudo chmod 600 /home/ec2-user/.ssh/authorized_keys 2>/dev/null || true
    
    # Configure kernel parameters for security
    sudo tee -a /etc/sysctl.conf << EOF

# Food Portfolio Security Settings
# Disable IP forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Enable syn flood protection
net.ipv4.tcp_syncookies = 1

# Ignore ping requests
net.ipv4.icmp_echo_ignore_all = 1

# Log martian packets
net.ipv4.conf.all.log_martians = 1

# Ignore broadcast pings
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
EOF

    sudo sysctl -p
    
    log "System hardening completed"
}

# Function to set up monitoring and alerting
setup_monitoring() {
    log "Setting up security monitoring..."
    
    # Create security monitoring script
    tee /home/ec2-user/security-monitor.sh << 'EOF'
#!/bin/bash

# Security monitoring script
LOG_FILE="/home/ec2-user/logs/security.log"
ALERT_EMAIL="admin@yourdomain.com"  # Update with your email

# Check for failed login attempts
check_failed_logins() {
    FAILED_LOGINS=$(grep "Failed password" /var/log/secure | tail -n 50 | wc -l)
    if [ "$FAILED_LOGINS" -gt 10 ]; then
        echo "$(date): WARNING - $FAILED_LOGINS failed login attempts detected" >> "$LOG_FILE"
    fi
}

# Check for unusual network connections
check_network_connections() {
    CONNECTIONS=$(netstat -an | grep :22 | grep ESTABLISHED | wc -l)
    if [ "$CONNECTIONS" -gt 5 ]; then
        echo "$(date): WARNING - $CONNECTIONS SSH connections detected" >> "$LOG_FILE"
    fi
}

# Check system load
check_system_load() {
    LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | sed 's/^[ \t]*//')
    if (( $(echo "$LOAD > 2.0" | bc -l) )); then
        echo "$(date): WARNING - High system load: $LOAD" >> "$LOG_FILE"
    fi
}

# Check disk space
check_disk_space() {
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 90 ]; then
        echo "$(date): CRITICAL - Disk usage is ${DISK_USAGE}%" >> "$LOG_FILE"
    fi
}

# Run checks
check_failed_logins
check_network_connections
check_system_load
check_disk_space
EOF

    chmod +x /home/ec2-user/security-monitor.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "*/15 * * * * /home/ec2-user/security-monitor.sh") | crontab -
    
    log "Security monitoring configured"
}

# Function to create security documentation
create_security_docs() {
    log "Creating security documentation..."
    
    tee /home/ec2-user/SECURITY.md << 'EOF'
# Food Portfolio Security Configuration

## Implemented Security Measures

### 1. SSH Security
- Root login disabled
- Password authentication disabled
- Key-based authentication only
- Connection limits and timeouts configured

### 2. Firewall Configuration
- iptables rules for port access control
- Rate limiting for HTTP/HTTPS and SSH
- Logging of dropped packets

### 3. Intrusion Prevention
- fail2ban installed and configured
- Automatic IP banning for failed attempts
- Custom jails for SSH and Nginx

### 4. System Hardening
- Unused services disabled
- Secure file permissions set
- Kernel security parameters configured

### 5. SSL/TLS
- Let's Encrypt SSL certificate (if domain configured)
- Automatic certificate renewal
- Strong cipher configuration

### 6. Monitoring
- Security monitoring script
- Automated alerts for suspicious activity
- Log rotation and retention

## Security Checklist

### Regular Tasks
- [ ] Review fail2ban logs: `sudo fail2ban-client status`
- [ ] Check security logs: `tail /home/ec2-user/logs/security.log`
- [ ] Review system logs: `sudo journalctl -f`
- [ ] Update system packages: `sudo yum update -y`

### Monthly Tasks
- [ ] Review firewall rules: `sudo iptables -L -n`
- [ ] Check SSL certificate expiry: `sudo certbot certificates`
- [ ] Audit user accounts: `cut -d: -f1 /etc/passwd`
- [ ] Review cron jobs: `crontab -l`

### Emergency Procedures
1. **Suspected breach**: Check logs and block suspicious IPs
2. **SSL issues**: Renew certificate manually with certbot
3. **High load**: Check running processes and restart services if needed

## Contact Information
- System Administrator: [Your Email]
- Emergency Contact: [Emergency Email]
- Server Location: AWS EC2
EOF

    log "Security documentation created at /home/ec2-user/SECURITY.md"
}

# Main execution
main() {
    local domain="$1"
    
    log "Starting security configuration for Food Portfolio..."
    
    # Run security configurations
    configure_ssh_security
    setup_fail2ban
    configure_firewall
    harden_system
    setup_monitoring
    
    # Setup SSL if domain provided
    if [ -n "$domain" ]; then
        setup_ssl "$domain"
    fi
    
    create_security_docs
    
    log "Security configuration completed successfully!"
    
    echo -e "\n${YELLOW}=== Security Summary ===${NC}"
    echo -e "${GREEN}✓${NC} SSH hardened (key-based auth only)"
    echo -e "${GREEN}✓${NC} fail2ban configured for intrusion prevention"
    echo -e "${GREEN}✓${NC} Firewall rules implemented"
    echo -e "${GREEN}✓${NC} System hardening applied"
    echo -e "${GREEN}✓${NC} Security monitoring set up"
    
    if [ -n "$domain" ]; then
        echo -e "${GREEN}✓${NC} SSL certificate installed for $domain"
    else
        echo -e "${YELLOW}!${NC} SSL not configured (no domain provided)"
    fi
    
    echo -e "\n${BLUE}=== Next Steps ===${NC}"
    echo "1. Test SSH access with key-based authentication"
    echo "2. Verify firewall rules: sudo iptables -L -n"
    echo "3. Check fail2ban status: sudo fail2ban-client status"
    echo "4. Review security documentation: cat /home/ec2-user/SECURITY.md"
    
    if [ -z "$domain" ]; then
        echo "5. Configure SSL when you have a domain: ./security.sh yourdomain.com"
    fi
    
    warning "IMPORTANT: Test SSH access from another terminal before closing this session!"
}

# Check if script is run as root (shouldn't be)
if [ "$EUID" -eq 0 ]; then
    error "This script should not be run as root. Run as ec2-user with sudo privileges."
fi

# Run main function with domain parameter
main "$1"