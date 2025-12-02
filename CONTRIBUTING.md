# Contributing to Jenkins Pipeline CI/CD

Thank you for considering contributing to this project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project adheres to professional standards. Please:
- Be respectful and inclusive
- Focus on constructive feedback
- Help maintain a welcoming environment

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/jenkins-pipeline-cicd.git
   cd jenkins-pipeline-cicd
   ```

3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/original-repo/jenkins-pipeline-cicd.git
   ```

4. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Setting Up Development Environment

```bash
# Install dependencies
make install

# Run tests
make test

# Start development environment
make start
```

### Making Changes

1. **Write Code**: Implement your feature or fix
2. **Add Tests**: Ensure new code is tested
3. **Run Tests**: Verify all tests pass
4. **Update Documentation**: Update README if needed
5. **Test Locally**: Run the full pipeline locally

### Testing Your Changes

```bash
# Run unit tests
make test

# Run with coverage
make test-coverage

# Build Docker image
make build

# Scan for vulnerabilities
make scan

# Test Kubernetes deployment
make k8s-setup
```

## Coding Standards

### Python Code

- Follow PEP 8 style guide
- Use type hints where appropriate
- Add docstrings to functions and classes
- Keep functions focused and small

```python
def process_data(input_data: str) -> dict:
    """
    Process input data and return result.

    Args:
        input_data: The data to process

    Returns:
        Dictionary containing processed results
    """
    # Implementation here
    pass
```

### Shell Scripts

- Use `set -e` to exit on errors
- Use `set -u` for undefined variables
- Add comments for complex logic
- Use functions for reusability

```bash
#!/bin/bash
set -e
set -u

# Function to perform task
perform_task() {
    local input="$1"
    # Implementation
}
```

### Dockerfile

- Use multi-stage builds
- Run as non-root user
- Minimize layers
- Add security scanning

### Kubernetes Manifests

- Include resource limits
- Add health checks
- Use security contexts
- Follow naming conventions

## Testing Guidelines

### Unit Tests

```python
def test_feature():
    """Test specific feature functionality."""
    # Arrange
    input_data = "test"

    # Act
    result = process_feature(input_data)

    # Assert
    assert result == expected_output
```

### Integration Tests

Test the complete workflow:
1. Build image
2. Push to registry
3. Deploy to Kubernetes
4. Verify endpoints

### Test Coverage

- Maintain minimum 80% code coverage
- Test edge cases and error conditions
- Include both positive and negative tests

## Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples

```
feat(pipeline): add security scanning stage

Add Trivy security scanning to Jenkins pipeline
to identify vulnerabilities before deployment.

Closes #123
```

```
fix(k8s): correct service port configuration

The service was using incorrect target port,
causing connection failures.
```

## Pull Request Process

### Before Submitting

- [ ] Code follows project style guidelines
- [ ] All tests pass locally
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] Commit messages follow guidelines
- [ ] No merge conflicts with main branch

### Submitting Pull Request

1. **Push to Your Fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request**:
   - Go to GitHub repository
   - Click "New Pull Request"
   - Select your branch
   - Fill in PR template

3. **PR Title Format**:
   ```
   [TYPE] Brief description of changes
   ```
   Example: `[FEATURE] Add Prometheus monitoring integration`

4. **PR Description Template**:
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Testing
   Describe testing performed

   ## Checklist
   - [ ] Tests pass
   - [ ] Documentation updated
   - [ ] Follows coding standards
   ```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs automatically
2. **Code Review**: Maintainers review code
3. **Feedback**: Address review comments
4. **Approval**: Get approval from maintainers
5. **Merge**: Maintainer merges PR

### After Merge

1. **Update Local Repository**:
   ```bash
   git checkout main
   git pull upstream main
   ```

2. **Delete Feature Branch**:
   ```bash
   git branch -d feature/your-feature-name
   ```

## Development Tips

### Local Testing

```bash
# Full pipeline test
make install
make build
make test
make scan
make k8s-setup

# Cleanup
make clean-all
```

### Debugging

```bash
# View Jenkins logs
make logs-jenkins

# View application logs
make logs-app

# Check Kubernetes pods
kubectl get pods -n cicd-demo -w

# Describe pod for events
kubectl describe pod <pod-name> -n cicd-demo
```

### Common Issues

#### Docker Build Fails

```bash
# Clear Docker cache
docker system prune -a

# Rebuild without cache
make build-no-cache
```

#### Tests Failing

```bash
# Run with verbose output
cd app
pytest test_app.py -v -s

# Run specific test
pytest test_app.py::test_function_name -v
```

#### Kubernetes Deployment Issues

```bash
# Check events
kubectl get events -n cicd-demo --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs -n cicd-demo <pod-name>

# Recreate deployment
make k8s-delete
make k8s-setup
```

## Project Structure

```
jenkins-pipeline-cicd/
├── app/                    # Application code
│   ├── main.py            # FastAPI application
│   ├── test_app.py        # Unit tests
│   └── requirements.txt   # Dependencies
├── kubernetes/            # K8s manifests
├── scripts/               # Automation scripts
├── Jenkinsfile           # Pipeline definition
├── Dockerfile            # Container build
└── Makefile              # Commands
```

## Additional Resources

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Python Testing with pytest](https://docs.pytest.org/)

## Questions?

If you have questions:
1. Check the README.md
2. Search existing issues
3. Create a new issue with detailed description

## Recognition

Contributors will be recognized in the project README. Thank you for your contributions!

---

Happy coding! 🚀
