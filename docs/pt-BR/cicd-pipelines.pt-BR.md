# Guia de Pipelines CI/CD

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [📚 Docs](../README.pt-BR.md)

---

## 🎯 Visão Geral

Esta POC inclui quatro pipelines do Azure DevOps para implantação automatizada de infraestrutura e serviços:

|| Pipeline | Tipo | Propósito | Gatilho |
|----------|------|----------|---------|
|| **infra_ci.yaml** | CI | Validar & construir templates de infraestrutura | Commits em `infra/` |
|| **infra_cd.yaml** | CD | Implantar infraestrutura no Azure | Manual ou após CI |
|| **k8s_ci.yaml** | CI | Construir e testar imagens de serviço AKS | Commits em `src/AKS/` |
|| **k8s_cd.yaml** | CD | Implantar serviços AKS no Kubernetes | Manual ou após k8s CI |

---

## 📦 Pipeline Infra CI (`infra_ci.yaml`)

**Local:** `infra/pipelines/infra_ci.yaml`

### Propósito

Valida templates Bicep e gera artefatos de template ARM **sem fazer nenhuma alteração** no Azure.

### Gatilhos

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

**Executa quando:**
- Commits enviados para branches `master` ou `development`
- Alterações feitas ao diretório `infra/`
- Exclui mudanças em arquivos markdown

### Parâmetros

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|----------|
| `environment` | string | dev | Ambiente alvo (dev/qa/prod) |
| `uniqueSuffix` | string | comp-poc-test | Prefixo para nomes de recursos |

### Etapas do Pipeline

#### 1. Descobrir Function Apps

**Propósito:** Auto-detecta Azure Functions em `src/AzureFunctions/`

**Lógica:**
- Varre cada subdiretório em `src/AzureFunctions/`
- Verifica presença de arquivos `.csproj` e `host.json`
- Extrai versão .NET de `TargetFramework` em `.csproj`
- Gera configuração JSON para cada função

**Saída:**
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

#### 2. Validar Grupo de Recursos

**Propósito:** Garante que o Grupo de Recursos alvo existe

**Por quê:** Previne falhas de pipeline devido a RG ausente

**Comando:**
```bash
az group exists --name comp-poc-test-rg-dev
```

**Se falhar:** Pipeline interrompe com mensagem de erro útil

#### 3. Instalar Bicep CLI

**Propósito:** Garante que a versão mais recente de Bicep está disponível

**Comando:**
```bash
az bicep install
az bicep version
```

#### 4. Validar Template Bicep

**Propósito:** Verifica sintaxe do template e tipos de parâmetros

**Etapas:**
1. Compilar Bicep para ARM JSON: `az bicep build`
2. Validar template ARM: `az deployment group validate`

**Valida:**
- ✅ Erros de sintaxe
- ✅ Tipos de parâmetros
- ✅ Dependências de recursos
- ✅ Versões de API

#### 5. Análise What-If

**Propósito:** Mostra quais recursos serão criados/modificados/excluídos

**Comando:**
```bash
az deployment group what-if \
  --resource-group comp-poc-test-rg-dev \
  --template-file main.json \
  --parameters environment=dev location=brazilsouth ...
```

**Exemplo de saída:**
```
Mudanças de recurso: 8 para criar, 0 para modificar, 0 para excluir

+ Microsoft.KeyVault/vaults
  ~ comp-poc-test-kv-dev

+ Microsoft.ContainerService/managedClusters
  ~ comp-poc-test-aks-dev

+ Microsoft.ApiManagement/service
  ~ comp-poc-test-apim-dev
```

**Codificação por cores:**
- `+` Verde: Recurso será criado
- `~` Amarelo: Recurso será modificado
- `-` Vermelho: Recurso será excluído
- `*` Cinza: Sem alterações

#### 6. Publicar Template ARM

**Propósito:** Disponibiliza template ARM para pipeline CD

**Nome do artefato:** `arm-templates`

**Conteúdo:**
- `main.json` - Template ARM compilado
- `parameters.json` - Valores de parâmetros

### Tempo de Execução

**Média:** 3-5 minutos

