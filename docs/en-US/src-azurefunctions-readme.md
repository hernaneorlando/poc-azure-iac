# Azure Functions - Local Development Guide

**Languages / Idiomas:** [🇺🇸 English](/docs/src-azurefunctions-readme.md) | [🇧🇷 Português](/docs/src-azurefunctions-readme.pt-BR.md)

**Navigation:** [🏠 Home](README.md) | [📚 Docs](/docs/README.md) | [⬅️ Back to Local Setup](/docs/02-local-development.md)

## Overview

This directory contains Azure Functions for serverless operations:
- **CustomerFunction**: Customer management (GET all, GET by ID, POST)
- **SupplierFunction**: Supplier management (GET all, GET by ID, POST)

## Available Endpoints

### CustomerFunction
- `GET /function/customer` - List all customers
- `GET /function/customer/{id}` - Get customer by ID
- `POST /function/customer` - Create new customer

### SupplierFunction
- `GET /function/supplier` - List all suppliers
- `GET /function/supplier/{id}` - Get supplier by ID
- `POST /function/supplier` - Create new supplier

## Prerequisites

- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [Azurite](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite) (for local storage emulation)

## Running Locally

### 1. Start Azurite

```bash
# Using Docker
docker run -d -p 10000:10000 -p 10001:10001 -p 10002:10002 --name azurite mcr.microsoft.com/azure-storage/azurite

# Or install globally with npm
npm install -g azurite
azurite
```

### 2. Run CustomerFunction

```bash
cd src/AzureFunctions/OrdersFunction
func start
```

Access at: `http://localhost:7071/function/customer`

### 3. Run SupplierFunction

```bash
cd src/AzureFunctions/SupplierFunction
func start --port 7072
```

Access at: `http://localhost:7072/function/supplier`

## Testing

```powershell
# Get all customers
Invoke-RestMethod -Uri "http://localhost:7071/function/customer" -Method GET

# Get customer by ID
Invoke-RestMethod -Uri "http://localhost:7071/function/customer/1" -Method GET

# Create customer
Invoke-RestMethod -Uri "http://localhost:7071/function/customer" -Method POST `
  -Body '{"customerName":"John Doe","email":"john@example.com"}' `
  -ContentType "application/json"
```

## Troubleshooting

### Problem: "func: command not found"

**Solution:**
```bash
# Install Azure Functions Core Tools
npm install -g azure-functions-core-tools@4

# Verify installation
func --version
```

### Problem: Function won't start - "Missing AzureWebJobsStorage"

**Symptoms:**
```
Microsoft.Azure.WebJobs.Host: Error indexing method...
Missing value for AzureWebJobsStorage in local.settings.json
```

**Solution:**

Ensure `local.settings.json` has the correct configuration:
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated"
  }
}
```

Verify Azurite is running:
```bash
docker ps | grep azurite
# If not running:
docker start azurite
```

### Problem: Port already in use

**Symptoms:**
```
Failed to start host: Port 7071 is already in use
```

**Solutions:**

1. **Change port:**
   ```bash
   func start --port 7072
   ```

2. **Find and kill process:**
   ```powershell
   # Windows
   netstat -ano | findstr :7071
   taskkill /PID <PID> /F
   
   # Linux/macOS
   lsof -ti:7071 | xargs kill -9
   ```

### Problem: Function returns 404 after deployment

**Solutions:**

1. **Verify route configuration:**
   - Check `[Function("FunctionName")]` attribute
   - Verify `[HttpTrigger(..., Route = "function/customer")]`

2. **Check function host status:**
   ```bash
   az functionapp show \
     --name <FUNCTION_APP_NAME> \
     --resource-group <RESOURCE_GROUP> \
     --query "state"
   ```

3. **View logs in Azure Portal:**
   - Function App → Log stream
   - Application Insights → Logs

### Problem: Function returns 500 error

**Solutions:**

1. **Check Application Insights:**
   - Azure Portal → Function App → Application Insights
   - View exceptions and detailed traces

2. **Enable detailed errors:**
   ```bash
   az functionapp config appsettings set \
     --name <FUNCTION_APP_NAME> \
     --resource-group <RESOURCE_GROUP> \
     --settings "AzureWebJobsStorage=<CONNECTION_STRING>"
   ```

3. **Verify dependencies:**
   - Ensure all NuGet packages are restored
   - Check .NET version matches runtime

### Problem: Cold start timeout

**Symptoms:**
- First request times out
- Subsequent requests work fine

**Solutions:**

1. **Use Premium or Dedicated plan:**
   - Consumption plan has 5-10 minute timeout
   - Premium plan supports longer execution

2. **Enable "Always On" (Premium/Dedicated only):**
   ```bash
   az functionapp config set \
     --name <FUNCTION_APP_NAME> \
     --resource-group <RESOURCE_GROUP> \
     --always-on true
   ```

### Problem: Cannot access local function from browser

**Solutions:**

1. **Check CORS settings in `local.settings.json`:**
   ```json
   {
     "Host": {
       "CORS": "*"
     }
   }
   ```

2. **Verify firewall allows connections**

3. **Try using `127.0.0.1` instead of `localhost`**

For more troubleshooting, see the [comprehensive troubleshooting guide](/docs/en-US/troubleshooting.md).

## CI/CD

- Functions are deployed to Azure Function Apps
- Use Application Insights for monitoring
- Configure connection strings via Key Vault references
