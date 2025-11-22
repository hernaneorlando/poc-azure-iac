# 04 - Implantação de Infraestrutura

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [👈 Anterior](03-devops-setup.pt-BR.md) | [👉 Próximo](05-services-deployment.pt-BR.md)

---

## 🎯 Objetivo

Implante a infraestrutura completa do Azure usando templates Bicep através de pipelines Azure DevOps.

## 📋 O Que Será Implantado?

Esta implantação cria:

| Recurso | Propósito | Tempo Aproximado de Criação |
|---------|----------|---------------------------|
| **Azure Key Vault** | Gerenciamento de secrets e configuração | ~2 min |
| **Log Analytics Workspace** | Logging centralizado | ~2 min |
| **Application Insights** | Telemetria e monitoramento | ~2 min |
| **Azure Kubernetes Service (AKS)** | Orquestração de containers para microsserviços | ~10-20 min |
| **Gerenciamento de API do Azure (APIM)** | Gateway de API e segurança | ~20-45 min |
| **Workload Identity (UAMI + FIC)** | Autenticação sem senha para cargas de trabalho AKS | ~1 min |
| **Azure Functions (auto-detectadas)** | Computação sem servidor para Cliente & Fornecedor | ~3-5 min cada |
| **Contas de Armazenamento** | Armazenamento backend para Functions & Logic Apps | ~2 min cada |

**Tempo total de primeira implantação: ~60-90 minutos** (principalmente devido ao APIM)

## 🚦 Pré-requisitos

Antes de implantar, certifique-se de que completou:

- ✅ [Configuração do Azure DevOps](03-devops-setup.pt-BR.md) - Conexões de serviço e pipelines configurados
- ✅ Grupo de Recursos criado (ex: `comp-poc-test-rg-dev`)
- ✅ Provedores de Recursos registrados
- ✅ Principal de serviço com permissões RBAC corretas

## 📦 Processo de Implantação

### Passo 1: Acione Pipeline CI de Infraestrutura

O **pipeline CI de Infraestrutura** (`infra/pipelines/infra_ci.yaml`) valida e constrói os templates Bicep.

**Para executar:**
1. Navegue até **Azure DevOps** > **Pipelines**
2. Selecione o pipeline **infra_ci**
3. Clique em **Executar pipeline**
4. Aguarde a conclusão (~3-5 minutos)

**O que faz:**
- ✅ Valida se o Grupo de Recursos existe
- ✅ Instala CLI do Bicep
- ✅ Constrói `main.bicep` em template ARM (JSON)
- ✅ Executa análise **What-If** (mostra o que mudará)
- ✅ Publica template ARM como artefato

**Saída esperada:**
```
✓ Construção Bicep bem-sucedida
✓ Análise What-If concluída
✓ Template ARM publicado em artefatos
```

### Passo 2: Revise Resultados do What-If

Antes de implantar, verifique a análise What-If nos logs do pipeline de CI:

```
Mudanças de recurso: 1 para criar, 0 para modificar, 0 para excluir
+ Microsoft.KeyVault/vaults
  + comp-poc-test-kv-dev
+ Microsoft.ContainerService/managedClusters
  + comp-poc-test-aks-dev
...
```

Isto mostra exatamente o que será criado/modificado.

### Passo 3: Acione Pipeline CD de Infraestrutura

O **pipeline CD de Infraestrutura** (`infra/pipelines/infra_cd.yaml`) implanta a infraestrutura no Azure.

**Para executar:**
1. Navegue até **Azure DevOps** > **Pipelines**
2. Selecione o pipeline **infra_cd**
3. Clique em **Executar pipeline**
4. Configure os parâmetros:
   - **Ambiente:** `dev` (ou `qa`/`prod`)
   - **Sufixo Único:** `comp-poc-test` (ou seu sufixo personalizado)
5. Clique em **Executar**

**O que faz:**
- ✅ Auto-detecta Azure Functions em `src/AzureFunctions/`
- ✅ Baixa template ARM dos artefatos de CI
- ✅ Valida se o Grupo de Recursos existe
- ✅ Implanta infraestrutura no Azure (⏱️ 60-90 min primeira vez)

