# CI/CD Pipelines Guide

**Navigation:** [🏠 Home](../../README.md) | [📚 Docs](../README.md)

---

## 🎯 Overview

This POC includes four Azure DevOps pipelines for automated infrastructure and services deployment:

|| Pipeline | Type | Purpose | Trigger |
|----------|------|---------|---------|
|| **infra_ci.yaml** | CI | Validate & build infrastructure templates | Commits to `infra/` |
|| **infra_cd.yaml** | CD | Deploy infrastructure to Azure | Manual or after CI |
|| **k8s_ci.yaml** | CI | Build and test AKS service images | Commits to `src/AKS/` |
|| **k8s_cd.yaml** | CD | Deploy AKS services to Kubernetes | Manual or after k8s CI |

---

## 📦 Infrastructure CI Pipeline (`infra_ci.yaml`)

**Location:** `infra/pipelines/infra_ci.yaml`

### Purpose

Validates Bicep templates and generates ARM template artifacts **without making any changes** to Azure.

### Triggers

```yaml
trigger:
  branches:
    include:
      - master
      - development
  paths:
    include:
      - infra/*
    exclude:
      - "**/*.md"
```

**Runs when:**
- Commits pushed to `master` or `development` branches
- Changes made to `infra/` directory
- Excludes markdown file changes

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `environment` | string | dev | Target environment (dev/qa/prod) |
| `uniqueSuffix` | string | comp-poc-test | Prefix for resource names |

### Pipeline Steps

#### 1. Discover Function Apps

**Purpose:** Auto-detects Azure Functions in `src/AzureFunctions/`

**Logic:**
- Scans each subdirectory in `src/AzureFunctions/`
- Checks for `.csproj` and `host.json` files
- Extracts .NET version from `TargetFramework` in `.csproj`
- Generates JSON configuration for each function

**Output:**
```json
[
  {
    "name": "comp-poc-test-func-customer-dev",
    "storageAccountName": "comppocteststcustomerdev",
    "runtime": "DOTNET-ISOLATED|8.0",
    "workerRuntime": "dotnet-isolated"
  },
  {
    "name": "comp-poc-test-func-supplier-dev",
    "storageAccountName": "comppocteststsupplierdev",
    "runtime": "DOTNET-ISOLATED|8.0",
    "workerRuntime": "dotnet-isolated"
  }
]
```

#### 2. Validate Resource Group

**Purpose:** Ensures target Resource Group exists

**Why:** Prevents pipeline failures due to missing RG

**Command:**
```bash
az group exists --name comp-poc-test-rg-dev
```

**If fails:** Pipeline stops with helpful error message

#### 3. Install Bicep CLI

**Purpose:** Ensures latest Bicep version is available

**Command:**
```bash
az bicep install
az bicep version
```

#### 4. Validate Bicep Template

**Purpose:** Checks template syntax and parameter types

**Steps:**
1. Compile Bicep to ARM JSON: `az bicep build`
2. Validate ARM template: `az deployment group validate`

**Validates:**
- ✅ Syntax errors
- ✅ Parameter types
- ✅ Resource dependencies
- ✅ API versions

#### 5. What-If Analysis

**Purpose:** Shows what resources will be created/modified/deleted

**Command:**
```bash
az deployment group what-if \
  --resource-group comp-poc-test-rg-dev \
  --template-file main.json \
  --parameters environment=dev location=brazilsouth ...
```

**Example output:**
```
Resource changes: 8 to create, 0 to modify, 0 to delete

+ Microsoft.KeyVault/vaults
  ~ comp-poc-test-kv-dev

+ Microsoft.ContainerService/managedClusters
  ~ comp-poc-test-aks-dev

+ Microsoft.ApiManagement/service
  ~ comp-poc-test-apim-dev
```

**Color coding:**
- `+` Green: Resource will be created
- `~` Yellow: Resource will be modified
- `-` Red: Resource will be deleted
- `*` Gray: No changes

