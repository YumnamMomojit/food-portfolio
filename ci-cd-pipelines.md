# CI/CD Pipeline Configuration for Food Portfolio

# This directory contains CI/CD pipeline configurations for various platforms

## GitHub Actions Workflow
name: Build and Deploy Food Portfolio

on:
  push:
    branches: [ main, develop ]
    tags: [ 'v*' ]
  pull_request:
    branches: [ main ]

env:
  IMAGE_NAME: food-portfolio
  REGISTRY: ghcr.io
  
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      security-events: write

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ github.repository }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}
          type=sha,prefix={{branch}}-

    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ env.REGISTRY }}/${{ github.repository }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_REGION }}

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.5.0

    - name: Terraform Init
      run: |
        cd terraform
        terraform init

    - name: Terraform Plan
      run: |
        cd terraform
        terraform plan -out=tfplan
      env:
        TF_VAR_supabase_url: ${{ secrets.SUPABASE_URL }}
        TF_VAR_supabase_anon_key: ${{ secrets.SUPABASE_ANON_KEY }}
        TF_VAR_supabase_service_role_key: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
        TF_VAR_gemini_api_key: ${{ secrets.GEMINI_API_KEY }}
        TF_VAR_public_key_content: ${{ secrets.PUBLIC_KEY_CONTENT }}

    - name: Terraform Apply
      run: |
        cd terraform
        terraform apply -auto-approve tfplan
      env:
        TF_VAR_supabase_url: ${{ secrets.SUPABASE_URL }}
        TF_VAR_supabase_anon_key: ${{ secrets.SUPABASE_ANON_KEY }}
        TF_VAR_supabase_service_role_key: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
        TF_VAR_gemini_api_key: ${{ secrets.GEMINI_API_KEY }}
        TF_VAR_public_key_content: ${{ secrets.PUBLIC_KEY_CONTENT }}

## Required Secrets for GitHub Actions

Add these secrets to your GitHub repository:

- `AWS_ACCESS_KEY_ID`: Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key  
- `AWS_REGION`: Your AWS region (e.g., us-east-1)
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key
- `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key
- `GEMINI_API_KEY`: Your Google Gemini AI API key
- `PUBLIC_KEY_CONTENT`: Your SSH public key content

## GitLab CI Configuration (.gitlab-ci.yml)

stages:
  - build
  - test
  - security
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: ""
  IMAGE_NAME: food-portfolio

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE/$IMAGE_NAME:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE/$IMAGE_NAME:$CI_COMMIT_SHA
  only:
    - main
    - develop

security_scan:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy image --exit-code 0 --format template --template "@contrib/sarif.tpl" -o trivy-report.sarif $CI_REGISTRY_IMAGE/$IMAGE_NAME:$CI_COMMIT_SHA
    - trivy image --exit-code 1 --severity HIGH,CRITICAL $CI_REGISTRY_IMAGE/$IMAGE_NAME:$CI_COMMIT_SHA
  artifacts:
    reports:
      sast: trivy-report.sarif
  only:
    - main
    - develop

deploy_production:
  stage: deploy
  image: hashicorp/terraform:latest
  before_script:
    - cd terraform
    - terraform init
  script:
    - terraform plan -out=tfplan
    - terraform apply -auto-approve tfplan
  only:
    - main
  when: manual

## Azure DevOps Pipeline (azure-pipelines.yml)

trigger:
  branches:
    include:
    - main
    - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  imageName: 'food-portfolio'
  dockerRegistryServiceConnection: 'DockerHub'
  imageRepository: 'food-portfolio'
  dockerfilePath: 'Dockerfile'
  tag: '$(Build.BuildId)'

stages:
- stage: Build
  displayName: Build and push stage
  jobs:
  - job: Build
    displayName: Build job
    steps:
    - task: Docker@2
      displayName: Build and push Docker image
      inputs:
        command: buildAndPush
        repository: $(imageRepository)
        dockerfile: $(dockerfilePath)
        containerRegistry: $(dockerRegistryServiceConnection)
        tags: |
          $(tag)
          latest

- stage: SecurityScan
  displayName: Security scan stage
  dependsOn: Build
  jobs:
  - job: SecurityScan
    displayName: Security scan job
    steps:
    - script: |
        docker run --rm -v $(pwd):/workspace aquasec/trivy:latest image $(imageRepository):$(tag)
      displayName: 'Run Trivy security scan'

- stage: Deploy
  displayName: Deploy to AWS
  dependsOn: SecurityScan
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - job: Deploy
    displayName: Deploy job
    steps:
    - task: TerraformInstaller@0
      displayName: Install Terraform
      inputs:
        terraformVersion: 'latest'
    
    - script: |
        cd terraform
        terraform init
        terraform plan -out=tfplan
        terraform apply -auto-approve tfplan
      displayName: 'Deploy with Terraform'
      env:
        AWS_ACCESS_KEY_ID: $(AWS_ACCESS_KEY_ID)
        AWS_SECRET_ACCESS_KEY: $(AWS_SECRET_ACCESS_KEY)
        TF_VAR_supabase_url: $(SUPABASE_URL)
        TF_VAR_supabase_anon_key: $(SUPABASE_ANON_KEY)
        TF_VAR_supabase_service_role_key: $(SUPABASE_SERVICE_ROLE_KEY)
        TF_VAR_gemini_api_key: $(GEMINI_API_KEY)
        TF_VAR_public_key_content: $(PUBLIC_KEY_CONTENT)

## Jenkins Pipeline (Jenkinsfile)

pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        IMAGE_NAME = 'food-portfolio'
        AWS_DEFAULT_REGION = 'us-east-1'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    def image = docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}")
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    sh """
                        docker run --rm -v \$(pwd):/workspace aquasec/trivy:latest image ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    """
                }
            }
        }
        
        stage('Push to Registry') {
            when {
                branch 'main'
            }
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-registry-credentials') {
                        def image = docker.image("${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}")
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to AWS') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                    string(credentialsId: 'supabase-url', variable: 'TF_VAR_supabase_url'),
                    string(credentialsId: 'supabase-anon-key', variable: 'TF_VAR_supabase_anon_key'),
                    string(credentialsId: 'supabase-service-role-key', variable: 'TF_VAR_supabase_service_role_key'),
                    string(credentialsId: 'gemini-api-key', variable: 'TF_VAR_gemini_api_key'),
                    string(credentialsId: 'public-key-content', variable: 'TF_VAR_public_key_content')
                ]) {
                    sh """
                        cd terraform
                        terraform init
                        terraform plan -out=tfplan
                        terraform apply -auto-approve tfplan
                    """
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}

## Docker Compose for CI/CD Testing

version: '3.8'

services:
  app-test:
    build:
      context: .
      dockerfile: Dockerfile
      target: test
    environment:
      - NODE_ENV=test
      - CI=true
    volumes:
      - ./coverage:/app/coverage
    command: npm test

  security-scan:
    image: aquasec/trivy:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: image food-portfolio:latest

## Local Development CI/CD Simulation

#!/bin/bash
# simulate-ci.sh - Simulate CI/CD pipeline locally

set -e

echo "🚀 Simulating CI/CD Pipeline Locally"

# Build
echo "📦 Building Docker image..."
./docker-build.sh build

# Test
echo "🧪 Running tests..."
./docker-build.sh test

# Security scan
echo "🔒 Security scanning..."
./docker-build.sh scan

# Deploy (dry run)
echo "🚀 Deployment simulation..."
./deploy-terraform.sh plan

echo "✅ CI/CD simulation completed successfully!"