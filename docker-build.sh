#!/bin/bash

# Docker Build and Push Automation Script for Food Portfolio
# This script automates Docker image building, tagging, and pushing to registries

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/docker-build.log"

# Default values
IMAGE_NAME="food-portfolio"
IMAGE_TAG="latest"
REGISTRY=""
DOCKERFILE="Dockerfile"
BUILD_CONTEXT="."
PLATFORM="linux/amd64"
NO_CACHE="false"
PUSH="false"
MULTI_ARCH="false"
SCAN_SECURITY="false"
BUILD_ARGS=""

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

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to display help
show_help() {
    cat << EOF
Docker Build and Push Automation Script

USAGE:
    $0 [OPTIONS] COMMAND

COMMANDS:
    build       Build Docker image
    push        Push Docker image to registry
    build-push  Build and push Docker image
    multi-arch  Build multi-architecture image
    scan        Scan image for security vulnerabilities
    cleanup     Clean up Docker resources
    help        Show this help message

OPTIONS:
    -n, --name NAME           Image name [default: food-portfolio]
    -t, --tag TAG            Image tag [default: latest]
    -r, --registry REGISTRY  Docker registry URL
    -f, --file DOCKERFILE    Dockerfile path [default: Dockerfile]
    -c, --context PATH       Build context path [default: .]
    -p, --platform PLATFORM  Target platform [default: linux/amd64]
    --no-cache               Build without cache
    --push                   Push after build
    --multi-arch             Build for multiple architectures
    --scan                   Scan for security vulnerabilities
    --build-arg ARG=VALUE    Build argument

EXAMPLES:
    # Basic build
    $0 build

    # Build with custom tag and push
    $0 -t v1.0.0 --push build

    # Build for multiple architectures
    $0 --multi-arch build

    # Build and push to custom registry
    $0 -r myregistry.com -t v1.0.0 build-push

    # Build with build arguments
    $0 --build-arg NODE_ENV=production build

    # Security scan
    $0 scan

DOCKER REGISTRIES:
    Docker Hub:      (no registry prefix)
    AWS ECR:         123456789.dkr.ecr.us-east-1.amazonaws.com
    Google GCR:      gcr.io/project-id
    GitHub:          ghcr.io/username
    GitLab:          registry.gitlab.com/group/project

EOF
}

# Function to check Docker availability
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running"
    fi
    
    success "Docker is available and running"
}

# Function to generate build arguments
prepare_build_args() {
    local args=""
    
    # Add timestamp
    args="$args --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    
    # Add version/tag
    args="$args --build-arg VERSION=$IMAGE_TAG"
    
    # Add VCS info if in git repo
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local git_commit=$(git rev-parse --short HEAD)
        local git_branch=$(git rev-parse --abbrev-ref HEAD)
        args="$args --build-arg VCS_REF=$git_commit"
        args="$args --build-arg VCS_BRANCH=$git_branch"
    fi
    
    # Add custom build args
    if [[ -n "$BUILD_ARGS" ]]; then
        args="$args $BUILD_ARGS"
    fi
    
    echo "$args"
}

# Function to get full image name
get_full_image_name() {
    if [[ -n "$REGISTRY" ]]; then
        echo "$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
    else
        echo "$IMAGE_NAME:$IMAGE_TAG"
    fi
}

# Function to build Docker image
build_image() {
    log "Building Docker image..."
    
    cd "$PROJECT_ROOT"
    
    local full_name=$(get_full_image_name)
    local build_args=$(prepare_build_args)
    local cache_flag=""
    
    if [[ "$NO_CACHE" == "true" ]]; then
        cache_flag="--no-cache"
    fi
    
    info "Image name: $full_name"
    info "Dockerfile: $DOCKERFILE"
    info "Build context: $BUILD_CONTEXT"
    info "Platform: $PLATFORM"
    
    # Build command
    local build_cmd="docker build"
    build_cmd="$build_cmd --platform $PLATFORM"
    build_cmd="$build_cmd --file $DOCKERFILE"
    build_cmd="$build_cmd --tag $full_name"
    build_cmd="$build_cmd $cache_flag"
    build_cmd="$build_cmd $build_args"
    build_cmd="$build_cmd $BUILD_CONTEXT"
    
    info "Build command: $build_cmd"
    
    if eval "$build_cmd"; then
        success "Docker image built successfully: $full_name"
        
        # Show image info
        docker images "$IMAGE_NAME" | head -2
        
        # Show image size
        local size=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep "$IMAGE_NAME" | grep "$IMAGE_TAG" | awk '{print $3}')
        info "Image size: $size"
        
    else
        error "Failed to build Docker image"
    fi
}

