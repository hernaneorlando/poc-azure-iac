# 03 - Azure DevOps Setup

**Navigation:** [🏠 Home](../../README.md) | [👈 Previous](02-local-development.md) | [👉 Next](04-infrastructure-deployment.md)

---

## 🎯 Goal

Configure Azure DevOps organization, service connections, and pipelines for automated deployment.

## 🚦 Prerequisites

- ✅ Azure subscription (with Owner or Contributor + User Access Administrator)
- ✅ Azure DevOps organization
- ✅ Azure CLI installed and authenticated

## 📋 Step-by-Step Setup

### Step 1: Azure Portal - Register Resource Providers

Register required resource providers in your Azure subscription:

```bash
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.ApiManagement
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.AlertsManagement
az provider register --namespace Microsoft.OperationsManagement
```

**Or via Portal:** Azure Portal > Subscriptions > (your subscription) > Resource providers

### Step 2: Create Resource Group

```bash
az group create -n comp-poc-test-rg-dev -l brazilsouth --tags environment=dev
```

**Replace:**
- `comp-poc-test-rg-dev` with your desired resource group name
- `brazilsouth` with your preferred region

### Step 3: Create Service Connection in Azure DevOps

1. Navigate to **Azure DevOps** > Your Project > **Project Settings**
2. Select **Service connections** > **New service connection**
3. Choose **Azure Resource Manager**
4. Select **Workload Identity federation (recommended)**
5. Configure:
   - **Scope**: Resource Group
   - **Subscription**: Your Azure subscription
   - **Resource Group**: Select the RG created in Step 2
   - **Service connection name**: `POC-Azure-Connection`
6. ✅ **Grant access permission to all pipelines** (for POC simplicity)
7. Click **Save**

### Step 4: Assign RBAC Permissions

The service connection needs specific roles:

#### On Subscription Level:
```bash
# Get the service principal Object ID from Azure DevOps service connection
az role assignment create \
  --assignee-object-id <APP_OBJECT_ID> \
  --role Reader \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

#### On Resource Group Level:
```bash
az role assignment create \
  --assignee-object-id <APP_OBJECT_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/comp-poc-test-rg-dev
```

**Or via Portal:**
1. **Subscription** > Access control (IAM) > Add role assignment > **Reader** > Select service principal
2. **Resource Group** > Access control (IAM) > Add role assignment > **Contributor** > Select service principal

### Step 5: Create Pipeline Files in Azure DevOps

Import the repository to Azure DevOps if not already done:

1. Azure DevOps > Repos > Import repository
2. Clone URL: Your repository URL
3. Once imported, the pipeline files in `infra/pipelines/` will be available

### Step 6: Create Infrastructure CI Pipeline

1. Azure DevOps > Pipelines > **New pipeline**
2. Select **Azure Repos Git** (or your source)
3. Select your repository
4. Choose **Existing Azure Pipelines YAML file**
5. Path: `/infra/pipelines/infra_ci.yaml`
6. Click **Run**

This pipeline will:
- Validate Resource Group exists
- Install Bicep CLI
- Build and validate Bicep templates
- Run `What-If` analysis
- Publish ARM template as artifact

### Step 7: Create Infrastructure CD Pipeline

1. Azure DevOps > Pipelines > **New pipeline**
2. Path: `/infra/pipelines/infra_cd.yaml`
3. **Before running:** Update variables in the pipeline file:
   - `azureSubscription`: Should match your service connection name
   - `resourceGroupName`: Your resource group name
   - `location`: Your Azure region

4. Click **Run**

This pipeline will:
- Download ARM template from CI
- Deploy infrastructure to Azure (⏱️ ~60-90 minutes on first run)

## 🔐 Security Considerations

### For POC/Dev Environment:
- ✅ Service connection with Contributor on RG is acceptable
- ✅ "Grant access to all pipelines" simplifies setup

### For Production:
- ❌ **Don't** grant access to all pipelines
- ✅ Create separate service connection with minimum permissions
- ✅ Use separate Resource Groups per environment
- ✅ Implement approval gates for production deployments
- ✅ Consider using a privileged connection only for RBAC operations

## 📊 Pipeline Overview

|| Pipeline | Type | Purpose | Trigger |
|----------|------|---------|---------|
|| **infra_ci.yaml** | CI | Validate & build infrastructure | On commit to `main` or PR |
|| **infra_cd.yaml** | CD | Deploy infrastructure | Manual or after CI |
|| **k8s_ci.yaml** | CI | Build AKS service images | On commit to `src/AKS/` |
|| **k8s_cd.yaml** | CD | Deploy AKS services | Manual or after k8s CI |

## ⏱️ Expected Timeframes

| Operation | First Time | Subsequent |
|-----------|-----------|------------|
| **Resource Provider Registration** | ~5 min | Instant |
| **Service Connection Setup** | ~10 min | - |
| **RBAC Assignment** | ~2 min | - |
| **Infrastructure CI Pipeline** | ~3-5 min | ~3-5 min |
| **Infrastructure CD Pipeline** | ~60-90 min | ~10-20 min |

**Why so long?**
- APIM creation (Developer SKU): 20-45 minutes
- AKS creation: 10-20 minutes
- First deployment includes all resources

## 🔧 Troubleshooting

### Service Connection Issues

**Problem:** "Failed to authorize"
- **Solution:** Verify the service principal has correct RBAC roles on subscription and RG

**Problem:** "Could not find resource group"
- **Solution:** Ensure RG exists and service connection scope is correctly configured

### Pipeline Failures

**Problem:** Pipeline timeout
- **Solution:** Infrastructure CD has 90-minute timeout configured. If it still times out, check Azure Portal for deployment progress

**Problem:** "Resource providers not registered"
- **Solution:** Wait for provider registration to complete (~5 minutes)

**Problem:** "Bicep not found"
- **Solution:** CI pipeline installs Bicep automatically. Check pipeline logs for installation errors

## ⏭️ What's Next?

- ✅ **Service connection created?** → Proceed to [Infrastructure Deployment](04-infrastructure-deployment.md)
- ⚠️ **Pipelines failing?** → Check [Troubleshooting Guide](troubleshooting.md)
- 📚 **Want to understand pipelines?** → See [CI/CD Pipelines Guide](cicd-pipelines.md)

## 📚 Additional Resources

- [Azure DevOps Service Connections](https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints)
- [Workload Identity Federation](https://learn.microsoft.com/azure/devops/pipelines/library/connect-to-azure)
- [Azure RBAC Documentation](https://learn.microsoft.com/azure/role-based-access-control/)

---

**Navigation:** [🏠 Home](../../README.md) | [👈 Previous](02-local-development.md) | [👉 Next](04-infrastructure-deployment.md)