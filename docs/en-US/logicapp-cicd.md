# Logic Apps CI/CD Guide

**Navigation:** [🏠 Home](../../README.md) | [📚 Docs](../README.md)

---

## 🎯 Overview

This guide explains the CI/CD process for **Logic Apps Standard** in this POC. Logic Apps Standard uses the Azure Functions runtime, which allows us to manage workflows as code and deploy them via pipelines.

## 📊 Architecture

Logic Apps Standard differs from Logic Apps Consumption:

| Feature | Consumption (Classic) | Standard (This POC) |
|---------|----------------------|---------------------|
| **Deployment** | Portal/ARM only | Code-based (Git + CI/CD) |
| **Runtime** | Multi-tenant | Single-tenant (Functions host) |
| **Pricing** | Pay-per-execution | App Service Plan |
| **Local Development** | Limited | Full local development |
| **CI/CD** | Complex | Native support |

## 🚀 Pipeline Structure

### CI Pipeline (`logicapp_ci.yaml`)

**Purpose:** Validate and package Logic App workflows

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

**Steps:**
1. **Validate Structure** - Checks for required files (`host.json`, `connections.json`)
2. **Validate JSON** - Ensures all workflow JSONs are valid
3. **Install Dependencies** - Runs `npm install` if `package.json` exists
4. **Create Package** - Zips the Logic App folder
5. **Publish Artifact** - Uploads `logic-app-package.zip`

**Artifact:** `logic-app-package.zip`

### CD Pipeline (`logicapp_cd.yaml`)

**Purpose:** Deploy Logic App workflows to Azure

**Trigger:** Manual

**Steps:**
1. **Download Artifact** - Gets ZIP from CI pipeline
2. **Verify Logic App Exists** - Checks if infrastructure was deployed
3. **Deploy Package** - Uses `AzureFunctionApp@2` task (Logic Apps use Functions runtime)
4. **Get Callback URLs** - Retrieves HTTP trigger URLs for each workflow
5. **Display Summary** - Shows deployment results

## 📁 Logic App Structure

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

### Required Files

#### `host.json`
Runtime configuration for Logic Apps Standard:

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
Defines API connections used by workflows:

```json
{
  "managedApiConnections": {},
  "serviceProviderConnections": {}
}
```

#### `workflow.json`
Workflow definition (similar to ARM template format):

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

## 🔄 Deployment Flow

### Initial Deployment

```
1. infra_ci.yaml → Validates infrastructure (includes Logic App resource)
2. infra_cd.yaml → Creates Logic App Standard in Azure
3. logicapp_ci.yaml → Validates and packages workflows
4. logicapp_cd.yaml → Deploys workflows to Logic App
```

### Workflow-Only Updates

When only workflows change:

```
1. logicapp_ci.yaml → Packages workflows
2. logicapp_cd.yaml → Deploys to existing Logic App
```

## 🛠️ Local Development

### Prerequisites

- **Node.js** 18.x or later
- **Azure Functions Core Tools** v4
- **VS Code** with Azure Logic Apps extension

### Setup

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

### VS Code Development

1. Open `src/LogicApp/OrdersLogicApp` in VS Code
2. Install **Azure Logic Apps (Standard)** extension
3. Use designer to create/edit workflows visually
4. Workflows are saved as JSON in folders

## 📦 Adding New Workflows

### Option 1: Via VS Code Designer

1. Open Logic App folder in VS Code
2. Right-click in Explorer → **Create new workflow**
3. Name your workflow (e.g., `ProcessOrder`)
4. Use visual designer to build workflow
5. Save → JSON is generated automatically

### Option 2: Via JSON (Advanced)

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

## 🔑 Configuration & Secrets

### App Settings

Logic Apps can use App Settings like Azure Functions:

```bash
az webapp config appsettings set \
  --name comp-poc-test-logic-orders-dev \
  --resource-group comp-poc-test-rg-dev \
  --settings "CustomSetting=Value"
```

Access in workflows via `@appsetting('CustomSetting')`

### Connections

Managed API connections (e.g., to Blob Storage, SQL) are defined in `connections.json` and configured in Azure Portal after deployment.

## 🌐 Getting Callback URLs

After deployment, the CD pipeline automatically displays callback URLs. You can also get them manually:

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

## 🔗 APIM Integration

To expose Logic Apps via APIM:

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

## 🔍 Troubleshooting

### Problem: Workflow not found after deployment

**Cause:** Workflow folder structure is incorrect

**Solution:**
- Ensure each workflow is in its own folder
- Each folder must contain `workflow.json`
- Check CI pipeline logs for validation errors

### Problem: Callback URL returns 404

**Cause:** Trigger type is not HTTP or workflow is disabled

**Solution:**
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

### Problem: Deployment fails with "Logic App not found"

**Cause:** Infrastructure not deployed

**Solution:**
1. Run `infra_ci.yaml` pipeline
2. Run `infra_cd.yaml` pipeline
3. Verify Logic App exists in Azure Portal
4. Re-run `logicapp_cd.yaml`

### Problem: Local development - workflows not loading

**Cause:** Missing Azure Functions Core Tools or wrong version

**Solution:**
```bash
# Check version
func --version  # Should be 4.x

# Reinstall if needed
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

## 📊 Monitoring

### View Run History

```bash
# List workflow runs
az logicapp workflow run list \
  --name comp-poc-test-logic-orders-dev \
  --resource-group comp-poc-test-rg-dev \
  --workflow-name GetAllOrders
```

### Application Insights

Logic Apps automatically log to Application Insights (configured during infrastructure deployment):

```bash
# Query Logic App executions
az monitor app-insights query \
  --app comp-poc-test-appins-dev \
  --analytics-query "requests | where cloud_RoleName contains 'logic-orders' | take 10"
```

## 📚 Best Practices

✅ **Version Control Everything** - All workflows are in Git  
✅ **Test Locally First** - Use `func start` before deploying  
✅ **Use Environments** - Separate dev/qa/prod Logic Apps  
✅ **Parameterize Connections** - Use App Settings for connection strings  
✅ **Monitor Executions** - Set up alerts for failed runs  
✅ **Document Workflows** - Add descriptions in workflow JSON  

---

## 🔗 Related Documentation

- [Azure Logic Apps Standard Documentation](https://learn.microsoft.com/azure/logic-apps/single-tenant-overview-compare)
- [CI/CD Pipelines Guide](cicd-pipelines.md)
- [APIM Configuration](apim-configuration.md)

---

**Navigation:** [🏠 Home](../../README.md) | [📚 Docs](../README.md)
