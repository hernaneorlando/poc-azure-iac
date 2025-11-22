# Guia de Solução de Problemas

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [📚 Docs](../README.pt-BR.md)

---

## 🎯 Visão Geral

Este guia cobre problemas comuns e soluções em todos os componentes da POC.

## 📑 Tabela de Conteúdos

- [Problemas de Desenvolvimento Local](#-problemas-de-desenvolvimento-local)
- [Problemas de Pipeline Azure DevOps](#-problemas-de-pipeline-azure-devops)
- [Problemas de Implantação de Infraestrutura](#-problemas-de-implantação-de-infraestrutura)
- [Problemas de AKS/Kubernetes](#-problemas-de-akskubernetes)
- [Problemas de Azure Functions](#-problemas-de-azure-functions)
- [Problemas de Logic Apps](#-problemas-de-logic-apps)
- [Problemas de Conectividade e Rede](#-problemas-de-conectividade-e-rede)
- [Problemas de Segurança e Permissões](#-problemas-de-segurança-e-permissões)

---

## 🖥️ Problemas de Desenvolvimento Local

### Problemas de Minikube

#### Problema: Minikube não inicia

**Sintomas:**
```
😄  minikube v1.32.0 on Windows 11
❌  Exiting due to HOST_VIRT_UNAVAILABLE: Failed to start host: ...
```

**Soluções:**

1. **Verifique se virtualização está habilitada:**
   ```powershell
   # Windows
   Get-ComputerInfo | Select-Object -ExpandProperty HyperVisorPresent
   # Deve retornar: True
   ```

2. **Tente driver diferente:**
   ```bash
   minikube start --driver=docker
   # ou
   minikube start --driver=hyperv
   ```

3. **Exclua e recrie:**
   ```bash
   minikube delete
   minikube start
   ```

4. **Verifique recursos do sistema:**
   - Certifique-se de ter pelo menos 2GB RAM disponível
   - Certifique-se de ter pelo menos 20GB de espaço em disco

#### Problema: Comandos kubectl falham após inicialização do Minikube

**Sintomas:**
```
Unable to connect to the server: dial tcp 127.0.0.1:... connectex: No connection could be made
```

**Solução:**
```bash
# Defina contexto para minikube
kubectl config use-context minikube

# Verifique
kubectl cluster-info
```

#### Problema: Port-forward não funciona

**Sintomas:**
- `kubectl port-forward` sucede mas não consegue acessar `localhost:<PORT>`

**Soluções:**

1. **Verifique status do pod:**
   ```bash
   kubectl get pods
   # Certifique-se de que pod está Running
   ```

2. **Verifique se serviço existe:**
   ```bash
   kubectl get services
   ```

3. **Tente porta local diferente:**
   ```bash
   kubectl port-forward service/products-api 8082:8081
   ```

4. **Verifique firewall:**
   - Windows: Permita kubectl através do firewall
   - Desabilite VPN se ativa

### Problemas do Azure Functions Core Tools

#### Problema: "func: command not found"

**Solução:**
```bash
# Instale Azure Functions Core Tools
npm install -g azure-functions-core-tools@4

# Verifique instalação
func --version
```

#### Problema: Função não inicia - "Missing AzureWebJobsStorage"

**Sintomas:**
```
Microsoft.Azure.WebJobs.Host: Error indexing method...
Missing value for AzureWebJobsStorage in local.settings.json
```

**Solução:**

Adicione a `local.settings.json`:
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated"
  }
}
```

Certifique-se de que Azurite está em execução:
```bash
docker ps | grep azurite
# Se não estiver executando:
docker start azurite
```

#### Problema: Porta já em uso

**Sintomas:**
```
Failed to start host: Port 7071 is already in use
```

**Soluções:**

1. **Altere a porta:**
   ```bash
   func start --port 7072
   ```

2. **Encontre e finalize o processo:**
   ```powershell
   # Windows
   netstat -ano | findstr :7071
   taskkill /PID <PID> /F

   # Linux/macOS
   lsof -ti:7071 | xargs kill -9
   ```

### Problemas de Execução Local do Logic App

#### Problema: Logic App não inicia - Node.js não encontrado

**Sintomas:**
```
Error: Cannot find module 'node'
```

**Solução:**
```bash
# Instale Node.js (necessário para runtime do Logic Apps)
# Baixe de https://nodejs.org/

# Verifique instalação
node --version
# Deve mostrar v18.x ou v20.x
```

#### Problema: Erro "MissingApiVersionParameter"

**Sintomas:**
```
Status code: 400
{"error":{"code":"MissingApiVersionParameter",...}}
```

**Solução:**

Adicione `api-version` à solicitação de URL de callback:
```bash
curl -X POST "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/GetAllOrders/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview"
```

#### Problema: Fluxos não detectados após inicialização

**Sintomas:**
- `func start` sucede mas nenhum fluxo listado

**Solução:**

Verifique estrutura de pasta:
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

Cada fluxo deve estar em seu próprio subdiretório com `workflow.json`.

---

## 🔄 Problemas de Pipeline Azure DevOps

### Problemas de Conexão de Serviço

#### Problema: "Service connection not found"

**Sintomas:**
```
##[error]There was a resource authorization issue: 
"POC-Azure-Connection could not be found."
```

**Soluções:**

1. **Verifique nome da conexão de serviço:**
   - Azure DevOps > Project Settings > Service connections
   - Certifique-se de que nome corresponde a `azureSubscription` em YAML

2. **Conceda permissão ao pipeline:**
   - Service connections > Selecione conexão > Security
   - Verifique "Grant access permission to all pipelines"
   - Ou autorize pipeline específico

#### Problema: "Forbidden" ou "Insufficient permissions"

**Sintomas:**
```
##[error]The client '...' does not have authorization to perform action 
'Microsoft.Resources/deployments/write'
```

**Soluções:**

1. **Verifique atribuições RBAC:**
   ```bash
   # Obtenha Object ID do service principal da conexão de serviço
   
   # Verifique atribuições de papel atuais
   az role assignment list \
     --assignee <SP_OBJECT_ID> \
     --resource-group comp-poc-test-rg-dev
   ```

2. **Atribua papéis necessários:**
   ```bash
   # Nível de assinatura: Reader
   az role assignment create \
     --assignee <SP_OBJECT_ID> \
     --role Reader \
     --scope /subscriptions/<SUB_ID>
   
   # Nível de RG: Contributor
   az role assignment create \
     --assignee <SP_OBJECT_ID> \
     --role Contributor \
     --scope /subscriptions/<SUB_ID>/resourceGroups/comp-poc-test-rg-dev
   ```

### Problemas de Execução de Pipeline

#### Problema: Pipeline atinge tempo limite

**Sintomas:**
- Pipeline executa por 60+ minutos e atinge tempo limite

**Soluções:**

1. **Para Infrastructure CD:**
   - Criação de APIM pode levar 45+ minutos
   - Verifique Portal Azure > Resource Group > Deployments
   - Se implantação ainda em progresso, aguarde

2. **Aumente tempo limite:**
   ```yaml
   - task: AzureCLI@2
     timeoutInMinutes: 120
   ```

#### Problema: "Resource Group not found"

**Sintomas:**
```
(ResourceGroupNotFound) Resource group 'comp-poc-test-rg-dev' could not be found
```

**Solução:**

Crie Grupo de Recursos antes de executar pipeline:
```bash
az group create \
  --name comp-poc-test-rg-dev \
  --location brazilsouth \
  --tags environment=dev
```

#### Problema: Build do Bicep falha

**Sintomas:**
```
Error BCP057: The name "..." does not exist in the current context
```

**Soluções:**

1. **Teste localmente:**
   ```bash
   az bicep build --file infra/main.bicep
   ```

2. **Problemas comuns:**
   - Erro de digitação em nome de parâmetro/variável
   - Referência de módulo ausente
   - Nome de propriedade incorreto de recurso

3. **Atualize Bicep:**
   ```bash
   az bicep upgrade
   ```

---

## ☁️ Problemas de Implantação de Infraestrutura

### Problemas de Provedor de Recursos

#### Problema: "Resource provider not registered"

**Sintomas:**
```
Code: MissingSubscriptionRegistration
Message: The subscription is not registered to use namespace 'Microsoft.ContainerService'
```

**Solução:**

Registre provedores necessários:
```bash
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ApiManagement
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.Web

# Verifique status de registro
az provider show \
  --namespace Microsoft.ContainerService \
  --query "registrationState"
```

**Nota:** Registro leva aproximadamente 5 minutos.

### Problemas de Key Vault

#### Problema: Nome do Key Vault já existe globalmente

**Sintomas:**
```
Error: (VaultAlreadyExists) A vault with the same name already exists in deleted state
```

**Soluções:**

1. **Limpe vault excluído de forma reversível:**
   ```bash
   az keyvault purge --name comp-poc-test-kv-dev
   ```

2. **Use nome diferente:**
   - Altere parâmetro `keyVaultName`
   - Nomes do Key Vault devem ser globalmente únicos

#### Problema: Não consegue acessar secrets do Key Vault

**Sintomas:**
```
(Forbidden) The user, group or application '...' does not have secrets get permission
```

**Solução:**

Conceda papel RBAC:
```bash
az role assignment create \
  --assignee <IDENTITY_CLIENT_ID> \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.KeyVault/vaults/<KV_NAME>
```

### Problemas de APIM

#### Problema: Criação de APIM leva muito tempo

**Sintomas:**
- Implantação travada em APIM por 30+ minutos

**Soluções:**

- **Comportamento normal:** Criação de APIM (SKU Developer) leva 20-45 minutos
- Verifique Portal Azure para progresso
- Não cancele implantação a menos que exceda 60 minutos

#### Problema: Nome de APIM já em uso

**Sintomas:**
```
Error: (ServiceNameNotAvailable) Service name is not available
```

**Solução:**

- Nomes de APIM devem ser globalmente únicos
- Altere parâmetro `apimName` para algo único

---

## ☸️ Problemas de AKS/Kubernetes

### Problemas de Pull de Imagem

#### Problema: ImagePullBackOff

**Sintomas:**
```bash
kubectl get pods
NAME                    READY   STATUS             RESTARTS   AGE
auth-api-xxxxx-xxxxx   0/1     ImagePullBackOff   0          2m
```

**Soluções:**

1. **Verifique nome da imagem:**
   ```bash
   kubectl describe pod <POD_NAME>
   # Procure por mensagem "Failed to pull image"
   ```

2. **Verifique se ACR está anexado:**
   ```bash
   az aks show \
     --name comp-poc-test-aks-dev \
     --resource-group comp-poc-test-rg-dev \
     --query "servicePrincipalProfile"
   
   # Anexe ACR
   az aks update \
     --name comp-poc-test-aks-dev \
     --resource-group comp-poc-test-rg-dev \
     --attach-acr compoctestacr
   ```

3. **Verifique se imagem existe em ACR:**
   ```bash
   az acr repository list --name compoctestacr
   az acr repository show-tags --name compoctestacr --repository auth-api
   ```

### Problemas de Pod Crash

#### Problema: CrashLoopBackOff

**Sintomas:**
```bash
kubectl get pods
NAME                    READY   STATUS             RESTARTS   AGE
auth-api-xxxxx-xxxxx   0/1     CrashLoopBackOff   5          5m
```

**Soluções:**

1. **Verifique logs do pod:**
   ```bash
   kubectl logs <POD_NAME>
   
   # Verifique logs de contêiner anterior
   kubectl logs <POD_NAME> --previous
   ```

2. **Causas comuns:**
   - Variáveis de ambiente ausentes
   - Crash de aplicação na inicialização
   - Configuração de porta incorreta
   - Secrets ausentes

3. **Descreva pod para eventos:**
   ```bash
   kubectl describe pod <POD_NAME>
   # Procure na seção Events
   ```

4. **Verifique se secrets existem:**
   ```bash
   kubectl get secrets
   
   # Verifique conteúdo do secret (codificado em base64)
   kubectl get secret auth-secrets -o yaml
   ```

### Problemas de Service/LoadBalancer

#### Problema: IP externo pendente para sempre

**Sintomas:**
```bash
kubectl get services
NAME       TYPE           EXTERNAL-IP   PORT(S)
auth-api   LoadBalancer   <pending>     8080:30080/TCP
```

**Soluções:**

1. **Minikube (local):**
   - Tipo LoadBalancer não funciona diretamente no Minikube
   - Use `kubectl port-forward` em vez disso:
     ```bash
     kubectl port-forward service/auth-api 8080:8080
     ```
   
   - Ou use `minikube tunnel` (requer admin/sudo):
     ```bash
     minikube tunnel
     ```

2. **AKS (Azure):**
   - Verifique se AKS tem permissões para criar IPs públicos
   - Verifique se grupos de segurança de rede permitem tráfego
   - Verifique Portal Azure para recurso Load Balancer

#### Problema: Não consegue conectar ao serviço

**Sintomas:**
- Serviço tem IP externo mas conexão recusada

**Soluções:**

1. **Verifique se pod está em execução:**
   ```bash
   kubectl get pods
   ```

2. **Verifique endpoints do serviço:**
   ```bash
   kubectl get endpoints
   # Deve mostrar IPs do pod
   ```

3. **Teste de dentro do cluster:**
   ```bash
   kubectl run -it --rm debug --image=busybox --restart=Never -- sh
   wget -O- http://auth-api:8080/api/auth/login
   ```

4. **Verifique configuração de porta:**
   - Certifique-se de que `targetPort` corresponde à porta do contêiner
   - Certifique-se de que `port` é o que você está acessando externamente

---

## ⚡ Problemas de Azure Functions

### Problemas de Implantação

#### Problema: Implantação falha com "SCM site not available"

**Sintomas:**
```
Error: The service is unavailable
```

**Solução:**

Aguarde 2-3 minutos após criação do Function App, depois tente novamente a implantação.

#### Problema: Implantação sucede mas função retorna 404

**Sintomas:**
```bash
curl https://comp-poc-test-func-customer-dev.azurewebsites.net/function/customer
# Retorna: 404 Not Found
```

**Soluções:**

1. **Verifique rota da função:**
   - Verifique atributo `[Function("CustomerGet")]`
   - Verifique `[HttpTrigger(..., Route = "function/customer")]`

2. **Verifique status de host da função:**
   ```bash
   az functionapp show \
     --name comp-poc-test-func-customer-dev \
     --resource-group comp-poc-test-rg-dev \
     --query "state"
   ```

3. **Visualize logs da função:**
   - Portal Azure > Function App > Log stream
   - Verifique erros de inicialização

#### Problema: Função retorna erro 500

**Soluções:**

1. **Verifique Application Insights:**
   - Portal Azure > Function App > Application Insights
   - Visualize exceções e rastreamentos

2. **Habilite erros detalhados:**
   ```bash
   az functionapp config appsettings set \
     --name comp-poc-test-func-customer-dev \
     --resource-group comp-poc-test-rg-dev \
     --settings "FUNCTIONS_EXTENSION_VERSION=~4" "AzureWebJobsStorage=<CONNECTION_STRING>"
   ```

3. **Verifique dependências:**
   - Certifique-se de que todos os pacotes NuGet foram restaurados
   - Verifique se versão .NET corresponde ao runtime do Function App

### Problemas de Runtime

#### Problema: Timeout de inicialização a frio

**Sintomas:**
- Primeira solicitação à função atinge tempo limite
- Solicitações subsequentes funcionam bem

**Soluções:**

1. **Aumente timeout (limitação do plano Consumption):**
   - Padrão: 5 minutos
   - Máx: 10 minutos

2. **Use plano Premium ou Dedicated:**
   ```bash
   az functionapp plan create \
     --name premium-plan \
     --resource-group comp-poc-test-rg-dev \
     --sku EP1
   ```

3. **Habilite "Always On" (Premium/Dedicated apenas):**
   ```bash
   az functionapp config set \
     --name comp-poc-test-func-customer-dev \
     --resource-group comp-poc-test-rg-dev \
     --always-on true
   ```

---

## 🔄 Problemas de Logic Apps

### Problemas de Implantação

#### Problema: Fluxos não visíveis após implantação

**Sintomas:**
- Implantação sucede
- Nenhum fluxo listado no Portal Azure

**Soluções:**

1. **Verifique estrutura do zip:**
   ```
   logicapp.zip
   ├── host.json
   ├── local.settings.json (opcional, excluído em produção)
   ├── connections.json
   ├── GetAllOrders/
   │   └── workflow.json
   └── GetOrderById/
       └── workflow.json
   ```

2. **Reimplante com estrutura correta:**
   ```bash
   cd src/LogicApp/OrdersLogicApp
   zip -r logicapp.zip . -x "local.settings.json"
   az logicapp deployment source config-zip \
     --name comp-poc-test-logicapp-dev \
     --resource-group comp-poc-test-rg-dev \
     --src logicapp.zip
   ```

### Problemas de Execução

#### Problema: URL de Callback retorna 401 Não Autorizado

**Sintomas:**
```bash
curl <CALLBACK_URL>
# Retorna: 401 Unauthorized
```

**Soluções:**

1. **Inclua parâmetro `sig`:**
   - URL de callback deve incluir parâmetro de assinatura (`sig`)
   - Assinatura muda em reinicialização/reimplantação
   - Sempre obtenha URL de callback nova após mudanças

2. **Obtenha URL de callback:**
   ```bash
   az rest --method POST \
     --uri "https://management.azure.com/subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.Web/sites/<LOGIC_APP_NAME>/hostruntime/runtime/webhooks/workflow/api/management/workflows/<WORKFLOW_NAME>/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview"
   ```

#### Problema: Fluxo GetOrderById espera POST mas docs dizem GET

**Explicação:**

Logic Apps com trigger HTTP que requerem **corpo de solicitação** devem usar método POST, mesmo que conceitualmente seja uma operação de "leitura".

**Solução:**

Use POST com corpo JSON:
```bash
curl -X POST "<CALLBACK_URL>" \
  -H "Content-Type: application/json" \
  -d '{"id": "123"}'
```

---

## 🌐 Problemas de Conectividade e Rede

### Problemas de Resolução de DNS

#### Problema: Não consegue resolver nomes de serviço

**Soluções:**

1. **Dentro do Kubernetes:**
   - Use nome do serviço: `http://auth-api:8080`
   - Use totalmente qualificado: `http://auth-api.default.svc.cluster.local:8080`

2. **De fora do cluster:**
   - Use IP Externo ou IP de LoadBalancer
   - Use URL de gateway do APIM

### Problemas de Firewall

#### Problema: Timeout de conexão da máquina local

**Soluções:**

1. **Verifique Windows Firewall:**
   ```powershell
   Get-NetFirewallProfile | Select-Object Name, Enabled
   
   # Desabilite temporariamente para testes
   Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
   ```

2. **Verifique Grupos de Segurança de Rede (Azure):**
   - Portal Azure > AKS/APIM > Networking
   - Certifique-se de que regras de entrada permitem tráfego em portas necessárias

### Problemas de VPN

#### Problema: Não consegue acessar recursos do Azure enquanto em VPN

**Soluções:**

- Desconecte VPN temporariamente
- Configure split tunneling de VPN
- Adicione intervalos de IP do Azure a exceções de VPN

---

## 🔐 Problemas de Segurança e Permissões

### Problemas de Identidade Gerenciada

#### Problema: Workload Identity não funciona em AKS

**Sintomas:**
```
Failed to acquire token: ManagedIdentityCredential authentication unavailable
```

**Soluções:**

1. **Verifique se OIDC está habilitado:**
   ```bash
   az aks show \
     --name comp-poc-test-aks-dev \
     --resource-group comp-poc-test-rg-dev \
     --query "oidcIssuerProfile.enabled"
   # Deve retornar: true
   ```

2. **Verifique anotação de ServiceAccount:**
   ```bash
   kubectl get serviceaccount workload-sa -o yaml
   ```
   
   Deve ter:
   ```yaml
   metadata:
     annotations:
       azure.workload.identity/client-id: "<UAMI_CLIENT_ID>"
   ```

3. **Verifique rótulo do pod:**
   ```yaml
   metadata:
     labels:
       azure.workload.identity/use: "true"
   ```

4. **Verifique permissões RBAC:**
   ```bash
   az role assignment list --assignee <UAMI_CLIENT_ID>
   ```

### Problemas de RBAC

#### Problema: "Authorization failed" ao acessar recursos do Azure

**Soluções:**

1. **Liste atribuições de papel atuais:**
   ```bash
   az role assignment list \
     --assignee <IDENTITY_CLIENT_ID> \
     --all
   ```

2. **Conceda papel mínimo necessário:**
   ```bash
   # Acesso ao Key Vault
   az role assignment create \
     --assignee <IDENTITY_CLIENT_ID> \
     --role "Key Vault Secrets User" \
     --scope <KEY_VAULT_RESOURCE_ID>
   ```

---

## 🆘 Obtendo Mais Ajuda

### Comandos de Diagnóstico

**Diagnósticos de AKS:**
```bash
kubectl get all
kubectl describe pod <POD_NAME>
kubectl logs <POD_NAME>
kubectl get events --sort-by='.lastTimestamp'
```

**Status de recurso do Azure:**
```bash
az resource list --resource-group comp-poc-test-rg-dev --output table
az deployment group list --resource-group comp-poc-test-rg-dev --output table
```

**Diagnósticos de Function App:**
```bash
az functionapp show --name <FUNC_NAME> --resource-group <RG>
az functionapp config appsettings list --name <FUNC_NAME> --resource-group <RG>
```

### Localizações de Log

| Componente | Localização de Log |
|-----------|-------------------|
| **Pods AKS** | `kubectl logs <POD_NAME>` |
| **Eventos AKS** | `kubectl get events` |
| **Functions** | Portal Azure > Function App > Log Stream |
| **Logic Apps** | Portal Azure > Logic App > Workflow > Run History |
| **Pipeline** | Azure DevOps > Pipelines > Run > Logs |
| **Infraestrutura** | Portal Azure > Resource Group > Deployments |

### Visualizações Úteis do Portal Azure

- **Application Insights:** Rastreamento de transação end-to-end
- **Log Analytics:** Consultas KQL em todos os serviços
- **Azure Monitor:** Métricas e alertas
- **Implantações do Resource Group:** Histórico de implantação de infraestrutura

---

## 📚 Recursos Adicionais

- [Solução de Problemas de AKS](https://learn.microsoft.com/azure/aks/troubleshooting)
- [Solução de Problemas de Azure Functions](https://learn.microsoft.com/azure/azure-functions/functions-recover-storage-account)
- [Solução de Problemas de Logic Apps](https://learn.microsoft.com/azure/logic-apps/logic-apps-diagnosing-failures)
- [Debugging de Kubernetes](https://kubernetes.io/docs/tasks/debug/)

---

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [📚 Docs](../README.pt-BR.md)