# Function to build multi-architecture image
build_multiarch_image() {
    log "Building multi-architecture Docker image..."
    
    # Check if buildx is available
    if ! docker buildx version &> /dev/null; then
        error "Docker buildx is not available. Please install Docker Desktop or buildx plugin."
    fi
    
    cd "$PROJECT_ROOT"
    
    local full_name=$(get_full_image_name)
    local build_args=$(prepare_build_args)
    local cache_flag=""
    local platforms="linux/amd64,linux/arm64"
    
    if [[ "$NO_CACHE" == "true" ]]; then
        cache_flag="--no-cache"
    fi
    
    info "Image name: $full_name"
    info "Platforms: $platforms"
    
    # Create builder if not exists
    if ! docker buildx ls | grep -q "food-portfolio-builder"; then
        docker buildx create --name food-portfolio-builder --use
    else
        docker buildx use food-portfolio-builder
    fi
    
    # Build command
    local build_cmd="docker buildx build"
    build_cmd="$build_cmd --platform $platforms"
    build_cmd="$build_cmd --file $DOCKERFILE"
    build_cmd="$build_cmd --tag $full_name"
    build_cmd="$build_cmd $cache_flag"
    build_cmd="$build_cmd $build_args"
    
    if [[ "$PUSH" == "true" ]]; then
        build_cmd="$build_cmd --push"
    else
        build_cmd="$build_cmd --load"
    fi
    
    build_cmd="$build_cmd $BUILD_CONTEXT"
    
    info "Build command: $build_cmd"
    
    if eval "$build_cmd"; then
        success "Multi-architecture Docker image built successfully: $full_name"
    else
        error "Failed to build multi-architecture Docker image"
    fi
}

# Function to push Docker image
push_image() {
    log "Pushing Docker image to registry..."
    
    local full_name=$(get_full_image_name)
    
    if [[ -z "$REGISTRY" ]]; then
        warning "No registry specified, pushing to Docker Hub"
    fi
    
    info "Pushing: $full_name"
    
    # Check if image exists locally
    if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$full_name$"; then
        error "Image $full_name not found locally. Build it first."
    fi
    
    # Push image
    if docker push "$full_name"; then
        success "Docker image pushed successfully: $full_name"
        
        # Show registry info
        info "Image available at: $full_name"
        
    else
        error "Failed to push Docker image"
    fi
}

# Function to scan image for security vulnerabilities
scan_image() {
    log "Scanning Docker image for security vulnerabilities..."
    
    local full_name=$(get_full_image_name)
    
    # Check if image exists locally
    if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$full_name$"; then
        error "Image $full_name not found locally. Build it first."
    fi
    
    # Try different scanning tools
    if command -v docker &> /dev/null && docker scout version &> /dev/null; then
        info "Using Docker Scout for vulnerability scanning..."
        docker scout cves "$full_name"
        
    elif command -v trivy &> /dev/null; then
        info "Using Trivy for vulnerability scanning..."
        trivy image "$full_name"
        
    elif command -v grype &> /dev/null; then
        info "Using Grype for vulnerability scanning..."
        grype "$full_name"
        
    else
        warning "No security scanning tool found. Consider installing:"
        echo "  - Docker Scout (built into Docker)"
        echo "  - Trivy: https://trivy.dev/"
        echo "  - Grype: https://github.com/anchore/grype"
        return 1
    fi
    
    success "Security scan completed"
}

