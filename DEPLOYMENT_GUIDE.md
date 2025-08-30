# Food Portfolio - Docker & EC2 Deployment Guide

## 🎯 Overview

This guide provides comprehensive instructions for deploying the Food Portfolio website using Docker containers on an AWS EC2 instance. The deployment includes:

- **Frontend**: React application (built with Vite)
- **Backend**: Node.js/Express API server
- **Database**: Supabase (PostgreSQL)
- **AI Integration**: Google Gemini API
- **Infrastructure**: AWS EC2 with Docker
- **Security**: SSL, firewall, intrusion prevention

## 📋 Prerequisites

### Local Development
- Docker and Docker Compose installed
- Node.js 16+ and npm
- Git
- AWS CLI (optional, for automation)

### AWS Requirements
- AWS Account with EC2 access
- SSH key pair for EC2 access
- Basic understanding of AWS services

### External Services
- Supabase project with database set up
- Google Gemini API key
- Domain name (optional, for SSL)

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd food-portfolio
   ```

2. **Set up environment**
   ```bash
   cp .env.production .env
   # Edit .env with your actual values
   ```

3. **Deploy with one command**
   ```bash
   # For simple deployment
   ./deploy.sh deploy

   # For production with Nginx
   ./deploy.sh deploy compose production
   ```

### Option 2: Manual Step-by-Step Deployment

Follow the detailed sections below for manual deployment.

## 📁 Project Structure

```
food-portfolio/
├── Dockerfile                 # Multi-stage production build
├── docker-compose.yml         # Production deployment
├── docker-compose.dev.yml     # Development environment
├── .dockerignore             # Docker build optimization
├── deploy.sh                 # Automated deployment script
├── setup-ec2.sh             # EC2 instance preparation
├── security.sh              # Security hardening
├── nginx/
│   └── nginx.conf           # Nginx reverse proxy config
├── server/                  # Backend API
├── src/                     # Frontend React app
└── deployment-docs/         # Additional documentation
```

## 🐳 Docker Configuration

### Dockerfile Architecture

The `Dockerfile` uses multi-stage build:

1. **Frontend Builder Stage**: Builds React app with Vite
2. **Production Stage**: Sets up Node.js backend with built frontend

Key features:
- Non-root user for security
- Health checks
- Optimized for production
- Signal handling with dumb-init

### Docker Compose Services

**Production (`docker-compose.yml`):**
- `food-portfolio-app`: Main application container
- `nginx`: Reverse proxy with SSL termination (optional)

**Development (`docker-compose.dev.yml`):**
- Hot reloading for development
- Volume mounts for live code changes

## ☁️ AWS EC2 Setup

### 1. Launch EC2 Instance

**Recommended Configuration:**
- Instance Type: `t3.small` or larger
- OS: Amazon Linux 2
- Storage: 20GB+ SSD
- Security Group: Ports 22, 80, 443, 5000

**Using AWS CLI:**
```bash
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1d0 \
  --instance-type t3.small \
  --key-name your-key-pair \
  --security-group-ids sg-yourid \
  --user-data file://setup-ec2.sh
```

### 2. Prepare Instance

**Automated Setup:**
```bash
# Upload and run setup script
scp -i your-key.pem setup-ec2.sh ec2-user@your-ec2-ip:~
ssh -i your-key.pem ec2-user@your-ec2-ip
chmod +x setup-ec2.sh
./setup-ec2.sh
```

**Manual Setup:**
```bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 3. Deploy Application

**Upload Code:**
```bash
# Option 1: Git clone (if repository is public)
git clone https://github.com/yourusername/food-portfolio.git

# Option 2: SCP upload
scp -i your-key.pem -r ./food-portfolio ec2-user@your-ec2-ip:~/
```

**Configure Environment:**
```bash
cd food-portfolio
cp .env.production .env
nano .env  # Update with your values
```

**Deploy:**
```bash
# Simple deployment
./deploy.sh deploy

# Or with Docker Compose
docker-compose up -d --build
```

## 🔧 Environment Configuration

### Required Environment Variables

```bash
# Server Configuration
NODE_ENV=production
PORT=5000
FRONTEND_URL=http://your-domain-or-ip

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# Gemini AI Configuration
GEMINI_API_KEY=AIza...
```

### Production vs Development

| Setting | Development | Production |
|---------|-------------|------------|
| NODE_ENV | development | production |
| PORT | 3000 (frontend), 5000 (backend) | 5000 |
| FRONTEND_URL | http://localhost:3000 | http://your-domain |
| SSL | Not required | Recommended |
| Nginx | Not used | Reverse proxy |

## 🔒 Security Configuration

### Automated Security Setup

```bash
# Run security hardening script
./security.sh yourdomain.com  # With SSL setup
./security.sh                # Without SSL
```

### Security Features Implemented

1. **SSH Security**
   - Key-based authentication only
   - Root login disabled
   - Connection rate limiting

2. **Firewall (iptables)**
   - Port access control
   - Rate limiting for HTTP/HTTPS
   - DDoS protection

3. **Intrusion Prevention**
   - fail2ban for automatic IP blocking
   - Custom jails for SSH and web attacks

4. **SSL/TLS**
   - Let's Encrypt certificates
   - Automatic renewal
   - Strong cipher suites

5. **System Hardening**
   - Kernel security parameters
   - Unused services disabled
   - Secure file permissions

## 🌐 Domain and SSL Setup

### 1. Configure Domain