### Problemas Comuns

**Problema:** "Resource Group not found"
- **Solução:** Crie RG antes de executar pipeline: `az group create -n <RG_NAME> -l brazilsouth`

**Problema:** "Bicep build failed"
- **Solução:** Verifique sintaxe Bicep localmente: `az bicep build --file infra/main.bicep`

**Problema:** "What-If shows unexpected changes"
- **Solução:** Revise cuidadosamente saída do What-If. Pode indicar diferença entre código e estado implantado.

---

## 🚀 Pipeline Infra CD (`infra_cd.yaml`)

**Local:** `infra/pipelines/infra_cd.yaml`

### Propósito

Implanta infraestrutura no Azure usando artefato de template ARM do pipeline CI.

### Gatilhos

```yaml
trigger: none  # Apenas gatilho manual
```

**Executar manualmente:**
- Azure DevOps → Pipelines → infra_cd → Run pipeline

### Parâmetros

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|----------|
| `environment` | string | dev | Ambiente alvo (dev/qa/prod) |
| `uniqueSuffix` | string | comp-poc-test | Prefixo para nomes de recursos |

### Estágios do Pipeline

#### Estágio: ValidateAndDeploy

**Tipo de job:** Deployment (permite rastreamento de ambiente)

**Ambiente:** Usa valor de parâmetro (dev/qa/prod)

### Etapas de Implantação

#### 1. Fazer Checkout do Repositório

**Propósito:** Acesso ao código-fonte para descoberta de Function Apps

#### 2. Descobrir Function Apps

**Mesma lógica do pipeline CI** - garante consistência

#### 3. Baixar Templates ARM

**Fonte:** Artefato do pipeline CI

**Baixa:**
- `main.json` - Template ARM
- `parameters.json` - Arquivo de parâmetros

#### 4. Validar Grupo de Recursos

**Mesmo que CI** - garante que RG existe antes da implantação

#### 5. Implantar Infraestrutura

**Timeout:** 90 minutos (criação do APIM é lenta)

**Comando:**
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

**Modo:** Incremental (apenas adiciona/atualiza, nunca exclui)

### Tempo de Execução

| Tipo de Execução | Duração | Observações |
|------------------|---------|-------------|
| **Primeira implantação** | 60-90 min | APIM leva 20-45 min |
| **Implantações subsequentes** | 10-20 min | Recursos existentes atualizados |

### Monitorar Implantação

**No Azure DevOps:**
- Acompanhe logs do pipeline em tempo real
- Verifique avisos ou erros

**No Portal Azure:**
1. Navegue até Grupo de Recursos
2. Clique em **Deployments** (em Configurações)
3. Selecione implantação ativa
4. Visualize progresso por recurso

### Problemas Comuns

**Problema:** Pipeline atinge tempo limite após 90 minutos
- **Solução:** Verifique implantações no Portal Azure. Se ainda em andamento, aguarde. Criação do APIM pode exceder 45 minutos.

**Problema:** "Deployment failed: Conflict"
```
Erro: Recurso já existe com propriedades diferentes
```
- **Solução:** Ou:
  - Atualize Bicep para corresponder ao recurso existente
  - Exclua recurso e reimplante
  - Use `mode: Complete` (⚠️ perigoso - exclui recursos não gerenciados)

**Problema:** "Function Apps not detected"
- **Solução:** Verifique que estrutura de pastas contém `.csproj` e `host.json`

---

## 🐳 Pipeline CI de Serviços AKS (`k8s_ci.yaml`)

**Local:** `infra/pipelines/k8s_ci.yaml`

### Propósito

Constrói, testa e valida serviços AKS (Authentication e Products), depois constrói e envia imagens Docker para o Registro de Container.

### Gatilhos

```yaml
trigger:
  branches:
    include:
      - master
      - development
```

**Executa quando:**
- Commits para branches `master` ou `development`
- Idealmente deve ser configurado para acionar apenas em mudanças no diretório `src/AKS/`

### Etapas do Pipeline

#### 1. Restaurar Pacotes NuGet

