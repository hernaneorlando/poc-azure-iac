# Infrastructure Components

**Navigation:** [🏠 Home](../../README.md) | [📚 Docs](../README.md)

---

## 🎯 Overview

This guide provides a detailed explanation of all Bicep modules used to provision the Azure infrastructure for this POC.

## 📂 Bicep Structure

```
infra/
├── main.bicep                    # Orchestration module
└── modules/
    ├── aks.bicep                 # Azure Kubernetes Service
    ├── acr.bicep                 # Azure Container Registry
    ├── apim.bicep                # API Management
    ├── keyvault.bicep            # Key Vault
    ├── monitor.bicep             # Log Analytics + App Insights
    ├── function-app.bicep        # Azure Functions
    └── workload-identity.bicep   # Workload Identity (UAMI + FIC)
```

---

## 📘 main.bicep - Orchestration Module

**Purpose:** Coordinates deployment of all infrastructure resources.

### Key Features

- **Modular design:** Calls individual modules for each resource type
- **Conditional deployments:** Uses `if` statements for optional resources
- **Dependency management:** Ensures resources are created in correct order
- **Parameter validation:** Uses `@allowed` decorators for type safety

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `environment` | string | - | Environment name (dev/qa/prod) |
| `location` | string | resourceGroup().location | Azure region |
| `keyVaultName` | string | - | Key Vault name |
| `logAnalyticsName` | string | - | Log Analytics workspace name |
| `appInsightsName` | string | - | Application Insights name |
| `aksName` | string | - | AKS cluster name |
| `acrName` | string | - | Azure Container Registry name |
| `apimName` | string | - | API Management name |
| `apimSku` | string | Developer | APIM SKU (Developer/Basic/Standard/Premium) |
| `enableWorkloadIdentity` | bool | true | Create UAMI + FIC for AKS workloads |
| `functionApps` | array | [] | Array of Function App configurations |

### Deployment Flow

```
1. Key Vault          [Independent]
2. Monitor            [Independent]
   ├── Log Analytics
   └── App Insights
3. ACR                [Independent]
4. AKS                [Depends on: Monitor, ACR]
5. APIM               [Independent]
6. Workload Identity  [Depends on: AKS]
7. Function Apps      [Depends on: Monitor]
8. ACR Pull Role      [Depends on: AKS, ACR]
```

### Example Usage

```bash
az deployment group create \
  --name infra-deployment \
  --resource-group comp-poc-test-rg-dev \
  --template-file infra/main.bicep \
  --parameters \
    environment=dev \
    location=brazilsouth \
    keyVaultName=comp-poc-test-kv-dev \
    aksName=comp-poc-test-aks-dev \
    acrName=comppoctestacr \
    apimName=comp-poc-test-apim-dev
```

---

## 🔐 keyvault.bicep - Azure Key Vault

**Purpose:** Secure storage for secrets, keys, and certificates.

### Configuration

- **SKU:** Standard
- **RBAC Authorization:** Enabled (access controlled via Azure RBAC, not access policies)
- **Soft Delete:** Enabled by default (90-day retention)
- **Public Network Access:** Enabled (for POC simplicity)

### Key Properties

```bicep
enableRbacAuthorization: true      // Use Azure RBAC instead of access policies
enabledForDeployment: true         // Allow VMs to retrieve secrets
enabledForTemplateDeployment: true // Allow ARM templates to retrieve secrets
```

### Outputs

- `keyVaultId`: Resource ID of the Key Vault
- `keyVaultUri`: Vault URI (e.g., `https://comp-poc-test-kv-dev.vault.azure.net/`)

### Security Best Practices

✅ **DO:**
- Use Managed Identities to access Key Vault
- Grant minimum required RBAC roles (e.g., "Key Vault Secrets User")
- Store connection strings, API keys, and certificates in Key Vault

❌ **DON'T:**
- Hardcode secrets in code or configuration
- Grant broad roles like "Contributor" to Key Vault
- Disable RBAC authorization in production

### Example: Granting Access

```bash
# Grant AKS Workload Identity access to secrets
az role assignment create \
  --assignee <MANAGED_IDENTITY_CLIENT_ID> \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.KeyVault/vaults/<KV_NAME>
```

---

## 📊 monitor.bicep - Logging & Monitoring

**Purpose:** Centralized logging and application telemetry.

### Components

#### 1. Log Analytics Workspace

