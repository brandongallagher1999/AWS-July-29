#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="nezz-takehome-test"
AWS_REGION="us-west-2"
EKS_CLUSTER_NAME="${PROJECT_NAME}-cluster"
ECR_REPOSITORY="${PROJECT_NAME}-app"

echo -e "${GREEN}🚀 Starting deployment of ${PROJECT_NAME}...${NC}"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

command -v aws >/dev/null 2>&1 || { echo -e "${RED}❌ AWS CLI is required but not installed.${NC}" >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}❌ Terraform is required but not installed.${NC}" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}❌ kubectl is required but not installed.${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ Docker is required but not installed.${NC}" >&2; exit 1; }

echo -e "${GREEN}✅ All prerequisites are installed${NC}"

# Check AWS credentials
echo -e "${YELLOW}🔐 Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure'${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials are configured${NC}"

# Deploy infrastructure with Terraform
echo -e "${YELLOW}🏗️  Deploying infrastructure with Terraform...${NC}"
cd terraform

# Initialize Terraform
echo -e "${YELLOW}📦 Initializing Terraform...${NC}"
terraform init

# Plan Terraform changes
echo -e "${YELLOW}📋 Planning Terraform changes...${NC}"
terraform plan -out=tfplan

# Apply Terraform changes
echo -e "${YELLOW}🚀 Applying Terraform changes...${NC}"
terraform apply tfplan

# Get outputs
echo -e "${YELLOW}📤 Getting Terraform outputs...${NC}"
ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url)
CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint)

cd ..

echo -e "${GREEN}✅ Infrastructure deployed successfully${NC}"

# Configure kubectl for EKS
echo -e "${YELLOW}⚙️  Configuring kubectl for EKS...${NC}"
aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME

# Wait for cluster to be ready
echo -e "${YELLOW}⏳ Waiting for EKS cluster to be ready...${NC}"
kubectl wait --for=condition=ready nodes --all --timeout=300s

# Build and push Docker image
echo -e "${YELLOW}🐳 Building and pushing Docker image...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URL

docker build -t $ECR_REPOSITORY_URL:latest .
docker push $ECR_REPOSITORY_URL:latest

echo -e "${GREEN}✅ Docker image pushed successfully${NC}"

# Deploy application to Kubernetes
echo -e "${YELLOW}🚀 Deploying application to Kubernetes...${NC}"

# Update deployment with ECR repository URL
sed -i.bak "s|\${ECR_REPOSITORY_URL}|$ECR_REPOSITORY_URL|g" k8s/deployment.yaml

# Apply Kubernetes manifests
kubectl apply -f k8s/

# Wait for deployment to be ready
echo -e "${YELLOW}⏳ Waiting for deployment to be ready...${NC}"
kubectl rollout status deployment/app-deployment -n nezz-takehome --timeout=300s

# Get service URL
echo -e "${YELLOW}🌐 Getting service URL...${NC}"
SERVICE_URL=$(kubectl get ingress app-ingress -n nezz-takehome -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")

if [ "$SERVICE_URL" = "pending" ]; then
    echo -e "${YELLOW}⏳ Waiting for ALB to be provisioned...${NC}"
    sleep 60
    SERVICE_URL=$(kubectl get ingress app-ingress -n nezz-takehome -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
fi

# Run health check
echo -e "${YELLOW}🏥 Running health check...${NC}"
sleep 30
if curl -f http://$SERVICE_URL/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Health check passed${NC}"
else
    echo -e "${RED}❌ Health check failed${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}📱 Application URL: http://$SERVICE_URL${NC}"
echo -e "${GREEN}📊 Grafana Dashboard: http://$SERVICE_URL/grafana${NC}"
echo -e "${GREEN}📈 Prometheus: http://$SERVICE_URL/prometheus${NC}"
echo -e "${GREEN}🔍 Health Check: http://$SERVICE_URL/health${NC}"

# Display cluster information
echo -e "${YELLOW}📋 Cluster Information:${NC}"
echo -e "  Cluster Name: $EKS_CLUSTER_NAME"
echo -e "  Region: $AWS_REGION"
echo -e "  ECR Repository: $ECR_REPOSITORY_URL"
echo -e "  Service URL: $SERVICE_URL"

# Display useful commands
echo -e "${YELLOW}🔧 Useful Commands:${NC}"
echo -e "  View pods: kubectl get pods -n nezz-takehome"
echo -e "  View logs: kubectl logs -f deployment/app-deployment -n nezz-takehome"
echo -e "  View services: kubectl get svc -n nezz-takehome"
echo -e "  View ingress: kubectl get ingress -n nezz-takehome"
echo -e "  Scale deployment: kubectl scale deployment app-deployment --replicas=5 -n nezz-takehome" 