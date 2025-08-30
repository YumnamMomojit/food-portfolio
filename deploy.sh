#!/bin/bash

# Food Portfolio - Docker Deployment Script for EC2
# This script automates the deployment process on EC2

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="food-portfolio"
CONTAINER_NAME="food-portfolio-app"
NGINX_CONTAINER="food-portfolio-nginx"
BACKUP_DIR="/home/ec2-user/backups"
LOG_FILE="/home/ec2-user/deploy.log"

# Function to log messages
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
    fi
    
    # Check if .env file exists
    if [ ! -f ".env" ]; then
        warning ".env file not found. Please create it from .env.production template."
        if [ -f ".env.production" ]; then
            cp .env.production .env
            warning "Copied .env.production to .env. Please update it with your values."
        else
            error "No environment file found. Please create .env file."
        fi
    fi
    
    log "Prerequisites check completed successfully"
}

# Function to create backup
create_backup() {
    log "Creating backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/${PROJECT_NAME}-backup-$DATE.tar.gz"
    
    # Backup current deployment
    if [ -d "/home/ec2-user/$PROJECT_NAME" ]; then
        tar -czf "$BACKUP_FILE" -C "/home/ec2-user" "$PROJECT_NAME" || warning "Failed to create backup"
        log "Backup created: $BACKUP_FILE"
    else
        warning "No existing deployment found to backup"
    fi
    
    # Clean old backups (keep last 5)
    find "$BACKUP_DIR" -name "${PROJECT_NAME}-backup-*.tar.gz" -mtime +5 -delete 2>/dev/null || true
}

# Function to stop existing containers
stop_containers() {
    log "Stopping existing containers..."
    
    # Stop and remove containers if they exist
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        docker stop "$CONTAINER_NAME" || warning "Failed to stop $CONTAINER_NAME"
        docker rm "$CONTAINER_NAME" || warning "Failed to remove $CONTAINER_NAME"
    fi
    
    if docker ps -q -f name="$NGINX_CONTAINER" | grep -q .; then
        docker stop "$NGINX_CONTAINER" || warning "Failed to stop $NGINX_CONTAINER"
        docker rm "$NGINX_CONTAINER" || warning "Failed to remove $NGINX_CONTAINER"
    fi
    
    # Alternative: use docker-compose down if using compose
    if [ -f "docker-compose.yml" ]; then
        docker-compose down || warning "Failed to stop docker-compose services"
    fi
    
    log "Existing containers stopped"
}

# Function to build and deploy
build_and_deploy() {
    log "Building and deploying application..."
    
    # Build Docker image
    info "Building Docker image..."
    docker build -t "$PROJECT_NAME:latest" . || error "Failed to build Docker image"
    
    # Run the application container
    info "Starting application container..."
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p 5000:5000 \
        --env-file .env \
        "$PROJECT_NAME:latest" || error "Failed to start application container"
    
    log "Application deployed successfully"
}

# Function to deploy with Docker Compose
deploy_with_compose() {
    log "Deploying with Docker Compose..."
    
    if [ "$1" = "production" ]; then
        docker-compose --profile production up -d --build || error "Failed to deploy with Docker Compose (production)"
    else
        docker-compose up -d --build || error "Failed to deploy with Docker Compose"
    fi
    
    log "Docker Compose deployment completed"
}

# Function to verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Wait a moment for container to start
    sleep 10
    
    # Check if container is running
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        error "Container $CONTAINER_NAME is not running"
    fi
    
    # Check health endpoint
    for i in {1..5}; do
        if curl -f -s http://localhost:5000/api/health > /dev/null; then
            log "Health check passed"
            break
        else
            warning "Health check failed (attempt $i/5). Retrying in 10 seconds..."
            sleep 10
            if [ $i -eq 5 ]; then
                error "Health check failed after 5 attempts"
            fi
        fi
    done
    
    # Display running containers
    info "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    log "Deployment verification completed successfully"
}

