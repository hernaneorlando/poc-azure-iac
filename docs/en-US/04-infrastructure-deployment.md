# 04 - Infrastructure Deployment

**Navigation:** [🏠 Home](../../README.md) | [👈 Previous](03-devops-setup.md) | [👉 Next](05-services-deployment.md)

---

## 🎯 Goal

Deploy the complete Azure infrastructure using Bicep templates through Azure DevOps pipelines.

## 📋 What Gets Deployed?

This deployment creates:

| Resource | Purpose | Approx. Creation Time |
|----------|---------|----------------------|
| **Azure Key Vault** | Secrets and configuration management | ~2 min |
| **Log Analytics Workspace** | Centralized logging | ~2 min |
| **Application Insights** | Telemetry and monitoring | ~2 min |
| **Azure Kubernetes Service (AKS)** | Container orchestration for microservices | ~10-20 min |
| **Azure API Management (APIM)** | API gateway and security | ~20-45 min |
| **Workload Identity (UAMI + FIC)** | Passwordless authentication for AKS workloads | ~1 min |
| **Azure Functions (auto-detected)** | Serverless compute for Customer & Supplier | ~3-5 min each |
| **Storage Accounts** | Backend storage for Functions & Logic Apps | ~2 min each |

**Total first deployment time: ~60-90 minutes** (mostly due to APIM)

## 🚦 Prerequisites

Before deploying, ensure you completed:

- ✅ [Azure DevOps Setup](03-devops-setup.md) - Service connections and pipelines configured
- ✅ Resource Group created (e.g., `comp-poc-test-rg-dev`)
- ✅ Resource Providers registered
- ✅ Service principal has correct RBAC permissions

## 📦 Deployment Process

### Step 1: Trigger Infrastructure CI Pipeline

The **Infrastructure CI pipeline** (`infra/pipelines/infra_ci.yaml`) validates and builds the Bicep templates.

**To run:**
1. Navigate to **Azure DevOps** > **Pipelines**
2. Select **infra_ci** pipeline
3. Click **Run pipeline**
4. Wait for completion (~3-5 minutes)

**What it does:**
- ✅ Validates Resource Group exists
- ✅ Installs Bicep CLI
- ✅ Builds `main.bicep` into ARM template (JSON)
- ✅ Runs **What-If** analysis (shows what will change)
- ✅ Publishes ARM template as artifact

**Expected output:**
```
✓ Bicep build successful
✓ What-If analysis completed
✓ ARM template published to artifacts
```

### Step 2: Review What-If Results

Before deploying, check the What-If analysis in the CI pipeline logs:

```
Resource changes: 1 to create, 0 to modify, 0 to delete
+ Microsoft.KeyVault/vaults
  + comp-poc-test-kv-dev
+ Microsoft.ContainerService/managedClusters
  + comp-poc-test-aks-dev
...
```

This shows exactly what will be created/modified.

### Step 3: Trigger Infrastructure CD Pipeline

The **Infrastructure CD pipeline** (`infra/pipelines/infra_cd.yaml`) deploys the infrastructure to Azure.

**To run:**
1. Navigate to **Azure DevOps** > **Pipelines**
2. Select **infra_cd** pipeline
3. Click **Run pipeline**
4. Configure parameters:
   - **Environment:** `dev` (or `qa`/`prod`)
   - **Unique Suffix:** `comp-poc-test` (or your custom suffix)
5. Click **Run**

**What it does:**
- ✅ Auto-detects Azure Functions in `src/AzureFunctions/`
- ✅ Downloads ARM template from CI artifacts
- ✅ Validates Resource Group exists
- ✅ Deploys infrastructure to Azure (⏱️ 60-90 min first time)

**Pipeline stages:**
```
1. Discover Function Apps      [~1 min]
2. Download ARM Templates       [~30 sec]
3. Validate Resource Group      [~10 sec]
4. Deploy Infrastructure        [~60-90 min]
```

### Step 4: Monitor Deployment Progress

**In Azure DevOps:**
- Monitor pipeline logs in real-time
- Check for any errors or warnings

**In Azure Portal:**
1. Navigate to your Resource Group
2. Select **Deployments** (under Settings)
3. Click on the active deployment to see progress
4. Watch resources being created in real-time

**Typical deployment order:**
```
1. Key Vault                    [~2 min]
2. Log Analytics                [~2 min]
3. Application Insights         [~2 min]
4. Storage Accounts             [~2 min each]
5. AKS Cluster                  [~10-20 min]
6. Function Apps                [~5 min each]
7. Workload Identity            [~1 min]
8. APIM (takes longest)         [~20-45 min]
```

### Step 5: Verify Deployment

After successful deployment, verify all resources:

```bash
# List all resources in the Resource Group
az resource list --resource-group comp-poc-test-rg-dev --output table

# Check AKS cluster status
az aks show --name comp-poc-test-aks-dev --resource-group comp-poc-test-rg-dev --query provisioningState

# Check APIM status
az apim show --name comp-poc-test-apim-dev --resource-group comp-poc-test-rg-dev --query provisioningState
```

**Expected output:**
```
Name                              Type
--------------------------------  ----------------------------------
comp-poc-test-kv-dev              Microsoft.KeyVault/vaults
comp-poc-test-log-dev             Microsoft.OperationalInsights/workspaces
comp-poc-test-appins-dev          Microsoft.Insights/components
comp-poc-test-aks-dev             Microsoft.ContainerService/managedClusters
comp-poc-test-apim-dev            Microsoft.ApiManagement/service
comp-poc-test-func-customer-dev   Microsoft.Web/sites
comp-poc-test-func-supplier-dev   Microsoft.Web/sites
...
```

