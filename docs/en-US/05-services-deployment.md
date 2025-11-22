# 05 - Services Deployment

**Navigation:** [🏠 Home](../../README.md) | [👈 Previous](04-infrastructure-deployment.md)

---

## 🎯 Goal

Deploy all microservices (AKS, Azure Functions, Logic Apps) to the Azure infrastructure created in the previous step.

## 📋 What Gets Deployed?

| Service Type | Services | Deployment Method |
|--------------|----------|-------------------|
| **AKS Services** | Authentication, Products | Docker images → Azure Container Registry → AKS |
| **Azure Functions** | CustomerFunction, SupplierFunction | CI/CD pipeline → Function Apps |
| **Logic Apps** | OrdersLogicApp (GetAllOrders, GetOrderById) | Manual or CI/CD → Logic App Standard |

## 🚦 Prerequisites

- ✅ Infrastructure deployed successfully ([Step 04](04-infrastructure-deployment.md))
- ✅ All services tested locally ([Step 02](02-local-development.md))
- ✅ Azure Container Registry (ACR) created (if deploying to AKS)
- ✅ Docker images built and tagged

## 📦 Deployment Options

### Option 1: Manual Deployment (Recommended for POC)

Best for learning and understanding the deployment process.

### Option 2: Automated CI/CD Pipeline

Best for production environments and team collaboration.

---

## 🐳 Deploying AKS Services (Authentication & Products)

### Step 1: Create Azure Container Registry (ACR)

```bash
# Create ACR
az acr create \
  --name compoctestacr \
  --resource-group comp-poc-test-rg-dev \
  --sku Basic \
  --location brazilsouth

# Enable admin user (for POC simplicity)
az acr update --name compoctestacr --admin-enabled true

# Get ACR credentials
az acr credential show --name compoctestacr
```

**Save the credentials:**
- Login server: `compoctestacr.azurecr.io`
- Username: `compoctestacr`
- Password: `<from output>`

### Step 2: Build and Push Docker Images

**From the project root:**

```bash
# Build Authentication service
cd src/AKS/Authentication
docker build -t compoctestacr.azurecr.io/auth-api:latest -f Dockerfile ..

# Build Products service
cd ../Products
docker build -t compoctestacr.azurecr.io/products-api:latest -f Dockerfile ..

# Login to ACR
az acr login --name compoctestacr

# Push images
docker push compoctestacr.azurecr.io/auth-api:latest
docker push compoctestacr.azurecr.io/products-api:latest
```

### Step 3: Connect AKS to ACR

```bash
# Attach ACR to AKS cluster
az aks update \
  --name comp-poc-test-aks-dev \
  --resource-group comp-poc-test-rg-dev \
  --attach-acr compoctestacr
```

This grants AKS permission to pull images from ACR.

### Step 4: Create Kubernetes Secrets

Update secrets in `infra/k8s/auth-secrets.yaml` and `infra/k8s/products-secrets.yaml`:

```yaml
# auth-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: auth-secrets
  namespace: default
type: Opaque
stringData:
  JWT_SECRET: "your-secret-key-here"
  # Add other secrets as needed
```

**Apply secrets:**
```bash
kubectl apply -f infra/k8s/auth-secrets.yaml
kubectl apply -f infra/k8s/products-secrets.yaml
```

### Step 5: Update Kubernetes Deployment Files

Update `infra/k8s/auth-deployment.yaml` and `infra/k8s/products-deployment.yaml`:

```yaml
spec:
  containers:
  - name: auth-api
    image: compoctestacr.azurecr.io/auth-api:latest
    # ... rest of config
```

### Step 6: Deploy to AKS

```bash
# Get AKS credentials
az aks get-credentials \
  --name comp-poc-test-aks-dev \
  --resource-group comp-poc-test-rg-dev \
  --overwrite-existing

# Deploy services
kubectl apply -f infra/k8s/auth-deployment.yaml
kubectl apply -f infra/k8s/auth-service.yaml
kubectl apply -f infra/k8s/products-deployment.yaml
kubectl apply -f infra/k8s/products-service.yaml

# Verify deployments
kubectl get pods
kubectl get services
```

**Expected output:**
```
NAME                            READY   STATUS    RESTARTS   AGE
auth-api-xxxxxxxxxx-xxxxx       1/1     Running   0          2m
products-api-xxxxxxxxxx-xxxxx   1/1     Running   0          2m

NAME           TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
auth-api       LoadBalancer   10.0.123.45     20.1.2.3        8080:30080/TCP
products-api   LoadBalancer   10.0.123.46     20.1.2.4        8081:30081/TCP
```

