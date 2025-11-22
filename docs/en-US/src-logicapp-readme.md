# Logic Apps - Local Development Guide

**Languages / Idiomas:** [🇺🇸 English](/docs/src-logicapp-readme.md) | [🇧🇷 Português](/docs/src-logicapp-readme.pt-BR.md)

**Navigation:** [🏠 Home](/README.md) | [📚 Docs](/docs/README.md) | [⬅️ Back to Local Setup](/docs/02-local-development.md)

## Overview

This directory contains Logic Apps Standard workflows for e-commerce operations:

### OrdersLogicApp
Manages order operations with two workflows:
- **GetAllOrders**: Retrieve all orders
- **GetOrderById**: Retrieve specific order by ID

### CartLogicApp
Manages shopping cart operations with two workflows:
- **AddItemToCart**: Add items to shopping cart
- **GetCart**: Retrieve cart contents by cart ID

## Available Endpoints

### OrdersLogicApp Endpoints
- `GET /api/GetAllOrders/triggers/manual/invoke` - List all orders
- `POST /api/GetOrderById/triggers/manual/invoke` - Get order by ID (requires body: `{"id": 1}`)

### CartLogicApp Endpoints
- `POST /api/AddItemToCart/triggers/manual/invoke` - Add item to cart (requires body with cart and product details)
- `POST /api/GetCart/triggers/manual/invoke` - Get cart by ID (requires body: `{"cartId": "cart-123"}`)

## Prerequisites

