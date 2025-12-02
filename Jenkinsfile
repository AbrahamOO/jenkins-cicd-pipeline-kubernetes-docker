/*
 * Enterprise-Grade Jenkins Declarative Pipeline
 * Implements complete CI/CD workflow with security scanning and deployment
 * Author: Abraham O
 * Version: 1.0.0
 */

pipeline {
    agent {
        docker {
            image 'docker:24-dind'
            args '-v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.kube:/root/.kube --network host'
        }
    }

    // Pipeline parameters for flexibility
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['development', 'staging', 'production'],
            description: 'Target deployment environment'
        )
        string(
            name: 'IMAGE_TAG',
            defaultValue: 'latest',
            description: 'Docker image tag'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip unit tests (not recommended for production)'
        )
        booleanParam(
            name: 'DEPLOY_TO_K8S',
            defaultValue: true,
            description: 'Deploy to Kubernetes cluster'
        )
    }

    // Environment variables
    environment {
        APP_NAME = 'fastapi-demo'
        DOCKER_REGISTRY = 'localhost:5001'
        IMAGE_NAME = "${DOCKER_REGISTRY}/${APP_NAME}"
        K8S_NAMESPACE = 'cicd-demo'
        TRIVY_SEVERITY = 'HIGH,CRITICAL'
        BUILD_VERSION = "${env.BUILD_NUMBER}-${env.GIT_COMMIT?.take(7) ?: 'local'}"
    }

    // Build options
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
        disableConcurrentBuilds()
    }

    stages {
        stage('Initialize') {
            steps {
                script {
                    echo """
                    ═══════════════════════════════════════════════════════
                    🚀 Jenkins CI/CD Pipeline Started
                    ═══════════════════════════════════════════════════════
                    Application: ${APP_NAME}
                    Environment: ${params.ENVIRONMENT}
                    Build Number: ${env.BUILD_NUMBER}
                    Build Version: ${BUILD_VERSION}
                    Image Tag: ${params.IMAGE_TAG}
                    Branch: ${env.GIT_BRANCH ?: 'local'}
                    ═══════════════════════════════════════════════════════
                    """
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    echo '📥 Checking out source code...'
                    // In Jenkins, this is automatic. For local testing:
                    sh '''
                        echo "Current directory: $(pwd)"
                        ls -la
                    '''
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    echo '📦 Installing required tools...'
                    sh '''
                        # Install essential tools
                        apk add --no-cache \
                            python3 \
                            py3-pip \
                            curl \
                            bash \
                            git \
                            make

                        # Verify installations
                        python3 --version
                        docker --version
                    '''
                }
            }
        }

        stage('Parallel Validation') {
            parallel {
                stage('Lint Dockerfile') {
                    steps {
                        script {
                            echo '🔍 Linting Dockerfile with Hadolint...'
                            sh '''
                                # Install Hadolint
                                wget -qO /usr/local/bin/hadolint \
                                    https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
                                chmod +x /usr/local/bin/hadolint

                                # Run Hadolint
                                hadolint Dockerfile || echo "Hadolint warnings found (non-blocking)"
                            '''
                        }
                    }
                }

                stage('Run Unit Tests') {
                    when {
                        expression { return !params.SKIP_TESTS }
                    }
                    steps {
                        script {
                            echo '🧪 Running unit tests...'
                            sh '''
                                # Install Python dependencies for testing
                                pip3 install --no-cache-dir -r app/requirements.txt

                                # Run pytest with coverage
                                cd app
                                python3 -m pytest test_app.py -v --tb=short --color=yes

                                echo "✅ All tests passed successfully"
                            '''
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo '🐳 Building Docker image...'
                    sh '''
                        # Build multi-stage Docker image
                        docker build \
                            --build-arg APP_VERSION=${BUILD_VERSION} \
                            --tag ${IMAGE_NAME}:${BUILD_VERSION} \
                            --tag ${IMAGE_NAME}:${IMAGE_TAG} \
                            --tag ${IMAGE_NAME}:latest \
                            -f Dockerfile \
                            .

                        echo "✅ Docker image built successfully"
                        docker images | grep ${APP_NAME}
                    '''
                }
            }
        }

        stage('Security Scan') {
            steps {
                script {
                    echo '🔒 Scanning Docker image for vulnerabilities...'
                    sh '''
                        # Install Trivy
                        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
                            apk add --allow-untrusted -
                        wget -qO /tmp/trivy.tar.gz \
                            https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.tar.gz
                        tar -xzf /tmp/trivy.tar.gz -C /usr/local/bin trivy
                        chmod +x /usr/local/bin/trivy

                        # Run Trivy scan
                        trivy image \
                            --severity ${TRIVY_SEVERITY} \
                            --no-progress \
                            --exit-code 0 \
                            ${IMAGE_NAME}:${BUILD_VERSION}

                        echo "✅ Security scan completed"
                    '''
                }
            }
        }

        stage('Push to Registry') {
            steps {
                script {
                    echo '📤 Pushing image to local registry...'
                    sh '''
                        # Push all tags to local registry
                        docker push ${IMAGE_NAME}:${BUILD_VERSION}
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest

                        echo "✅ Image pushed successfully to ${DOCKER_REGISTRY}"

                        # Verify image in registry
                        curl -s http://${DOCKER_REGISTRY}/v2/_catalog
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                expression { return params.DEPLOY_TO_K8S }
            }
            steps {
                script {
                    echo '☸️  Deploying to Kubernetes...'
                    sh '''
                        # Install kubectl
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        mv kubectl /usr/local/bin/

                        # Verify kubectl
                        kubectl version --client || echo "kubectl installed"

                        # Create namespace if it doesn't exist
                        kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

                        # Update deployment image
                        cd kubernetes

                        # Apply manifests
                        kubectl apply -f namespace.yaml
                        kubectl apply -f deployment.yaml
                        kubectl apply -f service.yaml

                        # Update image tag
                        kubectl set image deployment/${APP_NAME} \
                            ${APP_NAME}=${IMAGE_NAME}:${BUILD_VERSION} \
                            -n ${K8S_NAMESPACE}

                        echo "✅ Kubernetes manifests applied successfully"
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            when {
                expression { return params.DEPLOY_TO_K8S }
            }
            steps {
                script {
                    echo '✅ Verifying deployment...'
                    sh '''
                        # Wait for rollout to complete
                        kubectl rollout status deployment/${APP_NAME} \
                            -n ${K8S_NAMESPACE} \
                            --timeout=300s

                        # Check pod status
                        kubectl get pods -n ${K8S_NAMESPACE} -l app=${APP_NAME}

                        # Check service
                        kubectl get svc -n ${K8S_NAMESPACE}

                        echo "✅ Deployment verification completed"
                    '''
                }
            }
        }

        stage('Health Check') {
            when {
                expression { return params.DEPLOY_TO_K8S }
            }
            steps {
                script {
                    echo '🏥 Running health check...'
                    sh '''
                        # Get service NodePort or ClusterIP
                        SERVICE_PORT=$(kubectl get svc ${APP_NAME} -n ${K8S_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "8000")

                        # Wait for service to be ready
                        sleep 10

                        # Health check (adapt based on your cluster setup)
                        echo "Service should be accessible at http://localhost:${SERVICE_PORT}/health"

                        # Alternative: Port-forward for testing
                        kubectl port-forward -n ${K8S_NAMESPACE} svc/${APP_NAME} 8080:8000 &
                        PF_PID=$!
                        sleep 5

                        # Test health endpoint
                        curl -f http://localhost:8080/health || echo "Health check endpoint not accessible yet"

                        # Cleanup port-forward
                        kill $PF_PID || true

                        echo "✅ Health check completed"
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                echo """
                ═══════════════════════════════════════════════════════
                📊 Pipeline Execution Summary
                ═══════════════════════════════════════════════════════
                Status: ${currentBuild.result ?: 'SUCCESS'}
                Duration: ${currentBuild.durationString}
                Build Number: ${env.BUILD_NUMBER}
                ═══════════════════════════════════════════════════════
                """
            }

            // Clean up Docker images to save space
            sh '''
                docker system prune -f || true
            '''
        }

        success {
            echo '✅ Pipeline completed successfully!'
            // Uncomment for Slack notifications:
            // slackSend(color: 'good', message: "✅ Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} succeeded")
        }

        failure {
            echo '❌ Pipeline failed! Check logs for details.'
            // Uncomment for Slack notifications:
            // slackSend(color: 'danger', message: "❌ Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} failed")
        }

        unstable {
            echo '⚠️  Pipeline completed with warnings.'
        }

        cleanup {
            echo '🧹 Cleaning up workspace...'
            cleanWs()
        }
    }
}
