# Guia de CI/CD de Logic Apps

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [📚 Docs](../README.pt-BR.md)

---

## 🎯 Visão Geral

Este guia explica o processo de CI/CD para **Logic Apps Standard** nesta POC. O Logic Apps Standard usa o runtime do Azure Functions, o que nos permite gerenciar workflows como código e implantá-los via pipelines.

## 📊 Arquitetura

O Logic Apps Standard difere do Logic Apps Consumption:

| Característica | Consumption (Clássico) | Standard (Esta POC) |
|---------|----------------------|---------------------|
| **Deployment** | Portal/ARM apenas | Baseado em código (Git + CI/CD) |
| **Runtime** | Multi-tenant | Single-tenant (Functions host) |
| **Preço** | Por execução | App Service Plan |
| **Desenvolvimento Local** | Limitado | Desenvolvimento local completo |
| **CI/CD** | Complexo | Suporte nativo |

## 🚀 Estrutura das Pipelines

### Pipeline CI (`logicapp_ci.yaml`)

**Propósito:** Validar e empacotar workflows do Logic App

**Triggers:**
```yaml
trigger:
  branches:
    include:
      - master
      - development
  paths:
    include:
      - src/LogicApp/**
```

**Etapas:**
1. **Validar Estrutura** - Verifica arquivos obrigatórios (`host.json`, `connections.json`)
2. **Validar JSON** - Garante que todos os JSONs de workflow são válidos
3. **Instalar Dependências** - Executa `npm install` se `package.json` existir
4. **Criar Pacote** - Compacta a pasta do Logic App em ZIP
5. **Publicar Artefato** - Faz upload de `logic-app-package.zip`

**Artefato:** `logic-app-package.zip`

### Pipeline CD (`logicapp_cd.yaml`)

**Propósito:** Implantar workflows do Logic App no Azure

**Trigger:** Manual

**Etapas:**
1. **Baixar Artefato** - Obtém ZIP da pipeline CI
2. **Verificar Logic App Existe** - Verifica se a infraestrutura foi implantada
3. **Implantar Pacote** - Usa task `AzureFunctionApp@2` (Logic Apps usam runtime Functions)
4. **Obter Callback URLs** - Recupera URLs de trigger HTTP de cada workflow
5. **Exibir Resumo** - Mostra resultados do deployment

## 📁 Estrutura do Logic App

```
src/LogicApp/OrdersLogicApp/
├── host.json                   # Runtime configuration
├── connections.json            # API connections (Storage, etc.)
├── local.settings.json        # Local development settings
├── package.json               # NPM dependencies (optional)
├── GetAllOrders/
│   └── workflow.json          # Workflow definition
└── GetOrderById/
    └── workflow.json          # Workflow definition
```

### Arquivos Obrigatórios

#### `host.json`
Configuração de runtime para Logic Apps Standard:

```json
{
  "version": "2.0",
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle.Workflows",
    "version": "[1.*, 2.0.0)"
  }
}
```

#### `connections.json`
Define conexões de API usadas pelos workflows:

```json
{
  "managedApiConnections": {},
  "serviceProviderConnections": {}
}
```

#### `workflow.json`
Definição de workflow (similar ao formato ARM template):

```json
{
  "definition": {
    "$schema": "https://schema.management.azure.com/...",
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
          "body": {"message": "Success"}
        }
      }
    }
  }
}
```

## 🔄 Fluxo de Deployment

### Deployment Inicial

```
1. infra_ci.yaml → Validates infrastructure (includes Logic App resource)
2. infra_cd.yaml → Creates Logic App Standard in Azure
3. logicapp_ci.yaml → Validates and packages workflows
4. logicapp_cd.yaml → Deploys workflows to Logic App
```

### Atualizações Apenas de Workflows

Quando apenas workflows mudam:

```
1. logicapp_ci.yaml → Packages workflows
2. logicapp_cd.yaml → Deploys to existing Logic App
```

## 🛠️ Desenvolvimento Local

### Pré-requisitos

- **Node.js** 18.x or later
- **Azure Functions Core Tools** v4
- **VS Code** with Azure Logic Apps extension

### Configuração

1. **Install Azure Functions Core Tools:**
   ```bash
   npm install -g azure-functions-core-tools@4
   ```

2. **Navigate to Logic App folder:**
   ```bash
   cd src/LogicApp/OrdersLogicApp
   ```

3. **Start locally:**
   ```bash
   func start
   ```

4. **Test workflows:**
   ```bash
   curl -X POST http://localhost:7071/api/GetAllOrders/triggers/manual/invoke
   ```

### Desenvolvimento no VS Code

1. Open `src/LogicApp/OrdersLogicApp` in VS Code
2. Install **Azure Logic Apps (Standard)** extension
3. Use designer to create/edit workflows visually
4. Workflows are saved as JSON in folders

## 📦 Adicionando Novos Workflows

### Opção 1: Via Designer do VS Code

1. Open Logic App folder in VS Code
2. Right-click in Explorer → **Create new workflow**
3. Name your workflow (e.g., `ProcessOrder`)
4. Use visual designer to build workflow
5. Save → JSON is generated automatically

### Opção 2: Via JSON (Avançado)