- [Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [Node.js](https://nodejs.org/) (required by Logic App runtime)
- [Azurite](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite)

## Running Locally

### 1. Start Azurite

```bash
docker run -d -p 10000:10000 -p 10001:10001 -p 10002:10002 --name azurite mcr.microsoft.com/azure-storage/azurite
```

### 2. Start Logic Apps

**OrdersLogicApp:**
```bash
cd src/LogicApp/OrdersLogicApp
func start
```

**CartLogicApp (in another terminal):**
```bash
cd src/LogicApp/CartLogicApp
func start --port 7073
```

### 3. Get Callback URLs

**OrdersLogicApp:**
```powershell
# For GetAllOrders
$response = Invoke-RestMethod -Uri "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/GetAllOrders/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview" -Method POST
Write-Host $response.value

# For GetOrderById
$response = Invoke-RestMethod -Uri "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/GetOrderById/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview" -Method POST
Write-Host $response.value
```

**CartLogicApp:**
```powershell
# For AddItemToCart
$response = Invoke-RestMethod -Uri "http://localhost:7073/runtime/webhooks/workflow/api/management/workflows/AddItemToCart/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview" -Method POST
Write-Host $response.value

# For GetCart
$response = Invoke-RestMethod -Uri "http://localhost:7073/runtime/webhooks/workflow/api/management/workflows/GetCart/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview" -Method POST
Write-Host $response.value
```

### 4. Test Endpoints

**OrdersLogicApp:**
```powershell
# GetAllOrders
Invoke-RestMethod -Uri "<URL_FROM_STEP_3>" -Method GET

# GetOrderById
Invoke-RestMethod -Uri "<URL_FROM_STEP_3>" -Method POST -Body '{"id": 1}' -ContentType "application/json"
```

**CartLogicApp:**
```powershell
# AddItemToCart
Invoke-RestMethod -Uri "<URL_FROM_STEP_3>" -Method POST `
  -Body '{"cartId":"cart-123","productId":1,"productName":"Laptop","quantity":1,"unitPrice":1299.99}' `
  -ContentType "application/json"

# GetCart
Invoke-RestMethod -Uri "<URL_FROM_STEP_3>" -Method POST `
  -Body '{"cartId":"cart-123"}' `
  -ContentType "application/json"
```

## Project Structure

```
LogicApp/
├── OrdersLogicApp/
│   ├── host.json                # Logic App configuration
│   ├── local.settings.json      # Local settings
│   ├── connections.json         # Connection definitions
│   ├── package.json             # Node dependencies
│   ├── workflow-designtime/     # Designer runtime files (auto-generated)
│   │   ├── host.json            # Design-time host configuration
│   │   └── local.settings.json  # Design-time settings
│   ├── GetAllOrders/
│   │   └── workflow.json        # Workflow definition
│   └── GetOrderById/
│       └── workflow.json        # Workflow definition
└── CartLogicApp/
    ├── host.json                # Logic App configuration
    ├── local.settings.json      # Local settings
    ├── connections.json         # Connection definitions
    ├── package.json             # Node dependencies
    ├── workflow-designtime/     # Designer runtime files (auto-generated)
    │   ├── host.json            # Design-time host configuration
    │   └── local.settings.json  # Design-time settings
    ├── AddItemToCart/
    │   └── workflow.json        # Workflow definition
    └── GetCart/
        └── workflow.json        # Workflow definition
```

### `workflow-designtime` Folder

This folder is **automatically created** by the VS Code extension when you first open the designer. It contains:

- **Purpose**: Provides runtime configuration for the visual designer
- **host.json**: Includes `Runtime.WorkflowOperationDiscoveryHostMode: true` for designer operation
- **local.settings.json**: Contains project directory path and workflow app settings
- **When created**: First time you open a workflow in the designer
- **Git**: Should be excluded from version control (add to `.gitignore`)

**Note**: This folder is only used by the designer. It does not affect runtime execution or deployment.

## Working with the Visual Designer

### Prerequisites

1. **Azure Account**: Active Azure subscription
2. **VS Code Extensions**:
   - Azure Account (`ms-vscode.azure-account`)
   - Azure Logic Apps (Standard) (`ms-azuretools.vscode-azurelogicapps`)
3. **Azure Functions Core Tools**: Auto-installed by the extension

### Opening the Designer

**Step 1: Sign in to Azure**

```powershell
# Open VS Code Command Palette (Ctrl+Shift+P)
# Type: Azure: Sign In
# Follow browser authentication
```

**Step 2: Open Project Correctly**

⚠️ **IMPORTANT**: Open the Logic App folder as workspace root:

```powershell
# From project root - for OrdersLogicApp
code src/LogicApp/OrdersLogicApp

# From project root - for CartLogicApp
code src/LogicApp/CartLogicApp

# OR use the workspace file (recommended for multiple Logic Apps)
code azure-poc.code-workspace
```

**Step 3: Open Designer**

1. Navigate to any `workflow.json` file (e.g., `GetAllOrders/workflow.json`, `AddItemToCart/workflow.json`)
2. Right-click → **"Open in Designer"**
3. Wait for "starting the workflow design-time API" message
4. Select **"Use connectors from Azure"** → Choose subscription

### Designer Limitations

| Task | Requires Azure Connection? |
|------|---------------------------|
| Open Designer | ✅ Yes |
| Add Triggers/Actions (visual) | ✅ Yes |
| Edit JSON directly | ❌ No |
| Run locally (`func start`) | ❌ No (uses Azurite) |
| Debug workflows | ❌ No |
| Deploy to Azure | ✅ Yes |

**Why Azure connection is required:**
- Designer loads connector metadata from Azure
- Lists available triggers and actions
- Validates schemas and connection settings

### Offline Development

If you need to work offline:

1. **Edit JSON directly**: Modify `workflow.json` files manually
2. **Use schema reference**: [Workflow Definition Language](https://learn.microsoft.com/azure/logic-apps/logic-apps-workflow-actions-triggers)
3. **Test locally**: Run with `func start` (no Azure connection needed)

**Example workflow.json structure:**
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
          "body": { "message": "Success" }
        }
      }
    }
  },
  "kind": "Stateful"
}
```

## Important Notes

- **Signature (`sig`) parameter**: Changes on restart/deployment. Use Managed Identity or Key Vault in production.
- **API version**: Always required (`?api-version=2022-05-01`)
- **Authentication**: Callback URLs include security tokens for local development
- **Port allocation**: OrdersLogicApp uses 7071 (default), CartLogicApp uses 7073
- **Cart validation**: CartLogicApp enforces minimum quantity of 1 via JSON schema
- **Price calculation**: CartLogicApp automatically calculates total price: `quantity × unitPrice`

## Response Examples

### OrdersLogicApp

#### GetAllOrders Response
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

#### GetOrderById Request & Response

**Request Body:**
```json
{
  "id": 1
}
```

**Response:**
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

#### AddItemToCart Request & Response

**Request Body:**
```json
{
  "cartId": "cart-123",
  "productId": 1,
  "productName": "Laptop",
  "quantity": 1,
  "unitPrice": 1299.99
}
```

**Response (HTTP 201):**
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

#### GetCart Request & Response

**Request Body:**
```json
{
  "cartId": "cart-123"
}
```

**Response:**
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

## Troubleshooting

### Problem: Logic App won't start - Node.js not found

**Symptoms:**
```
Error: Cannot find module 'node'
```

**Solution:**
```bash
# Install Node.js (required for Logic Apps runtime)
# Download from https://nodejs.org/

