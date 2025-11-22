# Componentes de Infraestrutura

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [📚 Docs](../README.pt-BR.md)

---

## 🎯 Visão Geral

Este guia fornece uma explicação detalhada de todos os módulos Bicep utilizados para provisionar a infraestrutura do Azure para esta POC.

## 📂 Estrutura Bicep

```
infra/
├── main.bicep                    # Módulo de orquestração
└── modules/
    ├── aks.bicep                 # Azure Kubernetes Service
    ├── acr.bicep                 # Azure Container Registry
    ├── apim.bicep                # Gerenciamento de API
    ├── keyvault.bicep            # Key Vault
    ├── monitor.bicep             # Log Analytics + App Insights
    ├── function-app.bicep        # Azure Functions
    └── workload-identity.bicep   # Workload Identity (UAMI + FIC)
```

---

## 📘 main.bicep - Módulo de Orquestração

**Propósito:** Coordena implantação de todos os recursos de infraestrutura.

### Características Principais

- **Design modular:** Chama módulos individuais para cada tipo de recurso
- **Implantações condicionais:** Usa instruções `if` para recursos opcionais
- **Gerenciamento de dependências:** Garante que recursos sejam criados na ordem correta
- **Validação de parâmetros:** Usa decoradores `@allowed` para segurança de tipo

### Parâmetros

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|----------|
| `environment` | string | - | Nome do ambiente (dev/qa/prod) |
| `location` | string | resourceGroup().location | Região Azure |
| `keyVaultName` | string | - | Nome do Key Vault |
| `logAnalyticsName` | string | - | Nome do espaço de trabalho Log Analytics |
| `appInsightsName` | string | - | Nome do Application Insights |
| `aksName` | string | - | Nome do cluster AKS |
| `apimName` | string | - | Nome do Gerenciamento de API |
| `apimSku` | string | Developer | SKU do APIM (Developer/Basic/Standard/Premium) |
| `enableWorkloadIdentity` | bool | true | Criar UAMI + FIC para cargas de trabalho AKS |
| `functionApps` | array | [] | Array de configurações de Function App |

### Fluxo de Implantação

```
1. Key Vault          [Independente]
2. Monitor            [Independente]
   ├── Log Analytics
   └── App Insights
3. AKS                [Depende de: Monitor]
4. APIM               [Independente]
5. Workload Identity  [Depende de: AKS]
6. Function Apps      [Depende de: Monitor]
```

### Exemplo de Uso

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
    apimName=comp-poc-test-apim-dev
```

---

## 🔐 keyvault.bicep - Azure Key Vault

**Propósito:** Armazenamento seguro de secrets, chaves e certificados.

### Configuração

- **SKU:** Standard
- **Autorização RBAC:** Habilitada (acesso controlado via Azure RBAC, não políticas de acesso)
- **Soft Delete:** Habilitado por padrão (retenção de 90 dias)
- **Acesso à Rede Pública:** Habilitado (para simplicidade da POC)

### Propriedades Principais

```bicep
enableRbacAuthorization: true      // Usar Azure RBAC em vez de políticas de acesso
enabledForDeployment: true         // Permitir que VMs recuperem secrets
enabledForTemplateDeployment: true // Permitir que templates ARM recuperem secrets
```

### Saídas

- `keyVaultId`: ID do recurso do Key Vault
- `keyVaultUri`: URI do vault (ex.: `https://comp-poc-test-kv-dev.vault.azure.net/`)

### Melhores Práticas de Segurança

✅ **FAÇA:**
- Use Identidades Gerenciadas para acessar Key Vault
- Conceda papéis RBAC mínimos necessários (ex.: "Key Vault Secrets User")
- Armazene cadeias de conexão, chaves de API e certificados no Key Vault

❌ **NÃO FAÇA:**
- Codifique secrets no código ou configuração
- Conceda papéis amplos como "Contributor" ao Key Vault
- Desabilite autorização RBAC em produção

### Exemplo: Concedendo Acesso

