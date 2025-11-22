# Guia de Configuração do API Management

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [📚 Docs](../README.pt-BR.md)

---

## 🎯 Visão Geral

Este guia explica como o Azure API Management (APIM) é configurado como um **gateway unificado** para todos os serviços nesta POC:

- **Serviços AKS** (Autenticação, Produtos)
- **Azure Functions** (Clientes, Fornecedores)
- **Logic Apps** (Pedidos)

## 📊 Arquitetura

```
                    ┌─────────────────────┐
                    │                     │
    Clients  ─────▶|   APIM Gateway      │
                    │ (Single Entry Point)│
                    │                     │
                    └──────────┬──────────┘
                               │
                 ┌─────────────┼─────────────┐
                 │             │             │
          ┌──────▼─────┐  ┌────▼─────┐  ┌────▼────┐
          │    AKS     │  │Functions │  │Logic App│
          │            │  │          │  │         │
          │ • Auth     │  │• Customer│  │• Orders │
          │ • Products │  │• Supplier│  │         │
          └────────────┘  └──────────┘  └─────────┘
```

## 🛠️ Configuração do Módulo

### Parâmetros

O módulo `apim.bicep` aceita os seguintes parâmetros:

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|----------|-------------|
| `environment` | string | ✅ | Ambiente (dev/qa/prod) |
| `location` | string | ✅ | Região do Azure |
| `sku` | string | ✅ | SKU do APIM (Developer/Basic/Standard/Premium) |
| `apimName` | string | ✅ | Nome do serviço APIM |
| `publisherEmail` | string | ❌ | Email do publicador (padrão: admin@empresa.com) |
| `publisherName` | string | ❌ | Nome do publicador (padrão: Empresa Tech) |
| `aksServiceUrl` | string | ❌ | URL do LoadBalancer do AKS |
| `customerFunctionUrl` | string | ❌ | URL da Function App de Clientes |
| `supplierFunctionUrl` | string | ❌ | URL da Function App de Fornecedores |
| `logicAppUrl` | string | ❌ | URL de callback do Logic App |

### Configuração Automática

As APIs são **criadas condicionalmente** com base nas URLs fornecidas:

- Se `customerFunctionUrl` estiver vazio → API de Clientes **não** é criada
- Se `supplierFunctionUrl` estiver vazio → API de Fornecedores **não** é criada  
- Se `logicAppUrl` estiver vazio → API de Pedidos **não** é criada

**Serviços AKS são sempre criados** (Autenticação e Produtos).

## 🚀 Processo de Implantação

### Passo 1: Implantar Infraestrutura

Execute as pipelines de infraestrutura para criar o APIM (com URLs placeholder):

```bash
# CI pipeline validates
az pipelines run --name "infra_ci"

# CD pipeline deploys
az pipelines run --name "infra_cd"
```

Inicialmente, o APIM é criado com **URLs de backend placeholder** porque os serviços ainda não foram implantados.

### Passo 2: Implantar Serviços

Implante seus serviços backend:

```bash
# Deploy AKS services
kubectl apply -f infra/k8s/

# Deploy Azure Functions
az pipelines run --name "function_ci"
az pipelines run --name "function_cd"

# Logic App is deployed manually via Azure Portal
```

### Passo 3: Obter URLs dos Backends

Após os serviços serem implantados, obtenha suas URLs:

#### AKS LoadBalancer IP

```bash
# Get LoadBalancer external IP
kubectl get svc auth-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Expected output: `20.206.x.x`

**Format for APIM:** `http://20.206.x.x:8080`

#### Azure Function URLs

```bash
# Customer Function
az functionapp show \
  --name comp-poc-test-func-customerfunction-dev \
  --resource-group comp-poc-test-rg-dev \
  --query "defaultHostName" -o tsv
```

Expected output: `comp-poc-test-func-customerfunction-dev.azurewebsites.net`

**Format for APIM:** `https://comp-poc-test-func-customerfunction-dev.azurewebsites.net`

#### Logic App Callback URL

1. Go to Azure Portal > Logic App
2. Open the workflow
3. Click on "When a HTTP request is received" trigger
4. Copy the **HTTP POST URL**

**Format for APIM:** Use the full URL as-is

### Step 4: Update APIM Backend URLs

You have **two options** to update backend URLs:

#### Option A: Update via Azure Portal (Quick)

1. Go to **Azure Portal** > **API Management**
2. Navigate to **APIs** > Select API (e.g., "Authentication API")
3. Click **Settings**
4. Update **Web service URL** field
5. **Save**

Repeat for each API.

#### Option B: Re-deploy Infrastructure (Recommended)

Update `main.bicep` to pass actual URLs:

```bicep
// After AKS deployment, get LoadBalancer IP
var aksLoadBalancerIp = '20.206.x.x' // Replace with actual IP

// After Function deployment, use these URLs
var customerFunctionUrl = 'https://comp-poc-test-func-customerfunction-dev.azurewebsites.net'
var supplierFunctionUrl = 'https://comp-poc-test-func-supplierfunction-dev.azurewebsites.net'

module apim './modules/apim.bicep' = {
  name: 'apimDeployment'
  params: {
    location: location
    apimName: apimName
    environment: environment
    sku: apimSku
    aksServiceUrl: 'http://${aksLoadBalancerIp}:8080'
    customerFunctionUrl: customerFunctionUrl
    supplierFunctionUrl: supplierFunctionUrl
    logicAppUrl: logicAppUrl // Add if Logic App is deployed
  }
}
```

