#!/bin/bash

###############################################################################
# Jenkins Installation and Setup Script
# Description: Spins up Jenkins locally using Docker Compose
# Author: Abraham O
# Version: 1.0.0
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command_exists docker; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! command_exists docker-compose; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker ps >/dev/null 2>&1; then
        log_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi

    log_success "All prerequisites are satisfied"
}

# Function to create monitoring configuration if needed
create_monitoring_config() {
    log_info "Creating monitoring configuration..."

    mkdir -p monitoring

    # Create Prometheus configuration
    cat > monitoring/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'fastapi-app'
    static_configs:
      - targets: ['app:8000']
    metrics_path: '/metrics'

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

    # Create Grafana datasource configuration
    cat > monitoring/grafana-datasources.yml <<'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

    log_success "Monitoring configuration created"
}

# Function to stop existing containers
stop_existing_containers() {
    log_info "Stopping existing containers..."

    if docker ps -a | grep -q jenkins; then
        docker stop jenkins 2>/dev/null || true
        docker rm jenkins 2>/dev/null || true
    fi

    if docker ps -a | grep -q local-registry; then
        docker stop local-registry 2>/dev/null || true
        docker rm local-registry 2>/dev/null || true
    fi

    log_success "Existing containers stopped"
}

# Function to start Jenkins and Registry
start_services() {
    log_info "Starting Jenkins and Local Docker Registry..."

    # Start core services (Jenkins, Registry, App)
    docker-compose up -d jenkins registry app

    log_success "Services started successfully"
}

# Function to wait for Jenkins to be ready
wait_for_jenkins() {
    log_info "Waiting for Jenkins to start (this may take 1-2 minutes)..."

    local max_attempts=60
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if docker logs jenkins 2>&1 | grep -q "Jenkins is fully up and running"; then
            log_success "Jenkins is ready!"
            return 0
        fi

        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done

    log_warning "Jenkins startup timeout. Check logs with: docker logs jenkins"
}

# Function to get Jenkins initial password
get_jenkins_password() {
    log_info "Retrieving Jenkins initial admin password..."

    sleep 5  # Give Jenkins a moment to create the password file

    if docker exec jenkins test -f /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null; then
        local password
        password=$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "")

        if [ -n "$password" ]; then
            echo ""
            echo "╔════════════════════════════════════════════════════════════╗"
            echo "║           JENKINS INITIAL ADMIN PASSWORD                   ║"
            echo "╠════════════════════════════════════════════════════════════╣"
            echo "║                                                            ║"
            echo "║  Password: ${password}                        ║"
            echo "║                                                            ║"
            echo "╚════════════════════════════════════════════════════════════╝"
            echo ""
        fi
    else
        log_warning "Initial admin password not found. Jenkins may use a different auth method."
    fi
}

# Function to display access information
display_info() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         JENKINS CI/CD ENVIRONMENT READY                    ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║                                                            ║"
    echo "║  Jenkins UI:       http://localhost:8080                  ║"
    echo "║  FastAPI App:      http://localhost:8000                  ║"
    echo "║  API Docs:         http://localhost:8000/docs             ║"
    echo "║  Health Check:     http://localhost:8000/health           ║"
    echo "║  Docker Registry:  http://localhost:5000                  ║"
    echo "║                                                            ║"
    echo "║  Monitoring (optional):                                   ║"
    echo "║  Prometheus:       http://localhost:9090                  ║"
    echo "║  Grafana:          http://localhost:3000                  ║"
    echo "║                    (admin/admin)                           ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "View logs: docker-compose logs -f"
    log_info "Stop services: docker-compose down"
    log_info "Stop and remove volumes: docker-compose down -v"
    echo ""
}

# Function to install required Jenkins plugins
install_jenkins_plugins() {
    log_info "Installing required Jenkins plugins..."

    local plugins=(
        "git"
        "workflow-aggregator"
        "docker-workflow"
        "kubernetes"
        "pipeline-stage-view"
        "blueocean"
    )

    # Wait a bit more for Jenkins to be fully ready
    sleep 10

    for plugin in "${plugins[@]}"; do
        log_info "Installing plugin: $plugin"
        docker exec jenkins jenkins-plugin-cli --plugins "$plugin" 2>/dev/null || log_warning "Could not install $plugin"
    done

    log_success "Plugin installation completed"
}

# Function to display next steps
display_next_steps() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    NEXT STEPS                              ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║                                                            ║"
    echo "║  1. Open Jenkins: http://localhost:8080                   ║"
    echo "║  2. Use the initial admin password above                  ║"
    echo "║  3. Install suggested plugins                             ║"
    echo "║  4. Create your first admin user                          ║"
    echo "║  5. Create a new Pipeline job                             ║"
    echo "║  6. Point it to the Jenkinsfile in this repo              ║"
    echo "║  7. Run the pipeline!                                     ║"
    echo "║                                                            ║"
    echo "║  For detailed instructions, see README.md                 ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║      JENKINS CI/CD PIPELINE - INSTALLATION SCRIPT          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    check_prerequisites
    create_monitoring_config
    stop_existing_containers
    start_services
    wait_for_jenkins
    get_jenkins_password
    # install_jenkins_plugins  # Commented out as it may need manual intervention
    display_info
    display_next_steps

    log_success "Installation completed successfully!"
}

# Run main function
main "$@"
