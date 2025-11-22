# AKS Services - Local Development Guide

**Languages / Idiomas:** [🇺🇸 English](/docs/src-aks-readme.md) | [🇧🇷 Português](/docs/src-aks-readme.pt-BR.md)

**Navigation:** [🏠 Home](README.md) | [📚 Docs](/docs/README.md) | [⬅️ Back to Local Setup](../../docs/02-local-development.md)

## Overview

This directory contains the microservices running on Azure Kubernetes Service (AKS):
- **Authentication**: User authentication and authorization
- **Products**: Product catalog management

Both services are built with .NET 8.0 and containerized for deployment on Kubernetes.

## Available Endpoints

### Authentication Service
- `POST /api/auth/login` - User authentication
- `POST /api/auth/register` - User registration

### Products Service
- `GET /api/products` - List all products
- `GET /api/products/{id}` - Get product by ID

## Local Development Setup

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- Docker Hub account (for pushing images)

### Running Locally with Minikube

#### 1. Start Minikube

```bash
minikube start
```

#### 2. Build and Push Docker Images

```bash
cd src/AKS

# Build Authentication
docker build -t <YOUR_DOCKERHUB_USERNAME>/auth-api:latest -f Authentication/Dockerfile .
docker push <YOUR_DOCKERHUB_USERNAME>/auth-api:latest

# Build Products
docker build -t <YOUR_DOCKERHUB_USERNAME>/products-api:latest -f Products/Dockerfile .
docker push <YOUR_DOCKERHUB_USERNAME>/products-api:latest
```

#### 3. Update Kubernetes Manifests

Edit the deployment files in `infra/k8s/` to use your Docker Hub images:

```yaml
# infra/k8s/auth-deployment.yaml
image: <YOUR_DOCKERHUB_USERNAME>/auth-api:latest

# infra/k8s/products-deployment.yaml
image: <YOUR_DOCKERHUB_USERNAME>/products-api:latest
```

#### 4. Apply the Secrets YAML files

```bash
kubectl apply -f infra/k8s/auth-secrets.yaml
kubectl apply -f infra/k8s/products-secrets.yaml
```

Or create via CLI:

```bash
# Authentication secret (JWT)
kubectl create secret generic auth-api-secrets \
  --from-literal=jwt-secret="my-super-secret-key-for-testing-123"

# Products secret (Connection String)
kubectl create secret generic products-api-secrets \
  --from-literal=connectionString="Server=localhost;Database=ProductsDB;"
```

#### 5. Deploy to Minikube

```bash
kubectl apply -f infra/k8s/auth-deployment.yaml
kubectl apply -f infra/k8s/products-deployment.yaml
```

#### 6. Check Pod Status

```bash
kubectl get pods
kubectl logs <pod-name>
```

#### 7. Access Services

##### Using Port-Forward:

```bash
# Authentication (terminal 1)
kubectl port-forward service/auth-api 8080:8080

# Products (terminal 2)
kubectl port-forward service/products-api 8081:8081
```

Then access:
- Authentication: `http://localhost:8080/swagger`
- Products: `http://localhost:8081/swagger`

##### Using NodePort (if configured):

```bash
minikube service auth-api --url
minikube service products-api --url
```

## Project Structure

```
AKS/
├── Authentication/
│   ├── Program.cs
│   ├── Authentication.csproj
│   ├── Dockerfile
│   └── Resources/
│       └── AuthController.cs
├── Products/
│   ├── Program.cs
│   ├── Products.csproj
│   ├── Dockerfile
│   └── Resources/
│       └── ProductsController.cs
└── Common/
    └── Common.csproj
```

## Troubleshooting

### ImagePullBackOff Error
- Verify the image exists in Docker Hub
- Check if the image name in deployment YAML matches
- For private repos, create imagePullSecrets

### CreateContainerConfigError
- Ensure secrets are created before deployment
- Verify secret names match the deployment configuration

### Port 8080 Issue
- .NET 8 uses port 8080 by default
- Ensure `targetPort: 8080` in Service configuration

## Testing Locally (Without Kubernetes)

```bash
# Run Authentication API
cd src/AKS/Authentication
dotnet run

# Run Products API (in another terminal)
cd src/AKS/Products
dotnet run
```

Both will be available on `http://localhost:5000` (or configured port).

## CI/CD Integration

- Build images in CI pipeline
- Push to Azure Container Registry (ACR)
- Deploy to AKS cluster via CD pipeline
- Use Workload Identity for secure access to Azure resources
