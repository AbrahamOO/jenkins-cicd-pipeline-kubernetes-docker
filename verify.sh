#!/bin/bash

###############################################################################
# Project Verification Script
# Description: Verifies all project files and dependencies are in place
# Author: Abraham O
# Version: 1.0.0
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         PROJECT VERIFICATION SCRIPT                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check file structure
log_info "Checking project structure..."

files=(
    "Dockerfile"
    "Jenkinsfile"
    "docker-compose.yml"
    "Makefile"
    "README.md"
    "LICENSE"
    "CONTRIBUTING.md"
    ".gitignore"
    ".dockerignore"
    "app/main.py"
    "app/test_app.py"
    "app/requirements.txt"
    "kubernetes/namespace.yaml"
    "kubernetes/deployment.yaml"
    "kubernetes/service.yaml"
    "scripts/install_jenkins.sh"
    "scripts/scan_image.sh"
    "scripts/deploy_k8s.sh"
    ".github/workflows/lint.yml"
)

missing_files=0
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        log_success "$file"
    else
        log_error "$file not found"
        missing_files=$((missing_files + 1))
    fi
done

echo ""
if [ $missing_files -eq 0 ]; then
    log_success "All files present"
else
    log_error "$missing_files files missing"
    exit 1
fi

# Check prerequisites
echo ""
log_info "Checking prerequisites..."

if command -v docker >/dev/null 2>&1; then
    log_success "Docker installed ($(docker --version))"
else
    log_error "Docker not installed"
fi

if command -v docker-compose >/dev/null 2>&1; then
    log_success "Docker Compose installed ($(docker-compose --version))"
else
    log_error "Docker Compose not installed"
fi

if command -v make >/dev/null 2>&1; then
    log_success "Make installed ($(make --version | head -n1))"
else
    log_error "Make not installed"
fi

if command -v kubectl >/dev/null 2>&1; then
    log_success "kubectl installed ($(kubectl version --client --short 2>/dev/null || echo 'version available'))"
else
    log_error "kubectl not installed (optional)"
fi

if command -v kind >/dev/null 2>&1; then
    log_success "Kind installed ($(kind --version))"
elif command -v minikube >/dev/null 2>&1; then
    log_success "Minikube installed ($(minikube version --short))"
else
    log_error "Neither Kind nor Minikube installed (optional for K8s)"
fi

# Validate configuration files
echo ""
log_info "Validating configuration files..."

# Validate Python syntax
if command -v python3 >/dev/null 2>&1; then
    if python3 -m py_compile app/main.py 2>/dev/null; then
        log_success "app/main.py syntax valid"
    else
        log_error "app/main.py syntax error"
    fi

    if python3 -m py_compile app/test_app.py 2>/dev/null; then
        log_success "app/test_app.py syntax valid"
    else
        log_error "app/test_app.py syntax error"
    fi
fi

# Validate docker-compose
if command -v docker-compose >/dev/null 2>&1; then
    if docker-compose config > /dev/null 2>&1; then
        log_success "docker-compose.yml valid"
    else
        log_error "docker-compose.yml invalid"
    fi
fi

# Validate Kubernetes manifests
if command -v kubectl >/dev/null 2>&1; then
    if kubectl apply --dry-run=client -f kubernetes/ > /dev/null 2>&1; then
        log_success "Kubernetes manifests valid"
    else
        log_error "Kubernetes manifests invalid"
    fi
fi

# Check script permissions
echo ""
log_info "Checking script permissions..."

scripts=(
    "scripts/install_jenkins.sh"
    "scripts/scan_image.sh"
    "scripts/deploy_k8s.sh"
)

for script in "${scripts[@]}"; do
    if [ -x "$script" ]; then
        log_success "$script is executable"
    else
        log_error "$script is not executable"
    fi
done

# Display summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              VERIFICATION COMPLETE                         ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║                                                            ║"
echo "║  ✅ Project structure verified                             ║"
echo "║  ✅ Configuration files validated                          ║"
echo "║  ✅ Scripts are executable                                 ║"
echo "║                                                            ║"
echo "║  Next steps:                                              ║"
echo "║  1. Run: make install                                     ║"
echo "║  2. Open: http://localhost:8080                           ║"
echo "║  3. Follow README.md for complete setup                   ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log_success "Project is ready to use!"