```bash
# Point your domain A record to EC2 Elastic IP
# Example DNS configuration:
# yourdomain.com  A  203.0.113.1
```

### 2. Set up SSL Certificate

```bash
# Install certbot
sudo yum install certbot python3-certbot-nginx -y

# Get certificate
sudo certbot --nginx -d yourdomain.com

# Verify auto-renewal
sudo certbot renew --dry-run
```

### 3. Update Configuration

```bash
# Update nginx configuration with your domain
nano nginx/nginx.conf

# Update environment variables
echo "FRONTEND_URL=https://yourdomain.com" >> .env

# Restart services
docker-compose restart
```

## 📊 Monitoring and Maintenance

### Application Monitoring

```bash
# Check container status
docker ps

# View application logs
docker logs -f food-portfolio-app

# Monitor system resources
htop
df -h
```

### Automated Monitoring

The deployment includes monitoring scripts:

- **Container Health**: Checks if containers are running
- **Resource Usage**: Monitors CPU, memory, disk
- **Security Events**: Tracks failed logins and attacks
- **SSL Expiration**: Monitors certificate validity

### Log Files

| Component | Log Location |
|-----------|--------------|
| Application | `docker logs food-portfolio-app` |
| Nginx | `/var/log/nginx/` |
| Security | `/home/ec2-user/logs/security.log` |
| System | `journalctl -f` |

## 🔄 Updates and Deployment

### Automated Updates

```bash
# Update application
./deploy.sh update

# Update with Docker Compose
./deploy.sh update compose production
```

### Manual Updates

```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Rollback

```bash
# Rollback to previous version
./deploy.sh rollback
```

## 🛠 Troubleshooting

### Common Issues

**1. Container Won't Start**
```bash
# Check logs
docker logs food-portfolio-app

# Verify environment variables
docker exec -it food-portfolio-app env
```

**2. Database Connection Issues**
```bash
# Test Supabase connection
docker exec -it food-portfolio-app node -e "
const { createClient } = require('@supabase/supabase-js');
const client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
console.log('Connected successfully');
"
```

**3. SSL Certificate Issues**
```bash
# Check certificate status
sudo certbot certificates

# Renew manually
sudo certbot renew
```

**4. Port Access Issues**
```bash
# Check if port is open
sudo netstat -tlnp | grep :5000

# Verify security group in AWS
aws ec2 describe-security-groups --group-ids sg-yourid
```

### Performance Issues

**High Memory Usage:**
```bash
# Check container resources
docker stats

# Consider upgrading instance type
# t3.small → t3.medium → t3.large
```

**Slow Response Times:**
```bash
# Check application performance
curl -w "@curl-format.txt" -o /dev/null http://localhost:5000/api/health

# Monitor database performance in Supabase dashboard
```

## 📈 Scaling and Optimization

### Vertical Scaling

1. **Upgrade EC2 Instance Type**
   ```bash
   # Stop instance, change instance type in AWS console, restart
   ```

2. **Optimize Database**
   - Use Supabase connection pooling
   - Optimize database queries
   - Add database indexes

### Horizontal Scaling

1. **Load Balancer Setup**
   - Application Load Balancer (ALB)
   - Multiple EC2 instances
   - Auto Scaling Groups

2. **CDN Configuration**
   - CloudFront for static assets
   - Edge caching for better performance

## 💰 Cost Optimization

### EC2 Cost Optimization

1. **Right-size Instance**
   - Monitor CPU/memory usage
   - Use appropriate instance type

2. **Reserved Instances**
   - 1-3 year commitments for discounts
   - Suitable for production environments

3. **Scheduled Scaling**
   - Stop instances during off-hours
   - Use CloudWatch Events for automation

### Monitoring Costs

```bash
# Set up billing alerts in AWS
aws budgets create-budget --account-id 123456789012 --budget file://budget.json
```

## 🤝 Development Workflow

### Local Development

```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up

# Or run components separately
npm run dev:full  # Runs frontend and backend
```

### CI/CD Pipeline

Consider setting up:
1. **GitHub Actions** for automated builds
2. **AWS CodePipeline** for deployment automation
3. **Docker Hub** for image registry

## 📚 Additional Resources

### Documentation Files

- `DEPLOY_EC2.md` - Detailed EC2 deployment guide
- `SECURITY.md` - Security configuration details
- `README.md` - Project overview and setup
- `SETUP_SUPABASE.md` - Database configuration
- `GEMINI_SETUP.md` - AI integration setup

### Useful Commands

```bash
# Quick deployment commands
npm run docker:build      # Build Docker image
npm run docker:run        # Run container locally
npm run docker:prod       # Production deployment
npm run docker:logs       # View container logs

# Monitoring commands
./deploy.sh status        # Check deployment status
./deploy.sh logs          # View application logs
./deploy.sh cleanup       # Clean up unused resources
```

### Support and Community

- **Issues**: Create GitHub issues for bugs
- **Documentation**: Contribute to docs
- **Community**: Join project discussions

---

## 🎉 Conclusion

This deployment guide provides a production-ready setup for the Food Portfolio website. The configuration includes:

✅ **Containerized Application** with Docker
✅ **Production-ready Infrastructure** on AWS EC2
✅ **Security Hardening** with multiple layers
✅ **Automated Deployment** with scripts
✅ **Monitoring and Alerting** for operations
✅ **SSL/TLS Encryption** for secure communication
✅ **Backup and Recovery** procedures

For questions or issues, refer to the troubleshooting section or create an issue in the project repository.

**Happy Deploying! 🚀**