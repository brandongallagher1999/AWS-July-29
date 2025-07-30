# Deployment Guide

This guide provides step-by-step instructions for deploying the DevOps take-home test application on a fresh AWS account.

## Prerequisites

### Required Software
- **AWS CLI** (v2.x or later)
- **Terraform** (v1.0 or later)
- **kubectl** (v1.28 or later)
- **Docker** (v20.x or later)
- **Git** (v2.x or later)

### AWS Account Setup
1. Create a new AWS account (free tier eligible)
2. Create an IAM user with appropriate permissions
3. Configure AWS CLI credentials

### Required Permissions
The IAM user needs the following permissions:
- EC2 (Full access)
- EKS (Full access)
- ECR (Full access)
- IAM (Limited access for service roles)
- VPC (Full access)
- Secrets Manager (Full access)
- CloudWatch (Full access)

## Step-by-Step Deployment

### Step 1: Clone the Repository

```bash
git clone https://github.com/your-username/takehome-test.git
cd takehome-test
```

### Step 2: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your preferred region (e.g., us-west-2)
# Enter your preferred output format (json)
```

### Step 3: Create S3 Bucket for Terraform State

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://takehome-terraform-state --region us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket takehome-terraform-state \
    --versioning-configuration Status=Enabled
```

### Step 4: Deploy Infrastructure

```bash
# Navigate to Terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the infrastructure
terraform apply
```

**Expected Output:**
- EKS cluster will be created (takes 10-15 minutes)
- VPC with public/private subnets
- ECR repository
- ALB controller IAM roles
- Secrets Manager secret

### Step 5: Configure kubectl

```bash
# Get cluster name from Terraform output
CLUSTER_NAME=$(terraform output -raw cluster_name)

# Configure kubectl for EKS
aws eks update-kubeconfig --region us-west-2 --name $CLUSTER_NAME

# Verify connection
kubectl cluster-info
```

### Step 6: Install ALB Controller

```bash
# Install ALB controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# Get cluster OIDC provider
aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text

# Install ALB controller with Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller
```

### Step 7: Build and Push Docker Image

```bash
# Get ECR repository URL
ECR_REPO=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_REPO

# Build Docker image
docker build -t $ECR_REPO:latest .

# Push to ECR
docker push $ECR_REPO:latest
```

### Step 8: Deploy Application

```bash
# Navigate back to project root
cd ..

# Update deployment with ECR repository URL
sed -i.bak "s|\${ECR_REPOSITORY_URL}|$ECR_REPO|g" k8s/deployment.yaml

# Apply Kubernetes manifests
kubectl apply -f k8s/
```

### Step 9: Verify Deployment

```bash
# Check pod status
kubectl get pods -n takehome

# Check services
kubectl get svc -n takehome

# Check ingress
kubectl get ingress -n takehome

# Wait for ALB to be provisioned
kubectl wait --for=condition=ready ingress/app-ingress -n takehome --timeout=300s
```

### Step 10: Access the Application

```bash
# Get the ALB URL
ALB_URL=$(kubectl get ingress app-ingress -n takehome -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Application URL: http://$ALB_URL"
echo "Health Check: http://$ALB_URL/health"
echo "Metrics: http://$ALB_URL/metrics"
```

## Monitoring Setup

### Step 11: Access Monitoring Dashboards

```bash
# Port forward to access Grafana
kubectl port-forward svc/grafana 3001:3000 -n takehome

# Port forward to access Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n takehome
```

**Access URLs:**
- Grafana: http://localhost:3001 (admin/admin123)
- Prometheus: http://localhost:9090

### Step 12: Configure Alerts

```bash
# Update AlertManager with Slack webhook (optional)
# Edit k8s/monitoring/alertmanager.yaml and replace ${SLACK_WEBHOOK_URL}
# Then apply the updated configuration
kubectl apply -f k8s/monitoring/alertmanager.yaml
```

## Testing the Deployment

### Step 13: Run Load Tests