#### 6. Publish ARM Template

**Purpose:** Makes ARM template available for CD pipeline

**Artifact name:** `arm-templates`

**Contents:**
- `main.json` - Compiled ARM template
- `parameters.json` - Parameter values

### Execution Time

**Average:** 3-5 minutes

### Common Issues

**Problem:** "Resource Group not found"
- **Solution:** Create RG before running pipeline: `az group create -n <RG_NAME> -l brazilsouth`

**Problem:** "Bicep build failed"
- **Solution:** Check Bicep syntax locally: `az bicep build --file infra/main.bicep`

**Problem:** "What-If shows unexpected changes"
- **Solution:** Review What-If output carefully. May indicate drift between code and deployed state.

---

## 🚀 Infrastructure CD Pipeline (`infra_cd.yaml`)

**Location:** `infra/pipelines/infra_cd.yaml`

### Purpose

Deploys infrastructure to Azure using ARM template artifact from CI pipeline.

### Triggers

```yaml
trigger: none  # Manual trigger only
```

**Run manually:**
- Azure DevOps → Pipelines → infra_cd → Run pipeline

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `environment` | string | dev | Target environment (dev/qa/prod) |
| `uniqueSuffix` | string | comp-poc-test | Prefix for resource names |

### Pipeline Stages

#### Stage: ValidateAndDeploy

**Job type:** Deployment (allows environment tracking)

**Environment:** Uses parameter value (dev/qa/prod)

### Deployment Steps

#### 1. Checkout Repository

**Purpose:** Access to source code for Function App discovery

#### 2. Discover Function Apps

**Same logic as CI pipeline** - ensures consistency

#### 3. Download ARM Templates

**Source:** CI pipeline artifact

**Downloads:**
- `main.json` - ARM template
- `parameters.json` - Parameters file

#### 4. Validate Resource Group

**Same as CI** - ensures RG exists before deployment

#### 5. Deploy Infrastructure

**Timeout:** 90 minutes (APIM creation is slow)

**Command:**
```bash
az deployment group create \
  --name "infra-deploy-$(date +%Y%m%d-%H%M%S)" \
  --resource-group comp-poc-test-rg-dev \
  --template-file main.json \
  --parameters \
    environment=dev \
    location=brazilsouth \
    keyVaultName=comp-poc-test-kv-dev \
    aksName=comp-poc-test-aks-dev \
    apimName=comp-poc-test-apim-dev \
    functionApps='<JSON_FROM_DISCOVERY>'
```

**Mode:** Incremental (only adds/updates, never deletes)

### Execution Time

| Run Type | Duration | Notes |
|----------|----------|-------|
| **First deployment** | 60-90 min | APIM takes 20-45 min |
| **Subsequent deployments** | 10-20 min | Existing resources updated |

### Monitoring Deployment

**In Azure DevOps:**
- Watch pipeline logs in real-time
- Check for warnings or errors

**In Azure Portal:**
1. Navigate to Resource Group
2. Click **Deployments** (under Settings)
3. Select active deployment
4. View progress by resource

### Common Issues

**Problem:** Pipeline times out after 90 minutes
- **Solution:** Check Azure Portal deployments. If still in progress, wait. APIM creation can exceed 45 minutes.

**Problem:** "Deployment failed: Conflict"
```
Error: Resource already exists with different properties
```
- **Solution:** Either:
  - Update Bicep to match existing resource
  - Delete resource and redeploy
  - Use `mode: Complete` (⚠️ dangerous - deletes unmanaged resources)

**Problem:** "Function Apps not detected"
- **Solution:** Verify folder structure contains `.csproj` and `host.json`

---

## 🐳 AKS Services CI Pipeline (`k8s_ci.yaml`)

**Location:** `infra/pipelines/k8s_ci.yaml`

### Purpose

Builds, tests, and validates AKS services (Authentication and Products), then builds and pushes Docker images to Container Registry.

