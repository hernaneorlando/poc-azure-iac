// ============================================================================
// Key Vault Module (keyvault.bicep)
// Responsibility: provision secrets vault with RBAC enabled.
//
// Parameters (detailed):
// - environment (string): environment label
// - location (string): Azure region
// - keyVaultName (string): vault name
// Outputs:
// - keyVaultId (string): vault resourceId
// - keyVaultUri (string): vault public URI
// Key Points:
// - enableRbacAuthorization = true: access is controlled by Azure RBAC.
// - Manually grant (outside pipeline) minimal roles to identities
//   (e.g., UAMI with "Key Vault Secrets User").
// ============================================================================

// Main Parameters
param environment string
param location string = resourceGroup().location
param keyVaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  tags: {
    environment: environment
  }
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    // Policies can be added as needed
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