```bash
# Install hey (load testing tool)
# macOS: brew install hey
# Linux: wget https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64

# Run load test
hey -n 1000 -c 10 http://$ALB_URL/

# Test health endpoint
curl http://$ALB_URL/health

# Test metrics endpoint
curl http://$ALB_URL/metrics
```

### Step 14: Test Autoscaling

```bash
# Scale up the deployment
kubectl scale deployment app-deployment --replicas=5 -n takehome

# Monitor scaling
kubectl get hpa -n takehome
kubectl describe hpa app-hpa -n takehome
```

## Troubleshooting

### Common Issues

#### 1. EKS Cluster Not Ready
```bash
# Check cluster status
aws eks describe-cluster --name $CLUSTER_NAME --region us-west-2

# Check node status
kubectl get nodes
kubectl describe nodes
```

#### 2. Pods Not Starting
```bash
# Check pod events
kubectl describe pod -l app=takehome-app -n takehome

# Check pod logs
kubectl logs -l app=takehome-app -n takehome
```

#### 3. ALB Not Provisioned
```bash
# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check ingress events
kubectl describe ingress app-ingress -n takehome
```

#### 4. Image Pull Errors
```bash
# Check ECR repository
aws ecr describe-repositories --repository-names takehome-test-app

# Verify image exists
aws ecr describe-images --repository-name takehome-test-app
```

### Debug Commands

```bash
# Get all resources in namespace
kubectl get all -n takehome

# Check events
kubectl get events -n takehome --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n takehome
kubectl top nodes

# Check service endpoints
kubectl get endpoints -n takehome
```

## Cleanup

### Step 15: Destroy Infrastructure

```bash
# Delete Kubernetes resources
kubectl delete -f k8s/

# Wait for resources to be deleted
sleep 60

# Destroy Terraform infrastructure
cd terraform
terraform destroy -auto-approve

# Delete S3 bucket (if empty)
aws s3 rb s3://takehome-terraform-state --force
```

## Cost Estimation

### Monthly Costs (us-west-2)
- **EKS Cluster**: ~$73/month
- **ALB**: ~$16/month
- **EC2 Instances**: ~$30/month (t3.medium x 2)
- **EBS Volumes**: ~$5/month
- **Data Transfer**: ~$5/month
- **Total**: ~$129/month

### Cost Optimization Tips
1. Use Spot instances for non-critical workloads
2. Implement proper resource requests and limits
3. Enable cluster autoscaling
4. Use appropriate instance types
5. Monitor and optimize resource usage

## Security Considerations

### Network Security
- VPC with private subnets for application workloads
- Security groups with minimal required access
- ALB with SSL termination
- Network policies for pod-to-pod communication

### Application Security
- Non-root containers
- Read-only filesystems
- Security headers
- Input validation
- Secrets management

### Access Control
- IAM roles with least privilege
- RBAC for Kubernetes access
- Service accounts for pod authentication
- Regular access reviews

## Performance Optimization

### Application Level
- Implement caching strategies
- Optimize database queries
- Use connection pooling
- Implement proper error handling

### Infrastructure Level
- Use appropriate instance types
- Implement auto-scaling
- Optimize network configuration
- Monitor and tune performance

## Monitoring and Alerting

### Key Metrics to Monitor
- Application response time
- Error rates
- Resource utilization
- Pod restart frequency
- Network latency

### Alert Thresholds
- CPU usage > 80%
- Memory usage > 85%
- Error rate > 10%
- Response time > 2 seconds
- Pod restarts > 5 per hour

## Next Steps

### Production Considerations
1. Implement proper logging strategy
2. Set up backup and disaster recovery
3. Configure monitoring and alerting
4. Implement security scanning
5. Set up CI/CD pipeline
6. Configure cost monitoring
7. Implement compliance controls

### Scaling Considerations
1. Database scaling strategies
2. Caching implementation
3. CDN integration
4. Microservices architecture
5. Service mesh implementation 
