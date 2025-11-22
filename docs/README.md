# Documentation Index

**Languages / Idiomas:** [🇺🇸 English](README.md) | [🇧🇷 Português](README.pt-BR.md)

**Navigation:** [🏠 Home](../README.md)

---

## 📚 Complete Documentation Guide

Welcome to the comprehensive documentation for the Azure Microservices POC. This guide is organized as a **step-by-step wizard** to help you understand, set up, and deploy the entire solution.

## 🚀 Quick Start Guides (Follow in Order)

These guides walk you through the complete setup process:

| # | Guide | Description | Time |
|---|-------|-------------|------|
| **01** | [Project Overview](en-US/01-project-overview.md) | Understand the architecture and components | 10 min |
| **02** | [Local Development Setup](en-US/02-local-development.md) | Run all services on your machine | 30-45 min |
| **03** | [Azure DevOps Setup](en-US/03-devops-setup.md) | Configure pipelines and service connections | 20-30 min |
| **04** | [Infrastructure Deployment](en-US/04-infrastructure-deployment.md) | Deploy Azure resources | 60-90 min |
| **05** | [Services Deployment](en-US/05-services-deployment.md) | Deploy microservices | 20-30 min |

**Total time:** ~2.5-3 hours (including Azure deployment wait time)

## 📖 Service-Specific Guides

Detailed documentation for each service type:

| Service | English | Português |
|---------|---------|-----------|
| **AKS Services** | [README.md](en-US/src-aks-readme.md) | [README.pt-BR.md](pt-BR/src-aks-readme.pt-BR.md) |
| **Azure Functions** | [README.md](en-US/src-azurefunctions-readme.md) | [README.pt-BR.md](pt-BR/src-azurefunctions-readme.pt-BR.md) |
| **Logic App** | [README.md](en-US/src-logicapp-readme.md) | [README.pt-BR.md](pt-BR/src-logicapp-readme.pt-BR.md) |

## 🛠️ Reference Documentation

In-depth technical references:

- **[Infrastructure Components](en-US/infrastructure-components.md)** - Bicep modules explained
- **[CI/CD Pipelines](en-US/cicd-pipelines.md)** - Pipeline structure and configuration  
- **[Troubleshooting Guide](en-US/troubleshooting.md)** - Common issues and solutions
- **[Bootstrap Guide](en-US/bootstrap-guide.md)** - About automated setup (not recommended for POC)

## 📁 Examples & Templates

- **[Bootstrap Example](examples/infra_bootstrap.exemplo.yaml)** - Automated setup reference

## 🎯 Choose Your Path

### Path 1: Local Development First ⭐ Recommended for Learning

Perfect if you want to:
- Learn the architecture hands-on
- Test locally before deploying to Azure
- Minimize Azure costs during development

**Start here:** [02 - Local Development Setup](en-US/02-local-development.md)

### Path 2: Direct Azure Deployment

Perfect if you:
- Want a production-ready setup immediately
- Have an Azure subscription ready
- Need team collaboration from day one

**Start here:** [03 - Azure DevOps Setup](en-US/03-devops-setup.md)

## 📊 Documentation Status

| Document | Status | Last Updated |
|----------|--------|--------------|
| Project Overview | ✅ Complete | 2025-11 |
| Local Development | ✅ Complete | 2025-11 |
| Azure DevOps Setup | ✅ Complete | 2025-11 |
| Infrastructure Deployment | 🚧 In Progress | - |
| Services Deployment | 🚧 In Progress | - |
| Infrastructure Components | 🚧 Planned | - |
| CI/CD Pipelines | 🚧 Planned | - |
| Troubleshooting | 🚧 Planned | - |

## 🌍 Language Support

| Language | Status |
|----------|--------|
| 🇺🇸 English | ✅ Primary |
| 🇧🇷 Português | ⏳ Service READMEs only |

## 🔍 Quick Links

### Getting Started
- [What is this POC?](en-US/01-project-overview.md#-what-is-this-poc)
- [Architecture Diagram](en-US/01-project-overview.md#-architecture-diagram)
- [Prerequisites Summary](../README.md#-prerequisites-summary)

### Development
- [Run AKS Services Locally](en-US/src-aks-readme.md#running-locally-with-minikube)
- [Run Azure Functions Locally](en-US/src-azurefunctions-readme.md#running-locally)
- [Run Logic App Locally](en-US/src-logicapp-readme.md#running-locally)

### Deployment
- [Create Service Connection](en-US/03-devops-setup.md#step-3-create-service-connection-in-azure-devops)
- [Register Resource Providers](en-US/03-devops-setup.md#step-1-azure-portal---register-resource-providers)
- [Create Pipelines](en-US/03-devops-setup.md#step-6-create-infrastructure-ci-pipeline)

### Troubleshooting
- [AKS Issues](en-US/src-aks-readme.md#troubleshooting)
- [Functions Issues](en-US/src-azurefunctions-readme.md#troubleshooting)
- [Logic App Issues](en-US/src-logicapp-readme.md#troubleshooting)

## 💡 Tips for Using This Documentation

### For First-Time Users
1. Read [Project Overview](01-project-overview.md) to understand the big picture
2. Follow the Quick Start Guides in order
3. Refer to Service-Specific Guides for details
4. Keep the Troubleshooting Guide handy

### For Experienced Users
- Jump directly to relevant sections
- Use the Quick Links above
- Reference documentation for deep dives

### For Instructors/Trainers
- Guides are designed for self-paced learning
- Each guide has clear objectives and time estimates
- Includes troubleshooting for common learner issues

## 📝 Contributing to Documentation

If you find issues or have suggestions:
1. Check existing documentation first
2. Look in Troubleshooting Guide
3. Review service-specific READMEs
4. Submit feedback or PR

## 🆘 Need Help?

1. **Check the guide you're following** - Most issues are addressed inline
2. **Review [Troubleshooting Guide](troubleshooting.md)** - Common issues and solutions
3. **Check service-specific README** - Detailed setup for each service
4. **Review Azure DevOps pipeline logs** - For deployment issues

## 📚 External Resources

- [Azure Documentation](https://learn.microsoft.com/azure/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure DevOps Documentation](https://learn.microsoft.com/azure/devops/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Navigation:** [🏠 Home](../README.md)

**Ready to start?** 👉 [Begin with Project Overview](01-project-overview.md)