```bash
# Conceder acesso à Workload Identity do AKS para secrets
az role assignment create \
  --assignee <MANAGED_IDENTITY_CLIENT_ID> \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.KeyVault/vaults/<KV_NAME>
```

---

## 📊 monitor.bicep - Logging & Monitoramento

**Propósito:** Logging centralizado e telemetria de aplicação.

### Componentes

#### 1. Espaço de Trabalho Log Analytics

- **SKU:** PerGB2018 (pagamento conforme o uso)
- **Retenção:** 30 dias (padrão)
- **Propósito:** Agrega logs de AKS, APIM, Functions, Logic Apps

**Casos de uso:**
- Logs de contêiner Kubernetes
- Logs de solicitação/resposta do APIM
- Logs de execução de função
- Consultas customizadas com KQL (Linguagem de Consulta Kusto)

#### 2. Application Insights

- **Tipo:** Web
- **Vinculado a:** Espaço de trabalho Log Analytics
- **Propósito:** Monitoramento de desempenho de aplicação (APM)

**Características principais:**
- Rastreamento distribuído entre serviços
- Métricas de desempenho (tempos de resposta, taxas de falha)
- Eventos e métricas customizados
- Rastreamento de dependência

### Saídas

- `logAnalyticsId`: ID do recurso (usado por addon do AKS)
- `appInsightsConnectionString`: Usado por Functions/Logic Apps
- `appInsightsInstrumentationKey`: Chave legada (para SDKs mais antigos)

### Consultas de Exemplo

**Visualizar logs de pod AKS:**
```kql
ContainerLog
| where TimeGenerated > ago(1h)
| where Namespace == "default"
| project TimeGenerated, Computer, ContainerName, LogEntry
| order by TimeGenerated desc
```

**Tempos de execução de função:**
```kql
requests
| where cloud_RoleName startswith "comp-poc-test-func"
| summarize avg(duration), percentile(duration, 95) by name
```

---

## ☸️ aks.bicep - Azure Kubernetes Service

**Propósito:** Orquestração de contêineres para serviços de Autenticação e Produtos.

### Configuração

| Configuração | Valor | Notas |
|--------------|-------|-------|
| **SKU** | Basic/Free | Adequado para POC; use Standard para produção |
| **Contagem de Nós** | 1 | Parâmetro: `nodeCount` |
| **Tamanho de VM do Nó** | Standard_D2s_v6 | 2 vCPU, 8GB RAM |
| **RBAC** | Habilitado | RBAC Kubernetes para segurança de pod |
| **OIDC Issuer** | Habilitado | Necessário para Workload Identity |
| **Plugin de Rede** | Azure CNI | Atribui IPs do Azure para pods |
| **Load Balancer** | Standard | IPs públicos para serviços |

### Características Principais

#### 1. Perfil de Issuer OIDC

Habilita **Workload Identity** (autenticação sem senha):

```bicep
oidcIssuerProfile: {
  enabled: true
}
```

Isto gera uma URL de issuer OIDC usada para credenciais de identidade federada.

#### 2. Agente OMS (Container Insights)

Integra-se com Log Analytics para monitoramento:

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

#### 3. Identidade Gerenciada Atribuída pelo Sistema

O cluster AKS tem sua própria identidade para gerenciamento de recursos do Azure.

### Redes

**Azure CNI:**
- Pods recebem IPs da subnet da VNet
- Habilita comunicação direta entre pods
- Requer espaço de endereço IP suficiente

**Tipo LoadBalancer:**
- Cria Azure Load Balancer para cada Service
- Atribui IP público para acesso externo

### Saídas

- `aksClusterId`: ID do recurso
- `aksClusterName`: Nome do cluster

### Tarefas Pós-Implantação

1. **Obter credenciais:**
   ```bash
   az aks get-credentials --name <AKS_NAME> --resource-group <RG>
   ```

2. **Verificar issuer OIDC:**
   ```bash
   az aks show --name <AKS_NAME> --resource-group <RG> \
     --query "oidcIssuerProfile.issuerUrl" -o tsv
   ```