### Step 7: Test AKS Services

```bash
# Get external IPs
AUTH_IP=$(kubectl get service auth-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
PRODUCTS_IP=$(kubectl get service products-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test Authentication
curl http://$AUTH_IP:8080/swagger

# Test Products
curl http://$PRODUCTS_IP:8081/api/products
```

---

## ⚡ Deploying Azure Functions (Customer & Supplier)

### Option A: Manual Deployment via Azure CLI

```bash
# Navigate to CustomerFunction
cd src/AzureFunctions/OrdersFunction

# Build and publish
dotnet publish -c Release -o ./publish

# Create deployment package
cd publish
zip -r ../deploy.zip .
cd ..

# Deploy to Azure
az functionapp deployment source config-zip \
  --name comp-poc-test-func-ordersfunction-dev \
  --resource-group comp-poc-test-rg-dev \
  --src deploy.zip

# Repeat for SupplierFunction
cd ../SupplierFunction
dotnet publish -c Release -o ./publish
cd publish
zip -r ../deploy.zip .
cd ..

az functionapp deployment source config-zip \
  --name comp-poc-test-func-supplierfunction-dev \
  --resource-group comp-poc-test-rg-dev \
  --src deploy.zip
```

### Option B: Deploy via VS Code

1. Install **Azure Functions** extension in VS Code
2. Open `src/AzureFunctions/OrdersFunction` folder
3. Click Azure icon → Sign in to Azure
4. Right-click on function folder → **Deploy to Function App**
5. Select subscription and Function App (`comp-poc-test-func-ordersfunction-dev`)
6. Confirm deployment
7. Repeat for SupplierFunction

### Step 2: Configure Application Settings

```bash
# Add any required app settings
az functionapp config appsettings set \
  --name comp-poc-test-func-ordersfunction-dev \
  --resource-group comp-poc-test-rg-dev \
  --settings "CUSTOM_SETTING=value"
```

### Step 3: Test Azure Functions

```bash
# Get Function App URLs
az functionapp show \
  --name comp-poc-test-func-ordersfunction-dev \
  --resource-group comp-poc-test-rg-dev \
  --query "defaultHostName" -o tsv

# Test Customer Function
curl https://comp-poc-test-func-ordersfunction-dev.azurewebsites.net/function/customer

# Test Supplier Function
curl https://comp-poc-test-func-supplierfunction-dev.azurewebsites.net/function/supplier
```

---

## 🔄 Deploying Logic Apps (Orders Workflows)

### Step 1: Package Logic App

```bash
cd src/LogicApp/OrdersLogicApp

# Create deployment package (zip all files)
zip -r logicapp-deploy.zip .
```

### Step 2: Create Logic App Standard Resource

```bash
# Create Storage Account for Logic App
az storage account create \
  --name compoctestlogicstdev \
  --resource-group comp-poc-test-rg-dev \
  --location brazilsouth \
  --sku Standard_LRS

# Create App Service Plan for Logic App
az appservice plan create \
  --name comp-poc-test-logic-plan-dev \
  --resource-group comp-poc-test-rg-dev \
  --location brazilsouth \
  --sku WS1 \
  --is-linux

# Create Logic App Standard
az logicapp create \
  --name comp-poc-test-logicapp-dev \
  --resource-group comp-poc-test-rg-dev \
  --storage-account compoctestlogicstdev \
  --plan comp-poc-test-logic-plan-dev
```

### Step 3: Deploy Workflows

```bash
# Deploy via Azure CLI
az logicapp deployment source config-zip \
  --name comp-poc-test-logicapp-dev \
  --resource-group comp-poc-test-rg-dev \
  --src logicapp-deploy.zip
```

### Step 4: Get Workflow Callback URLs

```bash
# Get callback URL for GetAllOrders
az rest --method POST \
  --uri "https://management.azure.com/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/comp-poc-test-rg-dev/providers/Microsoft.Web/sites/comp-poc-test-logicapp-dev/hostruntime/runtime/webhooks/workflow/api/management/workflows/GetAllOrders/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview"

# Get callback URL for GetOrderById
az rest --method POST \
  --uri "https://management.azure.com/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/comp-poc-test-rg-dev/providers/Microsoft.Web/sites/comp-poc-test-logicapp-dev/hostruntime/runtime/webhooks/workflow/api/management/workflows/GetOrderById/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview"
```

**Save the callback URLs** (including `sig` parameters).

