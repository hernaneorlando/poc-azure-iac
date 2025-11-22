# Guia de Bootstrap

**Navegação:** [🏠 Início](../README.pt-BR.md) | [📚 Índice da Documentação](README.pt-BR.md)

---

## 🎯 O que é Bootstrap?

O **pipeline de bootstrap** (`infra_bootstrap.exemplo.yaml`) é uma configuração **opcional** automatizada que cria os recursos iniciais do Azure e as conexões de serviço necessárias para a POC.

⚠️ **Importante:** Este arquivo é fornecido apenas como **referência** e **NÃO é recomendado para esta POC**.

## 📂 Local do Arquivo

O exemplo de bootstrap foi movido para:
```
docs/examples/infra_bootstrap.exemplo.yaml
```

## 🚫 Por que NÃO usar Bootstrap para esta POC?

### Preocupações de Segurança
- Requer conexão de serviço com **privilégios elevados** (Owner ou User Access Administrator)
- Automatiza atribuições RBAC que devem ser revisadas manualmente
- Não é adequado para fins de aprendizado/educacionais

### Complexidade
- Acrescenta complexidade desnecessária à configuração da POC
- Passos manuais proporcionam melhor compreensão da arquitetura
- Mais fácil diagnosticar problemas quando feito manualmente

### Boa Prática
- O bootstrap de infraestrutura deve ser feito uma vez por organização/assinatura
- Não é destinado a ser repetido para cada POC ou ambiente

## ✅ Abordagem Recomendada (Configuração Manual)

Siga o **[Guia de Configuração do Azure DevOps (03)](03-devops-setup.md)** em vez disso, que fornece:
- Instruções passo a passo manuais
- Melhor experiência de aprendizado
- Mais controle sobre cada etapa
- Diagnóstico mais simples

## 📖 O que contém o arquivo de Bootstrap?

Para referência, o pipeline de bootstrap normalmente inclui:

### Estágio 1: Pré-requisitos
- Valida autenticação do Azure CLI
- Verifica acesso à assinatura
- Confirma permissões necessárias

### Estágio 2: Criação do Grupo de Recursos
```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: 'POC-Azure-Connection-Privileged'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az group create \
        --name $(resourceGroupName) \
        --location $(location) \
        --tags environment=$(environment)
```

### Estágio 3: Configuração da Conexão de Serviço
- Cria App Registration no Azure AD
- Configura credenciais federadas
- Atribui papéis RBAC
- Cria conexão de serviço no Azure DevOps via API

### Estágio 4: Atribuições RBAC
- Papel Reader na Assinatura
- Papel Contributor no Grupo de Recursos
- Outros papéis customizados conforme necessário

## 🔐 Quando VOCÊ usaria Bootstrap?

A automação de bootstrap é apropriada para:

### Cenários Corporativos
- Configurações **multi-assinatura** em larga escala
- **Padronização** de provisionamento de ambientes
- **Governança** com fluxos de aprovação
- **Auditoria** com registro adequado

### Requisitos
- ✅ Práticas DevOps maduras implementadas
- ✅ Aprovação da equipe de segurança
- ✅ Requisitos de trilha de auditoria atendidos
- ✅ Estrutura de governança adequada

### Casos de Uso Exemplares
- Criar 50+ ambientes de dev automaticamente
- Padronizar ambientes entre unidades de negócio
- Indústrias reguladas com requisitos de conformidade

## 🛠️ Como adaptar o Bootstrap (se necessário)

Se decidir usar bootstrap no futuro, veja como adaptar:

### 1. Criar Conexão de Serviço Privilegiada

Crie manualmente uma conexão com permissões elevadas:
- Azure DevOps > Service connections > New
- Escopo: **Subscription** (não Resource Group)
- Papel: **Owner** ou **User Access Administrator**
- Nome: `POC-Azure-Connection-Privileged`

### 2. Atualizar Variáveis

No arquivo YAML de bootstrap, atualize:

```yaml
variables:
  azureSubscription: 'POC-Azure-Connection-Privileged'
  subscriptionId: 'YOUR-SUBSCRIPTION-ID'
  resourceGroupName: 'your-rg-name'
  location: 'brazilsouth'
  environment: 'dev'
  serviceConnectionName: 'POC-Azure-Connection'
```

### 3. Adicionar Gates de Aprovação

Configure o pipeline para exigir aprovação antes de:
- Criar conexões de serviço
- Atribuir papéis RBAC
- Criar recursos

### 4. Executar com Cautela

- Revise todas as etapas antes de executar
- Tenha um plano de rollback
- Monitore o Activity Log do Azure
- Documente o que foi criado

## 📋 Bootstrap vs Manual (Comparação)

| Aspecto | Bootstrap | Manual (Recomendado) |
|--------|-----------|---------------------|
| **Tempo de Configuração** | ~15 minutos | ~30 minutos |
| **Valor de Aprendizado** | Baixo | Alto |
| **Risco de Segurança** | Maior | Menor |
| **Diagnóstico** | Mais difícil | Mais fácil |
| **Controle** | Menor | Maior |
| **Repetibilidade** | Alta | Média |
| **Auditabilidade** | Automatizada | Logs manuais |
| **Melhor Para** | Produção/Escala | POC/Aprendizado |

## 🎓 Principais Conclusões

1. ✅ **Para esta POC:** Use configuração manual (Guia 03)  
2. ✅ **Para aprendizado:** Manual é melhor  
3. ✅ **Para produção:** Considere bootstrap com governança adequada  
4. ⚠️ **Segurança primeiro:** Nunca execute automações privilegiadas sem revisão  
5. 📚 **Entenda antes:** Saiba o que o bootstrap faz antes de usá-lo

## ⏭️ Próximo Passo

Em vez de usar bootstrap, prossiga com:

👉 **[Configuração do Azure DevOps (Manual) — Guia 03](03-devops-setup.md)** - Caminho recomendado

## 📚 Recursos Adicionais

- [Segurança em Pipelines do Azure DevOps](https://learn.microsoft.com/azure/devops/pipelines/security/)
- [Segurança de Conexões de Serviço](https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints#secure-a-service-connection)
- [Melhores Práticas de RBAC no Azure](https://learn.microsoft.com/azure/role-based-access-control/best-practices)

---

**Navegação:** [🏠 Início](../../README.pt-BR.md) | [📚 Índice da Documentação](../README.pt-BR.md)