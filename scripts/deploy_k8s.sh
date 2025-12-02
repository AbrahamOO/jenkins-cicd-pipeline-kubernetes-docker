#!/bin/bash

###############################################################################
# Kubernetes Deployment Script
# Description: Deploys application to Kind/Minikube cluster
# Author: Abraham O
# Version: 1.0.0
###############################################################################

set -e
set -u
set -o pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-jenkins-cicd}"
NAMESPACE="${NAMESPACE:-cicd-demo}"
APP_NAME="fastapi-demo"
IMAGE_NAME="localhost:5000/fastapi-demo:latest"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is installed
check_kubectl() {
    if ! command -v kubectl >/dev/null 2>&1; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    log_success "kubectl is installed"
}

# Check if Kind or Minikube is installed
check_k8s_cluster() {
    if command -v kind >/dev/null 2>&1; then
        log_success "Kind is installed"
        K8S_TOOL="kind"
    elif command -v minikube >/dev/null 2>&1; then
        log_success "Minikube is installed"
        K8S_TOOL="minikube"
    else
        log_error "Neither Kind nor Minikube is installed. Please install one of them."
        exit 1
    fi
}

# Create Kind cluster if it doesn't exist
create_kind_cluster() {
    if kind get clusters | grep -q "$CLUSTER_NAME"; then
        log_info "Kind cluster '$CLUSTER_NAME' already exists"
    else
        log_info "Creating Kind cluster '$CLUSTER_NAME'..."

        cat <<EOF | kind create cluster --name "$CLUSTER_NAME" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5000"]
    endpoint = ["http://local-registry:5000"]
EOF

        log_success "Kind cluster created successfully"
    fi
}

# Connect local registry to Kind network
connect_registry_to_kind() {
    log_info "Connecting local registry to Kind network..."

    # Check if registry is running
    if ! docker ps | grep -q local-registry; then
        log_warning "Local registry is not running. Starting it..."
        docker run -d --name local-registry --network kind -p 5000:5000 registry:2
    fi

    # Connect registry to kind network if not already connected
    if ! docker network inspect kind | grep -q local-registry; then
        docker network connect kind local-registry 2>/dev/null || true
    fi

    log_success "Registry connected to Kind network"
}

# Start Minikube if not running
start_minikube() {
    if minikube status | grep -q "Running"; then
        log_info "Minikube is already running"
    else
        log_info "Starting Minikube..."
        minikube start --driver=docker --insecure-registry="localhost:5000"
        log_success "Minikube started successfully"
    fi

    # Enable ingress addon
    minikube addons enable ingress 2>/dev/null || true
}

# Apply Kubernetes manifests
apply_manifests() {
    log_info "Applying Kubernetes manifests..."

    # Create namespace
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

    # Apply all manifests
    kubectl apply -f kubernetes/namespace.yaml
    kubectl apply -f kubernetes/deployment.yaml
    kubectl apply -f kubernetes/service.yaml

    log_success "Manifests applied successfully"
}

# Wait for deployment to be ready
wait_for_deployment() {
    log_info "Waiting for deployment to be ready..."

    kubectl rollout status deployment/"$APP_NAME" -n "$NAMESPACE" --timeout=300s

    log_success "Deployment is ready"
}

# Display deployment status
display_status() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            DEPLOYMENT STATUS                               ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    log_info "Pods:"
    kubectl get pods -n "$NAMESPACE" -l app="$APP_NAME"

    echo ""
    log_info "Services:"
    kubectl get svc -n "$NAMESPACE"

    echo ""
    log_info "Deployment:"
    kubectl get deployment -n "$NAMESPACE"
}

# Test the deployment
test_deployment() {
    log_info "Testing deployment..."

    # Get NodePort
    NODE_PORT=$(kubectl get svc "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')

    if [ "$K8S_TOOL" == "kind" ]; then
        ENDPOINT="http://localhost:${NODE_PORT}"
    else
        MINIKUBE_IP=$(minikube ip)
        ENDPOINT="http://${MINIKUBE_IP}:${NODE_PORT}"
    fi

    log_info "Testing endpoint: $ENDPOINT/health"

    # Wait a bit for the service to be ready
    sleep 5

    if curl -f -s "$ENDPOINT/health" > /dev/null; then
        log_success "Health check passed!"
        echo ""
        curl -s "$ENDPOINT/health" | python3 -m json.tool || cat
    else
        log_warning "Health check failed. The service might not be ready yet."
        log_info "You can test manually with: curl $ENDPOINT/health"
    fi

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            APPLICATION ENDPOINTS                           ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║                                                            ║"
    echo "║  Health:  $ENDPOINT/health                    ║"
    echo "║  API:     $ENDPOINT                           ║"
    echo "║  Docs:    $ENDPOINT/docs                      ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        KUBERNETES DEPLOYMENT SCRIPT                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    check_kubectl
    check_k8s_cluster

    if [ "$K8S_TOOL" == "kind" ]; then
        create_kind_cluster
        connect_registry_to_kind
    else
        start_minikube
    fi

    apply_manifests
    wait_for_deployment
    display_status
    test_deployment

    log_success "Deployment completed successfully!"
}

main "$@"
