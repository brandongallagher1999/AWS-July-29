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

echo -e "${YELLOW}🧹 Starting cleanup of ${PROJECT_NAME}...${NC}"

# Check AWS credentials
echo -e "${YELLOW}🔐 Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure'${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials are configured${NC}"

# Delete Kubernetes resources
echo -e "${YELLOW}🗑️  Deleting Kubernetes resources...${NC}"
kubectl delete -f k8s/ --ignore-not-found=true || true

# Wait for resources to be deleted
echo -e "${YELLOW}⏳ Waiting for Kubernetes resources to be deleted...${NC}"
sleep 30

# Destroy Terraform infrastructure
echo -e "${YELLOW}🏗️  Destroying infrastructure with Terraform...${NC}"
cd terraform

# Initialize Terraform if not already done
terraform init

# Destroy infrastructure
echo -e "${YELLOW}💥 Destroying infrastructure...${NC}"
terraform destroy -auto-approve

cd ..

echo -e "${GREEN}✅ Cleanup completed successfully!${NC}"
echo -e "${YELLOW}📝 Note: Some resources may take a few minutes to be fully deleted${NC}" 