# Function to cleanup Docker resources
cleanup_docker() {
    log "Cleaning up Docker resources..."
    
    # Remove unused images
    info "Removing unused images..."
    docker image prune -f
    
    # Remove unused containers
    info "Removing unused containers..."
    docker container prune -f
    
    # Remove unused volumes
    info "Removing unused volumes..."
    docker volume prune -f
    
    # Remove unused networks
    info "Removing unused networks..."
    docker network prune -f
    
    # Remove build cache
    info "Removing build cache..."
    docker builder prune -f
    
    success "Docker cleanup completed"
    
    # Show disk usage
    info "Current Docker disk usage:"
    docker system df
}

# Function to show image history and layers
show_image_info() {
    local full_name=$(get_full_image_name)
    
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$full_name$"; then
        echo -e "\n${CYAN}=== Image Information ===${NC}"
        docker inspect "$full_name" --format '
Image ID: {{.Id}}
Created: {{.Created}}
Size: {{.Size}} bytes
Architecture: {{.Architecture}}
OS: {{.Os}}
'
        
        echo -e "\n${CYAN}=== Image Layers ===${NC}"
        docker history "$full_name" --no-trunc
        
    else
        warning "Image $full_name not found locally"
    fi
}

# Function to test image locally
test_image_local() {
    log "Testing Docker image locally..."
    
    local full_name=$(get_full_image_name)
    local container_name="food-portfolio-test-$(date +%s)"
    
    # Check if image exists locally
    if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$full_name$"; then
        error "Image $full_name not found locally. Build it first."
    fi
    
    info "Starting test container: $container_name"
    
    # Run container for testing
    if docker run -d --name "$container_name" -p 5000:5000 "$full_name"; then
        info "Container started successfully"
        
        # Wait for application to start
        sleep 10
        
        # Test health endpoint
        if curl -f -s http://localhost:5000/api/health > /dev/null; then
            success "✓ Application health check passed"
        else
            warning "✗ Application health check failed"
        fi
        
        # Show container logs
        echo -e "\n${CYAN}=== Container Logs ===${NC}"
        docker logs --tail 20 "$container_name"
        
        # Cleanup test container
        docker stop "$container_name" > /dev/null 2>&1
        docker rm "$container_name" > /dev/null 2>&1
        
        success "Local test completed"
        
    else
        error "Failed to start test container"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -f|--file)
            DOCKERFILE="$2"
            shift 2
            ;;
        -c|--context)
            BUILD_CONTEXT="$2"
            shift 2
            ;;
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE="true"
            shift
            ;;
        --push)
            PUSH="true"
            shift
            ;;
        --multi-arch)
            MULTI_ARCH="true"
            shift
            ;;
        --scan)
            SCAN_SECURITY="true"
            shift
            ;;
        --build-arg)
            BUILD_ARGS="$BUILD_ARGS --build-arg $2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

# Main command processing
case "${1:-build}" in
    build)
        check_docker
        if [[ "$MULTI_ARCH" == "true" ]]; then
            build_multiarch_image
        else
            build_image
        fi
        if [[ "$PUSH" == "true" ]]; then
            push_image
        fi
        if [[ "$SCAN_SECURITY" == "true" ]]; then
            scan_image
        fi
        show_image_info
        ;;
    push)
        check_docker
        push_image
        ;;
    build-push)
        check_docker
        if [[ "$MULTI_ARCH" == "true" ]]; then
            PUSH="true"
            build_multiarch_image
        else
            build_image
            push_image
        fi
        if [[ "$SCAN_SECURITY" == "true" ]]; then
            scan_image
        fi
        ;;
    multi-arch)
        check_docker
        MULTI_ARCH="true"
        build_multiarch_image
        ;;
    scan)
        check_docker
        scan_image
        ;;
    test)
        check_docker
        test_image_local
        ;;
    info)
        show_image_info
        ;;
    cleanup)
        check_docker
        cleanup_docker
        ;;
    help)
        show_help
        ;;
    *)
        error "Unknown command: $1. Use 'help' for usage information."
        ;;
esac