**Estágios do pipeline:**
```
1. Descobrir Aplicativos de Função      [~1 min]
2. Baixar Templates ARM                 [~30 seg]
3. Validar Grupo de Recursos            [~10 seg]
4. Implantar Infraestrutura             [~60-90 min]
```

### Passo 4: Monitore Progresso da Implantação

**No Azure DevOps:**
- Monitore logs do pipeline em tempo real
- Verifique se há erros ou avisos

**No Portal do Azure:**
1. Navegue até seu Grupo de Recursos
2. Selecione **Implantações** (em Configurações)
3. Clique na implantação ativa para ver o progresso
4. Observe os recursos sendo criados em tempo real

**Ordem de implantação típica:**
```
1. Key Vault                    [~2 min]
2. Log Analytics                [~2 min]
3. Application Insights         [~2 min]
4. Contas de Armazenamento      [~2 min cada]
5. Cluster AKS                  [~10-20 min]
6. Aplicativos de Função        [~5 min cada]
7. Workload Identity            [~1 min]
8. APIM (leva mais tempo)       [~20-45 min]
```

### Passo 5: Verifique a Implantação

Após implantação bem-sucedida, verifique todos os recursos:

```bash
# Listar todos os recursos no Grupo de Recursos
az resource list --resource-group comp-poc-test-rg-dev --output table

# Verificar status do cluster AKS
az aks show --name comp-poc-test-aks-dev --resource-group comp-poc-test-rg-dev --query provisioningState

# Verificar status do APIM
az apim show --name comp-poc-test-apim-dev --resource-group comp-poc-test-rg-dev --query provisioningState
```

**Saída esperada:**
```
Nome                              Tipo
--------------------------------  ----------------------------------
comp-poc-test-kv-dev              Microsoft.KeyVault/vaults
comp-poc-test-log-dev             Microsoft.OperationalInsights/workspaces
comp-poc-test-appins-dev          Microsoft.Insights/components
comp-poc-test-aks-dev             Microsoft.ContainerService/managedClusters
comp-poc-test-apim-dev            Microsoft.ApiManagement/service
comp-poc-test-func-customer-dev   Microsoft.Web/sites
comp-poc-test-func-supplier-dev   Microsoft.Web/sites
...
```

## 🔄 Auto-Descoberta de Aplicativos de Função

O pipeline de CD **automaticamente detecta** Azure Functions em `src/AzureFunctions/`:

**Critérios de detecção:**
- ✅ Contém um arquivo `.csproj`
- ✅ Contém um arquivo `host.json`

**Nomes auto-gerados:**
```
Pasta de função: src/AzureFunctions/OrdersFunction/
Nome gerado: comp-poc-test-func-ordersfunction-dev
Conta de Armazenamento: comppocteststorders...dev

Pasta de função: src/AzureFunctions/SupplierFunction/
Nome gerado: comp-poc-test-func-supplierfunction-dev
Conta de Armazenamento: comppocteststsuppli...dev
```

**Detecção de runtime:**
- Lê `TargetFramework` de `.csproj`
- Configura `DOTNET-ISOLATED|6.0`, `7.0` ou `8.0` accordingly

## 🔑 Workload Identity (Autenticação Sem Senha)

A implantação cria uma **Identidade Gerenciada Atribuída pelo Usuário (UAMI)** e **Credencial de Identidade Federada (FIC)** para cargas de trabalho do AKS acessarem recursos do Azure com segurança sem senhas.

**O que é criado:**
- UAMI: `comp-poc-test-aks-dev-wi`
- FIC: Vincula UAMI a ServiceAccount `workload-sa` do Kubernetes no namespace `default`

**Como funciona:**
```
Pod AKS com ServiceAccount → UAMI → Azure Key Vault
(Nenhuma senha ou secret necessária!)
```

**Para usar em pods AKS:**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-sa
  namespace: default
  annotations:
    azure.workload.identity/client-id: "<UAMI_CLIENT_ID>"
---
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: workload-sa
  containers:
  - name: app
    image: my-app:latest
```

## 🔐 Configuração de Segurança Pós-Implantação

A implantação cria a infraestrutura, mas **permissões RBAC devem ser atribuídas manualmente** por segurança:

### Conceda Acesso de Workload Identity ao Key Vault

```bash
# Obtenha ID de Cliente UAMI
UAMI_CLIENT_ID=$(az identity show \
  --name comp-poc-test-aks-dev-wi \
  --resource-group comp-poc-test-rg-dev \
  --query clientId -o tsv)