```yaml
- task: DotNetCoreCLI@2
  displayName: 'Restore'
  inputs:
    command: 'restore'
    projects: '**/*.csproj'
```

Restaura todas as dependências NuGet para projetos Authentication, Products e Common.

#### 2. Construir Projetos .NET

```yaml
- task: DotNetCoreCLI@2
  displayName: 'Build'
  inputs:
    command: 'build'
    projects: '**/*.csproj'
```

Compila todos os projetos C# para validar compilação do código.

#### 3. Executar Testes

```yaml
- task: DotNetCoreCLI@2
  displayName: 'Test'
  inputs:
    command: 'test'
    projects: '**/*.csproj'
```

Executa testes unitários (se projetos de teste existirem).

#### 4. Construir e Enviar Imagem Docker

```yaml
- task: Docker@2
  displayName: 'Build and Push Docker Image'
  inputs:
    containerRegistry: '$(dockerRegistryServiceConnection)'
    repository: '$(imageRepository)'
    command: 'buildAndPush'
    tags: '$(tag)'
```

**Nota:** O pipeline atual constrói uma única imagem genérica. Para imagens separadas de Authentication e Products, você deve:
- Adicionar múltiplas tasks Docker@2 com Dockerfiles diferentes
- Ou usar uma estratégia de matrix para construir ambos os serviços

### Variáveis

- `dockerRegistryServiceConnection`: Nome da conexão de serviço do registro Docker
- `imageRepository`: Caminho do repositório da imagem (ex.: `acr.azurecr.io/my-api`)
- `tag`: Tag da imagem (usa `$(Build.BuildId)`)

### Tempo de Execução

**Média:** 5-10 minutos (depende do tamanho da imagem e camadas em cache)

---

## 📡 Pipeline CD de Serviços AKS (`k8s_cd.yaml`)

**Local:** `infra/pipelines/k8s_cd.yaml`

### Propósito

Implanta serviços Authentication e Products no cluster AKS e configura permissões RBAC para acesso ao Key Vault.

### Gatilhos

```yaml
trigger: none  # Apenas gatilho manual
```

### Etapas de Implantação

#### 1. Implantar Serviço de Autenticação no AKS

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

Implanta o manifest de deployment da Authentication API no Kubernetes.

#### 2. Implantar Serviço de Produtos no AKS

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

Implanta o manifest de deployment da Products API no Kubernetes.

#### 3. Atribuir Permissões RBAC para Key Vault

```yaml
- task: AzureCLI@2
  displayName: 'Assign RBAC to AKS Managed Identity for Key Vault'
  inputs:
    azureSubscription: 'Azure-Connection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # Obter identidade gerenciada do AKS
      aksIdentity=$(az aks show --name $(aksName) --resource-group $(resourceGroupName) --query identityProfile.kubeletidentity.objectId -o tsv)
      
      # Atribuir papel Key Vault Secrets User
      az role assignment create \
        --assignee $aksIdentity \
        --role "Key Vault Secrets User" \
        --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$(resourceGroupName)/providers/Microsoft.KeyVault/vaults/$(keyVaultName)
```

Concede à identidade gerenciada do AKS permissão para ler secrets do Key Vault.

### Variáveis

- `kubernetesServiceConnection`: Nome da conexão de serviço Kubernetes no Azure DevOps
- `namespace`: Namespace do Kubernetes (padrão: `default`)
- `imageRepository`: Caminho da imagem de container
- `tag`: Tag da imagem do pipeline CI
- `aksName`: Nome do cluster AKS
- `resourceGroupName`: Nome do grupo de recursos
- `keyVaultName`: Nome do Key Vault

---

## 🔐 Conexões de Serviço

### POC-Azure-Connection

**Tipo:** Gerenciador de Recursos do Azure (Workload Identity Federation)

**Escopo:** Grupo de Recursos

**Papéis Necessários:**
- **Nível de assinatura:** Reader
- **Nível de Grupo de Recursos:** Contributor

**Usado por:**
- infra_ci.yaml
- infra_cd.yaml
- k8s_cd.yaml

### Conexão de Serviço de Registro Docker

**Tipo:** Docker Registry