3. **Implantar cargas de trabalho:**
   ```bash
   kubectl apply -f infra/k8s/
   ```

---

## 🌐 apim.bicep - Gerenciamento de API

**Propósito:** Gateway de API para roteamento centralizado, segurança e monitoramento.

### Configuração

| Configuração | Valor | Notas |
|--------------|-------|-------|
| **SKU** | Developer | $50/mês; inclui portal de desenvolvimento |
| **Capacidade** | 1 | Número de unidades de escala |
| **Rede Virtual** | Nenhuma | Para POC; use Internal/External para produção |
| **Informações do Publisher** | Configurável | Nome de email e organização |

### APIs Pré-Configuradas

O módulo cria duas APIs de exemplo:

#### 1. API de Autenticação
- **Caminho:** `/auth`
- **URL de Backend:** `http://localhost:8080` (placeholder - atualizar pós-implantação)
- **Protocolos:** HTTPS
- **Subscription:** Necessária

#### 2. API de Produtos
- **Caminho:** `/products`
- **URL de Backend:** `http://localhost:8081` (placeholder - atualizar pós-implantação)
- **Protocolos:** HTTPS
- **Subscription:** Necessária

### Conjunto de Versão de API

Usa esquema de versionamento **Segment**:
```
https://<apim>.azure-api.net/auth/v1/login
https://<apim>.azure-api.net/auth/v2/login
```

### Saídas

- `apimUrl`: URL do gateway (ex.: `https://comp-poc-test-apim-dev.azure-api.net`)

### Configuração Pós-Implantação

1. **Atualizar URLs de backend:**
   - Navegue para APIM > Backends > Edit
   - Substitua `localhost` com URLs de serviço reais (IPs do LoadBalancer do AKS ou URLs de Function)

2. **Adicionar operações:**
   - APIM > APIs > Selecione API > Add Operation
   - Defina métodos HTTP, caminhos, esquemas de requisição/resposta

3. **Aplicar políticas:**
   Exemplo: Limitação de taxa
   ```xml
   <policies>
     <inbound>
       <rate-limit calls="100" renewal-period="60" />
     </inbound>
   </policies>
   ```

4. **Configurar subscriptions:**
   - APIM > Subscriptions > Add subscription
   - Gere chaves para aplicações cliente

---

## ⚡ function-app.bicep - Azure Functions

**Propósito:** Provisionar Function Apps com Contas de Armazenamento e Planos de Serviço de Aplicativo associados.

### Características

- **Auto-descoberta:** Pipeline de CI detecta funções em `src/AzureFunctions/`
- **Runtime isolado:** Usa processo worker .NET Isolated
- **Identidade Gerenciada:** Atribuída pelo sistema para acesso seguro ao Key Vault
- **App Insights:** Telemetria integrada

### Configuração Por Function App

| Componente | Configuração |
|-----------|--------------|
| **Plano de Serviço de Aplicativo** | Dynamic (Consumption) ou Dedicated (baseado em parâmetro) |
| **Conta de Armazenamento** | Auto-criada com nome único |
| **Stack de Runtime** | .NET 6.0/7.0/8.0 (auto-detectado de .csproj) |
| **SO** | Linux (baseado em parâmetro) |
| **Always On** | Opcional (depende do SKU do plano) |

### Parâmetros (por função)

```bicep
{
  name: "comp-poc-test-func-customer-dev"
  storageAccountName: "comppocteststcustomer"
  runtime: "DOTNET-ISOLATED|8.0"
  workerRuntime: "dotnet-isolated"
}
```

### Configurações de Aplicativo

Configuradas automaticamente:
- `AzureWebJobsStorage`: Conexão com Conta de Armazenamento
- `APPINSIGHTS_INSTRUMENTATIONKEY`: Chave do App Insights
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: String de conexão do App Insights
- `FUNCTIONS_WORKER_RUNTIME`: `dotnet-isolated`
- `FUNCTIONS_EXTENSION_VERSION`: `~4`

### Nomenclatura de Conta de Armazenamento

Padrão: `<uniqueSuffix>st<functionName><environment>`

