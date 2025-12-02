.PHONY: help install start stop restart clean build test deploy logs status registry-check k8s-setup

# Variables
APP_NAME := fastapi-demo
REGISTRY := localhost:5001
IMAGE := $(REGISTRY)/$(APP_NAME)
NAMESPACE := cicd-demo

# Default target
.DEFAULT_GOAL := help

help: ## Display this help message
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║      Jenkins CI/CD Pipeline - Makefile Commands            ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

install: ## Install and start Jenkins environment
	@echo "🚀 Installing Jenkins CI/CD environment..."
	@bash scripts/install_jenkins.sh

start: ## Start all services (Jenkins, Registry, App)
	@echo "▶️  Starting services..."
	@docker-compose up -d
	@echo "✅ Services started successfully"
	@$(MAKE) status

start-monitoring: ## Start all services including monitoring stack
	@echo "▶️  Starting services with monitoring..."
	@docker-compose --profile monitoring up -d
	@echo "✅ Services with monitoring started successfully"
	@$(MAKE) status

stop: ## Stop all services
	@echo "⏹️  Stopping services..."
	@docker-compose down
	@echo "✅ Services stopped successfully"

restart: ## Restart all services
	@echo "🔄 Restarting services..."
	@docker-compose restart
	@echo "✅ Services restarted successfully"

clean: ## Stop services and remove volumes
	@echo "🧹 Cleaning up..."
	@docker-compose down -v
	@echo "✅ Cleanup completed"

clean-all: clean ## Remove all Docker images and clean Kind cluster
	@echo "🧹 Performing deep cleanup..."
	@docker rmi $(IMAGE):latest 2>/dev/null || true
	@kind delete cluster --name jenkins-cicd 2>/dev/null || true
	@echo "✅ Deep cleanup completed"

build: ## Build Docker image locally
	@echo "🐳 Building Docker image..."
	@docker build -t $(IMAGE):latest -f Dockerfile .
	@echo "✅ Image built successfully"

build-no-cache: ## Build Docker image without cache
	@echo "🐳 Building Docker image (no cache)..."
	@docker build --no-cache -t $(IMAGE):latest -f Dockerfile .
	@echo "✅ Image built successfully"

test: ## Run unit tests locally
	@echo "🧪 Running unit tests..."
	@pip3 install -r app/requirements.txt 2>/dev/null || true
	@cd app && python3 -m pytest test_app.py -v
	@echo "✅ Tests completed successfully"

test-coverage: ## Run unit tests with coverage report
	@echo "🧪 Running unit tests with coverage..."
	@pip3 install -r app/requirements.txt 2>/dev/null || true
	@cd app && python3 -m pytest test_app.py -v --cov=main --cov-report=html --cov-report=term
	@echo "✅ Coverage report generated in app/htmlcov/"

push: build ## Build and push image to local registry
	@echo "📤 Pushing image to local registry..."
	@docker push $(IMAGE):latest
	@echo "✅ Image pushed successfully"

scan: ## Scan Docker image for vulnerabilities
	@echo "🔒 Scanning Docker image..."
	@bash scripts/scan_image.sh $(IMAGE):latest

deploy: ## Deploy to Kubernetes cluster
	@echo "☸️  Deploying to Kubernetes..."
	@bash scripts/deploy_k8s.sh

k8s-setup: ## Setup Kind cluster and deploy
	@echo "☸️  Setting up Kubernetes environment..."
	@bash scripts/deploy_k8s.sh
	@echo "✅ Kubernetes setup completed"

k8s-delete: ## Delete Kubernetes deployment
	@echo "🗑️  Deleting Kubernetes deployment..."
	@kubectl delete namespace $(NAMESPACE) --ignore-not-found=true
	@echo "✅ Deployment deleted"

k8s-logs: ## View application logs in Kubernetes
	@echo "📋 Viewing application logs..."
	@kubectl logs -n $(NAMESPACE) -l app=$(APP_NAME) --tail=100 -f

k8s-describe: ## Describe Kubernetes deployment
	@kubectl describe deployment $(APP_NAME) -n $(NAMESPACE)

k8s-port-forward: ## Port forward to Kubernetes service
	@echo "🔌 Port forwarding to application..."
	@kubectl port-forward -n $(NAMESPACE) svc/$(APP_NAME) 8080:8000