## 🔄 Function Apps Auto-Discovery

The CD pipeline **automatically detects** Azure Functions in `src/AzureFunctions/`:

**Detection criteria:**
- ✅ Contains a `.csproj` file
- ✅ Contains a `host.json` file

**Auto-generated names:**
```
Function folder: src/AzureFunctions/OrdersFunction/
Generated name: comp-poc-test-func-ordersfunction-dev
Storage Account: comppocteststorders...dev

Function folder: src/AzureFunctions/SupplierFunction/
Generated name: comp-poc-test-func-supplierfunction-dev
Storage Account: comppocteststsuppli...dev
```

**Runtime detection:**
- Reads `TargetFramework` from `.csproj`
- Configures `DOTNET-ISOLATED|6.0`, `7.0`, or `8.0` accordingly

## 🔑 Workload Identity (Passwordless Authentication)

The deployment creates a **User-Assigned Managed Identity (UAMI)** and **Federated Identity Credential (FIC)** for AKS workloads to securely access Azure resources without passwords.

**What gets created:**
- UAMI: `comp-poc-test-aks-dev-wi`
- FIC: Links UAMI to Kubernetes ServiceAccount `workload-sa` in namespace `default`

**How it works:**
```
AKS Pod with ServiceAccount → UAMI → Azure Key Vault
(No passwords or secrets needed!)
```

**To use in AKS pods:**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-sa
  namespace: default
  annotations:
    azure.workload.identity/client-id: "<UAMI_CLIENT_ID>"
---
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: workload-sa
  containers:
  - name: app
    image: my-app:latest
```

## 🔐 Post-Deployment Security Setup

The deployment creates the infrastructure, but **RBAC permissions must be assigned manually** for security:

### Grant Workload Identity Access to Key Vault

```bash
# Get UAMI Client ID
UAMI_CLIENT_ID=$(az identity show \
  --name comp-poc-test-aks-dev-wi \
  --resource-group comp-poc-test-rg-dev \
  --query clientId -o tsv)

# Grant Key Vault Secrets User role
az role assignment create \
  --assignee $UAMI_CLIENT_ID \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/comp-poc-test-rg-dev/providers/Microsoft.KeyVault/vaults/comp-poc-test-kv-dev
```

### Grant Function Apps Access to Key Vault (if needed)

```bash
# Get Function App System-Assigned Managed Identity
FUNC_PRINCIPAL_ID=$(az functionapp identity show \
  --name comp-poc-test-func-customer-dev \
  --resource-group comp-poc-test-rg-dev \
  --query principalId -o tsv)

# Grant Key Vault Secrets User role
az role assignment create \
  --assignee-object-id $FUNC_PRINCIPAL_ID \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/comp-poc-test-rg-dev/providers/Microsoft.KeyVault/vaults/comp-poc-test-kv-dev
```

## 🔧 Troubleshooting

### Deployment Failures

**Problem:** Pipeline times out after 90 minutes
- **Solution:** APIM creation is slow. Check Azure Portal deployments for actual progress. If still in progress, wait.

**Problem:** "Resource provider not registered"
```
Error: Microsoft.ContainerService is not registered
```
- **Solution:** Register the provider:
  ```bash
  az provider register --namespace Microsoft.ContainerService
  ```

**Problem:** "Resource group not found"
- **Solution:** Ensure RG was created in Step 2 of [DevOps Setup](03-devops-setup.md)

### Function App Detection Issues

**Problem:** Function Apps not detected
- **Solution:** Verify folder structure:
  ```
  src/AzureFunctions/
  ├── OrdersFunction/
  │   ├── OrdersFunction.csproj   ← Required
  │   └── host.json               ← Required
  └── SupplierFunction/
      ├── SupplierFunction.csproj ← Required
      └── host.json               ← Required
  ```

**Problem:** Storage Account name too long
```
Error: Storage account name must be between 3 and 24 characters
```
- **Solution:** Function folder names are truncated to 6 chars. If still too long, use shorter `uniqueSuffix` parameter.

### AKS Issues

**Problem:** AKS creation fails with quota error
```
Error: Operation could not be completed as it results in exceeding approved Total Regional Cores quota
```
- **Solution:** Request quota increase in Azure Portal or use a different region.

**Problem:** OIDC not enabled on AKS
- **Solution:** Redeploy AKS. The `aks.bicep` module enables OIDC by default.

## 📊 Infrastructure Components Deep Dive

Want to understand what each Bicep module does?

👉 See [Infrastructure Components Guide](infrastructure-components.md) for detailed explanations.

## ⏭️ What's Next?

- ✅ **Infrastructure deployed successfully?** → Proceed to [Services Deployment](05-services-deployment.md)
- 📚 **Want to understand CI/CD pipelines?** → See [CI/CD Pipelines Guide](cicd-pipelines.md)
- ⚠️ **Deployment failed?** → Check [Troubleshooting Guide](troubleshooting.md)

## 📚 Additional Resources

- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure DevOps Pipelines](https://learn.microsoft.com/azure/devops/pipelines/)
- [ARM Template What-If](https://learn.microsoft.com/azure/azure-resource-manager/templates/deploy-what-if)

---

**Navigation:** [🏠 Home](../../README.md) | [👈 Previous](03-devops-setup.md) | [👉 Next](05-services-deployment.md)