Exemplo:
- Pasta de função: `OrdersFunction`
- Conta de Armazenamento gerada: `comppocteststorders...dev` (truncada para 24 caracteres)

---

## 🔑 workload-identity.bicep - Autenticação Sem Senha

**Propósito:** Habilitar cargas de trabalho AKS acessarem recursos do Azure sem secrets.

### Componentes

#### 1. Identidade Gerenciada Atribuída pelo Usuário (UAMI)

Uma identidade independente que pode ser atribuída a pods AKS.

```bicep
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName  // ex.: comp-poc-test-aks-dev-wi
  location: location
}
```

#### 2. Credencial de Identidade Federada (FIC)

Vincula a UAMI a uma ServiceAccount Kubernetes usando OIDC.

```bicep
resource fic 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: uami
  name: '${aksName}-fic'
  properties: {
    audiences: ['api://AzureADTokenExchange']
    issuer: aksOidcIssuer  // Do cluster AKS
    subject: 'system:serviceaccount:${workloadNamespace}:${workloadServiceAccount}'
  }
}
```

### Como Funciona

```
1. Pod inicia com ServiceAccount "workload-sa"
2. Kubernetes injeta token OIDC no pod
3. Azure SDK troca token por token do Azure AD
4. Pod acessa recursos do Azure (Key Vault, Storage, etc.)
```

**Nenhum secret, senha ou string de conexão necessários!**

### Parâmetros

- `workloadNamespace`: Namespace Kubernetes (padrão: `default`)
- `workloadServiceAccount`: Nome da ServiceAccount (padrão: `workload-sa`)
- `uamiName`: Nome da UAMI (padrão: `<aksName>-wi`)

### Uso em Kubernetes

**Criar ServiceAccount:**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-sa
  namespace: default
  annotations:
    azure.workload.identity/client-id: "<UAMI_CLIENT_ID>"
```

**Usar em Deployment:**
```yaml
spec:
  serviceAccountName: workload-sa
  labels:
    azure.workload.identity/use: "true"
```

### Conceder Permissões RBAC

Após implantação, conceda à UAMI acesso a recursos:

```bash
# Acesso ao Key Vault
az role assignment create \
  --assignee <UAMI_CLIENT_ID> \
  --role "Key Vault Secrets User" \
  --scope <KEY_VAULT_RESOURCE_ID>

# Acesso à Conta de Armazenamento
az role assignment create \
  --assignee <UAMI_CLIENT_ID> \
  --role "Storage Blob Data Contributor" \
  --scope <STORAGE_ACCOUNT_RESOURCE_ID>
```

---

## 📋 Resumo de Melhores Práticas

### Segurança

✅ Use Identidades Gerenciadas em vez de cadeias de conexão  
✅ Habilite RBAC no Key Vault  
✅ Conceda permissões mínimas necessárias  
✅ Use ambientes separados (dev/qa/prod)  
✅ Habilite soft delete no Key Vault  

### Otimização de Custos

✅ Use SKU Developer para APIM em não-prod  
✅ Use nível Free para AKS em POC  
✅ Use plano Consumption para Functions (pagamento por execução)  
✅ Defina retenção apropriada do Log Analytics (30 dias para POC)  

### Monitoramento

✅ Habilite Container Insights em AKS  
✅ Integre todos os serviços com Application Insights  
✅ Configure alertas para métricas críticas  
✅ Use consultas do Log Analytics para diagnóstico  

### Infrastructure as Code

✅ Use estrutura Bicep modular  
✅ Parametrize todos os nomes de recurso  
✅ Use What-If antes de implantar  
✅ Controle de versão de todos os arquivos IaC  
✅ Documente parâmetros e saídas  

---

## 📚 Recursos Adicionais

- [Documentação do Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [AKS Workload Identity](https://learn.microsoft.com/azure/aks/workload-identity-overview)
- [Azure Key Vault RBAC](https://learn.microsoft.com/azure/key-vault/general/rbac-guide)
- [Políticas do APIM](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)

---

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [📚 Docs](../README.pt-BR.md)