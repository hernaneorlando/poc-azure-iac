# 05 - Implantação de Serviços

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [👈 Anterior](04-infrastructure-deployment.pt-BR.md)

---

## 🎯 Objetivo

Implante todos os microsserviços (AKS, Azure Functions, Logic Apps) na infraestrutura do Azure criada na etapa anterior.

## 📋 O Que Será Implantado?

| Tipo de Serviço | Serviços | Método de Implantação |
|-----------------|----------|----------------------|
| **Serviços AKS** | Autenticação, Produtos | Imagens Docker → Registro de Container do Azure → AKS |
| **Azure Functions** | FunçãoCliente, FunçãoFornecedor | Pipeline CI/CD → Aplicativos de Função |
| **Logic Apps** | LogicAppPedidos (ObterTodosOsPedidos, ObterPedidoPorId) | Manual ou CI/CD → Logic App Standard |

## 🚦 Pré-requisitos

- ✅ Infraestrutura implantada com sucesso ([Passo 04](04-infrastructure-deployment.pt-BR.md))
- ✅ Todos os serviços testados localmente ([Passo 02](02-local-development.pt-BR.md))
- ✅ Registro de Container do Azure (ACR) criado (se implantando em AKS)
- ✅ Imagens Docker construídas e marcadas

## 📦 Opções de Implantação

### Opção 1: Implantação Manual (Recomendada para POC)

Melhor para aprendizado e compreensão do processo de implantação.

### Opção 2: Pipeline CI/CD Automatizado

Melhor para ambientes de produção e colaboração em equipe.

---

## 🐳 Implantando Serviços AKS (Autenticação & Produtos)

### Passo 1: Criar Registro de Container do Azure (ACR)

```bash
# Criar ACR
az acr create \
  --name compoctestacr \
  --resource-group comp-poc-test-rg-dev \
  --sku Basic \
  --location brazilsouth

# Habilitar usuário admin (para simplicidade da POC)
az acr update --name compoctestacr --admin-enabled true

# Obter credenciais do ACR
az acr credential show --name compoctestacr
```

**Salve as credenciais:**
- Servidor de login: `compoctestacr.azurecr.io`
- Nome de usuário: `compoctestacr`
- Senha: `<da saída>`

### Passo 2: Construir e Enviar Imagens Docker

**Da raiz do projeto:**

```bash
# Construir serviço de Autenticação
cd src/AKS/Authentication
docker build -t compoctestacr.azurecr.io/auth-api:latest -f Dockerfile ..

# Construir serviço de Produtos
cd ../Products
docker build -t compoctestacr.azurecr.io/products-api:latest -f Dockerfile ..

# Fazer login no ACR
az acr login --name compoctestacr

# Enviar imagens
docker push compoctestacr.azurecr.io/auth-api:latest
docker push compoctestacr.azurecr.io/products-api:latest
```

### Passo 3: Conectar AKS ao ACR

```bash
# Anexar ACR ao cluster AKS
az aks update \
  --name comp-poc-test-aks-dev \
  --resource-group comp-poc-test-rg-dev \
  --attach-acr compoctestacr
```

Isto concede permissão ao AKS para puxar imagens do ACR.

### Passo 4: Criar Secrets do Kubernetes

Atualize secrets em `infra/k8s/auth-secrets.yaml` e `infra/k8s/products-secrets.yaml`:

```yaml
# auth-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: auth-secrets
  namespace: default
type: Opaque
stringData:
  JWT_SECRET: "sua-chave-secreta-aqui"
  # Adicione outros secrets conforme necessário
```

**Aplicar secrets:**
```bash
kubectl apply -f infra/k8s/auth-secrets.yaml
kubectl apply -f infra/k8s/products-secrets.yaml
```

### Passo 5: Atualizar Arquivos de Implantação do Kubernetes

Atualize `infra/k8s/auth-deployment.yaml` e `infra/k8s/products-deployment.yaml`:

```yaml
spec:
  containers:
  - name: auth-api
    image: compoctestacr.azurecr.io/auth-api:latest
    # ... resto da configuração
```

### Passo 6: Implantar no AKS

```bash
# Obter credenciais do AKS
az aks get-credentials \
  --name comp-poc-test-aks-dev \
  --resource-group comp-poc-test-rg-dev \
  --overwrite-existing

# Implantar serviços
kubectl apply -f infra/k8s/auth-deployment.yaml
kubectl apply -f infra/k8s/auth-service.yaml
kubectl apply -f infra/k8s/products-deployment.yaml
kubectl apply -f infra/k8s/products-service.yaml

# Verificar implantações
kubectl get pods
kubectl get services
```

**Saída esperada:**
```
NAME                            READY   STATUS    RESTARTS   AGE
auth-api-xxxxxxxxxx-xxxxx       1/1     Running   0          2m
products-api-xxxxxxxxxx-xxxxx   1/1     Running   0          2m

NAME           TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
auth-api       LoadBalancer   10.0.123.45     20.1.2.3        8080:30080/TCP
products-api   LoadBalancer   10.0.123.46     20.1.2.4        8081:30081/TCP
```