# Function to show logs
show_logs() {
    log "Showing application logs..."
    docker logs --tail 50 -f "$CONTAINER_NAME"
}

# Function to update application (git pull + redeploy)
update_application() {
    log "Updating application..."
    
    # Pull latest changes
    if [ -d ".git" ]; then
        git pull origin main || warning "Failed to pull latest changes"
    else
        warning "Not a git repository. Skipping git pull."
    fi
    
    # Redeploy
    create_backup
    stop_containers
    
    if [ -f "docker-compose.yml" ] && [ "$1" = "compose" ]; then
        deploy_with_compose "$2"
    else
        build_and_deploy
    fi
    
    verify_deployment
    log "Application updated successfully"
}

# Function to rollback to previous backup
rollback() {
    log "Rolling back to previous backup..."
    
    LATEST_BACKUP=$(find "$BACKUP_DIR" -name "${PROJECT_NAME}-backup-*.tar.gz" | sort -r | head -n 1)
    
    if [ -z "$LATEST_BACKUP" ]; then
        error "No backup found for rollback"
    fi
    
    stop_containers
    
    # Extract backup
    cd "/home/ec2-user"
    tar -xzf "$LATEST_BACKUP" || error "Failed to extract backup"
    
    cd "$PROJECT_NAME"
    build_and_deploy
    verify_deployment
    
    log "Rollback completed successfully"
}

# Function to show status
show_status() {
    echo -e "\n${BLUE}=== Food Portfolio Deployment Status ===${NC}"
    
    # Show container status
    echo -e "\n${YELLOW}Container Status:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAME|food-portfolio)" || echo "No containers running"
    
    # Show disk usage
    echo -e "\n${YELLOW}Disk Usage:${NC}"
    df -h / | tail -n 1
    
    # Show memory usage
    echo -e "\n${YELLOW}Memory Usage:${NC}"
    free -h | head -n 2
    
    # Show recent logs
    echo -e "\n${YELLOW}Recent Logs (last 10 lines):${NC}"
    if docker ps | grep -q "$CONTAINER_NAME"; then
        docker logs --tail 10 "$CONTAINER_NAME"
    else
        echo "Container not running"
    fi
}

# Function to cleanup
cleanup() {
    log "Cleaning up..."
    
    # Remove unused Docker images
    docker image prune -f || warning "Failed to prune images"
    
    # Remove unused volumes
    docker volume prune -f || warning "Failed to prune volumes"
    
    # Clean old backups (keep last 3)
    find "$BACKUP_DIR" -name "${PROJECT_NAME}-backup-*.tar.gz" -mtime +3 -delete 2>/dev/null || true
    
    log "Cleanup completed"
}

# Main script logic
main() {
    case "$1" in
        "deploy"|"")
            check_prerequisites
            create_backup
            stop_containers
            if [ "$2" = "compose" ]; then
                deploy_with_compose "$3"
            else
                build_and_deploy
            fi
            verify_deployment
            ;;
        "update")
            update_application "$2" "$3"
            ;;
        "rollback")
            rollback
            ;;
        "logs")
            show_logs
            ;;
        "status")
            show_status
            ;;
        "stop")
            stop_containers
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command] [options]"
            echo ""
            echo "Commands:"
            echo "  deploy         - Deploy the application (default)"
            echo "  deploy compose - Deploy using Docker Compose"
            echo "  deploy compose production - Deploy with production profile"
            echo "  update         - Update application (git pull + redeploy)"
            echo "  update compose - Update using Docker Compose"
            echo "  rollback       - Rollback to previous backup"
            echo "  logs          - Show application logs"
            echo "  status        - Show deployment status"
            echo "  stop          - Stop all containers"
            echo "  cleanup       - Clean up unused Docker resources"
            echo "  help          - Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 deploy"
            echo "  $0 deploy compose production"
            echo "  $0 update"
            echo "  $0 logs"
            ;;
        *)
            error "Unknown command: $1. Use '$0 help' for usage information."
            ;;
    esac
}

# Run main function with all arguments
main "$@"