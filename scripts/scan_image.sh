#!/bin/bash

###############################################################################
# Docker Image Security Scanning Script
# Description: Runs Trivy security scanner on Docker images
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
IMAGE_NAME="${1:-localhost:5000/fastapi-demo:latest}"
SEVERITY="${2:-HIGH,CRITICAL}"
OUTPUT_FORMAT="${3:-table}"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Trivy is installed
check_trivy() {
    if ! command -v trivy >/dev/null 2>&1; then
        log_info "Trivy not found. Installing..."
        install_trivy
    else
        log_success "Trivy is already installed"
    fi
}

# Install Trivy
install_trivy() {
    log_info "Installing Trivy..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew >/dev/null 2>&1; then
            brew install aquasecurity/trivy/trivy
        else
            log_error "Homebrew not found. Please install Trivy manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
        echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
        sudo apt-get update
        sudo apt-get install trivy -y
    else
        log_error "Unsupported OS. Please install Trivy manually."
        exit 1
    fi

    log_success "Trivy installed successfully"
}

# Scan Docker image
scan_image() {
    log_info "Scanning Docker image: $IMAGE_NAME"
    log_info "Severity levels: $SEVERITY"
    echo ""

    trivy image \
        --severity "$SEVERITY" \
        --format "$OUTPUT_FORMAT" \
        --no-progress \
        "$IMAGE_NAME"

    local exit_code=$?

    echo ""
    if [ $exit_code -eq 0 ]; then
        log_success "Security scan completed"
    else
        log_error "Security scan found vulnerabilities"
        return $exit_code
    fi
}

# Main execution
main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          DOCKER IMAGE SECURITY SCANNER (TRIVY)             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    check_trivy
    scan_image

    echo ""
    log_info "For detailed report, run: trivy image --format json $IMAGE_NAME > report.json"
}

main "$@"