- **SKU:** PerGB2018 (pay-as-you-go)
- **Retention:** 30 days (default)
- **Purpose:** Aggregates logs from AKS, APIM, Functions, Logic Apps

**Use cases:**
- Kubernetes container logs
- APIM request/response logs
- Function execution logs
- Custom queries with KQL (Kusto Query Language)

#### 2. Application Insights

- **Type:** Web
- **Linked to:** Log Analytics workspace
- **Purpose:** Application performance monitoring (APM)

**Key features:**
- Distributed tracing across services
- Performance metrics (response times, failure rates)
- Custom events and metrics
- Dependency tracking

### Outputs

- `logAnalyticsId`: Resource ID (used by AKS addon)
- `appInsightsConnectionString`: Used by Functions/Logic Apps
- `appInsightsInstrumentationKey`: Legacy key (for older SDKs)

### Example Queries

**View AKS pod logs:**
```kql
ContainerLog
| where TimeGenerated > ago(1h)
| where Namespace == "default"
| project TimeGenerated, Computer, ContainerName, LogEntry
| order by TimeGenerated desc
```

**Function execution times:**
```kql
requests
| where cloud_RoleName startswith "comp-poc-test-func"
| summarize avg(duration), percentile(duration, 95) by name
```

---

## 📦 acr.bicep - Azure Container Registry

**Purpose:** Store and manage Docker container images for AKS services.

### Configuration

| Setting | Value | Notes |
|---------|-------|-------|
| **SKU** | Basic | Adequate for POC; use Standard/Premium for production |
| **Admin User** | Enabled | For POC simplicity; use Managed Identity in production |
| **Public Network Access** | Enabled | Allows push/pull from CI/CD pipelines |
| **Anonymous Pull** | Disabled | Requires authentication |

### Key Features

#### 1. Automatic AKS Integration

The `main.bicep` automatically configures **AcrPull** role assignment:

```bicep
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aksName, 'AcrPull')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: aks.outputs.kubeletIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}
```

This allows AKS to pull images from ACR **without** needing Docker registry secrets in Kubernetes.

#### 2. Admin User (POC Only)

For CI/CD pipelines, admin credentials are enabled:

```bash
# Get admin credentials
az acr credential show --name <ACR_NAME>
```

⚠️ **Production:** Use Service Principal or Managed Identity instead of admin user.

### Outputs

- `acrId`: Resource ID of the registry
- `acrName`: Registry name (e.g., `comppoctestacr`)
- `acrLoginServer`: Full login URL (e.g., `comppoctestacr.azurecr.io`)

### CI/CD Integration

The `k8s_ci.yaml` pipeline automatically:
1. Builds .NET projects
2. Creates Docker images
3. Pushes images to ACR
4. Tags with commit SHA

**Service Connection Required:**
- Type: Docker Registry
- Registry: Azure Container Registry
- Authentication: Service Principal or Admin User

See **[Docker Registry Setup Guide](../../infra/pipelines/DOCKER_REGISTRY_SETUP.md)** for detailed instructions.

### Naming Conventions

**ACR Name Rules:**
- ✅ Globally unique
- ✅ Alphanumeric only (no hyphens)
- ✅ 5-50 characters

Example: `comp-poc-test-aks-dev` → `comppoctestaksdev` (remove hyphens)

### Common Commands

**Login to ACR:**
```bash
az acr login --name <ACR_NAME>
```

**List images:**
```bash
az acr repository list --name <ACR_NAME> --output table
```

**Tag and push:**
```bash
docker tag my-image:latest <ACR_NAME>.azurecr.io/my-image:v1.0
docker push <ACR_NAME>.azurecr.io/my-image:v1.0
```

**Pull from Kubernetes:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
spec:
  template:
    spec:
      containers:
      - name: auth
        image: comppoctestacr.azurecr.io/auth-service:latest
        # No imagePullSecrets needed - AKS has AcrPull role
