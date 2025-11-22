# 01 - Visão Geral do Projeto

**Navegação:** [🏠 Início](../../README.pt-BR.md) | **👉 Próximo:** [Configuração de Desenvolvimento Local](02-local-development.pt-BR.md)

---

## 🎯 O que é esta POC?

Esta Prova de Conceito demonstra uma **arquitetura completa de microsserviços em nível empresarial** no Azure, destacando:

- **Arquitetura multi-serviço** através de AKS, Azure Functions e Logic Apps
- **Infrastructure as Code** usando templates Bicep
- **Automação de CI/CD** com pipelines Azure DevOps
- **Melhores práticas de segurança** com Workload Identity e Key Vault
- **Fluxo de trabalho de desenvolvimento local** antes da implantação em nuvem

## 🏗️ Diagrama de Arquitetura

```
┌────────────────────────────────────────────────────────────────┐
│                 Gerenciamento de API do Azure                  │
│                     (Gateway APIM)                             │
└────────────┬───────────────────┬──────────────────┬────────────┘
             │                   │                  │
   ┌─────────▼─────────┐ ┌───────▼──────┐ ┌─────────▼──────────┐
   │  Cluster AKS      │ │  Functions   │ │   Logic App        │
   │  ┌──────────────┐ │ │ ┌──────────┐ │ │  ┌──────────────┐  │
   │  │Serviço de    │ │ │ │Função    │ │ │  │ObterTodosOs  │  │
   │  │Autenticação  │ │ │ │Cliente   │ │ │  │Pedidos       │  │
   │  └──────────────┘ │ │ └──────────┘ │ │  └──────────────┘  │
   │  ┌──────────────┐ │ │ ┌──────────┐ │ │  ┌──────────────┐  │
   │  │   Produtos   │ │ │ │Função    │ │ │  │ObterPedidoPor│  │
   │  │   Serviço    │ │ │ │Fornecedor│ │ │  │Id            │  │
   │  └──────────────┘ │ │ └──────────┘ │ │  └──────────────┘  │
   └───────────────────┘ └──────────────┘ └────────────────────┘
             │                  │                   │
   ┌─────────▼──────────────────▼───────────────────▼─────────┐
   │                 Azure Key Vault                          │
   │            (Secrets e Configuração)                      │
   └──────────────────────────────────────────────────────────┘
                                │
   ┌────────────────────────────▼─────────────────────────────┐
   │      Azure Monitor + Application Insights                │
   │              (Logging e Monitoramento)                   │
   └──────────────────────────────────────────────────────────┘
```

## 📊 Detalhamento dos Serviços

### 1. **Serviços AKS (Kubernetes)** - Orquestração de Containers
**Propósito:** Hospedar microsserviços com estado, de longa duração

| Serviço | Porta | Endpoints | Descrição |
|---------|-------|-----------|----------|
| **Autenticação** | 8080 | POST `/api/auth/login`<br>POST `/api/auth/refresh-token` | Autenticação e registro de usuário |
| **Produtos** | 8081 | GET `/api/products`<br>GET `/api/products/{id}` | Gerenciamento de catálogo de produtos |

**Por que AKS?**
- Controle total sobre implantação
- Orquestração Kubernetes
- Capacidades de auto-escaling
- Adequado para serviços com estado

### 2. **Azure Functions** - Computação Sem Servidor
**Propósito:** Operações orientadas a eventos, sem estado

| Função | Porta | Endpoints | Descrição |
|--------|-------|-----------|----------|
| **FunçãoCliente** | 7071 | GET `/function/customer`<br>GET `/function/customer/{id}`<br>POST `/function/customer` | Gerenciamento de clientes |
| **FunçãoFornecedor** | 7072 | GET `/function/supplier`<br>GET `/function/supplier/{id}`<br>POST `/function/supplier` | Gerenciamento de fornecedores |

**Por que Azure Functions?**
- Modelo de pagamento por execução
- Auto-escaling automático
- Sem gerenciamento de infraestrutura
- Ideal para operações CRUD

### 3. **Logic Apps** - Orquestração de Fluxos
**Propósito:** Automação de processos de negócios

| Fluxo | Método | Endpoint | Descrição |
|-------|--------|----------|----------|
| **ObterTodosOsPedidos** | GET | `/api/GetAllOrders/triggers/manual/invoke` | Recuperar todos os pedidos |
| **ObterPedidoPorId** | POST | `/api/GetOrderById/triggers/manual/invoke` | Recuperar pedido específico |

**Por que Logic Apps?**
- Designer de fluxo visual
- Conectores integrados
- Integração fácil com serviços externos
- Solução com baixo código