logs: ## View logs from all services
	@docker-compose logs -f

logs-jenkins: ## View Jenkins logs
	@docker-compose logs -f jenkins

logs-app: ## View application logs
	@docker-compose logs -f app

logs-registry: ## View registry logs
	@docker-compose logs -f registry

status: ## Show status of all services
	@echo "📊 Service Status:"
	@echo ""
	@docker-compose ps
	@echo ""
	@echo "📍 Service URLs:"
	@echo "  Jenkins:        http://localhost:8080"
	@echo "  FastAPI App:    http://localhost:8000"
	@echo "  API Docs:       http://localhost:8000/docs"
	@echo "  Registry:       http://localhost:5000"
	@echo "  Prometheus:     http://localhost:9090"
	@echo "  Grafana:        http://localhost:3000"

registry-check: ## Check local registry contents
	@echo "📦 Registry Contents:"
	@curl -s http://$(REGISTRY)/v2/_catalog | python3 -m json.tool

registry-tags: ## Show available image tags in registry
	@echo "🏷️  Image Tags:"
	@curl -s http://$(REGISTRY)/v2/$(APP_NAME)/tags/list | python3 -m json.tool

shell-jenkins: ## Open shell in Jenkins container
	@docker exec -it jenkins bash

shell-app: ## Open shell in application container
	@docker exec -it fastapi-app bash

health-check: ## Check health of all services
	@echo "🏥 Health Check:"
	@echo -n "  Jenkins:   "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/login || echo "Down"
	@echo ""
	@echo -n "  App:       "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health || echo "Down"
	@echo ""
	@echo -n "  Registry:  "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/v2/ || echo "Down"
	@echo ""

run-local: ## Run application locally (without Docker)
	@echo "🚀 Running application locally..."
	@cd app && python3 main.py

run-pipeline: ## Display instructions for running Jenkins pipeline
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║           HOW TO RUN THE JENKINS PIPELINE                  ║"
	@echo "╠════════════════════════════════════════════════════════════╣"
	@echo "║                                                            ║"
	@echo "║  1. Open Jenkins: http://localhost:8080                   ║"
	@echo "║  2. Click 'New Item'                                      ║"
	@echo "║  3. Enter name: 'fastapi-cicd-pipeline'                   ║"
	@echo "║  4. Select 'Pipeline' and click OK                        ║"
	@echo "║  5. Under 'Pipeline', select 'Pipeline script from SCM'   ║"
	@echo "║  6. SCM: Git                                              ║"
	@echo "║  7. Repository URL: /workspace                            ║"
	@echo "║  8. Script Path: Jenkinsfile                              ║"
	@echo "║  9. Click 'Save' and then 'Build Now'                     ║"
	@echo "║                                                            ║"
	@echo "╚════════════════════════════════════════════════════════════╝"

info: ## Display project information
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║           PROJECT INFORMATION                              ║"
	@echo "╠════════════════════════════════════════════════════════════╣"
	@echo "║                                                            ║"
	@echo "║  Project:       Jenkins Pipeline CI/CD                    ║"
	@echo "║  Application:   FastAPI Microservice                      ║"
	@echo "║  Version:       1.0.0                                     ║"
	@echo "║  Author:        DevOps Team                               ║"
	@echo "║                                                            ║"
	@echo "║  Components:                                              ║"
	@echo "║  - Jenkins CI/CD Server                                   ║"
	@echo "║  - Local Docker Registry                                  ║"
	@echo "║  - FastAPI Application                                    ║"
	@echo "║  - Kubernetes (Kind/Minikube)                             ║"
	@echo "║  - Prometheus + Grafana (optional)                        ║"
	@echo "║                                                            ║"
	@echo "╚════════════════════════════════════════════════════════════╝"

validate: ## Validate all configuration files
	@echo "✅ Validating configuration files..."
	@docker-compose config > /dev/null && echo "  docker-compose.yml: OK"
	@kubectl apply --dry-run=client -f kubernetes/ > /dev/null && echo "  Kubernetes manifests: OK"
	@python3 -m py_compile app/main.py && echo "  app/main.py: OK"
	@python3 -m py_compile app/test_app.py && echo "  app/test_app.py: OK"
	@echo "✅ All validations passed"
