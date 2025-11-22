// ============================================================================
// Módulo APIM (apim.bicep)
// Responsabilidade: provisionar o API Management como gateway unificado para
// todos os serviços (AKS, Azure Functions, Logic Apps).
//
// Parâmetros (detalhados):
// - environment (string): rótulo do ambiente
// - location (string): região do Azure
// - sku (string): SKU do APIM (ex.: Developer)
// - apimName (string): nome do serviço APIM
// - publisherEmail (string): e-mail do publicador
// - publisherName (string): nome do publicador
// - aksServiceUrl (string): URL do serviço AKS LoadBalancer
// - customerFunctionUrl (string): URL da Customer Function
// - supplierFunctionUrl (string): URL da Supplier Function
// - logicAppUrl (string): URL do Logic App callback
//
// Saídas:
// - apimUrl (string): gatewayUrl do APIM
// - apimId (string): resourceId do APIM
//
// Pontos de atenção:
// - Os backends são configurados dinamicamente com base nas URLs fornecidas
// - Cada API tem operações específicas mapeadas
// - Subscription keys são requeridos por padrão
// - CORS e rate limiting podem ser adicionados via policies
// ============================================================================

// Parâmetros principais
param environment string
param location string = resourceGroup().location
param sku string
param apimName string
param publisherEmail string = 'admin@empresa.com'
param publisherName string = 'Empresa Tech'

// URLs dos backends (fornecidas pelo main.bicep após deployment)
param aksServiceUrl string = 'http://10.0.0.1' // Placeholder - atualizar após AKS deployment
param customerFunctionUrl string = '' // Ex: https://comp-poc-test-func-customer-dev.azurewebsites.net
param supplierFunctionUrl string = '' // Ex: https://comp-poc-test-func-supplier-dev.azurewebsites.net
param logicAppUrl string = '' // Ex: https://logic app callback URL

// ============================================================================
// APIM Service
// ============================================================================
resource apim 'Microsoft.ApiManagement/service@2022-08-01' = {
  name: apimName
  location: location
  tags: {
    environment: environment
  }
  sku: {
    name: sku
    capacity: 1
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: 'None'
    notificationSenderEmail: publisherEmail
  }
}

// ============================================================================
// API Version Set
// ============================================================================
resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2022-08-01' = {
  name: 'v1'
  parent: apim
  properties: {
    displayName: 'API Version 1'
    versioningScheme: 'Segment'
    description: 'Version 1 of all APIs'
  }
}

// ============================================================================
// APIs
// ============================================================================

// API: Authentication (AKS)
resource apiAuth 'Microsoft.ApiManagement/service/apis@2022-08-01' = {
  name: 'auth-api'
  parent: apim
  properties: {
    displayName: 'Authentication API'
    description: 'User authentication and token management'
    path: 'auth'
    protocols: ['https']
    apiVersion: 'v1'
    apiVersionSetId: apiVersionSet.id
    subscriptionRequired: true
    serviceUrl: '${aksServiceUrl}/api'
  }
}