Then re-run `infra_cd.yaml`.

## 📖 API Endpoints

### Authentication API

**Base Path:** `https://<apim-gateway-url>/auth/v1`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | Authenticate user |
| POST | `/auth/refresh-token` | Refresh JWT token |

**Example Request:**
```bash
curl -X POST "https://comp-poc-test-apim-dev.azure-api.net/auth/v1/auth/login" \
  -H "Ocp-Apim-Subscription-Key: YOUR_SUBSCRIPTION_KEY" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'
```

### Products API

**Base Path:** `https://<apim-gateway-url>/products/v1`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/products` | Get all products |
| GET | `/products/{id}` | Get product by ID |

**Example Request:**
```bash
curl -X GET "https://comp-poc-test-apim-dev.azure-api.net/products/v1/products" \
  -H "Ocp-Apim-Subscription-Key: YOUR_SUBSCRIPTION_KEY"
```

### Customers API

**Base Path:** `https://<apim-gateway-url>/customers/v1`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/customer` | Get all customers |
| GET | `/customer/{id}` | Get customer by ID |
| POST | `/customer` | Create new customer |

**Example Request:**
```bash
curl -X GET "https://comp-poc-test-apim-dev.azure-api.net/customers/v1/customer" \
  -H "Ocp-Apim-Subscription-Key: YOUR_SUBSCRIPTION_KEY"
```

### Suppliers API

**Base Path:** `https://<apim-gateway-url>/suppliers/v1`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/supplier` | Get all suppliers |
| GET | `/supplier/{id}` | Get supplier by ID |
| POST | `/supplier` | Create new supplier |

**Example Request:**
```bash
curl -X GET "https://comp-poc-test-apim-dev.azure-api.net/suppliers/v1/supplier" \
  -H "Ocp-Apim-Subscription-Key: YOUR_SUBSCRIPTION_KEY"
```

### Orders API

**Base Path:** `https://<apim-gateway-url>/orders/v1`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/process` | Process order via Logic App |

**Example Request:**
```bash
curl -X POST "https://comp-poc-test-apim-dev.azure-api.net/orders/v1/process" \
  -H "Ocp-Apim-Subscription-Key: YOUR_SUBSCRIPTION_KEY" \
  -H "Content-Type: application/json" \
  -d '{"orderId": 123, "customerId": 456, "items": []}'
```

## 🔑 Subscription Keys

### Get Subscription Key

```bash
# List all subscriptions
az apim subscription list \
  --service-name comp-poc-test-apim-dev \
  --resource-group comp-poc-test-rg-dev \
  --output table

# Get built-in subscription (created by default)
az apim subscription show \
  --service-name comp-poc-test-apim-dev \
  --resource-group comp-poc-test-rg-dev \
  --sid master \
  --query "primaryKey" -o tsv
```

### Create Custom Subscription

```bash
az apim subscription create \
  --service-name comp-poc-test-apim-dev \
  --resource-group comp-poc-test-rg-dev \
  --subscription-id my-app-subscription \
  --display-name "My Application" \
  --scope /apis
```

## 🔧 Advanced Configuration

### Add CORS Policy

To allow browser-based applications to call the API:

1. Go to **APIs** > **All APIs** > **Inbound processing**
2. Add policy:

```xml
<cors allow-credentials="false">
    <allowed-origins>
        <origin>https://myapp.com</origin>
        <origin>http://localhost:3000</origin>
    </allowed-origins>
    <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
    </allowed-methods>
    <allowed-headers>
        <header>*</header>
    </allowed-headers>
</cors>
```

### Add Rate Limiting

To prevent abuse:

```xml
<rate-limit calls="100" renewal-period="60" />
```

This allows 100 calls per 60 seconds per subscription key.

### Add JWT Validation

To validate authentication tokens:

```xml
<validate-jwt header-name="Authorization" failed-validation-httpcode="401">
    <openid-config url="https://your-auth-server/.well-known/openid-configuration" />
    <audiences>
        <audience>your-api-audience</audience>
    </audiences>
</validate-jwt>
```

## 📊 Monitoring

### View API Analytics

1. **Azure Portal** > **API Management** > **Analytics**
2. View:
   - Request volume by API
   - Response times
   - Error rates
   - Top consumers

### Application Insights Integration

APIM automatically logs to Application Insights (if configured):

```bash
# Query API calls
az monitor app-insights query \
  --app comp-poc-test-appins-dev \
  --analytics-query "requests | where cloud_RoleName == 'comp-poc-test-apim-dev' | take 10"
```

## 🔍 Troubleshooting

### Problem: 401 Unauthorized

**Cause:** Missing or invalid subscription key

**Solution:**
```bash
# Verify subscription key is correct
az apim subscription show --sid master \
  --service-name comp-poc-test-apim-dev \
  --resource-group comp-poc-test-rg-dev
```

### Problem: 502 Bad Gateway

**Cause:** Backend service is unreachable

**Solution:**
1. Verify backend service is running
2. Check backend URL in APIM is correct
3. Test backend directly (bypass APIM)

### Problem: 404 Not Found

**Cause:** Incorrect API path or operation not defined

**Solution:**
- Verify path format: `/<api-path>/v1/<operation-path>`
- Check API and operation definitions in APIM

---

**Navigation:** [🏠 Home](../../README.md) | [📚 Docs](../README.md)
