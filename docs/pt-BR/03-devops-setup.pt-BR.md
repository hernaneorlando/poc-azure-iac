# 03 - Configuração do Azure DevOps

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [👈 Anterior](02-local-development.pt-BR.md) | [👉 Próximo](04-infrastructure-deployment.pt-BR.md)

---

## 🎯 Objetivo

Configurar a organização do Azure DevOps, conexões de serviço e pipelines para implantação automatizada.

## 🚦 Pré-requisitos

- ✅ Assinatura Azure (com Owner ou Contributor + User Access Administrator)
- ✅ Organização no Azure DevOps
- ✅ Azure CLI instalada e autenticada

## 📋 Passo a Passo

### Passo 1: Portal Azure - Registrar Provedores de Recursos

Registre os provedores necessários na sua assinatura Azure:

```bash
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.ApiManagement
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.AlertsManagement
az provider register --namespace Microsoft.OperationsManagement
```

Ou via Portal: Azure Portal > Subscriptions > (sua assinatura) > Resource providers

### Passo 2: Criar Grupo de Recursos

```bash
az group create -n comp-poc-test-rg-dev -l brazilsouth --tags environment=dev
```

Substitua:
- `comp-poc-test-rg-dev` pelo nome desejado do grupo de recursos
- `brazilsouth` pela sua região preferida

### Passo 3: Criar Conexão de Serviço no Azure DevOps

1. Navegue em **Azure DevOps** > Seu Projeto > **Project Settings**
2. Selecione **Service connections** > **New service connection**
3. Escolha **Azure Resource Manager**
4. Selecione **Workload Identity federation (recommended)**
5. Configure:
   - **Scope**: Resource Group
   - **Subscription**: Sua assinatura Azure
   - **Resource Group**: Selecione o RG criado no Passo 2
   - **Service connection name**: `POC-Azure-Connection`
6. ✅ **Grant access permission to all pipelines** (para simplicidade da POC)
7. Clique em **Save**

### Passo 4: Atribuir Permissões RBAC

A conexão de serviço precisa de papéis específicos:

#### No nível da Assinatura:
```bash
# Obtenha o Object ID do service principal da conexão do Azure DevOps
az role assignment create \
  --assignee-object-id <APP_OBJECT_ID> \
  --role Reader \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

#### No nível do Grupo de Recursos:
```bash
az role assignment create \
  --assignee-object-id <APP_OBJECT_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/comp-poc-test-rg-dev
```

Ou via Portal:
1. **Subscription** > Access control (IAM) > Add role assignment > **Reader** > Selecione o service principal  
2. **Resource Group** > Access control (IAM) > Add role assignment > **Contributor** > Selecione o service principal

### Passo 5: Importar Repositório para o Azure DevOps

Se ainda não importado:
1. Azure DevOps > Repos > Import repository
2. Informe a URL do repositório
3. Após importar, os arquivos de pipeline em `infra/pipelines/` estarão disponíveis

### Passo 6: Criar Pipeline CI de Infraestrutura

1. Azure DevOps > Pipelines > **New pipeline**
2. Selecione **Azure Repos Git** (ou sua fonte)
3. Selecione seu repositório
4. Escolha **Existing Azure Pipelines YAML file**
5. Caminho: `/infra/pipelines/infra_ci.yaml`
6. Clique em **Run**

Este pipeline irá:
- Validar existência do Grupo de Recursos
- Instalar Bicep CLI
- Construir e validar templates Bicep
- Executar análise `What-If`
- Publicar template ARM como artefato

### Passo 7: Criar Pipeline CD de Infraestrutura

1. Azure DevOps > Pipelines > **New pipeline**
2. Caminho: `/infra/pipelines/infra_cd.yaml`
3. **Antes de executar:** atualize variáveis no arquivo do pipeline:
   - `azureSubscription`: deve corresponder ao nome da sua conexão de serviço
   - `resourceGroupName`: nome do seu grupo de recursos
   - `location`: sua região Azure

4. Clique em **Run**

Este pipeline irá:
- Baixar template ARM do CI
- Implantar infraestrutura no Azure (⏱️ ~60-90 minutos na primeira execução)

## 🔐 Considerações de Segurança

### Para ambiente POC/Dev:
- ✅ Conexão de serviço com Contributor no RG é aceitável
- ✅ "Grant access to all pipelines" simplifica a configuração

### Para Produção:
- ❌ Não conceda acesso a todos os pipelines
- ✅ Crie conexões de serviço com permissões mínimas necessárias
- ✅ Use Grupos de Recursos separados por ambiente
- ✅ Implemente gates de aprovação para deploys em produção
- ✅ Considere usar uma conexão privilegiada apenas para operações RBAC

## 📊 Visão Geral dos Pipelines

|| Pipeline | Tipo | Propósito | Trigger |
|----------|------|-----------|---------|
|| **infra_ci.yaml** | CI | Validar & build infra | Ao commitar em `main` ou em PR |
|| **infra_cd.yaml** | CD | Implantar infra | Manual ou após CI |
|| **k8s_ci.yaml** | CI | Build de imagens de serviço AKS | Ao commitar em `src/AKS/` |
|| **k8s_cd.yaml** | CD | Deploy dos serviços AKS | Manual ou após k8s CI |

## ⏱️ Prazos Estimados

| Operação | Primeira execução | Subsequentemente |
|----------|-------------------|------------------|
| Registro de provedores | ~5 min | Instantâneo |
| Configuração da conexão | ~10 min | - |
| Atribuição RBAC | ~2 min | - |
| Infra CI Pipeline | ~3-5 min | ~3-5 min |
| Infra CD Pipeline | ~60-90 min | ~10-20 min |

Por quê tão longo?
- Criação do APIM (Developer SKU): 20-45 minutos  
- Criação do AKS: 10-20 minutos  
- A primeira implantação inclui todos os recursos

## 🔧 Solução de Problemas

### Problemas com Conexão de Serviço

**Problema:** "Failed to authorize"  
- **Solução:** Verifique se o service principal tem os papéis RBAC corretos na assinatura e no RG

**Problema:** "Could not find resource group"  
- **Solução:** Garanta que o RG existe e que o escopo da conexão de serviço está configurado corretamente

### Falhas em Pipelines

**Problema:** Pipeline atingiu timeout  
- **Solução:** O pipeline Infra CD tem timeout de 90 minutos. Se ainda timeout, verifique o Portal Azure para progresso da implantação

**Problema:** "Resource providers not registered"  
- **Solução:** Aguarde registro dos provedores (~5 minutos)

**Problema:** "Bicep not found"  
- **Solução:** O CI instala o Bicep automaticamente. Verifique os logs do pipeline para erros de instalação

## ⏭️ Próximos Passos

- ✅ **Conexão de serviço criada?** → Prossiga para [Implantação de Infraestrutura](04-infrastructure-deployment.pt-BR.md)  
- ⚠️ **Pipelines falhando?** → Consulte [Guia de Solução de Problemas](troubleshooting.pt-BR.md)  
- 📚 **Quer entender pipelines?** → Veja [Guia de Pipelines CI/CD](cicd-pipelines.pt-BR.md)

## 📚 Recursos Adicionais

- [Azure DevOps Service Connections](https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints)
- [Workload Identity Federation](https://learn.microsoft.com/azure/devops/pipelines/library/connect-to-azure)
- [Azure RBAC Documentation](https://learn.microsoft.com/azure/role-based-access-control/)

---

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [👈 Anterior](02-local-development.pt-BR.md) | [👉 Próximo](04-infrastructure-deployment.pt-BR.md)