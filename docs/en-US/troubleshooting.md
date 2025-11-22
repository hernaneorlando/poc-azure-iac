# Troubleshooting Guide

**Navigation:** [🏠 Home](../../README.md) | [📚 Docs](../README.md)

---

## 🎯 Overview

This guide covers common issues and solutions across all components of the POC.

## 📑 Table of Contents

- [Local Development Issues](#-local-development-issues)
- [Azure DevOps Pipeline Issues](#-azure-devops-pipeline-issues)
- [Infrastructure Deployment Issues](#-infrastructure-deployment-issues)
- [AKS/Kubernetes Issues](#-akskubernetes-issues)
- [Azure Functions Issues](#-azure-functions-issues)
- [Logic Apps Issues](#-logic-apps-issues)
- [Networking & Connectivity Issues](#-networking--connectivity-issues)
- [Security & Permissions Issues](#-security--permissions-issues)

---

## 🖥️ Local Development Issues

### Minikube Issues

#### Problem: Minikube won't start

**Symptoms:**
```
😄  minikube v1.32.0 on Windows 11
❌  Exiting due to HOST_VIRT_UNAVAILABLE: Failed to start host: ...
```

**Solutions:**

1. **Check virtualization is enabled:**
   ```powershell
   # Windows
   Get-ComputerInfo | Select-Object -ExpandProperty HyperVisorPresent
   # Should return: True
   ```

2. **Try different driver:**
   ```bash
   minikube start --driver=docker
   # or
   minikube start --driver=hyperv
   ```

3. **Delete and recreate:**
   ```bash
   minikube delete
   minikube start
   ```

4. **Check system resources:**
   - Ensure at least 2GB RAM available
   - Ensure at least 20GB disk space

#### Problem: kubectl commands fail after Minikube start

**Symptoms:**
```
Unable to connect to the server: dial tcp 127.0.0.1:... connectex: No connection could be made
```

**Solution:**
```bash
# Set context to minikube
kubectl config use-context minikube

# Verify
kubectl cluster-info
```

#### Problem: Port-forward not working

**Symptoms:**
- `kubectl port-forward` succeeds but cannot access `localhost:<PORT>`

**Solutions:**

1. **Check pod status:**
   ```bash
   kubectl get pods
   # Ensure pod is Running
   ```

2. **Verify service exists:**
   ```bash
   kubectl get services
   ```

3. **Try different local port:**
   ```bash
   kubectl port-forward service/products-api 8082:8081
   ```

4. **Check firewall:**
   - Windows: Allow kubectl through firewall
   - Disable VPN if active

### Azure Functions Core Tools Issues

#### Problem: "func: command not found"

**Solution:**
```bash
# Install Azure Functions Core Tools
npm install -g azure-functions-core-tools@4

# Verify installation
func --version
```

#### Problem: Function won't start - "Missing AzureWebJobsStorage"

**Symptoms:**
```
Microsoft.Azure.WebJobs.Host: Error indexing method...
Missing value for AzureWebJobsStorage in local.settings.json
```

**Solution:**

Add to `local.settings.json`:
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated"
  }
}
```

Ensure Azurite is running:
```bash
docker ps | grep azurite
# If not running:
docker start azurite
```

#### Problem: Port already in use

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

### Logic App Local Execution Issues

#### Problem: Logic App won't start - Node.js not found

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

#### Problem: "MissingApiVersionParameter" error

**Symptoms:**
```
Status code: 400
{"error":{"code":"MissingApiVersionParameter",...}}
```

**Solution:**

Add `api-version` to callback URL request:
```bash
curl -X POST "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/GetAllOrders/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview"
```

#### Problem: Workflows not detected after start

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

---

## 🔄 Azure DevOps Pipeline Issues

### Service Connection Issues

#### Problem: "Service connection not found"

**Symptoms:**
```
##[error]There was a resource authorization issue: 
"POC-Azure-Connection could not be found."
```

**Solutions:**

1. **Verify service connection name:**
   - Azure DevOps > Project Settings > Service connections
   - Ensure name matches `azureSubscription` in YAML

2. **Grant pipeline permission:**
   - Service connections > Select connection > Security
   - Check "Grant access permission to all pipelines"
   - Or authorize specific pipeline

#### Problem: "Forbidden" or "Insufficient permissions"

**Symptoms:**
```
##[error]The client '...' does not have authorization to perform action 
'Microsoft.Resources/deployments/write'
```

**Solutions:**

1. **Verify RBAC assignments:**
   ```bash
   # Get service principal object ID from service connection
   
   # Check current role assignments
   az role assignment list \
     --assignee <SP_OBJECT_ID> \
     --resource-group comp-poc-test-rg-dev
   ```

2. **Assign required roles:**
   ```bash
   # Subscription level: Reader
   az role assignment create \
     --assignee <SP_OBJECT_ID> \
     --role Reader \
     --scope /subscriptions/<SUB_ID>
   
   # RG level: Contributor
   az role assignment create \
     --assignee <SP_OBJECT_ID> \
     --role Contributor \
     --scope /subscriptions/<SUB_ID>/resourceGroups/comp-poc-test-rg-dev
   ```

### Pipeline Execution Issues

#### Problem: Pipeline times out

**Symptoms:**
- Pipeline runs for 60+ minutes and times out

**Solutions:**

1. **For Infrastructure CD:**
   - APIM creation can take 45+ minutes
   - Check Azure Portal > Resource Group > Deployments
   - If deployment still in progress, wait

2. **Increase timeout:**
   ```yaml
   - task: AzureCLI@2
     timeoutInMinutes: 120
   ```

#### Problem: "Resource Group not found"

**Symptoms:**
```
(ResourceGroupNotFound) Resource group 'comp-poc-test-rg-dev' could not be found
```

**Solution:**

Create Resource Group before running pipeline:
```bash
az group create \
  --name comp-poc-test-rg-dev \
  --location brazilsouth \
  --tags environment=dev
```

#### Problem: Bicep build fails

**Symptoms:**
```
Error BCP057: The name "..." does not exist in the current context
```

**Solutions:**

1. **Test locally:**
   ```bash
   az bicep build --file infra/main.bicep
   ```

2. **Common issues:**
   - Typo in parameter/variable name
   - Missing module reference
   - Incorrect resource property name

3. **Update Bicep:**
   ```bash
   az bicep upgrade
   ```

---

## ☁️ Infrastructure Deployment Issues

### Resource Provider Issues

#### Problem: "Resource provider not registered"

**Symptoms:**
```
Code: MissingSubscriptionRegistration
Message: The subscription is not registered to use namespace 'Microsoft.ContainerService'
```

**Solution:**

Register required providers:
```bash
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ApiManagement
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.Web

# Check registration status
az provider show \
  --namespace Microsoft.ContainerService \
  --query "registrationState"
```

**Note:** Registration takes ~5 minutes.

### Key Vault Issues

#### Problem: Key Vault name already exists globally

**Symptoms:**
```
Error: (VaultAlreadyExists) A vault with the same name already exists in deleted state
```

**Solutions:**

1. **Purge soft-deleted vault:**
   ```bash
   az keyvault purge --name comp-poc-test-kv-dev
   ```

2. **Use different name:**
   - Change `keyVaultName` parameter
   - Key Vault names must be globally unique

#### Problem: Cannot access Key Vault secrets

**Symptoms:**
```
(Forbidden) The user, group or application '...' does not have secrets get permission
```

**Solution:**

Grant RBAC role:
```bash
az role assignment create \
  --assignee <IDENTITY_CLIENT_ID> \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.KeyVault/vaults/<KV_NAME>
```

### APIM Issues

#### Problem: APIM creation takes too long

**Symptoms:**
- Deployment stuck on APIM for 30+ minutes

**Solutions:**

- **Normal behavior:** APIM (Developer SKU) creation takes 20-45 minutes
- Check Azure Portal for progress
- Do not cancel deployment unless it exceeds 60 minutes

#### Problem: APIM name already taken

**Symptoms:**
```
Error: (ServiceNameNotAvailable) Service name is not available
```

**Solution:**

- APIM names must be globally unique
- Change `apimName` parameter to something unique

---

## ☸️ AKS/Kubernetes Issues

### Image Pull Issues

#### Problem: ImagePullBackOff

**Symptoms:**
```bash
kubectl get pods
NAME                    READY   STATUS             RESTARTS   AGE
auth-api-xxxxx-xxxxx   0/1     ImagePullBackOff   0          2m
```

**Solutions:**

1. **Check image name:**
   ```bash
   kubectl describe pod <POD_NAME>
   # Look for "Failed to pull image" message
   ```

2. **Verify ACR is attached:**
   ```bash
   az aks show \
     --name comp-poc-test-aks-dev \
     --resource-group comp-poc-test-rg-dev \
     --query "servicePrincipalProfile"
   
   # Attach ACR
   az aks update \
     --name comp-poc-test-aks-dev \
     --resource-group comp-poc-test-rg-dev \
     --attach-acr compoctestacr
   ```

3. **Check image exists in ACR:**
   ```bash
   az acr repository list --name compoctestacr
   az acr repository show-tags --name compoctestacr --repository auth-api
   ```

### Pod Crash Issues

#### Problem: CrashLoopBackOff

**Symptoms:**
```bash
kubectl get pods
NAME                    READY   STATUS             RESTARTS   AGE
auth-api-xxxxx-xxxxx   0/1     CrashLoopBackOff   5          5m
```

**Solutions:**

1. **Check pod logs:**
   ```bash
   kubectl logs <POD_NAME>
   
   # Check previous container logs
   kubectl logs <POD_NAME> --previous
   ```

2. **Common causes:**
   - Missing environment variables
   - Application crash on startup
   - Port misconfiguration
   - Missing secrets

3. **Describe pod for events:**
   ```bash
   kubectl describe pod <POD_NAME>
   # Look at Events section
   ```

4. **Verify secrets exist:**
   ```bash
   kubectl get secrets
   
   # Check secret content (base64 encoded)
   kubectl get secret auth-secrets -o yaml
   ```

### Service/LoadBalancer Issues

#### Problem: External IP pending forever

**Symptoms:**
```bash
kubectl get services
NAME       TYPE           EXTERNAL-IP   PORT(S)
auth-api   LoadBalancer   <pending>     8080:30080/TCP
```

**Solutions:**

1. **Minikube (local):**
   - LoadBalancer type doesn't work directly in Minikube
   - Use `kubectl port-forward` instead:
     ```bash
     kubectl port-forward service/auth-api 8080:8080
     ```
   
   - Or use `minikube tunnel` (requires admin/sudo):
     ```bash
     minikube tunnel
     ```

2. **AKS (Azure):**
   - Check AKS has permissions to create public IPs
   - Verify network security groups allow traffic
   - Check Azure Portal for Load Balancer resource

#### Problem: Cannot connect to service

**Symptoms:**
- Service has External IP but connection refused

**Solutions:**

1. **Verify pod is running:**
   ```bash
   kubectl get pods
   ```

2. **Check service endpoints:**
   ```bash
   kubectl get endpoints
   # Should show pod IPs
   ```

3. **Test from within cluster:**
   ```bash
   kubectl run -it --rm debug --image=busybox --restart=Never -- sh
   wget -O- http://auth-api:8080/api/auth/login
   ```

4. **Check port configuration:**
   - Ensure `targetPort` matches container port
   - Ensure `port` is what you're accessing externally

---

## ⚡ Azure Functions Issues

### Deployment Issues

#### Problem: Deployment fails with "SCM site not available"

**Symptoms:**
```
Error: The service is unavailable
```

**Solution:**

Wait 2-3 minutes after Function App creation, then retry deployment.

#### Problem: Deployment succeeds but function returns 404

**Symptoms:**
```bash
curl https://comp-poc-test-func-customer-dev.azurewebsites.net/function/customer
# Returns: 404 Not Found
```

**Solutions:**

1. **Check function route:**
   - Verify `[Function("CustomerGet")]` attribute
   - Verify `[HttpTrigger(..., Route = "function/customer")]`

2. **Check function host status:**
   ```bash
   az functionapp show \
     --name comp-poc-test-func-customer-dev \
     --resource-group comp-poc-test-rg-dev \
     --query "state"
   ```

3. **View function logs:**
   - Azure Portal > Function App > Log stream
   - Check for startup errors

#### Problem: Function returns 500 error

**Solutions:**

1. **Check Application Insights:**
   - Azure Portal > Function App > Application Insights
   - View exceptions and traces

2. **Enable detailed errors:**
   ```bash
   az functionapp config appsettings set \
     --name comp-poc-test-func-customer-dev \
     --resource-group comp-poc-test-rg-dev \
     --settings "FUNCTIONS_EXTENSION_VERSION=~4" "AzureWebJobsStorage=<CONNECTION_STRING>"
   ```

3. **Check dependencies:**
   - Ensure all NuGet packages restored
   - Verify .NET version matches Function App runtime

### Runtime Issues

#### Problem: Cold start timeout

**Symptoms:**
- First request to function times out
- Subsequent requests work fine

**Solutions:**

1. **Increase timeout (Consumption plan limitation):**
   - Default: 5 minutes
   - Max: 10 minutes

2. **Use Premium or Dedicated plan:**
   ```bash
   az functionapp plan create \
     --name premium-plan \
     --resource-group comp-poc-test-rg-dev \
     --sku EP1
   ```

3. **Enable "Always On" (Premium/Dedicated only):**
   ```bash
   az functionapp config set \
     --name comp-poc-test-func-customer-dev \
     --resource-group comp-poc-test-rg-dev \
     --always-on true
   ```

---

## 🔄 Logic Apps Issues

### Deployment Issues

#### Problem: Workflows not visible after deployment

**Symptoms:**
- Deployment succeeds
- No workflows listed in Azure Portal

**Solutions:**

1. **Verify zip structure:**
   ```
   logicapp.zip
   ├── host.json
   ├── local.settings.json (optional, excluded in production)
   ├── connections.json
   ├── GetAllOrders/
   │   └── workflow.json
   └── GetOrderById/
       └── workflow.json
   ```

2. **Re-deploy with correct structure:**
   ```bash
   cd src/LogicApp/OrdersLogicApp
   zip -r logicapp.zip . -x "local.settings.json"
   az logicapp deployment source config-zip \
     --name comp-poc-test-logicapp-dev \
     --resource-group comp-poc-test-rg-dev \
     --src logicapp.zip
   ```

### Execution Issues

#### Problem: Callback URL returns 401 Unauthorized

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

2. **Get callback URL:**
   ```bash
   az rest --method POST \
     --uri "https://management.azure.com/subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.Web/sites/<LOGIC_APP_NAME>/hostruntime/runtime/webhooks/workflow/api/management/workflows/<WORKFLOW_NAME>/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview"
   ```

#### Problem: GetOrderById workflow expects POST but docs say GET

**Explanation:**

Logic Apps with HTTP trigger that require **request body** must use POST method, even if conceptually it's a "read" operation.

**Solution:**

Use POST with JSON body:
```bash
curl -X POST "<CALLBACK_URL>" \
  -H "Content-Type: application/json" \
  -d '{"id": "123"}'
```

---

## 🌐 Networking & Connectivity Issues

### DNS Resolution Issues

#### Problem: Cannot resolve service names

**Solutions:**

1. **Within Kubernetes:**
   - Use service name: `http://auth-api:8080`
   - Use fully qualified: `http://auth-api.default.svc.cluster.local:8080`

2. **From outside cluster:**
   - Use External IP or LoadBalancer IP
   - Use APIM gateway URL

### Firewall Issues

#### Problem: Connection timeout from local machine

**Solutions:**

1. **Check Windows Firewall:**
   ```powershell
   Get-NetFirewallProfile | Select-Object Name, Enabled
   
   # Temporarily disable for testing
   Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
   ```

2. **Check Network Security Groups (Azure):**
   - Azure Portal > AKS/APIM > Networking
   - Ensure inbound rules allow traffic on required ports

### VPN Issues

#### Problem: Cannot access Azure resources while on VPN

**Solutions:**

- Disconnect VPN temporarily
- Configure VPN split tunneling
- Add Azure IP ranges to VPN exceptions

---

## 🔐 Security & Permissions Issues

### Managed Identity Issues

#### Problem: Workload Identity not working in AKS

**Symptoms:**
```
Failed to acquire token: ManagedIdentityCredential authentication unavailable
```

**Solutions:**

1. **Verify OIDC is enabled:**
   ```bash
   az aks show \
     --name comp-poc-test-aks-dev \
     --resource-group comp-poc-test-rg-dev \
     --query "oidcIssuerProfile.enabled"
   # Should return: true
   ```

2. **Verify ServiceAccount annotation:**
   ```bash
   kubectl get serviceaccount workload-sa -o yaml
   ```
   
   Should have:
   ```yaml
   metadata:
     annotations:
       azure.workload.identity/client-id: "<UAMI_CLIENT_ID>"
   ```

3. **Verify pod label:**
   ```yaml
   metadata:
     labels:
       azure.workload.identity/use: "true"
   ```

4. **Check RBAC permissions:**
   ```bash
   az role assignment list --assignee <UAMI_CLIENT_ID>
   ```

### RBAC Issues

#### Problem: "Authorization failed" when accessing Azure resources

**Solutions:**

1. **List current role assignments:**
   ```bash
   az role assignment list \
     --assignee <IDENTITY_CLIENT_ID> \
     --all
   ```

2. **Grant minimum required role:**
   ```bash
   # Key Vault access
   az role assignment create \
     --assignee <IDENTITY_CLIENT_ID> \
     --role "Key Vault Secrets User" \
     --scope <KEY_VAULT_RESOURCE_ID>
   ```

---

## 🆘 Getting More Help

### Diagnostic Commands

**AKS diagnostics:**
```bash
kubectl get all
kubectl describe pod <POD_NAME>
kubectl logs <POD_NAME>
kubectl get events --sort-by='.lastTimestamp'
```

**Azure resource status:**
```bash
az resource list --resource-group comp-poc-test-rg-dev --output table
az deployment group list --resource-group comp-poc-test-rg-dev --output table
```

**Function App diagnostics:**
```bash
az functionapp show --name <FUNC_NAME> --resource-group <RG>
az functionapp config appsettings list --name <FUNC_NAME> --resource-group <RG>
```

### Log Locations

| Component | Log Location |
|-----------|-------------|
| **AKS Pods** | `kubectl logs <POD_NAME>` |
| **AKS Events** | `kubectl get events` |
| **Functions** | Azure Portal > Function App > Log Stream |
| **Logic Apps** | Azure Portal > Logic App > Workflow > Run History |
| **Pipeline** | Azure DevOps > Pipelines > Run > Logs |
| **Infrastructure** | Azure Portal > Resource Group > Deployments |

### Useful Azure Portal Views

- **Application Insights:** End-to-end transaction tracking
- **Log Analytics:** KQL queries across all services
- **Azure Monitor:** Metrics and alerts
- **Resource Group Deployments:** Infrastructure deployment history

---

## 📚 Additional Resources

- [AKS Troubleshooting](https://learn.microsoft.com/azure/aks/troubleshooting)
- [Azure Functions Troubleshooting](https://learn.microsoft.com/azure/azure-functions/functions-recover-storage-account)
- [Logic Apps Troubleshooting](https://learn.microsoft.com/azure/logic-apps/logic-apps-diagnosing-failures)
- [Kubernetes Debugging](https://kubernetes.io/docs/tasks/debug/)

---

**Navigation:** [🏠 Home](../../README.md) | [📚 Docs](../README.md)
