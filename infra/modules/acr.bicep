// ============================================================================
// ACR Module (acr.bicep)
// Responsibility: provision Azure Container Registry to store
// Docker images for AKS services.
//
// Parameters (detailed):
// - environment (string): environment label
// - location (string): Azure region
// - acrName (string): ACR name (must be globally unique, alphanumeric only)
// - acrSku (string): ACR SKU (Basic/Standard/Premium)
//
// Outputs:
// - acrId (string): ACR resourceId
// - acrLoginServer (string): login server URL (e.g., compoctestacr.azurecr.io)
//
// Key Points:
// - ACR name must be globally unique and alphanumeric only (no hyphens)
// - Basic SKU is suitable for POC/Dev; Standard/Premium for production
// - Admin user enabled for POC convenience; use Managed Identity in production
// ============================================================================

// Main Parameters
param environment string
param location string = resourceGroup().location
param acrName string

@description('ACR SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('Enables admin user for easy access (POC/Dev only)')
param adminUserEnabled bool = true

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  tags: {
    environment: environment
  }
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
    anonymousPullEnabled: false
  }
}

output acrId string = acr.id
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
