// ============================================================================
// Workload Identity per Workload (workload-identity.bicep)
// Responsibility: create a dedicated UAMI for the workload and the federated
// credential (FIC) linking the ServiceAccount (namespace/sa) to the AKS OIDC
// issuer. This allows pods to obtain tokens via OIDC without secrets.
//
// Parameters (detailed):
// - location (string): Azure region
// - environment (string): environment label
// - aksName (string): AKS cluster name (to read OIDC issuer)
// - uamiName (string): user-assigned managed identity name
// - workloadNamespace (string): ServiceAccount namespace
// - workloadServiceAccount (string): ServiceAccount name
// Outputs:
// - uamiClientId (string): UAMI clientId (for SA annotation)
// - uamiPrincipalId (string): UAMI principalId (for RBAC)
// - uamiResourceId (string): UAMI resourceId
// Notes:
// - Still necessary to grant RBAC on Key Vault for UAMI (minimal role
//   "Key Vault Secrets User" on vault scope), done manually.
// ============================================================================

param location string
param environment string
param aksName string
param uamiName string
param workloadNamespace string
param workloadServiceAccount string

// Existing AKS to get OIDC issuer
resource aks 'Microsoft.ContainerService/managedClusters@2023-01-01' existing = {
  name: aksName
}

var oidcIssuer = aks.properties.oidcIssuerProfile.issuerURL

// User-assigned managed identity (UAMI) dedicated to workload
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName
  location: location
  tags: {
    environment: environment
  }
}

// Federated credential linking ServiceAccount (namespace/sa) to AKS OIDC issuer
resource fic 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: 'fic-${workloadNamespace}-${workloadServiceAccount}'
  parent: uami
  properties: {
    issuer: oidcIssuer
    subject: 'system:serviceaccount:${workloadNamespace}:${workloadServiceAccount}'
    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}

output uamiClientId string = uami.properties.clientId
output uamiPrincipalId string = uami.properties.principalId
output uamiResourceId string = uami.id