## 🔑 Componentes Principais

### Infrastructure as Code (Bicep)
- **main.bicep** - Orquestra todos os recursos
- **Design modular** - Componentes reutilizáveis
- **Parâmetros de ambiente** - Configurações Dev/Test/Prod

### Pipelines CI/CD
- **CI de Infraestrutura** - Valida e constrói templates Bicep
- **CD de Infraestrutura** - Implanta no Azure
- **CI/CD de Serviços** - Constrói e implanta microsserviços

### Segurança e Monitoramento
- **Azure Key Vault** - Gerenciamento de secrets
- **Workload Identity** - Autenticação sem senha
- **Application Insights** - Telemetria e monitoramento
- **APIM** - Gateway de API e segurança

## 🎓 Objetivos de Aprendizado

Ao completar esta POC, você aprenderá:

1. ✅ Como estruturar uma arquitetura de microsserviços multi-serviço
2. ✅ Infrastructure as Code com Bicep
3. ✅ Configuração de desenvolvimento local para iteração rápida
4. ✅ Configuração de pipeline CI/CD no Azure DevOps
5. ✅ Implantações Kubernetes e gerenciamento de serviços
6. ✅ Desenvolvimento e implantação de Azure Functions
7. ✅ Criação de fluxos de trabalho Logic Apps
8. ✅ Melhores práticas de segurança (Workload Identity, Key Vault)
9. ✅ Configuração de Gerenciamento de API
10. ✅ Configuração de monitoramento e observabilidade

## 📦 Stack de Tecnologia

| Camada | Tecnologia |
|--------|-----------|
| **Linguagens** | C# (.NET 8.0), Node.js |
| **Runtime de Container** | Docker |
| **Orquestração** | Kubernetes (AKS) |
| **Sem Servidor** | Azure Functions, Logic Apps |
| **IaC** | Bicep |
| **CI/CD** | Pipelines YAML do Azure DevOps |
| **Gateway de API** | Gerenciamento de API do Azure |
| **Secrets** | Azure Key Vault |
| **Monitoramento** | Azure Monitor, Application Insights |
| **Armazenamento** | Azure Storage (para Functions/Logic Apps) |

## 🚀 Abordagens de Desenvolvimento

Esta POC suporta **dois caminhos**:

### Caminho 1: Desenvolvimento Local-Primeiro (Recomendado)
**Melhor para:** Aprendizado, experimentação, otimização de custos

1. Execute todos os serviços localmente (Minikube, func start)
2. Teste e valide funcionalidade
3. Implante no Azure quando pronto

**Vantagens:**
- ✅ Sem custos do Azure durante desenvolvimento
- ✅ Ciclo de iteração mais rápido
- ✅ Aprenda arquitetura na prática
- ✅ Depure facilmente

### Caminho 2: Implantação Primeiro na Nuvem
**Melhor para:** Configuração de produção, colaboração em equipe

1. Configure Azure DevOps
2. Implante infraestrutura via pipelines
3. Implante serviços automaticamente

**Vantagens:**
- ✅ Pronto para produção imediatamente
- ✅ Colaboração em equipe via Azure
- ✅ Implantações automatizadas
- ✅ Monitoramento desde o primeiro dia

## 📁 Estrutura do Repositório

```
.
├── docs/                         # 📚 Documentação (você está aqui!)
├── infra/                        # 🏗️ Infrastructure as Code
│   ├── main.bicep                # Orquestração principal
│   ├── modules/                  # Módulos Bicep reutilizáveis
│   ├── k8s/                      # Manifestos Kubernetes
│   └── pipelines/                # Pipelines CI/CD
├── src/                          # 💻 Código da aplicação
│   ├── AKS/                      # Serviços Kubernetes
│   ├── AzureFunctions/           # Funções sem servidor
│   └── LogicApp/                 # Definições de fluxo
└── README.md                     # Ponto de entrada principal
```

## ⏭️ Próximos Passos

**Escolha seu caminho:**

- 🔧 **Quer executar localmente primeiro?** → Vá para [Configuração de Desenvolvimento Local](02-local-development.pt-BR.md)
- ☁️ **Pronto para implantar no Azure?** → Vá para [Configuração do Azure DevOps](03-devops-setup.pt-BR.md)
- 📖 **Quer entender a infraestrutura?** → Veja [Componentes de Infraestrutura](infrastructure-components.pt-BR.md)

---

**Navegação:** [🏠 Início](../../README.pt-BR.md) | **👉 Próximo:** [Configuração de Desenvolvimento Local](02-local-development.pt-BR.md)