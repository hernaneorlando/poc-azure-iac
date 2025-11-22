# Índice de Documentação

**Idiomas / Languages:** [🇧🇷 Português](README.pt-BR.md) | [🇺🇸 English](README.md)

**Navegação:** [🏠 Início](../README.pt-BR.md)

---

## 📚 Guia de Documentação Completa

Bem-vindo à documentação abrangente da POC de Microsserviços do Azure. Este guia é organizado como um **assistente passo a passo** para ajudá-lo a entender, configurar e implantar toda a solução.

## 🚀 Guias de Início Rápido (Siga em Ordem)

Estes guias orientam você durante todo o processo de configuração:

| # | Guia | Descrição | Tempo |
|---|------|----------|-------|
| **01** | [Visão Geral do Projeto](pt-BR/01-project-overview.pt-BR.md) | Entenda a arquitetura e componentes | 10 min |
| **02** | [Configuração de Desenvolvimento Local](pt-BR/02-local-development.pt-BR.md) | Execute todos os serviços em sua máquina | 30-45 min |
| **03** | [Configuração do Azure DevOps](pt-BR/03-devops-setup.pt-BR.md) | Configure pipelines e conexões de serviço | 20-30 min |
| **04** | [Implantação de Infraestrutura](pt-BR/04-infrastructure-deployment.pt-BR.md) | Implante recursos do Azure | 60-90 min |
| **05** | [Implantação de Serviços](pt-BR/05-services-deployment.pt-BR.md) | Implante microsserviços | 20-30 min |

**Tempo total:** ~2,5-3 horas (incluindo tempo de espera de implantação no Azure)

## 📖 Guias Específicos de Serviço

Documentação detalhada para cada tipo de serviço:

| Serviço | English | Português |
|---------|---------|-----------|
| **Serviços AKS** | [README.md](en-US/src-aks-readme.md) | [README.pt-BR.md](pt-BR/src-aks-readme.pt-BR.md) |
| **Azure Functions** | [README.md](en-US/src-azurefunctions-readme.md) | [README.pt-BR.md](pt-BR/src-azurefunctions-readme.pt-BR.md) |
| **Logic App** | [README.md](en-US/src-logicapp-readme.md) | [README.pt-BR.md](pt-BR/src-logicapp-readme.pt-BR.md) |

## 🛠️ Documentação de Referência

Referências técnicas aprofundadas:

- **[Componentes de Infraestrutura](pt-BR/infrastructure-components.pt-BR.md)** - Módulos Bicep explicados
- **[Pipelines CI/CD](pt-BR/cicd-pipelines.pt-BR.md)** - Estrutura e configuração de pipeline  
- **[Guia de Solução de Problemas](pt-BR/troubleshooting.pt-BR.md)** - Problemas comuns e soluções
- **[Guia de Bootstrap](pt-BR/bootstrap-guide.pt-BR.md)** - Sobre configuração automatizada (não recomendado para POC)

## 📁 Exemplos e Templates

- **[Exemplo de Bootstrap](examples/infra_bootstrap.exemplo.yaml)** - Referência de configuração automatizada

## 🎯 Escolha Seu Caminho

### Caminho 1: Desenvolvimento Local Primeiro ⭐ Recomendado para Aprendizado

Perfeito se você quer:
- Aprender a arquitetura na prática
- Testar localmente antes de implantar no Azure
- Minimizar custos do Azure durante desenvolvimento

**Comece aqui:** [02 - Configuração de Desenvolvimento Local](pt-BR/02-local-development.pt-BR.md)

### Caminho 2: Implantação Direta no Azure

Perfeito se você:
- Deseja uma configuração pronta para produção imediatamente
- Tem uma assinatura do Azure pronta
- Precisa de colaboração em equipe desde o primeiro dia

**Comece aqui:** [03 - Configuração do Azure DevOps](pt-BR/03-devops-setup.pt-BR.md)

## 📊 Status da Documentação