1. Create new folder: `src/LogicApp/OrdersLogicApp/ProcessOrder/`
2. Create `workflow.json`:
   ```json
   {
     "definition": {
       "$schema": "https://schema.management.azure.com/...",
       "triggers": {
         "manual": {
           "type": "Request",
           "kind": "Http"
         }
       },
       "actions": {}
     }
   }
   ```
3. Commit and push → CI/CD will pick it up automatically

## 🔑 Configuração & Secrets

### App Settings

Logic Apps can use App Settings like Azure Functions:

```bash
az webapp config appsettings set \
  --name comp-poc-test-logic-orders-dev \
  --resource-group comp-poc-test-rg-dev \
  --settings "CustomSetting=Value"
```

Access in workflows via `@appsetting('CustomSetting')`

### Conexões

Conexões de API gerenciadas (ex: Blob Storage, SQL) são definidas em `connections.json` e configuradas no Portal do Azure após o deployment.

## 🌐 Obtendo Callback URLs

Após o deployment, a pipeline CD exibe automaticamente as callback URLs. Você também pode obtê-las manualmente:

```bash
# List workflows
az logicapp workflow list \
  --name comp-poc-test-logic-orders-dev \
  --resource-group comp-poc-test-rg-dev

# Get callback URL
az rest --method post \
  --uri "/subscriptions/{subscription-id}/resourceGroups/comp-poc-test-rg-dev/providers/Microsoft.Web/sites/comp-poc-test-logic-orders-dev/hostruntime/runtime/webhooks/workflow/api/management/workflows/GetAllOrders/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview"
```

**Example URL:**
```
https://comp-poc-test-logic-orders-dev.azurewebsites.net:443/api/GetAllOrders/triggers/manual/invoke?api-version=2020-05-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=...
```

## 🔗 Integração com APIM

Para expor Logic Apps via APIM:

1. Get workflow callback URL (from CD pipeline output)
2. Update `main.bicep` with Logic App URL:
   ```bicep
   module apim './modules/apim.bicep' = {
     params: {
       logicAppUrl: 'https://comp-poc-test-logic-orders-dev.azurewebsites.net'
       // ... other params
     }
   }
   ```
3. Re-deploy infrastructure
4. Access via APIM: `https://<apim-gateway>/orders/v1/process`

## 🔍 Solução de Problemas

### Problema: Workflow não encontrado após deployment

**Causa:** Estrutura de pastas do workflow está incorreta

**Solução:**
- Ensure each workflow is in its own folder
- Each folder must contain `workflow.json`
- Check CI pipeline logs for validation errors

### Problema: Callback URL retorna 404

**Causa:** Tipo de trigger não é HTTP ou workflow está desabilitado

**Solução:**
```bash
# Check workflow status
az logicapp workflow show \
  --name comp-poc-test-logic-orders-dev \
  --resource-group comp-poc-test-rg-dev \
  --workflow-name GetAllOrders \
  --query "state"

# Enable workflow if disabled
az logicapp workflow update \
  --name comp-poc-test-logic-orders-dev \
  --resource-group comp-poc-test-rg-dev \
  --workflow-name GetAllOrders \
  --state "Enabled"
```

### Problema: Deployment falha com "Logic App not found"

**Causa:** Infraestrutura não foi implantada

**Solução:**
1. Run `infra_ci.yaml` pipeline
2. Run `infra_cd.yaml` pipeline
3. Verify Logic App exists in Azure Portal
4. Re-run `logicapp_cd.yaml`

### Problema: Desenvolvimento local - workflows não carregam

**Causa:** Azure Functions Core Tools ausente ou versão incorreta

**Solução:**
```bash
# Check version
func --version  # Should be 4.x

# Reinstall if needed
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

## 📊 Monitoramento

### Visualizar Histórico de Execuções

```bash
# List workflow runs
az logicapp workflow run list \
  --name comp-poc-test-logic-orders-dev \
  --resource-group comp-poc-test-rg-dev \
  --workflow-name GetAllOrders
```

### Application Insights

Logic Apps registram automaticamente no Application Insights (configurado durante o deployment de infraestrutura):

```bash
# Query Logic App executions
az monitor app-insights query \
  --app comp-poc-test-appins-dev \
  --analytics-query "requests | where cloud_RoleName contains 'logic-orders' | take 10"
```

## 📚 Melhores Práticas

✅ **Controle de Versão de Tudo** - Todos workflows estão no Git  
✅ **Teste Localmente Primeiro** - Use `func start` antes de implantar  
✅ **Use Ambientes** - Separe Logic Apps dev/qa/prod  
✅ **Parametrize Conexões** - Use App Settings para connection strings  
✅ **Monitore Execuções** - Configure alertas para execuções falhadas  
✅ **Documente Workflows** - Adicione descrições nos JSON de workflow

---

## 🔗 Documentação Relacionada

- [Documentação do Azure Logic Apps Standard](https://learn.microsoft.com/azure/logic-apps/single-tenant-overview-compare)
- [Guia de Pipelines CI/CD](cicd-pipelines.pt-BR.md)
- [Configuração do APIM](apim-configuration.pt-BR.md)

---

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [📚 Docs](../README.pt-BR.md)