### Step 5: Test Logic App Workflows

```bash
# Test GetAllOrders
curl -X GET "<CALLBACK_URL_FROM_STEP_4>"

# Test GetOrderById
curl -X POST "<CALLBACK_URL_FROM_STEP_4>" \
  -H "Content-Type: application/json" \
  -d '{"id": "123"}'
```

---

## 🔗 Configuring Azure API Management (APIM)

### Step 1: Add Backend Services to APIM

**For AKS Services:**
```bash
# Get AKS service IPs
AUTH_IP=$(kubectl get service auth-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
PRODUCTS_IP=$(kubectl get service products-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Add backends in APIM (via Azure Portal)
# APIM > Backends > Add
# - Name: aks-auth-backend
# - URL: http://<AUTH_IP>:8080
```

**For Azure Functions & Logic Apps:**
- Function URLs are available in Azure Portal → Function App → Functions → Get Function URL
- Logic App URLs obtained in previous step

### Step 2: Create APIs in APIM

1. Navigate to **Azure Portal** > **APIM** > **APIs**
2. Click **Add API** > **Blank API**
3. Configure:
   - **Display name:** Authentication API
   - **Name:** auth-api
   - **Web service URL:** `http://<AUTH_IP>:8080`
4. Add operations (POST /api/auth/login, POST /api/auth/refresh-token)
5. Repeat for all services

### Step 3: Apply Policies (Optional)

Example rate limiting policy:

```xml
<policies>
    <inbound>
        <rate-limit calls="100" renewal-period="60" />
        <base />
    </inbound>
</policies>
```

---

## ✅ Verification Checklist

After deployment, verify all services:

- [ ] **AKS Authentication:** `http://<AUTH_IP>:8080/swagger`
- [ ] **AKS Products:** `http://<PRODUCTS_IP>:8081/api/products`
- [ ] **CustomerFunction:** `https://comp-poc-test-func-ordersfunction-dev.azurewebsites.net/function/customer`
- [ ] **SupplierFunction:** `https://comp-poc-test-func-supplierfunction-dev.azurewebsites.net/function/supplier`
- [ ] **Logic App GetAllOrders:** Test via callback URL
- [ ] **Logic App GetOrderById:** Test via callback URL
- [ ] **APIM Gateway:** All APIs accessible through APIM

---

## 🔧 Troubleshooting

### AKS Deployment Issues

**Problem:** ImagePullBackOff error
```
Error: Failed to pull image "compoctestacr.azurecr.io/auth-api:latest"
```
- **Solution:** Ensure ACR is attached to AKS: `az aks update --attach-acr compoctestacr ...`

**Problem:** CrashLoopBackOff
- **Solution:** Check pod logs: `kubectl logs <pod-name>`
- Verify secrets are created: `kubectl get secrets`

### Function App Issues

**Problem:** Deployment fails with "SCM site not available"
- **Solution:** Wait a few minutes after Function App creation, then retry deployment

**Problem:** Function returns 500 error
- **Solution:** Check Application Insights logs in Azure Portal

### Logic App Issues

**Problem:** Workflows not visible after deployment
- **Solution:** Verify zip file contains correct structure (workflows in subdirectories)

**Problem:** Callback URL returns 401 Unauthorized
- **Solution:** Ensure `sig` parameter is included in URL

---

## 🔄 CI/CD Pipeline Deployment (Advanced)

For automated deployments, refer to the **CI/CD Pipelines Guide**:

👉 [CI/CD Pipelines Guide](cicd-pipelines.md)

---

## 🎉 Congratulations!

You've successfully deployed all microservices to Azure! 

## ⏭️ What's Next?

- 📊 **Monitor services:** Use Application Insights and Log Analytics
- 🔐 **Secure APIs:** Configure APIM policies and authentication
- 📈 **Scale services:** Configure autoscaling for AKS and Function Apps
- 🔧 **Troubleshoot issues:** See [Troubleshooting Guide](troubleshooting.md)

## 📚 Additional Resources

- [AKS Best Practices](https://learn.microsoft.com/azure/aks/best-practices)
- [Azure Functions Deployment](https://learn.microsoft.com/azure/azure-functions/functions-deployment-technologies)
- [Logic Apps Deployment](https://learn.microsoft.com/azure/logic-apps/logic-apps-deploy-azure-resource-manager-templates)
- [APIM Policies](https://learn.microsoft.com/azure/api-management/api-management-policies)

---

**Navigation:** [🏠 Home](../../README.md) | [👈 Previous](04-infrastructure-deployment.md)
