# 02 - Configuração de Desenvolvimento Local

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [👈 Anterior](01-project-overview.pt-BR.md) | [👉 Próximo](03-devops-setup.pt-BR.md)

---

## 🎯 Objetivo

Configurar e executar todos os serviços **localmente em sua máquina** para desenvolvimento e testes.

## 🚦 Pré-requisitos

Instale estas ferramentas antes de prosseguir:

### Necessário para Todos os Serviços
- ✅ [Docker Desktop](https://www.docker.com/products/docker-desktop/) - Runtime de container
- ✅ [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) - Para serviços C#
- ✅ [Azure Functions Core Tools](https://learn.microsoft.com/pt-br/azure/azure-functions/functions-run-local) - Para Functions e Logic Apps

### Necessário para Serviços AKS
- ✅ [Minikube](https://minikube.sigs.k8s.io/docs/start/) - Cluster Kubernetes local
- ✅ [kubectl](https://kubernetes.io/docs/tasks/tools/) - CLI do Kubernetes
- ✅ Conta Docker Hub - Para hospedar imagens de container

### Necessário para Logic Apps
- ✅ [Node.js](https://nodejs.org/) - Dependência de runtime do Logic App

### Recomendado
- ✅ [Visual Studio Code](https://code.visualstudio.com/) - Editor de código
- ✅ [Postman](https://www.postman.com/) ou similar - Para testes de API

## 📋 Checklist de Início Rápido

Siga esta ordem para configurar todos os serviços:

### Passo 1: Inicie Dependências Compartilhadas

```powershell
# Inicie Azurite (emulador de armazenamento para Functions & Logic Apps)
docker run -d -p 10000:10000 -p 10001:10001 -p 10002:10002 `
  --name azurite mcr.microsoft.com/azure-storage/azurite

# Inicie Minikube (para serviços AKS)
minikube start
```

### Passo 2: Serviços AKS (Autenticação & Produtos)

📖 **Guia detalhado:** [Configuração Local de AKS](src-aks-readme.pt-BR.md)

**Passos rápidos:**
1. Construa imagens Docker para Autenticação e Produtos
2. Envie imagens para Docker Hub
3. Crie secrets do Kubernetes
4. Implante para Minikube
5. Use port-forward para acessar serviços

```powershell
# Exemplo: Acessar serviço de Produtos
kubectl port-forward service/products-api 8081:8081
# Então abra: http://localhost:8081/swagger
```

> **Nota:** Port-forwarding é necessário em todas as plataformas (Windows, Linux, macOS) ao usar Minikube com driver Docker.

### Passo 3: Azure Functions (Cliente & Fornecedor)

📖 **Guia detalhado:** [Configuração Local de Azure Functions](src-azurefunctions-readme.pt-BR.md)

**Passos rápidos:**
1. Certifique-se de que Azurite está em execução
2. Navegue até o diretório da função
3. Execute `func start`

```powershell
# Execute FunçãoCliente
cd src/AzureFunctions/OrdersFunction
func start
# Acesse em: http://localhost:7071/function/customer

# Execute FunçãoFornecedor (em outro terminal)
cd src/AzureFunctions/SupplierFunction
func start --port 7072
# Acesse em: http://localhost:7072/function/supplier
```

### Passo 4: Logic Apps (Pedidos e Carrinho)

📍 **Guia detalhado:** [Configuração Local de Logic Apps](src-logicapp-readme.pt-BR.md)

**Passos rápidos:**
1. Certifique-se de que Azurite está em execução
2. Navegue até o diretório do Logic App
3. Execute `func start`
4. Obtenha URLs de callback para testes

```powershell
cd src/LogicApp/OrdersLogicApp
func start

# Obtenha URL de callback
$response = Invoke-RestMethod `
  -Uri "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/GetAllOrders/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview" `
  -Method POST

Write-Host $response.value
# Use a URL retornada para testar
```

## 🧪 Testando Sua Configuração

Quando todos os serviços estiverem em execução, teste cada endpoint:

### Serviços AKS
```powershell
# Produtos - Obter todos
Invoke-RestMethod -Uri "http://localhost:8081/api/products" -Method GET

# Autenticação - Login (exemplo)
Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method POST `
  -Body '{"username":"test","password":"test"}' `
  -ContentType "application/json"
```

### Azure Functions
```powershell
# Cliente - Obter todos
Invoke-RestMethod -Uri "http://localhost:7071/function/customer" -Method GET

# Fornecedor - Obter por ID
Invoke-RestMethod -Uri "http://localhost:7072/function/supplier/1" -Method GET
```

### Logic App
```powershell
# Use a URL de callback obtida anteriormente
Invoke-RestMethod -Uri "<URL_CALLBACK_DO_PASSO_4>" -Method GET
```

## 🔧 Solução de Problemas

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| **Porta já em uso** | Altere a porta com `func start --port <outra-porta>` ou interrompa o processo conflitante |
| **Azurite não está em execução** | Verifique com `docker ps`, inicie se necessário |
| **Minikube não acessível** | Execute `minikube status`, reinicie se necessário |
| **Não é possível construir imagem Docker** | Certifique-se de que Docker Desktop está em execução |
| **Logic App: MissingApiVersionParameter** | Adicione `?api-version=2022-05-01` à URL |
| **Logic App: DirectApiAuthorizationRequired** | Use URL de callback completa com parâmetro `sig` |

### Solução de Problemas Específica do Serviço

- **AKS:** Veja [Solução de Problemas de AKS](src-aks-readme.pt-BR#solução-de-problemas)
- **Functions:** Veja [Solução de Problemas de Functions](src-azurefunctions-readme.pt-BR#solução-de-problemas)
- **Logic Apps:** Veja [Solução de Problemas de Logic Apps](src-logicapp-readme.pt-BR.md#solução-de-problemas)

## 🎓 Fluxo de Trabalho de Desenvolvimento

**Fluxo de trabalho recomendado para desenvolvimento local:**

1. **Inicie dependências** (Azurite, Minikube)
2. **Execute serviços** em que você está trabalhando
3. **Faça alterações de código**
4. **Reconstrua/reinicie** serviços afetados
5. **Teste** via Swagger UI ou Postman
6. **Confirme** quando satisfeito

### Dicas de Hot Reload

- **Serviços AKS:** Reconstrua imagem Docker e reimplante para Minikube
- **Functions:** `func start` suporta hot reload para alterações de código
- **Logic App:** Reinicie `func start` após alterações de fluxo

## 📊 Arquitetura de Desenvolvimento Local

Ao executar localmente, sua arquitetura fica assim:

```
Sua Máquina
├── Minikube (localhost:30080, :30081)
│   ├── Serviço de Autenticação
│   └── Serviço de Produtos
│
├── FunçãoCliente (localhost:7071)
├── FunçãoFornecedor (localhost:7072)
|├── LogicAppPedidos (localhost:7071)
|├── LogicAppCarrinho (localhost:7073)
│
└── Azurite (localhost:10000-10002)
    └── Emulação de armazenamento
```

## ⏭️ Próximos Passos

- ✅ **Todos os serviços em execução?** Ótimo! Tente fazer alterações de código e testar
- 🔄 **Quer iterar mais rápido?** Consulte READMEs específicos de serviço para dicas de desenvolvimento
- ☁️ **Pronto para o Azure?** Prossiga para [Configuração do Azure DevOps](03-devops-setup.pt-BR.md)

## 📚 Recursos Adicionais

- [Guia de Desenvolvimento Local de AKS](src-aks-readme.pt-BR.md)
- [Guia de Desenvolvimento Local de Azure Functions](src-azurefunctions-readme.pt-BR.md)
- [Guia de Desenvolvimento Local de Logic App](src-logicapp-readme.pt-BR.md)
- [Guia de Solução de Problemas](troubleshooting.pt-BR.md)

---

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [👈 Anterior](01-project-overview.pt-BR.md) | [👉 Próximo](03-devops-setup.pt-BR.md)