### Passo 7: Testar Serviços AKS

```bash
# Obter IPs externos
AUTH_IP=$(kubectl get service auth-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
PRODUCTS_IP=$(kubectl get service products-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Testar Autenticação
curl http://$AUTH_IP:8080/swagger

# Testar Produtos
curl http://$PRODUCTS_IP:8081/api/products
```

---

## ⚡ Implantando Azure Functions (Cliente & Fornecedor)

### Opção A: Implantação Manual via Azure CLI

```bash
# Navegue até FunçãoCliente
cd src/AzureFunctions/OrdersFunction

# Construir e publicar
dotnet publish -c Release -o ./publish

# Criar pacote de implantação
cd publish
zip -r ../deploy.zip .
cd ..

# Implantar no Azure
az functionapp deployment source config-zip \
  --name comp-poc-test-func-ordersfunction-dev \
  --resource-group comp-poc-test-rg-dev \
  --src deploy.zip

# Repetir para FunçãoFornecedor
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

### Opção B: Implantar via VS Code

1. Instale a extensão **Azure Functions** no VS Code
2. Abra a pasta `src/AzureFunctions/OrdersFunction`
3. Clique no ícone Azure → Faça login no Azure
4. Clique com botão direito na pasta da função → **Deploy to Function App**
5. Selecione assinatura e Aplicativo de Função (`comp-poc-test-func-ordersfunction-dev`)
6. Confirme a implantação
7. Repita para FunçãoFornecedor

### Passo 2: Configurar Configurações da Aplicação

```bash
# Adicionar configurações de aplicativo necessárias
az functionapp config appsettings set \
  --name comp-poc-test-func-ordersfunction-dev \
  --resource-group comp-poc-test-rg-dev \
  --settings "CUSTOM_SETTING=value"
```

### Passo 3: Testar Azure Functions

```bash
# Obter URLs do Aplicativo de Função
az functionapp show \
  --name comp-poc-test-func-ordersfunction-dev \
  --resource-group comp-poc-test-rg-dev \
  --query "defaultHostName" -o tsv

# Testar Função de Cliente
curl https://comp-poc-test-func-ordersfunction-dev.azurewebsites.net/function/customer

# Testar Função de Fornecedor
curl https://comp-poc-test-func-supplierfunction-dev.azurewebsites.net/function/supplier
```

---

## 🔄 Implantando Logic Apps (Fluxos de Pedidos)

### Passo 1: Empacotar Logic App

```bash
cd src/LogicApp/OrdersLogicApp

# Criar pacote de implantação (compactar todos os arquivos)
zip -r logicapp-deploy.zip .
```

### Passo 2: Criar Recurso Logic App Standard

```bash
# Criar Conta de Armazenamento para Logic App
az storage account create \
  --name compoctestlogicstdev \
  --resource-group comp-poc-test-rg-dev \
  --location brazilsouth \
  --sku Standard_LRS

# Criar Plano de Serviço de Aplicativo para Logic App
az appservice plan create \
  --name comp-poc-test-logic-plan-dev \
  --resource-group comp-poc-test-rg-dev \
  --location brazilsouth \
  --sku WS1 \
  --is-linux

# Criar Logic App Standard
az logicapp create \
  --name comp-poc-test-logicapp-dev \
  --resource-group comp-poc-test-rg-dev \
  --storage-account compoctestlogicstdev \
  --plan comp-poc-test-logic-plan-dev
```

### Passo 3: Implantar Fluxos

```bash
# Implantar via Azure CLI
az logicapp deployment source config-zip \
  --name comp-poc-test-logicapp-dev \
  --resource-group comp-poc-test-rg-dev \
  --src logicapp-deploy.zip
```

### Passo 4: Obter URLs de Callback de Fluxo

```bash
# Obter URL de callback para ObterTodosOsPedidos
az rest --method POST \
  --uri "https://management.azure.com/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/comp-poc-test-rg-dev/providers/Microsoft.Web/sites/comp-poc-test-logicapp-dev/hostruntime/runtime/webhooks/workflow/api/management/workflows/GetAllOrders/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview"

# Obter URL de callback para ObterPedidoPorId
az rest --method POST \
  --uri "https://management.azure.com/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/comp-poc-test-rg-dev/providers/Microsoft.Web/sites/comp-poc-test-logicapp-dev/hostruntime/runtime/webhooks/workflow/api/management/workflows/GetOrderById/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview"
```

**Salve as URLs de callback** (incluindo parâmetros `sig`).

### Passo 5: Testar Fluxos de Logic App

```bash
# Testar ObterTodosOsPedidos
curl -X GET "<URL_CALLBACK_DO_PASSO_4>"