### Triggers

```yaml
trigger:
  branches:
    include:
      - master
      - development
```

**Runs when:**
- Commits to `master` or `development` branch
- Ideally should be configured to trigger only on changes in `src/AKS/` directory

### Pipeline Steps

#### 1. Restore NuGet Packages

```yaml
- task: DotNetCoreCLI@2
  displayName: 'Restore'
  inputs:
    command: 'restore'
    projects: '**/*.csproj'
```

Restores all NuGet dependencies for Authentication, Products, and Common projects.

#### 2. Build .NET Projects

```yaml
- task: DotNetCoreCLI@2
  displayName: 'Build'
  inputs:
    command: 'build'
    projects: '**/*.csproj'
```

Compiles all C# projects to validate code compilation.

#### 3. Run Tests

```yaml
- task: DotNetCoreCLI@2
  displayName: 'Test'
  inputs:
    command: 'test'
    projects: '**/*.csproj'
```

Executes unit tests (if test projects exist).

#### 4. Build and Push Docker Image

```yaml
- task: Docker@2
  displayName: 'Build and Push Docker Image'
  inputs:
    containerRegistry: '$(dockerRegistryServiceConnection)'
    repository: '$(imageRepository)'
    command: 'buildAndPush'
    tags: '$(tag)'
```

**Note:** The current pipeline builds a single generic image. For separate Authentication and Products images, you should:
- Add multiple Docker@2 tasks with different Dockerfiles
- Or use a matrix strategy to build both services

### Variables

- `dockerRegistryServiceConnection`: Docker registry service connection name
- `imageRepository`: Image repository path (e.g., `acr.azurecr.io/my-api`)
- `tag`: Image tag (uses `$(Build.BuildId)`)

### Execution Time

**Average:** 5-10 minutes (depending on image size and layers cached)

---

## 📡 AKS Services CD Pipeline (`k8s_cd.yaml`)

**Location:** `infra/pipelines/k8s_cd.yaml`

### Purpose

Deploys Authentication and Products services to AKS cluster and configures RBAC permissions for Key Vault access.

### Triggers

```yaml
trigger: none  # Manual trigger
```

### Deployment Steps

#### 1. Deploy Authentication Service to AKS

```yaml
- task: Kubernetes@1
  displayName: 'kubectl apply for Authentication API'
  inputs:
    connectionType: 'Kubernetes Service Connection'
    kubernetesServiceEndpoint: '$(kubernetesServiceConnection)'
    namespace: '$(namespace)'
    command: apply
    arguments: '-f infra/k8s/auth-deployment.yaml'
```

Deploys the Authentication API deployment manifest to Kubernetes.

#### 2. Deploy Products Service to AKS

```yaml
- task: Kubernetes@1
  displayName: 'kubectl apply for Products API'
  inputs:
    connectionType: 'Kubernetes Service Connection'
    kubernetesServiceEndpoint: '$(kubernetesServiceConnection)'
    namespace: '$(namespace)'
    command: apply
    arguments: '-f infra/k8s/products-deployment.yaml'
```

Deploys the Products API deployment manifest to Kubernetes.

#### 3. Assign RBAC Permissions for Key Vault

```yaml
- task: AzureCLI@2
  displayName: 'Assign RBAC to AKS Managed Identity for Key Vault'
  inputs:
    azureSubscription: 'Azure-Connection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # Get AKS managed identity
      aksIdentity=$(az aks show --name $(aksName) --resource-group $(resourceGroupName) --query identityProfile.kubeletidentity.objectId -o tsv)
      
      # Assign Key Vault Secrets User role
      az role assignment create \
        --assignee $aksIdentity \
        --role "Key Vault Secrets User" \
        --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$(resourceGroupName)/providers/Microsoft.KeyVault/vaults/$(keyVaultName)
```

Grants the AKS managed identity permission to read secrets from Key Vault.

### Variables

