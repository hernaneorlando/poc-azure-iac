# Azure Functions - Guia de Desenvolvimento Local

**Idiomas / Languages:** [🇺🇸 English](README.md) | [🇧🇷 Português](README.pt-BR.md)

**Navegação:** [🏠 Início](../../README.md) | [📚 Documentação](../../docs/README.md) | [⬅️ Voltar para Setup Local](../../docs/02-local-development.md)

## Visão Geral

Este diretório contém Azure Functions para operações serverless:
- **CustomerFunction**: Gerenciamento de clientes (GET all, GET por ID, POST)
- **SupplierFunction**: Gerenciamento de fornecedores (GET all, GET por ID, POST)

## Endpoints Disponíveis

### CustomerFunction
- `GET /api/customer` - Listar todos os clientes
- `GET /api/customer/{id}` - Obter cliente por ID
- `POST /api/customer` - Criar novo cliente

### SupplierFunction
- `GET /api/supplier` - Listar todos os fornecedores
- `GET /api/supplier/{id}` - Obter fornecedor por ID
- `POST /api/supplier` - Criar novo fornecedor

## Pré-requisitos

- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Azure Functions Core Tools](https://learn.microsoft.com/pt-br/azure/azure-functions/functions-run-local)
- [Azurite](https://learn.microsoft.com/pt-br/azure/storage/common/storage-use-azurite) (para emulação de storage local)

## Executando Localmente

### 1. Iniciar Azurite

```bash
# Usando Docker
docker run -d -p 10000:10000 -p 10001:10001 -p 10002:10002 --name azurite mcr.microsoft.com/azure-storage/azurite

# Ou instalar globalmente com npm
npm install -g azurite
azurite
```

### 2. Executar CustomerFunction

```bash
cd src/AzureFunctions/OrdersFunction
func start
```

Acesse em: `http://localhost:7071/api/customer`

### 3. Executar SupplierFunction

```bash
cd src/AzureFunctions/SupplierFunction
func start --port 7072
```

Acesse em: `http://localhost:7072/api/supplier`

## Testando

```powershell
# Obter todos os clientes
Invoke-RestMethod -Uri "http://localhost:7071/api/customer" -Method GET

# Obter cliente por ID
Invoke-RestMethod -Uri "http://localhost:7071/api/customer/1" -Method GET

# Criar cliente
Invoke-RestMethod -Uri "http://localhost:7071/api/customer" -Method POST `
  -Body '{"customerName":"João Silva","email":"joao@example.com"}' `
  -ContentType "application/json"
```

## Estrutura do Projeto

```
AzureFunctions/
├── OrdersFunction/              # Contém CustomerFunction
│   ├── CustomerFunction.cs
│   ├── OrdersFunction.cs       # (Legacy - pode ser removido)
│   ├── Program.cs
│   └── Models/
│       ├── Customer.cs
│       ├── Order.cs
│       └── ApiResponse.cs
└── SupplierFunction/
    ├── SupplierFunction.cs
    ├── Program.cs
    └── Models/
        ├── Supplier.cs
        └── ApiResponse.cs
```

## Solução de Problemas

### Erro: "AzureWebJobsStorage" não configurado
- Certifique-se de que o Azurite está rodando
- Verifique se `local.settings.json` contém:
  ```json
  {
    "Values": {
      "AzureWebJobsStorage": "UseDevelopmentStorage=true"
    }
  }
  ```

### Porta já em uso
- Use `func start --port <outra-porta>` para especificar uma porta diferente
- Exemplo: `func start --port 7072`

### Authorization Level
- Localmente, funções com `AuthorizationLevel.Function` não requerem chave
- Em produção, obtenha a chave via Azure Portal ou CLI

## CI/CD

- Functions são deployadas em Azure Function Apps
- Use Application Insights para monitoramento
- Configure connection strings via referências do Key Vault
- Deploy via pipelines YAML no Azure DevOps

## Modelos de Dados

### Customer
```csharp
{
    "customerId": 1,
    "customerName": "João Silva",
    "email": "joao@example.com",
    "phoneNumber": "+55-11-99999-9999"
}
```

### Supplier
```csharp
{
    "supplierId": 1,
    "supplierName": "ABC Supplies",
    "contactEmail": "contact@abcsupplies.com"
}
```

## Próximos Passos

1. Implementar persistência de dados (Azure SQL, Cosmos DB)
2. Adicionar autenticação e autorização
3. Configurar Application Insights para telemetria
4. Implementar retry policies e circuit breakers