# Conceda função Key Vault Secrets User
az role assignment create \
  --assignee $UAMI_CLIENT_ID \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/comp-poc-test-rg-dev/providers/Microsoft.KeyVault/vaults/comp-poc-test-kv-dev
```

### Conceda Acesso de Aplicativos de Função ao Key Vault (se necessário)

```bash
# Obtenha Identidade Gerenciada Atribuída pelo Sistema do Aplicativo de Função
FUNC_PRINCIPAL_ID=$(az functionapp identity show \
  --name comp-poc-test-func-customer-dev \
  --resource-group comp-poc-test-rg-dev \
  --query principalId -o tsv)

# Conceda função Key Vault Secrets User
az role assignment create \
  --assignee-object-id $FUNC_PRINCIPAL_ID \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/comp-poc-test-rg-dev/providers/Microsoft.KeyVault/vaults/comp-poc-test-kv-dev
```

## 🔧 Solução de Problemas

### Falhas de Implantação

**Problema:** Pipeline atinge tempo limite após 90 minutos
- **Solução:** Criação de APIM é lenta. Verifique implantações do Portal Azure para progresso real. Se ainda em progresso, aguarde.

**Problema:** "Provedor de recursos não registrado"
```
Erro: Microsoft.ContainerService não está registrado
```
- **Solução:** Registre o provedor:
  ```bash
  az provider register --namespace Microsoft.ContainerService
  ```

**Problema:** "Grupo de recursos não encontrado"
- **Solução:** Certifique-se de que RG foi criado no Passo 2 de [Configuração de DevOps](03-devops-setup.pt-BR.md)

### Problemas de Detecção de Aplicativo de Função

**Problema:** Aplicativos de Função não detectados
- **Solução:** Verifique estrutura de pasta:
  ```
  src/AzureFunctions/
  ├── OrdersFunction/
  │   ├── OrdersFunction.csproj   ← Obrigatório
  │   └── host.json               ← Obrigatório
  └── SupplierFunction/
      ├── SupplierFunction.csproj ← Obrigatório
      └── host.json               ← Obrigatório
  ```

**Problema:** Nome de Conta de Armazenamento muito longo
```
Erro: Nome de conta de armazenamento deve ter entre 3 e 24 caracteres
```
- **Solução:** Nomes de pasta de função são truncados para 6 caracteres. Se ainda muito longo, use parâmetro `uniqueSuffix` mais curto.

### Problemas de AKS

**Problema:** Criação de AKS falha com erro de cota
```
Erro: Operação não pôde ser concluída pois resultaria em exceder cota de Total Regional Cores aprovada
```
- **Solução:** Solicite aumento de cota no Portal Azure ou use uma região diferente.

**Problema:** OIDC não habilitado em AKS
- **Solução:** Reimplante AKS. O módulo `aks.bicep` habilita OIDC por padrão.

## 📊 Análise Aprofundada de Componentes de Infraestrutura

Quer entender o que cada módulo Bicep faz?

👉 Veja [Guia de Componentes de Infraestrutura](infrastructure-components.pt-BR.md) para explicações detalhadas.

## ⏭️ O Que Vem Depois?

- ✅ **Infraestrutura implantada com sucesso?** → Prossiga para [Implantação de Serviços](05-services-deployment.pt-BR.md)
- 📚 **Quer entender pipelines CI/CD?** → Veja [Guia de Pipelines CI/CD](cicd-pipelines.pt-BR.md)
- ⚠️ **Implantação falhou?** → Verifique [Guia de Solução de Problemas](troubleshooting.pt-BR.md)

## 📚 Recursos Adicionais

- [Documentação do Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Pipelines Azure DevOps](https://learn.microsoft.com/azure/devops/pipelines/)
- [What-If de Template ARM](https://learn.microsoft.com/azure/azure-resource-manager/templates/deploy-what-if)

---

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [👈 Anterior](03-devops-setup.pt-BR.md) | [👉 Próximo](05-services-deployment.pt-BR.md)