- `kubernetesServiceConnection`: Kubernetes service connection name in Azure DevOps
- `namespace`: Kubernetes namespace (default: `default`)
- `imageRepository`: Container image path
- `tag`: Image tag from CI pipeline
- `aksName`: AKS cluster name
- `resourceGroupName`: Resource group name
- `keyVaultName`: Key Vault name

---

## 🔐 Service Connections

### POC-Azure-Connection

**Type:** Azure Resource Manager (Workload Identity Federation)

**Scope:** Resource Group

**Required Roles:**
- **Subscription level:** Reader
- **Resource Group level:** Contributor

**Used by:**
- infra_ci.yaml
- infra_cd.yaml
- k8s_cd.yaml

### Docker Registry Service Connection

**Type:** Docker Registry

**Registry:** Container registry URL (e.g., Docker Hub or ACR)

**Authentication:** Service Principal, Admin User, or Access Token

**Used by:**
- k8s_ci.yaml (push images)

### Kubernetes Service Connection

**Type:** Kubernetes

**Cluster:** AKS cluster

**Authentication:** Service Account or Azure Subscription

**Used by:**
- k8s_cd.yaml (deploy manifests)

---

## 📊 Pipeline Best Practices

### Security

✅ Use Workload Identity Federation (passwordless)  
✅ Scope service connections to Resource Group only  
✅ Separate service connections per environment  
✅ Use Azure DevOps Environments for approval gates  
✅ Store secrets in Azure Key Vault, not pipeline variables  

### Performance

✅ Use caching for Docker layers  
✅ Run parallel jobs when possible  
✅ Use `condition: succeeded()` to skip unnecessary steps  
✅ Increase timeout for long-running deployments (APIM)  

### Maintainability

✅ Use templates for reusable pipeline logic  
✅ Parameterize resource names and environments  
✅ Add comments explaining complex steps  
✅ Use meaningful display names for tasks  
✅ Version control pipeline YAML files  

### Monitoring

✅ Enable pipeline run retention  
✅ Set up notifications for failed pipelines  
✅ Review What-If analysis before deploying  
✅ Track deployment history in Azure Portal  

---

## 📦 Docker Registry Setup

### Overview

The `k8s_ci.yaml` pipeline can build and push Docker images to a container registry. You have **three options** for registry configuration:

### Option 1: Docker Hub (Recommended for POC)

**Pros:**
- ✅ Free tier available
- ✅ Simple setup
- ✅ Public or private repositories

**Setup Steps:**

#### 1. Create Docker Hub Account

1. Go to https://hub.docker.com/
2. Sign up for a free account

#### 2. Generate Access Token

