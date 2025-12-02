# Jenkins Pipeline CI/CD - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### 1. Verify Prerequisites

```bash
docker --version
docker-compose --version
make --version
```

### 2. Start the Environment

```bash
# One command to rule them all
make install
```

This will:
- ✅ Start Jenkins on http://localhost:8080
- ✅ Start local Docker registry on http://localhost:5000
- ✅ Start FastAPI app on http://localhost:8000
- ✅ Display Jenkins initial admin password

### 3. Access Jenkins

Open http://localhost:8080 and use the displayed admin password.

### 4. Create Pipeline Job

1. Click **New Item**
2. Name: `fastapi-cicd-pipeline`
3. Type: **Pipeline**
4. Pipeline → Definition: **Pipeline script from SCM**
5. SCM: **Git**
6. Repository URL: `/workspace`
7. Script Path: `Jenkinsfile`
8. Click **Save**

### 5. Run the Pipeline

1. Click **Build with Parameters**
2. Set parameters:
   - ENVIRONMENT: `development`
   - IMAGE_TAG: `latest`
   - SKIP_TESTS: `false`
   - DEPLOY_TO_K8S: `false` (for first run)
3. Click **Build**

### 6. Verify Build

Watch the pipeline execute all stages:
```
✅ Initialize
✅ Checkout
✅ Install Dependencies
✅ Lint Dockerfile
✅ Run Unit Tests
✅ Build Docker Image
✅ Security Scan
✅ Push to Registry
```

### 7. Check Registry

```bash
make registry-check
```

You should see `fastapi-demo` in the repositories list.

### 8. Setup Kubernetes (Optional)

```bash
make k8s-setup
```

### 9. Run Full Pipeline

1. Go back to Jenkins
2. Click **Build with Parameters**
3. Set `DEPLOY_TO_K8S` to `true`
4. Click **Build**

### 10. Access Your Application

```bash
# Via NodePort
curl http://localhost:30080/health

# Via port-forward
make k8s-port-forward
# Then: http://localhost:8080
```

## 📊 All Available Commands

```bash
make help          # Show all commands
make status        # Check service status
make logs          # View all logs
make test          # Run unit tests
make scan          # Security scan
make clean         # Stop services
make clean-all     # Complete cleanup
```

## 🏥 Health Checks

```bash
make health-check
```

Expected output:
```
Jenkins:   200
App:       200
Registry:  200
```

## 📖 Full Documentation

For complete documentation, see [README.md](README.md)

## 🆘 Quick Troubleshooting

### Jenkins won't start
```bash
docker logs jenkins
docker restart jenkins
```

### Can't access application
```bash
kubectl get pods -n cicd-demo
kubectl logs -n cicd-demo -l app=fastapi-demo
```

### Image won't push
```bash
docker ps | grep registry
docker restart local-registry
```

## 🎯 What This Demonstrates

- ✅ Jenkins Pipeline as Code
- ✅ Multi-stage Docker builds
- ✅ Automated testing (pytest)
- ✅ Security scanning (Trivy)
- ✅ Local container registry
- ✅ Kubernetes deployment
- ✅ Health checks & monitoring
- ✅ Complete automation

## 📚 Learn More

- Architecture: See [README.md](README.md#architecture)
- Contributing: See [CONTRIBUTING.md](CONTRIBUTING.md)
- Pipeline stages: See [Jenkinsfile](Jenkinsfile)

---

**Ready to show enterprise-grade DevOps skills!** 🚀
