// =============================================================================
// Module: Logic App Standard
// Description: Creates a Logic App Standard (single-tenant) instance
// =============================================================================

@description('Name of the Logic App')
param logicAppName string

@description('Location for the Logic App')
param location string = resourceGroup().location

@description('Name of the App Service Plan for Logic App')
param appServicePlanName string

@description('Name of the Storage Account for Logic App state')
param storageAccountName string

@description('Application Insights Instrumentation Key')
param appInsightsInstrumentationKey string = ''

@description('Tags to apply to resources')
param tags object = {}

// Storage Account (Logic Apps Standard requires storage)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// App Service Plan for Logic App
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'WS1' // Workflow Standard tier
    tier: 'WorkflowStandard'
  }
  kind: 'elastic'
  properties: {
    reserved: false
    maximumElasticWorkerCount: 20
  }
}

// Logic App Standard
resource logicApp 'Microsoft.Web/sites@2023-01-01' = {
  name: logicAppName
  location: location
  tags: tags
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(logicAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: empty(appInsightsInstrumentationKey) ? '' : 'InstrumentationKey=${appInsightsInstrumentationKey}'
        }
      ]
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
          'https://ms.portal.azure.com'
        ]
      }
      use32BitWorkerProcess: false
      ftpsState: 'Disabled'
      netFrameworkVersion: 'v6.0'
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
}

// Outputs
output logicAppId string = logicApp.id
output logicAppName string = logicApp.name
output logicAppDefaultHostName string = logicApp.properties.defaultHostName
output logicAppPrincipalId string = logicApp.identity.principalId
output appServicePlanId string = appServicePlan.id
