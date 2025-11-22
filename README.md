# Azure Microservices POC - IaC with Bicep, AKS, Functions & Logic Apps

**Languages / Idiomas:** [🇺🇸 English](README.md) | [🇧🇷 Português](README.pt-BR.md)

[![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat&logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)
[![.NET](https://img.shields.io/badge/.NET-8.0-512BD4?style=flat&logo=dotnet&logoColor=white)](https://dotnet.microsoft.com/)
[![Bicep](https://img.shields.io/badge/Bicep-IaC-blue)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

## 📖 Overview

This repository contains a **Proof of Concept (POC)** demonstrating a complete microservices architecture on Azure using:

- **Azure Kubernetes Service (AKS)** - Containerized microservices
- **Azure Functions** - Serverless compute
- **Azure Logic Apps** - Workflow orchestration
- **Azure API Management (APIM)** - API Gateway
- **Infrastructure as Code (IaC)** - Bicep templates
- **CI/CD Pipelines** - Azure DevOps YAML

## 🎯 Purpose

This POC is designed for **learning and exploration** of Azure services. It demonstrates:
- ✅ Modern cloud-native architecture patterns
- ✅ Infrastructure as Code with Bicep
- ✅ Local development workflow
- ✅ CI/CD automation with Azure DevOps
- ✅ Multiple Azure services working together (AKS, Functions, Logic Apps)
- ✅ Security basics with Workload Identity and Key Vault

> ⚠️ **Note:** This is a learning POC, best suited for development/testing environments.

## 🏗️ Architecture

The solution is distributed across **six Azure services/APIs**:

| Service | Technology | Endpoints |
|---------|-----------|-----------|
| **Authentication** | AKS (.NET 8) | 2 endpoints (login, token refresh) |
| **Products** | AKS (.NET 8) | 2 endpoints (list, get by id) |
| **Customers** | Azure Function | 3 endpoints (list, get by id, create) |
| **Suppliers** | Azure Function | 3 endpoints (list, get by id, create) |
|| **Orders** | Logic App | 2 workflows (list, get by id) |
|| **Cart** | Logic App | 2 workflows (add item, get cart) |

**Total:** 14 RESTful API endpoints exposed through APIM.

## 🚦 Prerequisites Summary

### For Infrastructure Deployment:
- Azure subscription with owner/contributor access
- Azure CLI installed
- Azure DevOps organization

### For Local Development:
- Docker Desktop
- .NET 8.0 SDK
- Azure Functions Core Tools
- Node.js (for Logic Apps)
- Minikube (for AKS)

> 📖 **See detailed prerequisites in [Local Development Setup](docs/en-US/02-local-development.md)**

## 📁 Repository Structure

```
├── docs/                    # 📚 Complete documentation
├── infra/                   # 🏗️ Infrastructure as Code
│   ├── main.bicep
│   ├── modules/             # Bicep modules (ACR, AKS, APIM, Functions, etc.)
│   ├── k8s/                 # Kubernetes manifests (deployments, services, secrets)
│   └── pipelines/           # Azure DevOps CI/CD pipelines
├── src/                     # 💻 Application code
│   ├── AKS/                 # Kubernetes services
│   │   ├── Authentication/  # Auth API (.NET 8)
│   │   ├── Products/        # Products API (.NET 8)
│   │   └── Common/          # Shared models and utilities
│   ├── AzureFunctions/      # Serverless functions
│   │   ├── CustomerFunction/   # Customer API (.NET 8)
│   │   └── SupplierFunction/   # Supplier API (.NET 8)
│   └── LogicApp/            # Workflow orchestration
│       ├── OrdersLogicApp/  # Orders workflows (GetAllOrders, GetOrderById)
│       └── CartLogicApp/    # Cart workflows (AddItemToCart, GetCart)
└── README.md                # 👈 You are here!
```

## 🎬 Getting Started

**Choose your path:**

### Option 1: Local Development First (Recommended for learning)
👉 Start with **[Local Development Setup](docs/en-US/02-local-development.md)**

This approach lets you:
- Run all services on your machine
- Understand the architecture hands-on
- Make changes without Azure costs
- Deploy to Azure when ready

### Option 2: Direct Azure Deployment (For development/test setup)
👉 Start with **[Azure DevOps Setup](docs/en-US/03-devops-setup.md)**

This approach:
- Sets up Azure resources immediately
- Configures CI/CD pipelines
- Deploys infrastructure ready for development/test

## 📚 Documentation Structure

Follow this **step-by-step guide** to understand and deploy this POC:

### 🚀 Quick Start
1. **[Project Overview](docs/en-US/01-project-overview.md)** - Architecture and components
2. **[Local Development Setup](docs/en-US/02-local-development.md)** - Run all services locally
3. **[Azure DevOps Setup](docs/en-US/03-devops-setup.md)** - Configure service connections and pipelines
4. **[Infrastructure Deployment](docs/en-US/04-infrastructure-deployment.md)** - Deploy to Azure
5. **[Services Deployment](docs/en-US/05-services-deployment.md)** - Deploy microservices

### 📚 Detailed Guides
- **[AKS Services Guide](docs/en-US/src-aks-readme.md)** - Kubernetes services documentation
- **[Azure Functions Guide](docs/en-US/src-azurefunctions-readme.md)** - Serverless functions documentation
- **[Logic App Guide](docs/en-US/src-logicapp-readme.md)** - Workflow orchestration documentation
- **[Logic Apps CI/CD Guide](docs/en-US/logicapp-cicd.md)** - Logic Apps Standard deployment

### 🛠️ Reference Documentation
- **[Infrastructure Components](docs/en-US/infrastructure-components.md)** - Bicep modules explained
- **[CI/CD Pipelines](docs/en-US/cicd-pipelines.md)** - Pipeline structure and configuration
- **[API Management Configuration](docs/en-US/apim-configuration.md)** - APIM gateway setup and usage
- **[Troubleshooting Guide](docs/en-US/troubleshooting.md)** - Common issues and solutions
- **[Bootstrap Guide](docs/en-US/bootstrap-guide.md)** - Automated environment setup

## 📄 License

This project is provided as-is for educational purposes.

## 🔗 Useful Links

- [Azure Documentation](https://learn.microsoft.com/azure/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [AKS Documentation](https://learn.microsoft.com/azure/aks/)
- [Azure Functions Documentation](https://learn.microsoft.com/azure/azure-functions/)
- [Logic Apps Documentation](https://learn.microsoft.com/azure/logic-apps/)

---

**Ready to start?** 👉 Go to **[Project Overview](docs/en-US/01-project-overview.md)**
