# Logic Apps - Guia de Desenvolvimento Local

**Idiomas / Languages:** [🇺🇸 English](../en-US/src-logicapp-readme.md) | [🇧🇷 Português](src-logicapp-readme.pt-BR.md)

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [📚 Documentação](../README.md) | [⬅️ Voltar para Setup Local](02-local-development.pt-BR.md)

## Visão Geral

Este diretório contém workflows Logic Apps Standard para operações de e-commerce:

### OrdersLogicApp
Gerencia operações de pedidos com dois workflows:
- **GetAllOrders**: Recuperar todos os pedidos
- **GetOrderById**: Recuperar pedido específico por ID

### CartLogicApp
Gerencia operações de carrinho de compras com dois workflows:
- **AddItemToCart**: Adicionar itens ao carrinho de compras
- **GetCart**: Recuperar conteúdo do carrinho por ID do carrinho

## Endpoints Disponíveis

### Endpoints do OrdersLogicApp
- `GET /api/GetAllOrders/triggers/manual/invoke` - Listar todos os pedidos
- `POST /api/GetOrderById/triggers/manual/invoke` - Obter pedido por ID (requer body: `{"id": 1}`)

### Endpoints do CartLogicApp
- `POST /api/AddItemToCart/triggers/manual/invoke` - Adicionar item ao carrinho (requer body com detalhes do carrinho e produto)
- `POST /api/GetCart/triggers/manual/invoke` - Obter carrinho por ID (requer body: `{"cartId": "cart-123"}`)

## Pré-requisitos