```

---

## ☸️ aks.bicep - Azure Kubernetes Service

**Purpose:** Container orchestration for Authentication and Products services.

### Configuration

| Setting | Value | Notes |
|---------|-------|-------|
| **SKU** | Basic/Free | Adequate for POC; use Standard for production |
| **Node Count** | 1 | Parameter: `nodeCount` |
| **Node VM Size** | Standard_D2s_v6 | 2 vCPU, 8GB RAM |
| **RBAC** | Enabled | Kubernetes RBAC for pod security |
| **OIDC Issuer** | Enabled | Required for Workload Identity |
| **Network Plugin** | Azure CNI | Assigns Azure IPs to pods |
| **Load Balancer** | Standard | Public IPs for services |

### Key Features

#### 1. OIDC Issuer Profile

Enables **Workload Identity** (passwordless authentication):

```bicep
oidcIssuerProfile: {
  enabled: true
}
```

This generates an OIDC issuer URL used for federated identity credentials.

#### 2. OMS Agent (Container Insights)

Integrates with Log Analytics for monitoring:

```bicep
addonProfiles: {
  omsagent: {
    enabled: true
    config: {
      logAnalyticsWorkspaceResourceID: logAnalyticsId
    }
  }
}
```

#### 3. System-Assigned Managed Identity

AKS cluster has its own identity for Azure resource management.

### Networking

**Azure CNI:**
- Pods get IPs from VNet subnet
- Enables direct pod-to-pod communication
- Requires sufficient IP address space

**LoadBalancer Type:**
- Creates Azure Load Balancer for each Service
- Assigns public IP for external access

### Outputs

- `aksClusterId`: Resource ID
- `aksClusterName`: Cluster name

### Post-Deployment Tasks

1. **Get credentials:**
   ```bash
   az aks get-credentials --name <AKS_NAME> --resource-group <RG>
   ```

2. **Verify OIDC issuer:**
   ```bash
   az aks show --name <AKS_NAME> --resource-group <RG> \
     --query "oidcIssuerProfile.issuerUrl" -o tsv
   ```

3. **Deploy workloads:**
   ```bash
   kubectl apply -f infra/k8s/
   ```

---

## 🌐 apim.bicep - API Management

**Purpose:** API gateway for centralized routing, security, and monitoring.

### Configuration

| Setting | Value | Notes |
|---------|-------|-------|
| **SKU** | Developer | $50/month; includes dev portal |
| **Capacity** | 1 | Number of scale units |
| **Virtual Network** | None | For POC; use Internal/External for production |
| **Publisher Info** | Configurable | Email and organization name |

### Pre-Configured APIs

The module creates two sample APIs:

#### 1. Authentication API
- **Path:** `/auth`
- **Backend URL:** `http://localhost:8080` (placeholder - update post-deployment)
- **Protocols:** HTTPS
- **Subscription:** Required

#### 2. Products API
- **Path:** `/products`
- **Backend URL:** `http://localhost:8081` (placeholder - update post-deployment)
- **Protocols:** HTTPS
- **Subscription:** Required

### API Version Set

Uses **Segment** versioning scheme:
```
https://<apim>.azure-api.net/auth/v1/login
https://<apim>.azure-api.net/auth/v2/login
```

### Outputs

- `apimUrl`: Gateway URL (e.g., `https://comp-poc-test-apim-dev.azure-api.net`)

### Post-Deployment Configuration

1. **Update backend URLs:**
   - Navigate to APIM > Backends > Edit
   - Replace `localhost` with actual service URLs (AKS LoadBalancer IPs or Function URLs)

2. **Add operations:**
   - APIM > APIs > Select API > Add Operation
   - Define HTTP methods, paths, request/response schemas

3. **Apply policies:**
   Example: Rate limiting
   ```xml
   <policies>
     <inbound>
       <rate-limit calls="100" renewal-period="60" />
     </inbound>
   </policies>
   ```

4. **Configure subscriptions:**
   - APIM > Subscriptions > Add subscription
   - Generate keys for client applications

---

## ⚡ function-app.bicep - Azure Functions

**Purpose:** Provision Function Apps with associated Storage Accounts and App Service Plans.

### Features

- **Auto-discovery:** CI pipeline detects functions in `src/AzureFunctions/`
- **Isolated runtime:** Uses .NET Isolated worker process
- **Managed Identity:** System-assigned for secure access to Key Vault
- **App Insights:** Integrated telemetry

### Configuration Per Function App

| Component | Configuration |
|-----------|---------------|
| **App Service Plan** | Dynamic (Consumption) or Dedicated (parameter-based) |
| **Storage Account** | Auto-created with unique name |
| **Runtime Stack** | .NET 6.0/7.0/8.0 (auto-detected from .csproj) |
| **OS** | Linux (parameter-based) |
| **Always On** | Optional (depends on plan SKU) |

### Parameters (per function)

