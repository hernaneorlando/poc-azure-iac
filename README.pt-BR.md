# Azure Microservices POC - IaC com Bicep, AKS, Functions & Logic Apps

**Idiomas / Languages:** [🇧🇷 Português](README.pt-BR.md) | [🇺🇸 English](README.md)

[![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat&logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)
[![.NET](https://img.shields.io/badge/.NET-8.0-512BD4?style=flat&logo=dotnet&logoColor=white)](https://dotnet.microsoft.com/)
[![Bicep](https://img.shields.io/badge/Bicep-IaC-blue)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

## 📖 Visão Geral

Este repositório contém uma **Prova de Conceito (POC)** que demonstra uma arquitetura completa de microsserviços no Azure utilizando:

- **Azure Kubernetes Service (AKS)** - Microsserviços containerizados
- **Azure Functions** - Computação sem servidor
- **Azure Logic Apps** - Orquestração de fluxos de trabalho
- **Azure API Management (APIM)** - Gateway de API
- **Infrastructure as Code (IaC)** - Templates Bicep
- **Pipelines CI/CD** - Azure DevOps YAML

## 🎯 Propósito

Esta POC foi projetada para **aprendizado e exploração** de serviços Azure. Demonstra:
- ✅ Padrões modernos de arquitetura nativa em nuvem
- ✅ Infrastructure as Code com Bicep
- ✅ Fluxo de trabalho de desenvolvimento local
- ✅ Automação de CI/CD com Azure DevOps
- ✅ Múltiplos serviços Azure funcionando juntos (AKS, Functions, Logic Apps)
- ✅ Fundamentos de segurança com Workload Identity e Key Vault

> ⚠️ **Nota:** Esta é uma POC de aprendizado, mais adequada para ambientes de desenvolvimento/testes.

## 🏗️ Arquitetura

A solução está distribuída entre **seis serviços/APIs Azure**:

| Serviço | Tecnologia | Endpoints |
|---------|-----------|-----------|
| **Autenticação** | AKS (.NET 8) | 2 endpoints (login, atualizar token) |
| **Produtos** | AKS (.NET 8) | 2 endpoints (listar, obter por id) |
| **Clientes** | Azure Function | 3 endpoints (listar, obter por id, criar) |
| **Fornecedores** | Azure Function | 3 endpoints (listar, obter por id, criar) |
|| **Pedidos** | Logic App | 2 fluxos (listar, obter por id) |
|| **Carrinho** | Logic App | 2 fluxos (adicionar item, obter carrinho) |

**Total:** 14 endpoints de API RESTful expostos através do APIM.

## 🚦 Resumo dos Pré-requisitos

### Para Implantação de Infraestrutura:
- Assinatura Azure com acesso de proprietário/contribuidor
- Azure CLI instalado
- Organização Azure DevOps

### Para Desenvolvimento Local:
- Docker Desktop
- .NET 8.0 SDK
- Azure Functions Core Tools
- Node.js (para Logic Apps)
- Minikube (para AKS)

> 📖 **Veja pré-requisitos detalhados em [Configuração de Desenvolvimento Local](docs/pt-BR/02-local-development.pt-BR.md)**

## 📁 Estrutura do Repositório

```
├── docs/                    # 📚 Documentação completa
├── infra/                   # 🏗️ Infrastructure as Code
│   ├── main.bicep
│   ├── modules/             # Módulos Bicep (ACR, AKS, APIM, Functions, etc.)
│   ├── k8s/                 # Manifestos Kubernetes (deployments, services, secrets)
│   └── pipelines/           # Pipelines CI/CD do Azure DevOps
├── src/                     # 💻 Código da aplicação
│   ├── AKS/                 # Serviços Kubernetes
│   │   ├── Authentication/  # API de Autenticação (.NET 8)
│   │   ├── Products/        # API de Produtos (.NET 8)
│   │   └── Common/          # Modelos e utilitários compartilhados
│   ├── AzureFunctions/      # Funções serverless
│   │   ├── CustomerFunction/   # API de Clientes (.NET 8)
│   │   └── SupplierFunction/   # API de Fornecedores (.NET 8)
│   └── LogicApp/            # Orquestração de fluxos de trabalho
│       ├── OrdersLogicApp/  # Fluxos de Pedidos (GetAllOrders, GetOrderById)
│       └── CartLogicApp/    # Fluxos de Carrinho (AddItemToCart, GetCart)
└── README.md                # 👈 Você está aqui!
```

## 🎬 Primeiros Passos

**Escolha seu caminho:**

### Opção 1: Desenvolvimento Local Primeiro (Recomendado para aprendizado)
👉 Comece com **[Configuração de Desenvolvimento Local](docs/pt-BR/02-local-development.pt-BR.md)**

Esta abordagem permite:
- Executar todos os serviços em sua máquina
- Entender a arquitetura na prática
- Fazer alterações sem custos do Azure
- Implantar no Azure quando pronto

### Opção 2: Implantação Direta no Azure (Para configuração do ambiente de desenvolvimento/teste)
👉 Comece com **[Configuração do Azure DevOps](docs/pt-BR/03-devops-setup.pt-BR.md)**

Esta abordagem:
- Configura recursos Azure imediatamente
- Define pipelines CI/CD
- Implanta infraestrutura pronta para desenvolvimento/teste

## 📚 Estrutura da Documentação

Siga este **guia passo a passo** para entender e implantar esta POC:

### 🚀 Início Rápido
1. **[Visão Geral do Projeto](docs/pt-BR/01-project-overview.pt-BR.md)** - Arquitetura e componentes
2. **[Configuração de Desenvolvimento Local](docs/pt-BR/02-local-development.pt-BR.md)** - Execute todos os serviços localmente
3. **[Configuração do Azure DevOps](docs/pt-BR/03-devops-setup.pt-BR.md)** - Configure conexões de serviço e pipelines
4. **[Implantação de Infraestrutura](docs/pt-BR/04-infrastructure-deployment.pt-BR.md)** - Implante no Azure
5. **[Implantação de Serviços](docs/pt-BR/05-services-deployment.pt-BR.md)** - Implante microsserviços

### 📚 Guias Detalhados
- **[Guia de Serviços AKS](docs/pt-BR/src-aks-readme.pt-BR.md)** - Documentação de serviços Kubernetes
- **[Guia de Azure Functions](docs/pt-BR/src-azurefunctions-readme.pt-BR.md)** - Documentação de funções sem servidor
- **[Guia de Logic App](docs/pt-BR/src-logicapp-readme.pt-BR.md)** - Documentação de orquestração de fluxos
- **[Guia de CI/CD de Logic Apps](docs/pt-BR/logicapp-cicd.pt-BR.md)** - Deploy de Logic Apps Standard

### 🛠️ Documentação de Referência
- **[Componentes de Infraestrutura](docs/pt-BR/infrastructure-components.pt-BR.md)** - Módulos Bicep explicados
- **[Pipelines CI/CD](docs/pt-BR/cicd-pipelines.pt-BR.md)** - Estrutura e configuração de pipeline
- **[Configuração do API Management](docs/pt-BR/apim-configuration.pt-BR.md)** - Configuração e uso do gateway APIM
- **[Guia de Solução de Problemas](docs/pt-BR/troubleshooting.pt-BR.md)** - Problemas comuns e soluções
- **[Guia de Bootstrap](docs/pt-BR/bootstrap-guide.pt-BR.md)** - Configuração automatizada de ambiente

## 📄 Licença

Este projeto é fornecido como está para fins educacionais.

## 🔗 Links Úteis

- [Documentação do Azure](https://learn.microsoft.com/azure/)
- [Documentação do Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Documentação do AKS](https://learn.microsoft.com/azure/aks/)
- [Documentação do Azure Functions](https://learn.microsoft.com/azure/azure-functions/)
- [Documentação do Logic Apps](https://learn.microsoft.com/azure/logic-apps/)

---

**Pronto para começar?** 👉 Vá para **[Visão Geral do Projeto](docs/pt-BR/01-project-overview.pt-BR.md)**