- [Azure Functions Core Tools](https://learn.microsoft.com/pt-br/azure/azure-functions/functions-run-local)
- [Node.js](https://nodejs.org/) (requerido pelo runtime do Logic App)
- [Azurite](https://learn.microsoft.com/pt-br/azure/storage/common/storage-use-azurite)

## Executando Localmente

### 1. Iniciar Azurite

```bash
docker run -d -p 10000:10000 -p 10001:10001 -p 10002:10002 --name azurite mcr.microsoft.com/azure-storage/azurite
```

### 2. Iniciar Logic Apps

**OrdersLogicApp:**
```bash
cd src/LogicApp/OrdersLogicApp
func start
```

**CartLogicApp (em outro terminal):**
```bash
cd src/LogicApp/CartLogicApp
func start --port 7073
```

### 3. Obter URLs de Callback

**OrdersLogicApp:**
```powershell
# Para GetAllOrders
$response = Invoke-RestMethod -Uri "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/GetAllOrders/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview" -Method POST
Write-Host $response.value

# Para GetOrderById
$response = Invoke-RestMethod -Uri "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/GetOrderById/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview" -Method POST
Write-Host $response.value
```

**CartLogicApp:**
```powershell
# Para AddItemToCart
$response = Invoke-RestMethod -Uri "http://localhost:7073/runtime/webhooks/workflow/api/management/workflows/AddItemToCart/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview" -Method POST
Write-Host $response.value

# Para GetCart
$response = Invoke-RestMethod -Uri "http://localhost:7073/runtime/webhooks/workflow/api/management/workflows/GetCart/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview" -Method POST
Write-Host $response.value
```

### 4. Testar Endpoints

**OrdersLogicApp:**
```powershell
# GetAllOrders
Invoke-RestMethod -Uri "<URL_DO_PASSO_3>" -Method GET

# GetOrderById
Invoke-RestMethod -Uri "<URL_DO_PASSO_3>" -Method POST -Body '{"id": 1}' -ContentType "application/json"
```

**CartLogicApp:**
```powershell
# AddItemToCart
Invoke-RestMethod -Uri "<URL_DO_PASSO_3>" -Method POST `
  -Body '{"cartId":"cart-123","productId":1,"productName":"Laptop","quantity":1,"unitPrice":1299.99}' `
  -ContentType "application/json"

# GetCart
Invoke-RestMethod -Uri "<URL_DO_PASSO_3>" -Method POST `
  -Body '{"cartId":"cart-123"}' `
  -ContentType "application/json"
```

## Estrutura do Projeto

```
LogicApp/
├── OrdersLogicApp/
│   ├── host.json                # Configuração do Logic App
│   ├── local.settings.json      # Configurações locais
│   ├── connections.json         # Definições de conexão
│   ├── package.json             # Dependências Node
│   ├── workflow-designtime/     # Arquivos de runtime do designer (auto-gerado)
│   │   ├── host.json            # Configuração de host do design-time
│   │   └── local.settings.json  # Configurações do design-time
│   ├── GetAllOrders/
│   │   └── workflow.json        # Definição do workflow
│   └── GetOrderById/
│       └── workflow.json        # Definição do workflow
└── CartLogicApp/
    ├── host.json                # Configuração do Logic App
    ├── local.settings.json      # Configurações locais
    ├── connections.json         # Definições de conexão
    ├── package.json             # Dependências Node
    ├── workflow-designtime/     # Arquivos de runtime do designer (auto-gerado)
    │   ├── host.json            # Configuração de host do design-time
    │   └── local.settings.json  # Configurações do design-time
    ├── AddItemToCart/
    │   └── workflow.json        # Definição do workflow
    └── GetCart/
        └── workflow.json        # Definição do workflow
```
└── GetOrderById/
    └── workflow.json            # Definição do workflow
```

### Pasta `workflow-designtime`

Esta pasta é **criada automaticamente** pela extensão do VS Code quando você abre o designer pela primeira vez. Ela contém:

- **Propósito**: Fornece configuração de runtime para o designer visual
- **host.json**: Inclui `Runtime.WorkflowOperationDiscoveryHostMode: true` para operação do designer
- **local.settings.json**: Contém caminho do diretório do projeto e configurações da workflow app
- **Quando criada**: Na primeira vez que você abre um workflow no designer
- **Git**: Deve ser excluída do controle de versão (adicione ao `.gitignore`)

**Nota**: Esta pasta é usada apenas pelo designer. Não afeta a execução em runtime ou o deployment.

## Exemplos de Resposta

### OrdersLogicApp

#### Resposta GetAllOrders
```json
{
  "success": true,
  "message": "Orders retrieved successfully",
  "data": [
    {
      "orderId": 1,
      "customerName": "John Doe",
      "totalAmount": 299.99,
      "orderDate": "2024-01-10T10:00:00Z",
      "status": "Completed"
    }
  ]
}
```

#### Requisição e Resposta GetOrderById

**Body da Requisição:**
```json
{
  "id": 1
}
```

**Resposta:**
```json
{
  "success": true,
  "message": "Order retrieved successfully",
  "data": {
    "orderId": 1,
    "customerName": "John Doe",
    "totalAmount": 299.99,
    "orderDate": "2024-01-10T10:00:00Z",
    "status": "Completed"
  }
}
```

### CartLogicApp

#### Requisição e Resposta AddItemToCart

**Body da Requisição:**
```json
{
  "cartId": "cart-123",
  "productId": 1,
  "productName": "Laptop",
  "quantity": 1,
  "unitPrice": 1299.99
}
```

**Resposta (HTTP 201):**
```json
{
  "success": true,
  "message": "Item added to cart successfully",
  "data": {
    "cartId": "cart-123",
    "item": {
      "productId": 1,
      "productName": "Laptop",
      "quantity": 1,
      "unitPrice": 1299.99,
      "totalPrice": 1299.99
    },
    "addedAt": "2024-11-22T18:59:45Z"
  }
}
```

#### Requisição e Resposta GetCart

**Body da Requisição:**
```json
{
  "cartId": "cart-123"
}
```

**Resposta:**
```json
{
  "success": true,
  "message": "Cart retrieved successfully",
  "data": {
    "cartId": "cart-123",
    "items": [
      {
        "productId": 1,
        "productName": "Laptop",
        "quantity": 1,
        "unitPrice": 1299.99,
        "totalPrice": 1299.99
      },
      {
        "productId": 2,
        "productName": "Wireless Mouse",
        "quantity": 2,
        "unitPrice": 29.99,
        "totalPrice": 59.98
      }
    ],
    "itemCount": 2,
    "totalAmount": 1359.97,
    "currency": "USD",
    "lastUpdated": "2024-11-22T18:59:45Z"
  }
}
```

## Trabalhando com o Designer Visual

### Pré-requisitos

1. **Conta Azure**: Assinatura Azure ativa
2. **Extensões do VS Code**:
   - Azure Account (`ms-vscode.azure-account`)
   - Azure Logic Apps (Standard) (`ms-azuretools.vscode-azurelogicapps`)
3. **Azure Functions Core Tools**: Instalado automaticamente pela extensão

### Abrindo o Designer

**Passo 1: Fazer login no Azure**

```powershell
# Abra o Command Palette do VS Code (Ctrl+Shift+P)
# Digite: Azure: Sign In
# Siga a autenticação no navegador
```

**Passo 2: Abrir o Projeto Corretamente**

⚠️ **IMPORTANTE**: Abra a pasta do Logic App como raiz do workspace:

```powershell
# A partir da raiz do projeto
code src/LogicApp/OrdersLogicApp

# OU use o arquivo de workspace
code azure-poc.code-workspace
```

**Passo 3: Abrir o Designer**

1. Navegue até `GetAllOrders/workflow.json` ou `GetOrderById/workflow.json`
2. Clique com botão direito → **"Open in Designer"**
3. Aguarde a mensagem "starting the workflow design-time API"
4. Selecione **"Use connectors from Azure"** → Escolha a subscription

### Limitações do Designer

| Tarefa | Requer Conexão Azure? |
|--------|------------------------|
| Abrir Designer | ✅ Sim |
| Adicionar Triggers/Actions (visual) | ✅ Sim |
| Editar JSON diretamente | ❌ Não |
| Executar localmente (`func start`) | ❌ Não (usa Azurite) |
| Depurar workflows | ❌ Não |
| Deploy para Azure | ✅ Sim |

**Por que a conexão Azure é necessária:**
- O designer carrega metadados dos conectores do Azure
- Lista triggers e actions disponíveis
- Valida schemas e configurações de conexão

### Desenvolvimento Offline

Se você precisa trabalhar offline:

1. **Edite o JSON diretamente**: Modifique os arquivos `workflow.json` manualmente
2. **Use referência de schema**: [Workflow Definition Language](https://learn.microsoft.com/pt-br/azure/logic-apps/logic-apps-workflow-actions-triggers)
3. **Teste localmente**: Execute com `func start` (não precisa de conexão Azure)

**Exemplo de estrutura workflow.json:**
```json
{
  "definition": {
    "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
    "triggers": {
      "manual": {
        "type": "Request",
        "kind": "Http"
      }
    },
    "actions": {
      "Response": {
        "type": "Response",
        "inputs": {
          "statusCode": 200,
          "body": { "message": "Sucesso" }
        }
      }
    }
  },
  "kind": "Stateful"
}
```

## Notas Importantes

- **Parâmetro de assinatura (`sig`)**: Muda em restart/deployment. Use Managed Identity ou Key Vault em produção.
- **Versão da API**: Sempre obrigatória (`?api-version=2022-05-01`)
- **Autenticação**: URLs de callback incluem tokens de segurança para desenvolvimento local
- **Alocação de portas**: OrdersLogicApp usa 7071 (padrão), CartLogicApp usa 7073
- **Validação do carrinho**: CartLogicApp valida quantidade mínima de 1 via schema JSON
- **Cálculo de preço**: CartLogicApp calcula automaticamente preço total: `quantity × unitPrice`

## Solução de Problemas

### Erro: "Error in determining project root" no Designer

**Sintomas:**
```
Error in determining project root. Please confirm project structure is correct.
Source: Azure Logic Apps (Standard)
```

**Causas:**
1. VS Code não aberto na pasta correta
2. Não conectado ao Azure
3. Arquivos necessários ausentes

**Soluções:**

1. **Abrir a pasta correta como raiz do workspace:**
   ```powershell
   # Feche o VS Code, depois abra APENAS a pasta do Logic App
   code src/LogicApp/OrdersLogicApp
   ```

2. **Fazer login no Azure:**
   - Verifique o canto inferior esquerdo do VS Code para ver a conta Azure
   - `Ctrl+Shift+P` → "Azure: Sign In"

3. **Verificar se os arquivos necessários existem:**
   ```
   OrdersLogicApp/
   ├── host.json              ✅
   ├── local.settings.json    ✅
   ├── connections.json       ✅
   └── package.json           ✅
   ```

### Erro: "MissingApiVersionParameter"
- Certifique-se de incluir `?api-version=2022-05-01` na URL

### Erro: "DirectApiAuthorizationRequired"
- Use a URL completa obtida via endpoint de `listCallbackUrl`
- A URL inclui o parâmetro `sig` (assinatura) necessário

### Erro: "No job functions found"
- Verifique se `host.json` e `local.settings.json` estão na raiz da pasta OrdersLogicApp
- Confirme que o `extensionBundle` está correto em `host.json`:
  ```json
  {
    "id": "Microsoft.Azure.Functions.ExtensionBundle.Workflows",
    "version": "[1.*, 2.0.0)"
  }
  ```

### Erro: Required property 'content' expects a value but got null
- Verifique se o método do trigger está correto (POST para workflows que esperam body)
- Confirme que o body JSON está sendo enviado corretamente

## CI/CD

- Deploy para Azure Logic Apps (Standard)
- Use APIM com Managed Identity para acesso seguro
- Armazene URLs de callback no Key Vault ou como Named Values do APIM
- Use arquivos de infraestrutura (Bicep/Terraform) na pasta `infra/`

## Segurança em Produção

### ❌ NÃO faça:
- Hardcode da assinatura (`sig`) em código ou configuração

### ✅ Faça:
- Use **Managed Identity** entre APIM e Logic App (mais seguro)
- Use **Key Vault** para secrets dinâmicos
- Use **Named Values** no APIM (facilita atualização)
- Chame endpoint de management para obter URLs dinamicamente

## Próximos Passos

1. Implementar conectores para serviços externos (SQL, Cosmos DB, Service Bus)
2. Adicionar tratamento de erros e retry policies
3. Configurar monitoring e alertas via Application Insights
4. Implementar versionamento de workflows
