# 01 - Project Overview

**Navigation:** [🏠 Home](../../README.md) | **👉 Next:** [Local Development Setup](02-local-development.md)

---

## 🎯 What is this POC?

This Proof of Concept demonstrates a **complete enterprise-grade microservices architecture** on Azure, showcasing:

- **Multi-service architecture** across AKS, Azure Functions, and Logic Apps
- **Infrastructure as Code** using Bicep templates
- **CI/CD automation** with Azure DevOps pipelines
- **Security best practices** with Workload Identity and Key Vault
- **Local development workflow** before cloud deployment

## 🏗️ Architecture Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                     Azure API Management                       │
│                         (APIM Gateway)                         │
└────────────┬──────────────────┬──────────────────┬─────────────┘
             │                  │                  │
   ┌─────────▼─────────┐ ┌──────▼──────┐ ┌─────────▼──────────┐
   │    AKS Cluster    │ │  Functions  │ │   Logic App        │
   │  ┌──────────────┐ │ │ ┌─────────┐ │ │  ┌──────────────┐  │
   │  │Authentication│ │ │ │Customer │ │ │  │GetAllOrders  │  │
   │  │   Service    │ │ │ │Function │ │ │  │              │  │
   │  └──────────────┘ │ │ └─────────┘ │ │  └──────────────┘  │
   │  ┌──────────────┐ │ │ ┌─────────┐ │ │  ┌──────────────┐  │
   │  │   Products   │ │ │ │Supplier │ │ │  │GetOrderById  │  │
   │  │   Service    │ │ │ │Function │ │ │  │              │  │
   │  └──────────────┘ │ │ └─────────┘ │ │  └──────────────┘  │
   └───────────────────┘ └─────────────┘ └────────────────────┘
             │                  │                 │
   ┌─────────▼──────────────────▼─────────────────▼───────────┐
   │                  Azure Key Vault                         │
   │              (Secrets & Configuration)                   │
   └──────────────────────────────────────────────────────────┘
                                │
   ┌────────────────────────────▼─────────────────────────────┐
   │           Azure Monitor + Application Insights           │
   │                  (Logging & Monitoring)                  │
   └──────────────────────────────────────────────────────────┘
```

## 📊 Services Breakdown

### 1. **AKS (Kubernetes) Services** - Container Orchestration
**Purpose:** Host stateful, long-running microservices

| Service | Port | Endpoints | Description |
|---------|------|-----------|-------------|
| **Authentication** | 8080 | POST `/api/auth/login`<br>POST `/api/auth/refresh-token` | User authentication and registration |
| **Products** | 8081 | GET `/api/products`<br>GET `/api/products/{id}` | Product catalog management |

**Why AKS?**
- Full control over deployment
- Kubernetes orchestration
- Auto-scaling capabilities
- Suitable for stateful services

### 2. **Azure Functions** - Serverless Compute
**Purpose:** Event-driven, stateless operations

| Function | Port | Endpoints | Description |
|----------|------|-----------|-------------|
| **CustomerFunction** | 7071 | GET `/function/customer`<br>GET `/function/customer/{id}`<br>POST `/function/customer` | Customer management |
| **SupplierFunction** | 7072 | GET `/function/supplier`<br>GET `/function/supplier/{id}`<br>POST `/function/supplier` | Supplier management |

**Why Azure Functions?**
- Pay-per-execution model
- Auto-scaling
- No infrastructure management
- Ideal for CRUD operations

### 3. **Logic Apps** - Workflow Orchestration
**Purpose:** Business process automation

| Workflow | Method | Endpoint | Description |
|----------|--------|----------|-------------|
| **GetAllOrders** | GET | `/api/GetAllOrders/triggers/manual/invoke` | Retrieve all orders |
| **GetOrderById** | POST | `/api/GetOrderById/triggers/manual/invoke` | Retrieve specific order |

**Why Logic Apps?**
- Visual workflow designer
- Built-in connectors
- Easy integration with external services
- Low-code solution

## 🔑 Key Components

### Infrastructure as Code (Bicep)
- **main.bicep** - Orchestrates all resources
- **Modular design** - Reusable components
- **Environment parameters** - Dev/Test/Prod configurations

### CI/CD Pipelines
- **Infrastructure CI** - Validates and builds Bicep templates
- **Infrastructure CD** - Deploys to Azure
- **Services CI/CD** - Builds and deploys microservices

### Security & Monitoring
- **Azure Key Vault** - Secrets management
- **Workload Identity** - Passwordless authentication
- **Application Insights** - Telemetry and monitoring
- **APIM** - API gateway and security

## 🎓 Learning Objectives

By completing this POC, you will learn:

1. ✅ How to structure a multi-service microservices architecture
2. ✅ Infrastructure as Code with Bicep
3. ✅ Local development setup for rapid iteration
4. ✅ CI/CD pipeline configuration in Azure DevOps
5. ✅ Kubernetes deployments and service management
6. ✅ Azure Functions development and deployment
7. ✅ Logic Apps workflow creation
8. ✅ Security best practices (Workload Identity, Key Vault)
9. ✅ API Management configuration
10. ✅ Monitoring and observability setup

## 📦 Technology Stack

| Layer | Technology |
|-------|-----------|
| **Languages** | C# (.NET 8.0), Node.js |
| **Container Runtime** | Docker |
| **Orchestration** | Kubernetes (AKS) |
| **Serverless** | Azure Functions, Logic Apps |
| **IaC** | Bicep |
| **CI/CD** | Azure DevOps YAML Pipelines |
| **API Gateway** | Azure API Management |
| **Secrets** | Azure Key Vault |
| **Monitoring** | Azure Monitor, Application Insights |
| **Storage** | Azure Storage (for Functions/Logic Apps) |

## 🚀 Development Approaches

This POC supports **two paths**:

### Path 1: Local-First Development (Recommended)
**Best for:** Learning, experimentation, cost optimization

1. Run all services locally (Minikube, func start)
2. Test and validate functionality
3. Deploy to Azure when ready

**Advantages:**
- ✅ No Azure costs during development
- ✅ Faster iteration cycle
- ✅ Learn architecture hands-on
- ✅ Debug easily

### Path 2: Cloud-First Deployment
**Best for:** Production setup, team collaboration

1. Set up Azure DevOps
2. Deploy infrastructure via pipelines
3. Deploy services automatically

**Advantages:**
- ✅ Production-ready immediately
- ✅ Team collaboration via Azure
- ✅ Automated deployments
- ✅ Monitoring from day one

## 📁 Repository Structure

```
.
├── docs/                         # 📚 Documentation (you are here!)
├── infra/                        # 🏗️ Infrastructure as Code
│   ├── main.bicep                # Main orchestration
│   ├── modules/                  # Reusable Bicep modules
│   ├── k8s/                      # Kubernetes manifests
│   └── pipelines/                # CI/CD pipelines
├── src/                          # 💻 Application code
│   ├── AKS/                      # Kubernetes services
│   ├── AzureFunctions/           # Serverless functions
│   └── LogicApp/                 # Workflow definitions
└── README.md                     # Main entry point
```

## ⏭️ What's Next?

**Choose your path:**

- 🔧 **Want to run locally first?** → Go to [Local Development Setup](02-local-development.md)
- ☁️ **Ready to deploy to Azure?** → Go to [Azure DevOps Setup](03-devops-setup.md)
- 📖 **Want to understand infrastructure?** → See [Infrastructure Components](infrastructure-components.md)

---

**Navigation:** [🏠 Home](../../README.md) | **👉 Next:** [Local Development Setup](02-local-development.md)