# Verify installation
node --version
# Should show v18.x or v20.x
```

### Problem: "MissingApiVersionParameter" error

**Symptoms:**
```
Status code: 400
{"error":{"code":"MissingApiVersionParameter",...}}
```

**Solution:**

Add `api-version` parameter to callback URL request:
```bash
curl -X POST "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/GetAllOrders/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview"
```

### Problem: Designer error "Error in determining project root"

**Symptoms:**
```
Error in determining project root. Please confirm project structure is correct.
Source: Azure Logic Apps (Standard)
```

**Causes:**
1. VS Code not opened in correct folder
2. Not signed in to Azure
3. Missing required files

**Solutions:**

1. **Open correct folder as workspace root:**
   ```powershell
   # Close VS Code, then open ONLY the Logic App folder
   code src/LogicApp/OrdersLogicApp
   # OR for CartLogicApp
   code src/LogicApp/CartLogicApp
   ```

2. **Sign in to Azure:**
   - Check bottom-left corner of VS Code for Azure account
   - `Ctrl+Shift+P` → "Azure: Sign In"

3. **Verify required files exist:**
   ```
   OrdersLogicApp/
   ├── host.json              ✅
   ├── local.settings.json    ✅
   ├── connections.json       ✅
   └── package.json           ✅
   ```

### Problem: Workflows not detected after start

**Symptoms:**
- `func start` succeeds but no workflows listed

**Solution:**

Verify folder structure:
```
OrdersLogicApp/
├── host.json
├── local.settings.json
├── connections.json
├── package.json
├── GetAllOrders/
│   └── workflow.json
└── GetOrderById/
    └── workflow.json
```

Each workflow must be in its own subdirectory with `workflow.json`.

### Problem: Callback URL returns 401 Unauthorized

**Symptoms:**
```bash
curl <CALLBACK_URL>
# Returns: 401 Unauthorized
```

**Solutions:**

1. **Include `sig` parameter:**
   - Callback URL must include signature (`sig`) parameter
   - Signature changes on restart/redeployment
   - Always get fresh callback URL after changes

2. **Get new callback URL:**
   ```bash
   # Local
   Invoke-RestMethod -Uri "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/<WORKFLOW_NAME>/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview" -Method POST
   
   # Azure
   az rest --method POST \
     --uri "https://management.azure.com/subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.Web/sites/<LOGIC_APP_NAME>/hostruntime/runtime/webhooks/workflow/api/management/workflows/<WORKFLOW_NAME>/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview"
   ```

### Problem: Workflow expects POST but conceptually it's a GET

**Explanation:**

Logic Apps with HTTP trigger that require **request body** must use POST method, even if conceptually it's a "read" operation (like GetOrderById).

**Solution:**

Use POST with JSON body:
```bash
curl -X POST "<CALLBACK_URL>" \
  -H "Content-Type: application/json" \
  -d '{"id": 123}'
```

### Problem: Workflows not visible after deployment to Azure

**Symptoms:**
- Deployment succeeds
- No workflows listed in Azure Portal

**Solutions:**

1. **Verify zip structure:**
   ```
   logicapp.zip
   ├── host.json
   ├── connections.json
   ├── GetAllOrders/
   │   └── workflow.json
   └── GetOrderById/
       └── workflow.json
   ```
   
   **Note:** Exclude `local.settings.json` from production deployment

2. **Re-deploy with correct structure:**
   ```bash
   cd src/LogicApp/OrdersLogicApp
   zip -r logicapp.zip . -x "local.settings.json"
   az logicapp deployment source config-zip \
     --name <LOGIC_APP_NAME> \
     --resource-group <RESOURCE_GROUP> \
     --src logicapp.zip
   ```

### Problem: Port 7071 already in use

**Solution:**

Change port when starting:
```bash
func start --port 7073
```

Or find and kill the process:
```powershell
# Windows
netstat -ano | findstr :7071
taskkill /PID <PID> /F

# Linux/macOS
lsof -ti:7071 | xargs kill -9
```

### Problem: Azurite connection error

**Symptoms:**
```
Error: connect ECONNREFUSED 127.0.0.1:10000
```

**Solution:**

Ensure Azurite is running:
```bash
# Check if running
docker ps | grep azurite

# Start Azurite
docker start azurite

# Or run new container
docker run -d -p 10000:10000 -p 10001:10001 -p 10002:10002 \
  --name azurite mcr.microsoft.com/azure-storage/azurite
```

For more troubleshooting, see the [comprehensive troubleshooting guide](/docs/en-US/troubleshooting.md).

## CI/CD

- Deploy to Azure Logic Apps (Standard)
- Use APIM with Managed Identity for secure access
- Store callback URLs in Key Vault or as APIM Named Values
- Use infrastructure files (Bicep/Terraform) in `infra/` folder