**Registro:** URL do registro de container (ex.: Docker Hub ou ACR)

**Autenticação:** Service Principal, Admin User ou Access Token

**Usado por:**
- k8s_ci.yaml (enviar imagens)

### Conexão de Serviço Kubernetes

**Tipo:** Kubernetes

**Cluster:** Cluster AKS

**Autenticação:** Service Account ou Azure Subscription

**Usado por:**
- k8s_cd.yaml (implantar manifests)

---

## 📊 Melhores Práticas de Pipeline

### Segurança

✅ Use Workload Identity Federation (sem senha)  
✅ Escope conexões de serviço apenas ao Grupo de Recursos  
✅ Separe conexões de serviço por ambiente  
✅ Use Azure DevOps Environments para gates de aprovação  
✅ Armazene secrets no Azure Key Vault, não em variáveis de pipeline  

### Performance

✅ Use cache para camadas do Docker  
✅ Execute jobs em paralelo quando possível  
✅ Use `condition: succeeded()` para pular etapas desnecessárias  
✅ Aumente timeout para implantações longas (APIM)  

### Manutenibilidade

✅ Use templates para lógica de pipeline reutilizável  
✅ Parametrize nomes de recursos e ambientes  
✅ Adicione comentários explicando etapas complexas  
✅ Use nomes significativos de exibição para tasks  
✅ Controle de versão de arquivos YAML de pipeline  

### Monitoramento

✅ Habilite retenção de execuções de pipeline  
✅ Configure notificações para pipelines que falharam  
✅ Revise análise What-If antes de implantar  
✅ Rastreie histórico de implantação no Portal Azure  

---

## 📦 Configuração do Docker Registry

### Visão Geral

A pipeline `k8s_ci.yaml` pode fazer build e push de imagens Docker para um registro de contêiner. Você tem **três opções** para configuração de registro:

### Opção 1: Docker Hub (Recomendado para POC)

**Vantagens:**
- ✅ Nível gratuito disponível
- ✅ Configuração simples
- ✅ Repositórios públicos ou privados

**Passos de Configuração:**

#### 1. Criar Conta no Docker Hub

1. Acesse https://hub.docker.com/
2. Cadastre-se para uma conta gratuita

#### 2. Gerar Access Token

1. Faça login no Docker Hub
2. Navegue para **Account Settings** > **Security**
3. Clique em **New Access Token**
4. Nome: `azure-devops-poc`
5. Permissões: **Read, Write, Delete**
6. Clique em **Generate**
7. **⚠️ COPIE O TOKEN IMEDIATAMENTE** (não será exibido novamente)

#### 3. Criar Service Connection no Azure DevOps

1. Azure DevOps > Seu Projeto > **Project Settings**
2. **Service connections** > **New service connection**
3. Selecione **Docker Registry**
4. Escolha **Docker Hub**
5. Configure:
   - **Docker Registry**: `https://index.docker.io/v1/`
   - **Docker ID**: seu username do Docker Hub
   - **Password**: cole o access token
   - **Service connection name**: `dockerConnection`
6. ✅ **Grant access permission to all pipelines**
7. Clique em **Verify and save**

#### 4. Atualizar k8s_ci.yaml

Descomente estas linhas em `infra/pipelines/k8s_ci.yaml`:

```yaml
variables:
  dockerRegistryServiceConnection: 'dockerConnection'
  imageRepository: 'seu-username-dockerhub/auth-api'  # Substitua pelo SEU username
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

### Opção 2: Azure Container Registry (Recomendado para Produção)

**Vantagens:**
- ✅ Integrado com Azure
- ✅ Autenticação automática com AKS
- ✅ Registro privado dentro da sua assinatura
- ✅ Sem limites de pull rate

**Nota:** O ACR é criado automaticamente pelas pipelines de infraestrutura quando você implanta os templates Bicep.

**Passos de Configuração:**

#### 1. Verificar Criação do ACR

Após executar `infra_cd.yaml`, verifique se o ACR existe:

```bash
az acr list --resource-group comp-poc-test-rg-dev --output table
```

Saída esperada:
```
NAME                 RESOURCE GROUP          LOCATION
comppoctestacrdev    comp-poc-test-rg-dev    brazilsouth
```

#### 2. Criar Service Connection

**Opção 2a: Via Azure Subscription (Recomendado)**

1. Azure DevOps > **Service connections** > **New service connection**
2. Selecione **Docker Registry**
3. Escolha **Azure Container Registry**
4. Selecione sua **Subscription**
5. Selecione ACR: `comppoctestacrdev`
6. **Service connection name**: `dockerConnection`
7. ✅ **Grant access permission to all pipelines**
8. Clique em **Save**

**Opção 2b: Via Admin User (Mais simples mas menos seguro)**

```bash
# Habilitar admin user
az acr update --name comppoctestacrdev --admin-enabled true

