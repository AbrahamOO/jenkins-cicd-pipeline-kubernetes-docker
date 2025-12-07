# Jenkins Pipeline CI/CD Demo

[![Jenkins](https://img.shields.io/badge/Jenkins-Pipeline-red?logo=jenkins)](https://www.jenkins.io/)
[![Docker](https://img.shields.io/badge/Docker-Multi--stage-blue?logo=docker)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Kind-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![FastAPI](https://img.shields.io/badge/FastAPI-Python-009688?logo=fastapi)](https://fastapi.tiangolo.com/)
[![Security](https://img.shields.io/badge/Security-Trivy-1904DA?logo=aqua)](https://trivy.dev/)

Hey there! I built this project to showcase a complete, production-ready CI/CD pipeline using Jenkins Pipeline as Code. Everything runs locally, so you can see it in action without needing any cloud services. It's a fully functional pipeline that handles building, testing, security scanning, and deploying a FastAPI microservice.

## What's This All About?

This project demonstrates real-world DevOps practices that I use in production environments:

- **Jenkins Pipeline as Code** - Everything is defined in code, no manual clicking around
- **Multi-stage Docker builds** - Optimized images with security baked in
- **Automated testing** - pytest running on every build
- **Security scanning** - Trivy checking for vulnerabilities before deployment
- **Container registry** - Local registry for image management
- **Kubernetes deployment** - Automated deployment to Kind/Minikube
- **Infrastructure as Code** - Complete automation from start to finish
- **Monitoring** - Optional Prometheus and Grafana setup

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       Jenkins Pipeline                           │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐   │
│  │Build │→ │Test  │→ │Scan  │→ │Push  │→ │Deploy│→ │Verify│   │
│  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    ┌──────────────────┐
                    │ Local Registry   │
                    │  localhost:5000  │
                    └──────────────────┘
                              ↓
                    ┌──────────────────┐
                    │ Kubernetes (Kind)│
                    │   Deployment     │
                    └──────────────────┘
```

## Prerequisites

Before getting started, make sure you have these installed:

### Required
- **Docker** (v20.10+) - For containerization
  ```bash
  docker --version
  ```
- **Docker Compose** (v2.0+) - For orchestrating services
  ```bash
  docker-compose --version
  ```
- **Make** - Makes running commands easier
  ```bash
  make --version
  ```

### For Kubernetes Deployment
- **Kind** (recommended) or **Minikube** - Local Kubernetes clusters
  ```bash
  # Install Kind (macOS)
  brew install kind

  # Install Kind (Linux)
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
  ```

- **kubectl** - Kubernetes CLI
  ```bash
  # Install kubectl (macOS)
  brew install kubectl

  # Install kubectl (Linux)
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
  ```

### Optional
- **Trivy** - For local security scanning
  ```bash
  # macOS
  brew install aquasecurity/trivy/trivy

  # Linux
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
  echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
  sudo apt-get update
  sudo apt-get install trivy
  ```

## Quick Start

### The Easiest Way

```bash
# Navigate to the project directory
cd jenkins-pipeline-cicd

# Install and start everything with one command
make install
```

That's it! This single command will:
1. Check that you have all prerequisites
2. Start Jenkins, a local Docker registry, and the application
3. Show you the Jenkins admin password
4. Display all service URLs

### The Manual Way

If you prefer to do it step by step:

```bash
# Start all services
docker-compose up -d

# Check that everything is running
docker-compose ps

# View logs
docker-compose logs -f
```

## Setting It All Up

### Step 1: Start the Environment

```bash
# Navigate to project directory
cd jenkins-pipeline-cicd

# Start Jenkins and supporting services
./scripts/install_jenkins.sh

# Or use Make
make install
```

You'll see output like this:

```
╔════════════════════════════════════════════════════════════╗
║         JENKINS CI/CD ENVIRONMENT READY                    ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  Jenkins UI:       http://localhost:8080                  ║
║  FastAPI App:      http://localhost:8000                  ║
║  API Docs:         http://localhost:8000/docs             ║
║  Health Check:     http://localhost:8000/health           ║
║  Docker Registry:  http://localhost:5000                  ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

### Step 2: Access Jenkins

1. Open Jenkins at http://localhost:8080

2. Get the initial admin password:
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```

3. Complete the setup wizard:
   - Paste the admin password
   - Click "Install suggested plugins"
   - Create your admin user
   - Keep the default Jenkins URL
   - Click "Start using Jenkins"

### Step 3: Configure Jenkins

#### Install Required Plugins

1. Go to **Manage Jenkins** → **Manage Plugins**
2. Click the **Available** tab
3. Search for and install:
   - Docker Pipeline
   - Kubernetes
   - Pipeline Stage View
   - Blue Ocean (optional, for a nicer UI)

4. Click **Install without restart**

#### Docker Access

The Jenkins container already has access to Docker via the socket mount configured in `docker-compose.yml`:
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

#### Kubernetes Access (Optional)

If you're deploying to Kubernetes:

1. Copy your kubeconfig to Jenkins:
   ```bash
   docker cp ~/.kube/config jenkins:/root/.kube/config
   ```

2. Or configure it in Jenkins:
   - Go to **Manage Jenkins** → **Configure System**
   - Add Kubernetes cloud configuration

### Step 4: Create the Pipeline Job

1. Click **"New Item"** on the Jenkins dashboard

2. Enter job details:
   - Name: `fastapi-cicd-pipeline`
   - Type: Select **Pipeline**
   - Click **OK**

3. Configure the pipeline:

   **Option A: Pipeline from SCM (Recommended)**
   - Under **Pipeline** section:
     - Definition: `Pipeline script from SCM`
     - SCM: `Git`
     - Repository URL: `/workspace` (mounted in docker-compose)
     - Branch: `*/main` or `*/master`
     - Script Path: `Jenkinsfile`

   **Option B: Pipeline Script**
   - Copy the entire content of `Jenkinsfile` into the script box

4. The pipeline parameters are already defined in the Jenkinsfile:
   - ENVIRONMENT: `development`
   - IMAGE_TAG: `latest`
   - SKIP_TESTS: `false`
   - DEPLOY_TO_K8S: `true`

5. Click **"Save"**

### Step 5: Run the Pipeline

#### First Run: Just Docker Build

For the first run, let's test without Kubernetes:

1. Click **"Build with Parameters"**
2. Set `DEPLOY_TO_K8S` to `false`
3. Click **"Build"**

You should see these pipeline stages execute:
```
✅ Initialize
✅ Checkout
✅ Install Dependencies
✅ Lint Dockerfile (Hadolint)
✅ Run Unit Tests (pytest)
✅ Build Docker Image
✅ Security Scan (Trivy)
✅ Push to Registry
```

#### Monitor Pipeline Execution

- **Console Output**: Click on the build number → **Console Output**
- **Stage View**: Use the visual pipeline view
- **Blue Ocean**: Even better visualization (if you installed the plugin)

### Step 6: Verify the Image in Registry

```bash
# Check what's in the registry
curl http://localhost:5000/v2/_catalog

# Or use Make
make registry-check

# Check image tags
curl http://localhost:5000/v2/fastapi-demo/tags/list

# Or use Make
make registry-tags
```

You should see:
```json
{
  "repositories": ["fastapi-demo"]
}
```

### Step 7: Setup Kubernetes Cluster

```bash
# Using the deployment script
./scripts/deploy_k8s.sh

# Or use Make
make k8s-setup
```

This script will:
1. Create a Kind cluster named `jenkins-cicd`
2. Connect the local registry to the Kind network
3. Apply all Kubernetes manifests
4. Wait for the deployment to be ready
5. Test the deployment

### Step 8: Run the Full Pipeline with Kubernetes

1. Go back to Jenkins
2. Click **"Build with Parameters"**
3. Set `DEPLOY_TO_K8S` to `true`
4. Click **"Build"**

Now you'll see the complete pipeline:
```
✅ Initialize
✅ Checkout
✅ Install Dependencies
✅ Parallel Validation
   ├── ✅ Lint Dockerfile
   └── ✅ Run Unit Tests
✅ Build Docker Image
✅ Security Scan
✅ Push to Registry
✅ Deploy to Kubernetes
✅ Verify Deployment
✅ Health Check
```

### Step 9: Verify the Deployment

#### Check Kubernetes Resources

```bash
# Check pods
kubectl get pods -n cicd-demo

# Check services
kubectl get svc -n cicd-demo

# Check deployment
kubectl get deployment -n cicd-demo

# Or use Make
make status
```

#### Test the Application

```bash
# Get the NodePort
NODE_PORT=$(kubectl get svc fastapi-demo -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}')

# Test health endpoint
curl http://localhost:$NODE_PORT/health

# Test API
curl http://localhost:$NODE_PORT/

# Or use Make for port forwarding
make k8s-port-forward
# Then access: http://localhost:8080
```

You should get a response like:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.000000",
  "uptime_seconds": 123.45,
  "version": "1.0.0",
  "environment": "production"
}
```

### Step 10: Access API Documentation

With Kind deployment:
```bash
# Access via NodePort
open http://localhost:30080/docs
```

Or with port forwarding:
```bash
kubectl port-forward -n cicd-demo svc/fastapi-demo 8080:8000
open http://localhost:8080/docs
```

## Using Make Commands

I've included a comprehensive Makefile to make your life easier:

### Essential Commands

```bash
# Display all available commands
make help

# Install and start everything
make install

# Start services
make start

# Start with monitoring (Prometheus + Grafana)
make start-monitoring

# Stop services
make stop

# View status
make status

# View logs
make logs
```

### Development Commands

```bash
# Build Docker image
make build

# Run tests
make test

# Run tests with coverage
make test-coverage

# Scan for vulnerabilities
make scan

# Push to registry
make push
```

### Kubernetes Commands

```bash
# Setup Kubernetes and deploy
make k8s-setup

# Deploy to existing cluster
make deploy

# Delete deployment
make k8s-delete

# View application logs
make k8s-logs

# Port forward to service
make k8s-port-forward
```

### Monitoring Commands

```bash
# Check health of all services
make health-check

# Check registry contents
make registry-check

# View Jenkins logs
make logs-jenkins

# View app logs
make logs-app
```

### Cleanup Commands

```bash
# Stop and remove containers
make clean

# Complete cleanup (including images and Kind cluster)
make clean-all
```

## Pipeline Configuration

### Pipeline Parameters

The Jenkinsfile supports these parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| ENVIRONMENT | Choice | development | Target environment (development/staging/production) |
| IMAGE_TAG | String | latest | Docker image tag |
| SKIP_TESTS | Boolean | false | Skip unit tests (not recommended) |
| DEPLOY_TO_K8S | Boolean | true | Deploy to Kubernetes after build |

### Pipeline Stages

1. **Initialize**: Display build information
2. **Checkout**: Get source code
3. **Install Dependencies**: Install required tools
4. **Parallel Validation**:
   - Lint Dockerfile with Hadolint
   - Run unit tests with pytest
5. **Build Docker Image**: Multi-stage build
6. **Security Scan**: Trivy vulnerability scanning
7. **Push to Registry**: Push to local registry
8. **Deploy to Kubernetes**: Apply manifests and update deployment
9. **Verify Deployment**: Wait for rollout and check status
10. **Health Check**: Test application endpoints

### Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| APP_NAME | fastapi-demo | Application name |
| DOCKER_REGISTRY | localhost:5000 | Local registry address |
| K8S_NAMESPACE | cicd-demo | Kubernetes namespace |
| TRIVY_SEVERITY | HIGH,CRITICAL | Vulnerability severity levels |

## Security Features

I've implemented several security best practices:

### Docker Security

- Multi-stage builds to minimize image size
- Non-root user (UID 1000)
- Read-only root filesystem capability
- No privilege escalation
- Dropped all capabilities
- Regular security updates in base image

### Kubernetes Security

- SecurityContext with non-root user
- Resource limits (CPU and memory)
- Liveness and readiness probes
- Network policies (can be added)
- Pod Security Standards compliance

### Vulnerability Scanning

The pipeline uses Trivy to scan for:
- OS vulnerabilities
- Application dependencies
- HIGH and CRITICAL severity issues

```bash
# Manual scan
make scan

# Or directly
trivy image localhost:5000/fastapi-demo:latest
```

## Testing

### Unit Tests

```bash
# Run tests locally
cd app
pip install -r requirements.txt
pytest test_app.py -v

# Or use Make
make test
```

### Integration Tests

```bash
# Test the deployed application
curl http://localhost:30080/health
curl http://localhost:30080/api/info
curl -X POST http://localhost:30080/api/process \
  -H "Content-Type: application/json" \
  -d '{"message": "test"}'
```

### Coverage Report

```bash
# Generate coverage report
make test-coverage

# View HTML report
open app/htmlcov/index.html
```

## Optional: Monitoring with Prometheus and Grafana

### Enable Monitoring Stack

```bash
# Start with monitoring
make start-monitoring

# Or manually
docker-compose --profile monitoring up -d
```

### Access Monitoring Tools

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)

### Configure Grafana

1. Log in to Grafana: http://localhost:3000
2. Username: `admin`, Password: `admin`
3. Add Prometheus data source (pre-configured)
4. Import dashboard for FastAPI metrics

### Application Metrics

The FastAPI app exposes metrics at `/metrics`:
```bash
curl http://localhost:8000/metrics
```

## Troubleshooting

### Jenkins Cannot Start

```bash
# Check logs
docker logs jenkins

# Restart Jenkins
docker restart jenkins

# Clean start
docker-compose down
docker volume rm jenkins_home
docker-compose up -d jenkins
```

### Docker Socket Permission Denied

```bash
# Fix permissions (Linux)
sudo chmod 666 /var/run/docker.sock

# Or run Jenkins as root (already configured in docker-compose.yml)
```

### Pipeline Fails at Docker Build

```bash
# Verify Docker is accessible from Jenkins
docker exec jenkins docker ps

# Rebuild without cache
docker-compose exec jenkins docker build --no-cache .
```

### Kubernetes Deployment Fails

```bash
# Check Kind cluster
kind get clusters

# Recreate cluster
kind delete cluster --name jenkins-cicd
make k8s-setup

# Check if registry is connected to Kind network
docker network inspect kind | grep local-registry
```

### Cannot Access Application

```bash
# Check pod status
kubectl get pods -n cicd-demo

# Check pod logs
kubectl logs -n cicd-demo -l app=fastapi-demo

# Describe pod for events
kubectl describe pod -n cicd-demo -l app=fastapi-demo

# Port forward directly to pod
kubectl port-forward -n cicd-demo deployment/fastapi-demo 8080:8000
```

### Image Pull Errors in Kubernetes

```bash
# Verify registry is accessible from Kind
docker exec jenkins-cicd-control-plane curl http://local-registry:5000/v2/_catalog

# Reconnect registry to Kind network
docker network connect kind local-registry
```

## Project Structure

```
jenkins-pipeline-cicd/
├── app/
│   ├── main.py              # FastAPI application
│   ├── test_app.py          # Unit tests with pytest
│   └── requirements.txt     # Python dependencies
├── kubernetes/
│   ├── namespace.yaml       # Kubernetes namespace
│   ├── deployment.yaml      # Application deployment
│   └── service.yaml         # Service with NodePort
├── scripts/
│   ├── install_jenkins.sh   # Jenkins setup script
│   ├── scan_image.sh        # Trivy security scanner
│   └── deploy_k8s.sh        # Kubernetes deployment script
├── monitoring/              # Created by setup scripts
│   ├── prometheus.yml       # Prometheus configuration
│   └── grafana-datasources.yml
├── Dockerfile               # Multi-stage Docker build
├── docker-compose.yml       # Services orchestration
├── Jenkinsfile             # Jenkins Pipeline as Code
├── Makefile                # Convenience commands
└── README.md               # This file
```

## What I Learned

Building this project gave me hands-on experience with:

1. **Jenkins Pipeline as Code**
   - Declarative syntax
   - Parameterized builds
   - Parallel stages
   - Error handling and notifications

2. **Docker**
   - Multi-stage builds
   - Security best practices
   - Image optimization
   - Local registry management

3. **Kubernetes**
   - Deployments and Services
   - Health checks (liveness/readiness)
   - Rolling updates
   - Resource management

4. **CI/CD Best Practices**
   - Automated testing
   - Security scanning
   - Infrastructure as Code
   - Automated deployments

5. **DevOps Automation**
   - Shell scripting
   - Make automation
   - Docker Compose orchestration
   - One-command setup

## Future Improvements

Some ideas I'm considering:

- Add Helm charts for Kubernetes deployment
- Implement blue-green deployment strategy
- Add SonarQube for code quality analysis
- Implement Jenkins shared libraries
- Add Slack/email notifications
- Implement GitOps with ArgoCD
- Add performance testing with Locust
- Implement canary deployments

### Enhancement Ideas

1. **Multi-environment support**: Add staging and production pipelines
2. **Secrets management**: Integrate HashiCorp Vault
3. **Database integration**: Add PostgreSQL with migrations
4. **API Gateway**: Add Kong or NGINX Ingress
5. **Service Mesh**: Integrate Istio for advanced traffic management

## Additional Resources

### Documentation
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)

### Useful Commands Reference

```bash
# Jenkins
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
docker logs jenkins -f

# Docker
docker images | grep fastapi-demo
docker ps -a
docker system prune -af

# Kubernetes
kubectl get all -n cicd-demo
kubectl describe deployment fastapi-demo -n cicd-demo
kubectl logs -n cicd-demo -l app=fastapi-demo --tail=100 -f
kubectl exec -it -n cicd-demo deployment/fastapi-demo -- /bin/bash

# Registry
curl http://localhost:5000/v2/_catalog
curl http://localhost:5000/v2/fastapi-demo/tags/list

# Application
curl http://localhost:8000/health | jq
curl http://localhost:8000/docs
curl -X POST http://localhost:8000/api/process \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello CI/CD"}'
```

## Contributing

I welcome contributions to this project! Here's how you can get involved:

### Getting Started

1. **Fork the repository** to your GitHub account
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/jenkins-pipeline-cicd.git
   cd jenkins-pipeline-cicd
   ```
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Development Workflow

1. **Make your changes** - Implement your feature or fix
2. **Test thoroughly**:
   ```bash
   # Run unit tests
   make test

   # Test the full pipeline
   make build
   make k8s-setup
   ```
3. **Follow coding standards**:
   - Python: Follow PEP 8
   - Shell scripts: Use proper error handling
   - Docker: Multi-stage builds, non-root users
   - Kubernetes: Include resource limits and security contexts

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: your feature description"
   ```

### Commit Message Format

Use conventional commits:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Adding tests
- `chore:` - Maintenance tasks

### Submitting a Pull Request

1. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** on GitHub

3. **Ensure all checks pass**:
   - Tests must pass
   - Code must be properly formatted
   - No security vulnerabilities

### Questions or Issues?

- Check existing issues first
- Create a new issue with detailed description
- Feel free to ask questions in discussions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## About Me

**Abraham O**

I'm a DevOps Engineer passionate about automation, containerization, and cloud-native technologies. I built this project to demonstrate real-world CI/CD practices that I use in production environments.

Feel free to reach out if you have questions or want to discuss DevOps practices!

## Acknowledgments

Thanks to the amazing open-source communities behind:
- Jenkins for excellent documentation and a powerful CI/CD platform
- FastAPI for making Python web development a joy
- Aqua Security for the Trivy scanner
- The Kubernetes team for Kind
- Docker for revolutionizing how we build and deploy applications

---

Questions or issues? Check the [troubleshooting section](#troubleshooting) or create an issue in the repository.
