# Serviços AKS - Guia de Desenvolvimento Local

**Idiomas / Languages:** [🇺🇸 English](README.md) | [🇧🇷 Português](README.pt-BR.md)

**Navegação:** [🏠 Início](../../README.md) | [📚 Documentação](../../docs/README.md) | [⬅️ Voltar para Setup Local](../../docs/02-local-development.md)

## Visão Geral

Este diretório contém os microsserviços executados no Azure Kubernetes Service (AKS):
- **Authentication**: Autenticação e autorização de usuários
- **Products**: Gerenciamento de catálogo de produtos

Ambos os serviços são construídos com .NET 8.0 e containerizados para deployment no Kubernetes.

## Endpoints Disponíveis

### Serviço de Autenticação
- `POST /api/auth/login` - Autenticação de usuários
- `POST /api/auth/register` - Registro de novos usuários

### Serviço de Produtos
- `GET /api/products` - Listar todos os produtos
- `GET /api/products/{id}` - Obter produto por ID

## Configuração para Desenvolvimento Local

### Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- Conta no Docker Hub (para publicar imagens)

### Executando Localmente com Minikube

#### 1. Iniciar Minikube

```bash
minikube start
```

#### 2. Build e Push das Imagens Docker

```bash
cd src/AKS

# Build Authentication
docker build -t <SEU_USUARIO_DOCKERHUB>/auth-api:latest -f Authentication/Dockerfile .
docker push <SEU_USUARIO_DOCKERHUB>/auth-api:latest

# Build Products
docker build -t <SEU_USUARIO_DOCKERHUB>/products-api:latest -f Products/Dockerfile .
docker push <SEU_USUARIO_DOCKERHUB>/products-api:latest
```

#### 3. Atualizar Manifestos do Kubernetes

Edite os arquivos de deployment em `infra/k8s/` para usar suas imagens do Docker Hub:

```yaml
# infra/k8s/auth-deployment.yaml
image: <SEU_USUARIO_DOCKERHUB>/auth-api:latest

# infra/k8s/products-deployment.yaml
image: <SEU_USUARIO_DOCKERHUB>/products-api:latest
```

#### 4. Criar Secrets

```bash
# Secret do Authentication (JWT)
kubectl create secret generic auth-api-secrets \
  --from-literal=jwt-secret="my-super-secret-key-for-testing-123"

# Secret do Products (Connection String)
kubectl create secret generic products-api-secrets \
  --from-literal=connectionString="Server=localhost;Database=ProductsDB;"
```

Ou aplicar os arquivos YAML:

```bash
kubectl apply -f infra/k8s/auth-secrets.yaml
kubectl apply -f infra/k8s/products-secrets.yaml
```

#### 5. Deploy no Minikube

```bash
kubectl apply -f infra/k8s/auth-deployment.yaml
kubectl apply -f infra/k8s/products-deployment.yaml
```

#### 6. Verificar Status dos Pods

```bash
kubectl get pods
kubectl logs <nome-do-pod>
```

#### 7. Acessar os Serviços

##### Usando Port-Forward:

```bash
# Authentication (terminal 1)
kubectl port-forward service/auth-api 8080:8080

# Products (terminal 2)
kubectl port-forward service/products-api 8081:8081
```

Depois acesse:
- Authentication: `http://localhost:8080/swagger`
- Products: `http://localhost:8081/swagger`

##### Usando NodePort (se configurado):

```bash
minikube service auth-api --url
minikube service products-api --url
```

## Estrutura do Projeto

```
AKS/
├── Authentication/
│   ├── Program.cs
│   ├── Authentication.csproj
│   ├── Dockerfile
│   └── Resources/
│       └── AuthController.cs
├── Products/
│   ├── Program.cs
│   ├── Products.csproj
│   ├── Dockerfile
│   └── Resources/
│       └── ProductsController.cs
└── Common/
    └── Common.csproj
```

## Solução de Problemas

### Erro ImagePullBackOff
- Verifique se a imagem existe no Docker Hub
- Confira se o nome da imagem no YAML do deployment está correto
- Para repos privados, crie imagePullSecrets

### CreateContainerConfigError
- Certifique-se de que os secrets foram criados antes do deployment
- Verifique se os nomes dos secrets correspondem à configuração do deployment

### Problema com Porta 8080
- .NET 8 usa porta 8080 por padrão
- Garanta que `targetPort: 8080` está configurado no Service

## Teste Local (Sem Kubernetes)

```bash
# Executar API de Authentication
cd src/AKS/Authentication
dotnet run

# Executar API de Products (em outro terminal)
cd src/AKS/Products
dotnet run
```

Ambas estarão disponíveis em `http://localhost:5000` (ou porta configurada).

## Integração CI/CD

- Build de imagens no pipeline de CI
- Push para Azure Container Registry (ACR)
- Deploy no cluster AKS via pipeline de CD
- Use Workload Identity para acesso seguro aos recursos do Azure
