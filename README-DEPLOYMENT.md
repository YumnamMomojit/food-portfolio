# 🍽️ Food Portfolio - Complete AWS Deployment Solution

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-blue.svg)](https://terraform.io)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://docker.com)
[![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20VPC-orange.svg)](https://aws.amazon.com)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org)
[![React](https://img.shields.io/badge/React-19+-blue.svg)](https://reactjs.org)

A modern, production-ready food portfolio website with complete AWS infrastructure automation using Terraform and Docker containers.

## 🎯 Quick Start (5 Minutes)

### Prerequisites
- AWS Account with credentials
- Terraform installed
- Docker installed  
- Supabase project setup
- Google Gemini AI API key

### Deploy Now
```bash
# 1. Configure environment
./terraform/setup-env.sh setup

# 2. Load configuration
source .env.terraform

# 3. Deploy everything
./deploy-terraform.sh deploy

# 4. Access your application
./deploy-terraform.sh output
```

**Your application will be live in 5-8 minutes!** 🚀

## 📋 What You Get

### 🏗️ **Complete AWS Infrastructure**
- **VPC** with multi-AZ public subnets
- **EC2** instance with auto-scaling capability
- **Security Groups** with proper firewall rules
- **Elastic IP** for consistent access
- **IAM Roles** with least privilege access
- **Optional ALB** for high availability
- **SSL/TLS** with Let's Encrypt automation

### 🐳 **Containerized Application**
- **Multi-stage Docker** build for optimization
- **Production-ready** Node.js + React stack
- **Health checks** and monitoring
- **Security hardening** with non-root user
- **Automated deployment** and updates

### 🛡️ **Security & Monitoring**
- **Network security** with VPC isolation
- **Intrusion prevention** with fail2ban
- **SSL encryption** for secure communication
- **CloudWatch monitoring** (optional)
- **Security scanning** in CI/CD pipeline
- **Backup automation** for disaster recovery

## 📁 Project Structure

```
food-portfolio/
├── 🚀 deploy-terraform.sh          # One-command deployment
├── 🐳 Dockerfile                   # Multi-stage container build
├── 📦 docker-compose.yml           # Container orchestration
├── 🔧 docker-build.sh             # Docker automation
│
├── terraform/                      # Infrastructure as Code
│   ├── 📄 main.tf                 # Main infrastructure
│   ├── 📄 variables.tf            # Configuration variables
│   ├── 📄 outputs.tf              # Deployment outputs
│   ├── 📄 user-data.sh            # EC2 initialization
│   ├── 🔧 setup-env.sh            # Environment setup
│   ├── 🔧 test-terraform.sh       # Configuration testing
│   ├── 📚 aws-setup-guide.md      # AWS credentials guide
│   ├── 📚 TERRAFORM_DEPLOYMENT_GUIDE.md  # Complete deployment guide
│   │
│   └── modules/                    # Reusable Terraform modules
│       ├── vpc/                    # VPC and networking
│       ├── security/               # Security groups and WAF
│       └── ec2/                    # Compute resources
│
├── server/                         # Backend API (Node.js/Express)
│   ├── config/                    # Configuration files
│   ├── controllers/               # Route handlers
│   ├── models/                    # Data models
│   ├── routes/                    # API routes
│   └── index.js                   # Server entry point
│
├── src/                           # Frontend (React + Vite)
│   ├── components/                # React components
│   ├── services/                  # API services
│   └── styles/                    # CSS styles
│
├── nginx/                         # Reverse proxy config
└── 📚 docs/                       # Documentation
```

## 🚀 Deployment Options

### **Basic Deployment**
Perfect for development and testing:
```bash
./deploy-terraform.sh deploy
# Cost: ~$15-20/month
```

### **Production with Custom Domain**
Production-ready with SSL:
```bash
./deploy-terraform.sh -d yourdomain.com -s deploy
# Cost: ~$15-20/month + domain cost
```

### **High Availability Setup**
Enterprise-ready with load balancer:
```bash
./deploy-terraform.sh -d yourdomain.com -s -l deploy
# Cost: ~$35-40/month
```

### **Multi-Region Deployment**
For global applications:
```bash
./deploy-terraform.sh -r us-west-2 deploy
./deploy-terraform.sh -r eu-west-1 deploy
```

## 💰 Cost Breakdown

| Component | Basic | Production | High Availability |
|-----------|-------|------------|-------------------|
| **EC2 Instance (t3.small)** | $16.79 | $16.79 | $16.79 |
| **EBS Storage (20GB)** | $2.00 | $2.00 | $2.00 |
| **Elastic IP** | $0.00* | $0.00* | $0.00* |
| **Load Balancer** | - | - | $16.20 |
| **SSL Certificate** | FREE | FREE | FREE |
| **Total/Month** | **~$19** | **~$19** | **~$35** |

*Free when attached to running instance

### 🏷️ **Instance Type Options**
- **t3.micro**: $8.50/month (1 vCPU, 1GB RAM) - Development
- **t3.small**: $16.79/month (2 vCPU, 2GB RAM) - **Recommended**
- **t3.medium**: $33.58/month (2 vCPU, 4GB RAM) - High traffic
- **t3.large**: $67.16/month (2 vCPU, 8GB RAM) - Enterprise

## 🔧 Management Commands

### **Deployment Management**
```bash
# Show deployment plan
./deploy-terraform.sh plan

# Deploy with auto-approval
./deploy-terraform.sh -y deploy

# Check deployment status  
./deploy-terraform.sh status

# View deployment outputs
./deploy-terraform.sh output

# Show deployment logs
./deploy-terraform.sh logs

# SSH into server
./deploy-terraform.sh ssh
```

### **Docker Management**
```bash
# Build Docker image
./docker-build.sh build

# Build and push to registry
./docker-build.sh -r myregistry.com -t v1.0.0 build-push

# Security scan
./docker-build.sh scan

# Multi-architecture build
./docker-build.sh --multi-arch build

# Test container locally
./docker-build.sh test
```

### **Infrastructure Cleanup**
```bash
# Destroy all resources
./deploy-terraform.sh destroy

# Cleanup Docker resources
./docker-build.sh cleanup
```

## 🛠️ Configuration

### **Environment Variables**
```bash
# AWS Configuration
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_DEFAULT_REGION=us-east-1

# Application Configuration  
TF_VAR_supabase_url=https://your-project.supabase.co
TF_VAR_supabase_anon_key=your_anon_key
TF_VAR_supabase_service_role_key=your_service_key
TF_VAR_gemini_api_key=your_gemini_key
TF_VAR_public_key_content="ssh-rsa AAAAB3... your_email@example.com"
```

### **Customization Options**
```bash
# Instance configuration
-t t3.medium              # Larger instance
-r us-west-2             # Different region
-e staging               # Environment name

# Domain and SSL
-d yourdomain.com        # Custom domain
-s                       # Enable SSL
-l                       # Load balancer

# Advanced options
--auto-approve           # Skip confirmation
--destroy                # Destruction mode
```

## 🔄 CI/CD Integration

### **GitHub Actions**
Automated deployment on push to main:
```yaml
name: Deploy Food Portfolio
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to AWS
        run: ./deploy-terraform.sh -y deploy
```

### **GitLab CI/CD**
```yaml
deploy:
  stage: deploy
  script:
    - ./deploy-terraform.sh -y deploy
  only:
    - main
```

### **Jenkins Pipeline**
```groovy
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                sh './deploy-terraform.sh -y deploy'
            }
        }
    }
}
```

## 🧪 Testing

### **Local Testing**
```bash
# Test Terraform configuration
./terraform/test-terraform.sh full

# Test Docker build
./docker-build.sh test

# Validate all configurations
./terraform/test-terraform.sh validate
```

### **Load Testing**
```bash
# Simple load test
for i in {1..1000}; do
  curl -s https://yourdomain.com/api/health > /dev/null
done

# Apache Bench (if installed)
ab -n 1000 -c 10 https://yourdomain.com/
```

## 🛡️ Security Features

### **Infrastructure Security**
- ✅ VPC isolation with private networking
- ✅ Security groups with minimal access
- ✅ IAM roles with least privilege
- ✅ Encrypted EBS volumes
- ✅ SSL/TLS encryption
- ✅ Optional WAF protection

### **Application Security**
- ✅ Container security with non-root user
- ✅ Intrusion prevention with fail2ban
- ✅ Regular security updates
- ✅ Environment variable security
- ✅ Health check monitoring
- ✅ Automated backup

### **Network Security**
- ✅ SSH key-based authentication only
- ✅ Restricted port access
- ✅ Rate limiting protection
- ✅ DDoS protection (with ALB)
- ✅ Geographic restrictions (optional)

## 📊 Monitoring & Alerting

### **Built-in Monitoring**
- 📈 Application health checks
- 📈 Container status monitoring  
- 📈 System resource tracking
- 📈 Security event logging
- 📈 SSL certificate monitoring

### **Optional CloudWatch**
```bash
# Enable monitoring
./deploy-terraform.sh -e prod --enable-monitoring deploy
```

### **Custom Alerts**
- 🚨 High CPU usage (>80%)
- 🚨 High memory usage (>80%)
- 🚨 Instance status failures
- 🚨 SSL certificate expiration
- 🚨 Failed login attempts

## 🔄 Updates & Maintenance

### **Application Updates**
```bash
# Update application code
git pull origin main
./deploy-terraform.sh apply

# Rolling update with zero downtime
./deploy-terraform.sh -l update
```

### **Infrastructure Updates**
```bash
# Update Terraform providers
cd terraform && terraform init -upgrade

# Update instance type
./deploy-terraform.sh -t t3.medium apply
```

### **Security Updates**
```bash
# SSH into instance
./deploy-terraform.sh ssh

# Update system packages
sudo yum update -y && sudo reboot
```

## 🆘 Troubleshooting

### **Common Issues**

**1. Terraform Permission Errors**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify IAM permissions
aws iam get-user
```

**2. Application Not Accessible**
```bash
# Check application health
./deploy-terraform.sh status

# View application logs
./deploy-terraform.sh ssh
docker logs food-portfolio-app
```

**3. SSL Certificate Issues**
```bash
# Check certificate status
sudo certbot certificates

# Manual renewal
sudo certbot renew
```

**4. Docker Build Failures**
```bash
# Check Docker daemon
docker info

# Clean Docker cache
./docker-build.sh cleanup
```

### **Debug Commands**
```bash
# Show detailed logs
./deploy-terraform.sh logs

# Check infrastructure status
./deploy-terraform.sh output

# Validate configuration
./terraform/test-terraform.sh validate

# Test connectivity
curl -v https://yourdomain.com/api/health
```

## 📚 Documentation

- 📖 [**Complete Deployment Guide**](terraform/TERRAFORM_DEPLOYMENT_GUIDE.md)
- 📖 [**AWS Setup Guide**](terraform/aws-setup-guide.md)
- 📖 [**Docker Automation**](docker-build.sh)
- 📖 [**Security Configuration**](security.sh)
- 📖 [**CI/CD Pipelines**](ci-cd-pipelines.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- 📧 **Issues**: [GitHub Issues](https://github.com/yourorg/food-portfolio/issues)
- 📚 **Documentation**: [Complete Guide](terraform/TERRAFORM_DEPLOYMENT_GUIDE.md)
- 💬 **Community**: [Discussions](https://github.com/yourorg/food-portfolio/discussions)

---

## ⭐ Star this Repository

If this project helped you, please consider giving it a ⭐ star to help others find it!

---

**Built with ❤️ for the culinary community**

*Deploy your food portfolio to the cloud in minutes, not hours!*