```bicep
{
  name: "comp-poc-test-func-customer-dev"
  storageAccountName: "comppocteststcustomer"
  runtime: "DOTNET-ISOLATED|8.0"
  workerRuntime: "dotnet-isolated"
}
```

### Application Settings

Automatically configured:
- `AzureWebJobsStorage`: Connection to Storage Account
- `APPINSIGHTS_INSTRUMENTATIONKEY`: App Insights key
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: App Insights connection string
- `FUNCTIONS_WORKER_RUNTIME`: `dotnet-isolated`
- `FUNCTIONS_EXTENSION_VERSION`: `~4`

### Storage Account Naming

Pattern: `<uniqueSuffix>st<functionName><environment>`

Example:
- Function folder: `OrdersFunction`
- Generated Storage Account: `comppocteststorders...dev` (truncated to 24 chars)

---

## 🔑 workload-identity.bicep - Passwordless Authentication

**Purpose:** Enable AKS workloads to access Azure resources without secrets.

### Components

#### 1. User-Assigned Managed Identity (UAMI)

A standalone identity that can be assigned to AKS pods.

```bicep
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName  // e.g., comp-poc-test-aks-dev-wi
  location: location
}
```

#### 2. Federated Identity Credential (FIC)

Links the UAMI to a Kubernetes ServiceAccount using OIDC.

```bicep
resource fic 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: uami
  name: '${aksName}-fic'
  properties: {
    audiences: ['api://AzureADTokenExchange']
    issuer: aksOidcIssuer  // From AKS cluster
    subject: 'system:serviceaccount:${workloadNamespace}:${workloadServiceAccount}'
  }
}
```

### How It Works

```
1. Pod starts with ServiceAccount "workload-sa"
2. Kubernetes injects OIDC token into pod
3. Azure SDK exchanges token for Azure AD token
4. Pod accesses Azure resources (Key Vault, Storage, etc.)
```

**No secrets, passwords, or connection strings needed!**

### Parameters

- `workloadNamespace`: Kubernetes namespace (default: `default`)
- `workloadServiceAccount`: ServiceAccount name (default: `workload-sa`)
- `uamiName`: UAMI name (default: `<aksName>-wi`)

### Usage in Kubernetes

**Create ServiceAccount:**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-sa
  namespace: default
  annotations:
    azure.workload.identity/client-id: "<UAMI_CLIENT_ID>"
```

**Use in Deployment:**
```yaml
spec:
  serviceAccountName: workload-sa
  labels:
    azure.workload.identity/use: "true"
```

### Grant RBAC Permissions

After deployment, grant the UAMI access to resources:

```bash
# Access Key Vault
az role assignment create \
  --assignee <UAMI_CLIENT_ID> \
  --role "Key Vault Secrets User" \
  --scope <KEY_VAULT_RESOURCE_ID>

# Access Storage Account
az role assignment create \
  --assignee <UAMI_CLIENT_ID> \
  --role "Storage Blob Data Contributor" \
  --scope <STORAGE_ACCOUNT_RESOURCE_ID>
```

---

## 📋 Best Practices Summary

### Security

✅ Use Managed Identities instead of connection strings  
✅ Enable RBAC on Key Vault  
✅ Grant minimum required permissions  
✅ Use separate environments (dev/qa/prod)  
✅ Enable soft delete on Key Vault  

### Cost Optimization

✅ Use Developer SKU for APIM in non-prod  
✅ Use Free tier for AKS in POC  
✅ Use Consumption plan for Functions (pay-per-execution)  
✅ Set appropriate Log Analytics retention (30 days for POC)  

### Monitoring

✅ Enable Container Insights on AKS  
✅ Integrate all services with Application Insights  
✅ Set up alerts for critical metrics  
✅ Use Log Analytics queries for troubleshooting  

### Infrastructure as Code

✅ Use modular Bicep structure  
✅ Parameterize all resource names  
✅ Use What-If before deploying  
✅ Version control all IaC files  
✅ Document parameters and outputs  

---

## 📚 Additional Resources

- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [AKS Workload Identity](https://learn.microsoft.com/azure/aks/workload-identity-overview)
- [Azure Key Vault RBAC](https://learn.microsoft.com/azure/key-vault/general/rbac-guide)
- [APIM Policies](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)

---

**Navigation:** [🏠 Home](../../README.md) | [📚 Docs](../README.md)