# Obter credenciais
az acr credential show --name comppoctestacrdev
```

Então crie service connection:
1. Azure DevOps > **Service connections** > **New service connection**
2. Selecione **Docker Registry**
3. Escolha **Others**
4. Configure:
   - **Docker Registry**: `https://comppoctestacrdev.azurecr.io`
   - **Docker ID**: username de `az acr credential show`
   - **Password**: password de `az acr credential show`
   - **Service connection name**: `dockerConnection`
5. ✅ **Grant access permission to all pipelines**
6. Clique em **Verify and save**

#### 3. Atualizar k8s_ci.yaml

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

#### 4. Atualizar Manifestos Kubernetes

Os arquivos `auth-deployment.yaml` e `products-deployment.yaml` já estão configurados com:

```yaml
image: comppoctestacrdev.azurecr.io/auth-api:latest
```

**Não precisa de imagePullSecrets** - AKS tem papel `AcrPull` automaticamente atribuído!

### Opção 3: Sem Registry (Apenas Build & Test)

**Quando usar:**
- Você quer apenas validar compilação do código
- Ainda desenvolvendo localmente
- Workflow manual de build/push Docker

**Configuração:** Nada! A pipeline já funciona sem Docker registry. Ela vai:
1. ✅ Restaurar pacotes NuGet
2. ✅ Compilar todos os projetos .NET
3. ✅ Executar testes unitários
4. ❌ Pular build/push Docker

### Solução de Problemas do Docker Registry

**Problema:** "service connection dockerConnection could not be found"
- **Solução:** Verifique que service connection existe e nome corresponde exatamente
- **Verificar:** Azure DevOps > Project Settings > Service connections

**Problema:** "unauthorized: authentication required"
- **Docker Hub:** Regere access token e atualize service connection
- **ACR:** Verifique que admin user está habilitado: `az acr update --name <ACR> --admin-enabled true`

**Problema:** "denied: requested access to the resource is denied"
- **Docker Hub:** Verifique que nome do repositório inclui SEU username
- **ACR:** Verifique que service principal tem papel `AcrPush`

---

## ⚡ CI/CD de Azure Functions

### Visão Geral

O deployment de Azure Functions usa as mesmas pipelines de infraestrutura (`infra_ci.yaml` / `infra_cd.yaml`) para provisionar Function Apps, com pipelines separadas para implantar código.

**Estrutura de Pipeline:**

| Pipeline | Propósito | Trigger |
|----------|----------|---------|
| `infra_ci.yaml` | Descobre e valida Function Apps | Mudanças em `infra/` |
| `infra_cd.yaml` | Cria Function Apps + Storage | Manual |
| `function_ci.yaml` | Compila código de Function | Mudanças em `src/AzureFunctions/` |
| `function_cd.yaml` | Implanta código de Function | Manual |

### Ordem de Execução

#### Implantação Inicial (Primeira Vez)

```
1. infra_ci.yaml    → Descobre Functions, valida infraestrutura
2. infra_cd.yaml    → Cria Function Apps no Azure
3. function_ci.yaml → Compila código de Function (.NET)
4. function_cd.yaml → Implanta código nas Function Apps
```

#### Atualizações Apenas de Código

Quando apenas o código da Function muda:

```
1. function_ci.yaml → Compila código
2. function_cd.yaml → Implanta código
```