| Documento | Status | Última Atualização |
|-----------|--------|-------------------|
| Visão Geral do Projeto | ✅ Concluído | 2025-11 |
| Desenvolvimento Local | ✅ Concluído | 2025-11 |
| Configuração do Azure DevOps | ✅ Concluído | 2025-11 |
| Implantação de Infraestrutura | 🚧 Em Progresso | - |
| Implantação de Serviços | 🚧 Em Progresso | - |
| Componentes de Infraestrutura | 🚧 Planejado | - |
| Pipelines CI/CD | 🚧 Planejado | - |
| Solução de Problemas | 🚧 Planejado | - |

## 🌍 Suporte de Idioma

| Idioma | Status |
|--------|--------|
| 🇺🇸 English | ✅ Principal |
| 🇧🇷 Português | ⏳ Apenas READMEs de Serviço |

## 🔍 Links Rápidos

### Primeiros Passos
- [O que é esta POC?](pt-BR/01-project-overview.pt-BR#-o-que-é-esta-poc)
- [Diagrama de Arquitetura](pt-BR/01-project-overview.pt-BR#-diagrama-de-arquitetura)
- [Resumo de Pré-requisitos](../README.pt-BR#-resumo-dos-pré-requisitos)

### Desenvolvimento
- [Executar Serviços AKS Localmente](pt-BR/src-aks-readme.pt-BR#executando-localmente-com-minikube)
- [Executar Azure Functions Localmente](pt-BR/src-azurefunctions-readme.pt-BR#executando-localmente)
- [Executar Logic App Localmente](pt-BR/src-logicapp-readme.pt-BR#executando-localmente)

### Implantação
- [Criar Conexão de Serviço](pt-BR/03-devops-setup.pt-BR#passo-3-criar-conexão-de-serviço-no-azure-devops)
- [Registrar Provedores de Recursos](pt-BR/03-devops-setup.pt-BR#passo-1-portal-azure---registrar-provedores-de-recursos)
- [Criar Pipelines](pt-BR/03-devops-setup.pt-BR#passo-6-criar-pipeline-ci-de-infraestrutura)

### Solução de Problemas
- [Problemas de AKS](pt-BR/src-aks-readme.pt-BR#solução-de-problemas)
- [Problemas de Functions](pt-BR/src-azurefunctions-readme.pt-BR#solução-de-problemas)
- [Problemas de Logic App](pt-BR/src-logicapp-readme.pt-BR#solução-de-problemas)

## 💡 Dicas para Usar Esta Documentação

### Para Usuários Novatos
1. Leia [Visão Geral do Projeto](pt-BR/01-project-overview.pt-BR.md) para entender o quadro geral
2. Siga os Guias de Início Rápido em ordem
3. Consulte os Guias Específicos de Serviço para detalhes
4. Mantenha o Guia de Solução de Problemas à mão

### Para Usuários Experientes
- Pule diretamente para seções relevantes
- Use os Links Rápidos acima
- Consulte documentação de referência para análises aprofundadas

### Para Instrutores/Treinadores
- Guias são projetados para aprendizado no seu próprio ritmo
- Cada guia tem objetivos claros e estimativas de tempo
- Inclui solução de problemas para problemas comuns de aprendizado

## 📝 Contribuindo para a Documentação

Se você encontrar problemas ou tiver sugestões:
1. Verifique a documentação existente primeiro
2. Procure no Guia de Solução de Problemas
3. Revise READMEs específicos de serviço
4. Envie feedback ou PR

## 🆘 Precisa de Ajuda?

1. **Verifique o guia que você está seguindo** - A maioria dos problemas é abordada inline
2. **Revise [Guia de Solução de Problemas](pt-BR/troubleshooting.md)** - Problemas comuns e soluções
3. **Verifique README específico de serviço** - Configuração detalhada para cada serviço
4. **Revise logs de pipeline do Azure DevOps** - Para problemas de implantação

## 📚 Recursos Externos

- [Documentação do Azure](https://learn.microsoft.com/azure/)
- [Documentação do Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Documentação do Azure DevOps](https://learn.microsoft.com/azure/devops/)
- [Documentação do Kubernetes](https://kubernetes.io/docs/)

---

**Navegação:** [🏠 Início](../README.pt-BR.md)

**Pronto para começar?** 👉 [Comece com Visão Geral do Projeto](pt-BR/01-project-overview.pt-BR.md)