// Operations: Auth API
resource authOperationLogin 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = {
  name: 'login'
  parent: apiAuth
  properties: {
    displayName: 'Login'
    method: 'POST'
    urlTemplate: '/auth/login'
    description: 'Authenticate user and return JWT token'
    request: {
      description: 'Login credentials'
      representations: [
        {
          contentType: 'application/json'
          examples: {
            default: {
              value: {
                username: 'admin'
                password: 'admin123'
              }
            }
          }
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        description: 'Login successful'
        representations: [
          {
            contentType: 'application/json'
          }
        ]
      }
      {
        statusCode: 401
        description: 'Invalid credentials'
      }
    ]
  }
}

resource authOperationRefresh 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = {
  name: 'refresh-token'
  parent: apiAuth
  properties: {
    displayName: 'Refresh Token'
    method: 'POST'
    urlTemplate: '/auth/refresh-token'
    description: 'Refresh JWT token'
    request: {
      representations: [
        {
          contentType: 'application/json'
          examples: {
            default: {
              value: {
                token: 'EXISTING_JWT_TOKEN'
              }
            }
          }
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        description: 'Token refreshed successfully'
      }
    ]
  }
}

// API: Products (AKS)
resource apiProducts 'Microsoft.ApiManagement/service/apis@2022-08-01' = {
  name: 'products-api'
  parent: apim
  properties: {
    displayName: 'Products API'
    description: 'Product catalog management'
    path: 'products'
    protocols: ['https']
    apiVersion: 'v1'
    apiVersionSetId: apiVersionSet.id
    subscriptionRequired: true
    serviceUrl: '${aksServiceUrl}/api'
  }
}

// Operations: Products API
resource productsOperationGetAll 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = {
  name: 'get-all-products'
  parent: apiProducts
  properties: {
    displayName: 'Get All Products'
    method: 'GET'
    urlTemplate: '/products'
    description: 'Retrieve all products'
    responses: [
      {
        statusCode: 200
        description: 'Products retrieved successfully'
        representations: [
          {
            contentType: 'application/json'
          }
        ]
      }
    ]
  }
}

resource productsOperationGetById 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = {
  name: 'get-product-by-id'
  parent: apiProducts
  properties: {
    displayName: 'Get Product by ID'
    method: 'GET'
    urlTemplate: '/products/{id}'
    description: 'Retrieve a specific product by ID'
    templateParameters: [
      {
        name: 'id'
        type: 'integer'
        required: true
        description: 'Product ID'
      }
    ]
    responses: [
      {
        statusCode: 200
        description: 'Product found'
      }
      {
        statusCode: 404
        description: 'Product not found'
      }
    ]
  }
}

// API: Customers (Azure Function)
resource apiCustomers 'Microsoft.ApiManagement/service/apis@2022-08-01' = if (!empty(customerFunctionUrl)) {
  name: 'customers-api'
  parent: apim
  properties: {
    displayName: 'Customers API'
    description: 'Customer management via Azure Functions'
    path: 'customers'
    protocols: ['https']
    apiVersion: 'v1'
    apiVersionSetId: apiVersionSet.id
    subscriptionRequired: true
    serviceUrl: !empty(customerFunctionUrl) ? '${customerFunctionUrl}/api' : ''
  }
}

// Operations: Customers API
resource customersOperationGetAll 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = if (!empty(customerFunctionUrl)) {
  name: 'get-all-customers'
  parent: apiCustomers
  properties: {
    displayName: 'Get All Customers'
    method: 'GET'
    urlTemplate: '/customer'
    description: 'Retrieve all customers'
    responses: [
      {
        statusCode: 200
        description: 'Customers retrieved successfully'
      }
    ]
  }
}

resource customersOperationGetById 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = if (!empty(customerFunctionUrl)) {
  name: 'get-customer-by-id'
  parent: apiCustomers
  properties: {
    displayName: 'Get Customer by ID'
    method: 'GET'
    urlTemplate: '/customer/{id}'
    description: 'Retrieve a specific customer by ID'
    templateParameters: [
      {
        name: 'id'
        type: 'integer'
        required: true
        description: 'Customer ID'
      }
    ]
    responses: [
      {
        statusCode: 200
        description: 'Customer found'
      }
      {
        statusCode: 404
        description: 'Customer not found'
      }
    ]
  }
}

resource customersOperationCreate 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = if (!empty(customerFunctionUrl)) {
  name: 'create-customer'
  parent: apiCustomers
  properties: {
    displayName: 'Create Customer'
    method: 'POST'
    urlTemplate: '/customer'
    description: 'Create a new customer'
    request: {
      representations: [
        {
          contentType: 'application/json'
          examples: {
            default: {
              value: {
                customerName: 'John Doe'
                email: 'john@example.com'
                phoneNumber: '+1-555-0101'
              }
            }
          }
        }
      ]
    }
    responses: [
      {
        statusCode: 201
        description: 'Customer created successfully'
      }
    ]
  }
}

// API: Suppliers (Azure Function)
resource apiSuppliers 'Microsoft.ApiManagement/service/apis@2022-08-01' = if (!empty(supplierFunctionUrl)) {
  name: 'suppliers-api'
  parent: apim
  properties: {
    displayName: 'Suppliers API'
    description: 'Supplier management via Azure Functions'
    path: 'suppliers'
    protocols: ['https']
    apiVersion: 'v1'
    apiVersionSetId: apiVersionSet.id
    subscriptionRequired: true
    serviceUrl: !empty(supplierFunctionUrl) ? '${supplierFunctionUrl}/api' : ''
  }
}

// Operations: Suppliers API
resource suppliersOperationGetAll 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = if (!empty(supplierFunctionUrl)) {
  name: 'get-all-suppliers'
  parent: apiSuppliers
  properties: {
    displayName: 'Get All Suppliers'
    method: 'GET'
    urlTemplate: '/supplier'
    description: 'Retrieve all suppliers'
    responses: [
      {
        statusCode: 200
        description: 'Suppliers retrieved successfully'
      }
    ]
  }
}

resource suppliersOperationGetById 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = if (!empty(supplierFunctionUrl)) {
  name: 'get-supplier-by-id'
  parent: apiSuppliers
  properties: {
    displayName: 'Get Supplier by ID'
    method: 'GET'
    urlTemplate: '/supplier/{id}'
    description: 'Retrieve a specific supplier by ID'
    templateParameters: [
      {
        name: 'id'
        type: 'integer'
        required: true
        description: 'Supplier ID'
      }
    ]
    responses: [
      {
        statusCode: 200
        description: 'Supplier found'
      }
      {
        statusCode: 404
        description: 'Supplier not found'
      }
    ]
  }
}

resource suppliersOperationCreate 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = if (!empty(supplierFunctionUrl)) {
  name: 'create-supplier'
  parent: apiSuppliers
  properties: {
    displayName: 'Create Supplier'
    method: 'POST'
    urlTemplate: '/supplier'
    description: 'Create a new supplier'
    request: {
      representations: [
        {
          contentType: 'application/json'
          examples: {
            default: {
              value: {
                supplierName: 'ABC Supplies'
                contactEmail: 'contact@abc.com'
              }
            }
          }
        }
      ]
    }
    responses: [
      {
        statusCode: 201
        description: 'Supplier created successfully'
      }
    ]
  }
}

// API: Orders (Logic App)
resource apiOrders 'Microsoft.ApiManagement/service/apis@2022-08-01' = if (!empty(logicAppUrl)) {
  name: 'orders-api'
  parent: apim
  properties: {
    displayName: 'Orders API'
    description: 'Order processing via Logic Apps'
    path: 'orders'
    protocols: ['https']
    apiVersion: 'v1'
    apiVersionSetId: apiVersionSet.id
    subscriptionRequired: true
    serviceUrl: !empty(logicAppUrl) ? logicAppUrl : ''
  }
}

// Operations: Orders API (placeholder - ajustar conforme Logic App)
resource ordersOperationProcess 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = if (!empty(logicAppUrl)) {
  name: 'process-order'
  parent: apiOrders
  properties: {
    displayName: 'Process Order'
    method: 'POST'
    urlTemplate: '/process'
    description: 'Process a new order via Logic App workflow'
    request: {
      representations: [
        {
          contentType: 'application/json'
          examples: {
            default: {
              value: {
                orderId: 123
                customerId: 456
                items: []
              }
            }
          }
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        description: 'Order processed successfully'
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================
output apimUrl string = apim.properties.gatewayUrl
output apimId string = apim.id
output apimName string = apim.name
