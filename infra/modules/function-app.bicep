// ============================================================================
// Function App Module (function-app.bicep)
// Responsibility: provision Azure Function Apps generically,
// including Storage Account, App Service Plan and configurations.
//
// Parameters (detailed):
// - environment (string): environment label
// - location (string): Azure region
// - functionApps (array): array of objects with name, storageAccountName
// - appInsightsConnectionString (string): App Insights connection string
// - appInsightsInstrumentationKey (string): App Insights instrumentation key
//
// Outputs:
// - functionAppNames (array): created Function App names
// - functionAppIds (array): created Function App IDs
//
// Notes:
// - Uses consumption plan (Y1) for cost optimization
// - Runtime configurable per function (Node.js, .NET, Python, etc.)
// - Storage Account created automatically for each function
// ============================================================================

// Main Parameters
param environment string
param location string = resourceGroup().location

@description('Array of Function App configurations to be created')
param functionApps array

@description('Application Insights Connection String')
param appInsightsConnectionString string

@description('Application Insights Instrumentation Key')
param appInsightsInstrumentationKey string

// App Service Plan (Consumption - Y1)
resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-functions-${environment}'
  location: location
  tags: {
    environment: environment
  }
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  properties: {
    reserved: true // Linux
  }
}

// Storage Accounts (one for each Function App)
resource storageAccounts 'Microsoft.Storage/storageAccounts@2022-09-01' = [for func in functionApps: {
  name: func.storageAccountName
  location: location
  tags: {
    environment: environment
    functionApp: func.name
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}]

// Function Apps
resource functionAppsResource 'Microsoft.Web/sites@2022-03-01' = [for (func, i) in functionApps: {
  name: func.name
  location: location
  kind: 'functionapp,linux'
  tags: {
    environment: environment
  }
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: func.runtime
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccounts[i].name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccounts[i].listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccounts[i].name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccounts[i].listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(func.name)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: func.workerRuntime
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
  }
}]

// Outputs
output functionAppNames array = [for (func, i) in functionApps: functionAppsResource[i].name]
output functionAppIds array = [for (func, i) in functionApps: functionAppsResource[i].id]
output functionAppUrls array = [for (func, i) in functionApps: functionAppsResource[i].properties.defaultHostName]
