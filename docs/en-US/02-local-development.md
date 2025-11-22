# 02 - Local Development Setup

**Navigation:** [🏠 Home](../../README.md) | [👈 Previous](01-project-overview.md) | [👉 Next](03-devops-setup.md)

---

## 🎯 Goal

Set up and run all services **locally on your machine** for development and testing.

## 🚦 Prerequisites

Install these tools before proceeding:

### Required for All Services
- ✅ [Docker Desktop](https://www.docker.com/products/docker-desktop/) - Container runtime
- ✅ [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) - For C# services
- ✅ [Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local) - For Functions and Logic Apps

### Required for AKS Services
- ✅ [Minikube](https://minikube.sigs.k8s.io/docs/start/) - Local Kubernetes cluster
- ✅ [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- ✅ Docker Hub account - For hosting container images

### Required for Logic Apps
- ✅ [Node.js](https://nodejs.org/) - Logic App runtime dependency

### Recommended
- ✅ [Visual Studio Code](https://code.visualstudio.com/) - Code editor
- ✅ [Postman](https://www.postman.com/) or similar - For API testing

## 📋 Quick Start Checklist

Follow this order to set up all services:

### Step 1: Start Shared Dependencies

```powershell
# Start Azurite (storage emulator for Functions & Logic Apps)
docker run -d -p 10000:10000 -p 10001:10001 -p 10002:10002 `
  --name azurite mcr.microsoft.com/azure-storage/azurite

# Start Minikube (for AKS services)
minikube start
```

### Step 2: AKS Services (Authentication & Products)

📖 **Detailed guide:** [AKS Local Setup](src-aks-readme.md)

**Quick steps:**
1. Build Docker images for Authentication and Products
2. Push images to Docker Hub
3. Create Kubernetes secrets
4. Deploy to Minikube
5. Use port-forward to access services

```powershell
# Example: Access Products service
kubectl port-forward service/products-api 8081:8081
# Then open: http://localhost:8081/swagger
> **Note:** Port-forwarding is required on all platforms (Windows, Linux, macOS) when using Minikube with Docker driver.
```

### Step 3: Azure Functions (Customer & Supplier)

📖 **Detailed guide:** [Azure Functions Local Setup](src-azurefunctions-readme.md)

**Quick steps:**
1. Ensure Azurite is running
2. Navigate to function directory
3. Run `func start`

```powershell
# Run CustomerFunction
cd src/AzureFunctions/OrdersFunction
func start
# Access at: http://localhost:7071/function/customer

# Run SupplierFunction (in another terminal)
cd src/AzureFunctions/SupplierFunction
func start --port 7072
# Access at: http://localhost:7072/function/supplier
```

### Step 4: Logic Apps (Orders & Cart)

📍 **Detailed guide:** [Logic Apps Local Setup](src-logicapp-readme.md)

**Quick steps:**
1. Ensure Azurite is running
2. Navigate to Logic App directory
3. Run `func start`
4. Obtain callback URLs for testing

```powershell
cd src/LogicApp/OrdersLogicApp
func start

# Get callback URL
$response = Invoke-RestMethod `
  -Uri "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/GetAllOrders/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview" `
  -Method POST

Write-Host $response.value
# Use the returned URL to test
```

## 🧪 Testing Your Setup

Once all services are running, test each endpoint:

### AKS Services
```powershell
# Products - Get all
Invoke-RestMethod -Uri "http://localhost:8081/api/products" -Method GET

# Authentication - Login (example)
Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method POST `
  -Body '{"username":"test","password":"test"}' `
  -ContentType "application/json"
```

### Azure Functions
```powershell
# Customer - Get all
Invoke-RestMethod -Uri "http://localhost:7071/function/customer" -Method GET

# Supplier - Get by ID
Invoke-RestMethod -Uri "http://localhost:7072/function/supplier/1" -Method GET
```

### Logic App
```powershell
# Use the callback URL obtained earlier
Invoke-RestMethod -Uri "<CALLBACK_URL_FROM_STEP_4>" -Method GET
```

## 🔧 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **Port already in use** | Change port with `func start --port <other-port>` or stop conflicting process |
| **Azurite not running** | Verify with `docker ps`, start if needed |
| **Minikube not accessible** | Run `minikube status`, restart if needed |
| **Cannot build Docker image** | Ensure Docker Desktop is running |
| **Logic App: MissingApiVersionParameter** | Add `?api-version=2022-05-01` to URL |
| **Logic App: DirectApiAuthorizationRequired** | Use complete callback URL with `sig` parameter |

### Service-Specific Troubleshooting

- **AKS:** See [AKS Troubleshooting](src-aks-readme.md#troubleshooting)
- **Functions:** See [Functions Troubleshooting](src-azurefunctions-readme.md#troubleshooting)
- **Logic Apps:** See [Logic Apps Troubleshooting](src-logicapp-readme.md#troubleshooting)

## 🎓 Development Workflow

**Recommended workflow for local development:**

1. **Start dependencies** (Azurite, Minikube)
2. **Run services** you're working on
3. **Make code changes**
4. **Rebuild/restart** affected services
5. **Test** via Swagger UI or Postman
6. **Commit** when satisfied

### Hot Reload Tips

- **AKS Services:** Rebuild Docker image and redeploy to Minikube
- **Functions:** `func start` supports hot reload for code changes
- **Logic App:** Restart `func start` after workflow changes

## 📊 Local Development Architecture

When running locally, your architecture looks like this:

```
Your Machine
├── Minikube (localhost:30080, :30081)
│   ├── Authentication Service
│   └── Products Service
│
├── CustomerFunction (localhost:7071)
├── SupplierFunction (localhost:7072)
|├── OrdersLogicApp (localhost:7071)
|├── CartLogicApp (localhost:7073)
│
└── Azurite (localhost:10000-10002)
    └── Storage emulation
```

## ⏭️ What's Next?

- ✅ **All services running?** Great! Try making code changes and testing
- 🔄 **Want to iterate faster?** Check service-specific READMEs for development tips
- ☁️ **Ready for Azure?** Proceed to [Azure DevOps Setup](03-devops-setup.md)

## 📚 Additional Resources

- [AKS Local Development Guide](src-aks-readme.md)
- [Azure Functions Local Development Guide](src-azurefunctions-readme.md)
- [Logic App Local Development Guide](src-logicapp-readme.md)
- [Troubleshooting Guide](troubleshooting.md)

---

**Navigation:** [🏠 Home](../../README.md) | [👈 Previous](01-project-overview.md) | [👉 Next](03-devops-setup.md)