# Testar ObterPedidoPorId
curl -X POST "<URL_CALLBACK_DO_PASSO_4>" \
  -H "Content-Type: application/json" \
  -d '{"id": "123"}'
```

---

## 🔗 Configurando Gerenciamento de API do Azure (APIM)

### Passo 1: Adicionar Serviços Backend ao APIM

**Para Serviços AKS:**
```bash
# Obter IPs de serviço do AKS
AUTH_IP=$(kubectl get service auth-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
PRODUCTS_IP=$(kubectl get service products-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Adicionar backends no APIM (via Portal Azure)
# APIM > Backends > Adicionar
# - Nome: aks-auth-backend
# - URL: http://<AUTH_IP>:8080
```

**Para Azure Functions & Logic Apps:**
- As URLs de Função estão disponíveis em Portal Azure → Aplicativo de Função → Funções → Obter URL de Função
- URLs de Logic App obtidas na etapa anterior

### Passo 2: Criar APIs no APIM

1. Navegue até **Portal Azure** > **APIM** > **APIs**
2. Clique em **Adicionar API** > **API em Branco**
3. Configure:
   - **Nome para exibição:** API de Autenticação
   - **Nome:** auth-api
   - **URL do serviço Web:** `http://<AUTH_IP>:8080`
4. Adicione operações (POST /api/auth/login, POST /api/auth/refresh-token)
5. Repita para todos os serviços

### Passo 3: Aplicar Políticas (Opcional)

Exemplo de política de limitação de taxa:

```xml
<policies>
    <inbound>
        <rate-limit calls="100" renewal-period="60" />
        <base />
    </inbound>
</policies>
```

---

## ✅ Checklist de Verificação

Após a implantação, verifique todos os serviços:

- [ ] **Autenticação AKS:** `http://<AUTH_IP>:8080/swagger`
- [ ] **Produtos AKS:** `http://<PRODUCTS_IP>:8081/api/products`
- [ ] **FunçãoCliente:** `https://comp-poc-test-func-ordersfunction-dev.azurewebsites.net/function/customer`
- [ ] **FunçãoFornecedor:** `https://comp-poc-test-func-supplierfunction-dev.azurewebsites.net/function/supplier`
- [ ] **Logic App ObterTodosOsPedidos:** Testar via URL de callback
- [ ] **Logic App ObterPedidoPorId:** Testar via URL de callback
- [ ] **Gateway APIM:** Todas as APIs acessíveis através do APIM

---

## 🔧 Solução de Problemas

### Problemas de Implantação AKS

**Problema:** Erro ImagePullBackOff
```
Erro: Falha ao puxar imagem "compoctestacr.azurecr.io/auth-api:latest"
```
- **Solução:** Certifique-se de que ACR está anexado a AKS: `az aks update --attach-acr compoctestacr ...`

**Problema:** CrashLoopBackOff
- **Solução:** Verifique logs do pod: `kubectl logs <nome-pod>`
- Verifique se secrets foram criados: `kubectl get secrets`

### Problemas do Aplicativo de Função

**Problema:** Implantação falha com "Site SCM não disponível"
- **Solução:** Aguarde alguns minutos após criação do Aplicativo de Função, depois tente novamente

**Problema:** Função retorna erro 500
- **Solução:** Verifique logs do Application Insights no Portal Azure

### Problemas de Logic App

**Problema:** Fluxos não visíveis após implantação
- **Solução:** Verifique se arquivo zip contém estrutura correta (fluxos em subdiretórios)

**Problema:** URL de callback retorna 401 Não Autorizado
- **Solução:** Certifique-se de que parâmetro `sig` está incluído na URL

---

## 🔄 Implantação Pipeline CI/CD (Avançado)

Para implantações automatizadas, consulte o **Guia de Pipelines CI/CD**:

👉 [Guia de Pipelines CI/CD](cicd-pipelines.pt-BR.md)

---

## 🎉 Parabéns!

Você implantou com sucesso todos os microsserviços no Azure!

## ⏭️ O Que Vem Depois?

- 📊 **Monitorar serviços:** Use Application Insights e Log Analytics
- 🔐 **Proteger APIs:** Configure políticas APIM e autenticação
- 📈 **Escalar serviços:** Configure auto-escaling para AKS e Aplicativos de Função
- 🔧 **Resolver problemas:** Veja [Guia de Solução de Problemas](troubleshooting.pt-BR.md)

## 📚 Recursos Adicionais

- [Melhores Práticas de AKS](https://learn.microsoft.com/azure/aks/best-practices)
- [Implantação de Azure Functions](https://learn.microsoft.com/azure/azure-functions/functions-deployment-technologies)
- [Implantação de Logic Apps](https://learn.microsoft.com/azure/logic-apps/logic-apps-deploy-azure-resource-manager-templates)
- [Políticas APIM](https://learn.microsoft.com/azure/api-management/api-management-policies)

---

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [👈 Anterior](04-infrastructure-deployment.pt-BR.md)