#### Atualizações de Infraestrutura + Código

Quando tanto infraestrutura quanto código mudam:

```
1. infra_ci.yaml    → Valida mudanças de infraestrutura
2. infra_cd.yaml    → Atualiza infraestrutura
3. function_ci.yaml → Compila código
4. function_cd.yaml → Implanta código
```

### Mecanismo de Auto-Descoberta

As pipelines de infraestrutura **detectam automaticamente** Function Apps varrendo `src/AzureFunctions/`:

**Critérios de detecção:**
1. ✅ Deve ser um subdiretório de `src/AzureFunctions/`
2. ✅ Deve conter um arquivo `.csproj`
3. ✅ Deve conter um arquivo `host.json`

**Estrutura de exemplo:**
```
src/AzureFunctions/
├── CustomerFunction/
│   ├── CustomerFunction.csproj  ← Obrigatório
│   ├── host.json                ← Obrigatório
│   ├── Program.cs
│   └── Functions/
│       └── GetCustomer.cs
└── SupplierFunction/
    ├── SupplierFunction.csproj  ← Obrigatório
    ├── host.json                ← Obrigatório
    ├── Program.cs
    └── Functions/
        └── GetSuppliers.cs
```

### Convenções de Nomenclatura

Com `uniqueSuffix` = `comp-poc-test` e `environment` = `dev`:

| Recurso | Padrão | Exemplo |
|---------|--------|--------|
| Function App | `{suffix}-func-{folder}-{env}` | `comp-poc-test-func-customer-dev` |
| Storage Account | `{suffix}st{folder:6}{env}` | `comppocteststcustomerdev` |
| App Service Plan | `{suffix}-asp-{env}` | `comp-poc-test-asp-dev` |

**Notas:**
- `{folder}` = nome do subdiretório em lowercase
- Nome da Storage Account remove hífens e trunca para 24 chars
- Versão .NET auto-detectada de `<TargetFramework>` no `.csproj`

### Adicionando Novas Functions

#### Criar Novo Projeto de Function App

```bash
cd src/AzureFunctions
mkdir OrdersFunction
cd OrdersFunction

# Inicializar projeto .NET
func init --worker-runtime dotnet-isolated --target-framework net8.0

# Adicionar function HTTP trigger
func new --name GetOrders --template "HTTP trigger"
```

**Pronto!** Na próxima execução de pipeline, automaticamente:
1. Detectará `OrdersFunction`
2. Criará Function App + Storage no Azure
3. Implantará o código

### Testes Locais

**Executar CustomerFunction localmente:**
```bash
cd src/AzureFunctions/CustomerFunction
func start
```

Endpoints disponíveis em:
- `http://localhost:7071/api/customers` (GET/POST)
- `http://localhost:7071/api/customers/{id}` (GET)

---

## 🔧 Solução de Problemas de Pipelines

### Falhas no Pipeline CI

**Problema:** "az: command not found"
- **Solução:** Use task `AzureCLI@2` em vez de `Bash@3`

**Problema:** "Service connection not found"
- **Solução:** Verifique que nome da conexão de serviço corresponde ao parâmetro `azureSubscription`

### Falhas no Pipeline CD

**Problema:** "Insufficient permissions"
- **Solução:** Verifique que service principal tem papel Contributor no Grupo de Recursos

**Problema:** "Template validation failed"
- **Solução:** Execute What-If no CI primeiro para identificar problemas

### Falhas no Docker Build

**Problema:** "Cannot find Dockerfile"
- **Solução:** Verifique que `buildContext` está configurado corretamente (geralmente `src/AKS/`)

**Problema:** "Copy failed: no such file"
- **Solução:** Verifique que caminhos COPY no Dockerfile são relativos ao build context

---

## 📚 Recursos Adicionais

- [Documentação de Pipelines do Azure DevOps](https://learn.microsoft.com/azure/devops/pipelines/)
- [Bicep CI/CD](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-github-actions)
- [Task Docker@2](https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/docker-v2)
- [Task AzureCLI@2](https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/azure-cli-v2)

---

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [📚 Docs](../README.pt-BR.md)