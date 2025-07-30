# DevOps Take-Home Test

A scalable and observable web application deployment using modern DevOps practices.

## 🏗️ Architecture Overview

This project demonstrates a complete DevOps workflow with:

- **Infrastructure as Code**: Terraform-managed AWS resources
- **Container Orchestration**: Amazon EKS (Elastic Kubernetes Service)
- **CI/CD Pipeline**: GitHub Actions for automated deployment
- **Monitoring & Observability**: Prometheus + Grafana stack
- **Load Balancing**: AWS Application Load Balancer
- **Auto-scaling**: EKS Cluster Autoscaler
- **HTTPS**: Cert-manager with Let's Encrypt
- **Secrets Management**: AWS Secrets Manager integration

### System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │    │  GitHub Actions │    │  AWS ECR        │
│                 │───▶│  CI/CD Pipeline │───▶│  Container      │
│                 │    │                 │    │  Registry       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Grafana       │    │   Prometheus    │    │   EKS Cluster   │
│   Dashboard     │◀───│   Monitoring    │◀───│   Application   │
│                 │    │                 │    │   Pods          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AWS Secrets   │    │   Cert-manager  │    │   ALB Ingress   │
│   Manager       │    │   (HTTPS)       │    │   Controller    │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- kubectl
- Docker
- GitHub account with repository access

### Step-by-Step Deployment

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/nezz-takehome-test.git
   cd nezz-takehome-test
   ```

2. **Configure AWS credentials**
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Access Key, and region
   ```

3. **Initialize and apply Terraform infrastructure**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configure kubectl for EKS**
   ```bash
   aws eks update-kubeconfig --region us-west-2 --name nezz-takehome-cluster
   ```

5. **Deploy the application**
   ```bash
   kubectl apply -f k8s/
   ```

6. **Access the application**
   - Application: https://your-domain.com
   - Grafana Dashboard: http://your-domain.com/grafana
   - Prometheus: http://your-domain.com/prometheus

## 📊 Monitoring & Alerting

### Metrics Available
- **Application Metrics**: Request rate, response time, error rate
- **Infrastructure Metrics**: CPU, memory, disk usage
- **Kubernetes Metrics**: Pod status, node health, resource utilization

### Dashboards
- **Application Dashboard**: Real-time application performance
- **Infrastructure Dashboard**: Cluster and node health
- **Business Dashboard**: User-facing metrics

### Alerting
- **Slack Integration**: Configured for critical alerts
- **Email Alerts**: Available for important notifications
- **PagerDuty**: Optional integration for on-call teams

## 🔧 Configuration

### Environment Variables
- `AWS_REGION`: AWS region for deployment
- `DOMAIN_NAME`: Your domain for HTTPS certificates
- `SLACK_WEBHOOK_URL`: Slack webhook for alerts
- `GITHUB_TOKEN`: GitHub token for CI/CD

### Secrets Management
- Database credentials stored in AWS Secrets Manager
- Application secrets managed via Kubernetes secrets
- TLS certificates automatically managed by cert-manager

## 🏗️ Infrastructure Details

### AWS Resources Created
- **VPC**: Custom VPC with public/private subnets
- **EKS Cluster**: Managed Kubernetes cluster
- **ALB**: Application Load Balancer for traffic distribution
- **ECR**: Container registry for Docker images
- **RDS**: PostgreSQL database (optional)
- **Secrets Manager**: Secure secret storage

### Kubernetes Components
- **Deployments**: Application and monitoring stack
- **Services**: Internal and external service definitions
- **Ingress**: Traffic routing with SSL termination
- **ConfigMaps**: Application configuration
- **Secrets**: Sensitive data management

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
1. **Build**: Create Docker image from source code
2. **Test**: Run unit and integration tests
3. **Scan**: Security vulnerability scanning
4. **Push**: Upload image to ECR
5. **Deploy**: Update Kubernetes deployment
6. **Verify**: Health check and smoke tests

### Deployment Strategies
- **Blue-Green**: Zero-downtime deployments
- **Canary**: Gradual traffic shifting
- **Rolling Update**: Default Kubernetes strategy

## 🛡️ Security Features

- **Network Security**: VPC with security groups
- **Pod Security**: Security contexts and policies
- **RBAC**: Role-based access control
- **Network Policies**: Pod-to-pod communication rules
- **TLS**: End-to-end encryption

## 📈 Scaling

### Horizontal Pod Autoscaling
- CPU-based autoscaling (50-80% threshold)
- Memory-based autoscaling (70-85% threshold)
- Custom metrics support

### Cluster Autoscaling
- Automatic node scaling based on demand
- Spot instance support for cost optimization
- Multi-AZ deployment for high availability

## 🧪 Testing

### Test Coverage
- **Unit Tests**: Application logic testing
- **Integration Tests**: API endpoint testing
- **E2E Tests**: Full user journey testing
- **Load Tests**: Performance validation

### Test Automation
- Automated testing in CI/CD pipeline
- Test result reporting and notifications
- Coverage metrics and reporting

## 🔍 Troubleshooting

### Common Issues
1. **EKS Cluster not accessible**
   - Verify AWS credentials and permissions
   - Check cluster status in AWS console

2. **Application not responding**
   - Check pod status: `kubectl get pods`
   - View logs: `kubectl logs <pod-name>`
   - Verify service configuration

3. **Monitoring not working**
   - Check Prometheus pod status
   - Verify service discovery configuration
   - Check Grafana data source settings

### Debug Commands
```bash
# Check cluster status
kubectl cluster-info

# View all resources
kubectl get all

# Check pod logs
kubectl logs -f deployment/app-deployment

# Port forward for local access
kubectl port-forward svc/app-service 8080:80
```

## 💰 Cost Optimization

### Recommendations
- Use Spot instances for non-critical workloads
- Implement resource requests and limits
- Enable cluster autoscaling
- Use appropriate instance types
- Monitor and optimize resource usage

### Estimated Costs (us-west-2)
- **EKS Cluster**: ~$73/month
- **ALB**: ~$16/month
- **ECR**: ~$0.10 per GB stored
- **Monitoring**: ~$5/month (t3.small instances)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For questions or issues:
- Create a GitHub issue
- Check the troubleshooting section
- Review the documentation

---

**Note**: This is a demonstration project. For production use, additional security, monitoring, and operational considerations should be implemented. 