1. Login to Docker Hub
2. Navigate to **Account Settings** > **Security**
3. Click **New Access Token**
4. Name: `azure-devops-poc`
5. Permissions: **Read, Write, Delete**
6. Click **Generate**
7. **⚠️ COPY THE TOKEN IMMEDIATELY** (won't be shown again)

#### 3. Create Service Connection in Azure DevOps

1. Azure DevOps > Your Project > **Project Settings**
2. **Service connections** > **New service connection**
3. Select **Docker Registry**
4. Choose **Docker Hub**
5. Configure:
   - **Docker Registry**: `https://index.docker.io/v1/`
   - **Docker ID**: your Docker Hub username
   - **Password**: paste the access token
   - **Service connection name**: `dockerConnection`
6. ✅ **Grant access permission to all pipelines**
7. Click **Verify and save**

#### 4. Update k8s_ci.yaml

Uncomment these lines in `infra/pipelines/k8s_ci.yaml`:

```yaml
variables:
  dockerRegistryServiceConnection: 'dockerConnection'
  imageRepository: 'your-dockerhub-username/auth-api'  # Replace with YOUR username
  tag: '$(Build.BuildId)'

# ...

  - task: Docker@2
    displayName: 'Build and Push Docker Image'
    inputs:
      containerRegistry: '$(dockerRegistryServiceConnection)'
      repository: '$(imageRepository)'
      command: 'buildAndPush'
      tags: '$(tag)'
```

### Option 2: Azure Container Registry (Recommended for Production)

**Pros:**
- ✅ Integrated with Azure
- ✅ Automatic authentication with AKS
- ✅ Private registry within your subscription
- ✅ No pull rate limits

**Note:** ACR is automatically created by the infrastructure pipelines when you deploy the Bicep templates.

**Setup Steps:**

#### 1. Verify ACR Creation

After running `infra_cd.yaml`, verify ACR exists:

```bash
az acr list --resource-group comp-poc-test-rg-dev --output table
```

Expected output:
```
NAME                 RESOURCE GROUP          LOCATION
comppoctestacrdev    comp-poc-test-rg-dev    brazilsouth
```

#### 2. Create Service Connection

**Option 2a: Via Azure Subscription (Recommended)**

1. Azure DevOps > **Service connections** > **New service connection**
2. Select **Docker Registry**
3. Choose **Azure Container Registry**
4. Select your **Subscription**
5. Select ACR: `comppoctestacrdev`
6. **Service connection name**: `dockerConnection`
7. ✅ **Grant access permission to all pipelines**
8. Click **Save**

**Option 2b: Via Admin User (Simpler but less secure)**

```bash
# Enable admin user
az acr update --name comppoctestacrdev --admin-enabled true

# Get credentials
az acr credential show --name comppoctestacrdev
```

Then create service connection:
1. Azure DevOps > **Service connections** > **New service connection**
2. Select **Docker Registry**
3. Choose **Others**
4. Configure:
   - **Docker Registry**: `https://comppoctestacrdev.azurecr.io`
   - **Docker ID**: username from `az acr credential show`
   - **Password**: password from `az acr credential show`
   - **Service connection name**: `dockerConnection`
5. ✅ **Grant access permission to all pipelines**
6. Click **Verify and save**

#### 3. Update k8s_ci.yaml

```yaml
variables:
  dockerRegistryServiceConnection: 'dockerConnection'
  imageRepository: 'comppoctestacrdev.azurecr.io/auth-api'
  tag: '$(Build.BuildId)'

# ...

  - task: Docker@2
    displayName: 'Build and Push Docker Image'
    inputs:
      containerRegistry: '$(dockerRegistryServiceConnection)'
      repository: '$(imageRepository)'
      command: 'buildAndPush'
      tags: '$(tag)'
```

#### 4. Update Kubernetes Manifests

The `auth-deployment.yaml` and `products-deployment.yaml` are already configured with:

```yaml
image: comppoctestacrdev.azurecr.io/auth-api:latest
```

**No imagePullSecrets needed** - AKS has `AcrPull` role automatically assigned!

### Option 3: No Registry (Build & Test Only)

**When to use:**
- You only want to validate code compilation
- Still developing locally
- Manual Docker build/push workflow

**Setup:** Nothing! The pipeline already works without Docker registry. It will:
1. ✅ Restore NuGet packages
2. ✅ Build all .NET projects
3. ✅ Run unit tests
4. ❌ Skip Docker build/push

### Troubleshooting Docker Registry

**Problem:** "service connection dockerConnection could not be found"
- **Solution:** Verify service connection exists and name matches exactly
- **Check:** Azure DevOps > Project Settings > Service connections

**Problem:** "unauthorized: authentication required"
- **Docker Hub:** Regenerate access token and update service connection
- **ACR:** Verify admin user is enabled: `az acr update --name <ACR> --admin-enabled true`

**Problem:** "denied: requested access to the resource is denied"
- **Docker Hub:** Verify repository name includes YOUR username
- **ACR:** Verify service principal has `AcrPush` role

---

## ⚡ Azure Functions CI/CD

### Overview

Azure Functions deployment uses the same infrastructure pipelines (`infra_ci.yaml` / `infra_cd.yaml`) for provisioning Function Apps, with separate pipelines for deploying code.

**Pipeline Structure:**

| Pipeline | Purpose | Trigger |
|----------|---------|--------|
| `infra_ci.yaml` | Discovers and validates Function Apps | Changes to `infra/` |
| `infra_cd.yaml` | Creates Function Apps + Storage | Manual |
| `function_ci.yaml` | Builds Function code | Changes to `src/AzureFunctions/` |
| `function_cd.yaml` | Deploys Function code | Manual |

### Execution Order

#### Initial Deployment (First Time)

```
1. infra_ci.yaml    → Discovers Functions, validates infrastructure
2. infra_cd.yaml    → Creates Function Apps in Azure
3. function_ci.yaml → Builds Function code (.NET)
4. function_cd.yaml → Deploys code to Function Apps
```

#### Code-Only Updates

When only Function code changes:

```
1. function_ci.yaml → Builds code
2. function_cd.yaml → Deploys code
```

#### Infrastructure + Code Updates

When both infrastructure and code change:

```
1. infra_ci.yaml    → Validates infrastructure changes
2. infra_cd.yaml    → Updates infrastructure
3. function_ci.yaml → Builds code
4. function_cd.yaml → Deploys code
```

### Auto-Discovery Mechanism

The infrastructure pipelines **automatically detect** Function Apps by scanning `src/AzureFunctions/`:

**Detection criteria:**
1. ✅ Must be a subdirectory of `src/AzureFunctions/`
2. ✅ Must contain a `.csproj` file
3. ✅ Must contain a `host.json` file

**Example structure:**
```
src/AzureFunctions/
├── CustomerFunction/
│   ├── CustomerFunction.csproj  ← Required
│   ├── host.json                ← Required
│   ├── Program.cs
│   └── Functions/
│       └── GetCustomer.cs
└── SupplierFunction/
    ├── SupplierFunction.csproj  ← Required
    ├── host.json                ← Required
    ├── Program.cs
    └── Functions/
        └── GetSuppliers.cs
```

**Generated JSON configuration:**
```json
[
  {
    "name": "comp-poc-test-func-customerfunction-dev",
    "storageAccountName": "comppocteststcustomerdev",
    "runtime": "DOTNET-ISOLATED|8.0",
    "workerRuntime": "dotnet-isolated"
  },
  {
    "name": "comp-poc-test-func-supplierfunction-dev",
    "storageAccountName": "comppocteststsupplierdev",
    "runtime": "DOTNET-ISOLATED|8.0",
    "workerRuntime": "dotnet-isolated"
  }
]
```

### Naming Conventions

With `uniqueSuffix` = `comp-poc-test` and `environment` = `dev`:

| Resource | Pattern | Example |
|----------|---------|--------|
| Function App | `{suffix}-func-{folder}-{env}` | `comp-poc-test-func-customer-dev` |
| Storage Account | `{suffix}st{folder:6}{env}` | `comppocteststcustomerdev` |
| App Service Plan | `{suffix}-asp-{env}` | `comp-poc-test-asp-dev` |

**Notes:**
- `{folder}` = subdirectory name in lowercase
- Storage Account name removes hyphens and truncates to 24 chars
- .NET version auto-detected from `<TargetFramework>` in `.csproj`

### Adding New Functions

#### Create New Function App Project

```bash
cd src/AzureFunctions
mkdir OrdersFunction
cd OrdersFunction

# Initialize .NET project
func init --worker-runtime dotnet-isolated --target-framework net8.0

# Add HTTP trigger function
func new --name GetOrders --template "HTTP trigger"
```

**That's it!** Next pipeline run will automatically:
1. Detect `OrdersFunction`
2. Create Function App + Storage in Azure
3. Deploy the code

#### Add Function to Existing Project

To add more endpoints to an existing Function App:

```bash
cd src/AzureFunctions/CustomerFunction
func new --name CreateCustomer --template "HTTP trigger"
```

Or manually create a `.cs` file with `[Function]` attribute.

### Local Testing

**Run CustomerFunction locally:**
```bash
cd src/AzureFunctions/CustomerFunction
func start
```

Endpoints available at:
- `http://localhost:7071/api/customers` (GET/POST)
- `http://localhost:7071/api/customers/{id}` (GET)

**Run SupplierFunction locally:**
```bash
cd src/AzureFunctions/SupplierFunction
func start
```

Endpoints available at:
- `http://localhost:7071/api/suppliers` (GET/POST)

### Testing in Azure

After deployment, get Function URLs:

```bash
# List all Function Apps
az functionapp list \
  --resource-group comp-poc-test-rg-dev \
  --output table

# Get Function keys
az functionapp function keys list \
  --resource-group comp-poc-test-rg-dev \
  --name comp-poc-test-func-customer-dev \
  --function-name GetCustomers
```

**Invoke Function:**
```bash
curl "https://comp-poc-test-func-customer-dev.azurewebsites.net/api/customers?code=YOUR_FUNCTION_KEY"
```

### Function App Settings

Automatically configured by infrastructure pipelines:

| Setting | Value | Purpose |
|---------|-------|--------|
| `AzureWebJobsStorage` | Storage connection string | Required for Functions runtime |
| `APPINSIGHTS_INSTRUMENTATIONKEY` | App Insights key | Telemetry |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | App Insights connection | Telemetry (new format) |
| `FUNCTIONS_WORKER_RUNTIME` | `dotnet-isolated` | Runtime type |
| `FUNCTIONS_EXTENSION_VERSION` | `~4` | Functions runtime version |

**Add custom settings:**
```bash
az functionapp config appsettings set \
  --name comp-poc-test-func-customer-dev \
  --resource-group comp-poc-test-rg-dev \
  --settings "CustomSetting=Value"
```

### Troubleshooting Functions

**Problem:** Function App not detected by pipeline
- **Solution:** Verify `.csproj` and `host.json` exist in subdirectory
- **Check:** Pipeline logs show "No Function Apps found"

**Problem:** Storage Account name too long
- **Solution:** Use shorter function folder names (<18 chars recommended)
- **Reason:** Storage names limited to 24 chars total

**Problem:** Function deployment fails with "Cannot find package"
- **Solution:** Check `function_ci.yaml` successfully built and published artifact
- **Verify:** Artifact `function-app-build` exists in pipeline run

**Problem:** Function returns 500 error
- **Solution:** Check Application Insights logs:
  ```bash
  az monitor app-insights query \
    --app comp-poc-test-appins-dev \
    --analytics-query "exceptions | take 10"
  ```

---

## 🔧 Troubleshooting Pipelines

### CI Pipeline Failures

**Problem:** "az: command not found"
- **Solution:** Use `AzureCLI@2` task instead of `Bash@3`

**Problem:** "Service connection not found"
- **Solution:** Verify service connection name matches `azureSubscription` parameter

### CD Pipeline Failures

**Problem:** "Insufficient permissions"
- **Solution:** Verify service principal has Contributor role on Resource Group

**Problem:** "Template validation failed"
- **Solution:** Run What-If in CI first to identify issues

### Docker Build Failures

**Problem:** "Cannot find Dockerfile"
- **Solution:** Verify `buildContext` is set correctly (usually `src/AKS/`)

**Problem:** "Copy failed: no such file"
- **Solution:** Check Dockerfile COPY paths are relative to build context

---

## 📚 Additional Resources

- [Azure DevOps Pipelines Documentation](https://learn.microsoft.com/azure/devops/pipelines/)
- [Bicep CI/CD](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-github-actions)
- [Docker@2 Task](https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/docker-v2)
- [AzureCLI@2 Task](https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/azure-cli-v2)

---

**Navigation:** [🏠 Home](../../README.md) | [📚 Docs](../README.md)