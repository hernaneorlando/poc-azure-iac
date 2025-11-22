// ============================================================================
// AKS Module (aks.bicep)
// Responsibility: provision AKS cluster with OIDC enabled to
// support Azure AD Workload Identity; RBAC enabled; default network profile.
//
// Parameters (detailed):
// - environment (string): environment label
// - location (string): Azure region
// - aksName (string): AKS cluster name
// - nodeCount (int): number of nodes in system nodepool (default: 1)
// - nodeVMSize (string): VM SKU for nodepool (default: Standard_D2s_v6)
// Outputs:
// - aksClusterId (string): cluster resourceId
// - aksClusterName (string): cluster name
// - kubeletIdentityObjectId (string): Kubelet identity objectId (for ACR RBAC)
// Key Points:
// - oidcIssuerProfile.enabled = true to allow FIC (federated identity).
// - Adjust nodeVMSize/nodeCount based on budget and expected load.
// ============================================================================

// Main Parameters
param environment string
param location string = resourceGroup().location
param aksName string
param nodeCount int = 1
param nodeVMSize string = 'Standard_D2s_v6'
param logAnalyticsId string

resource aks 'Microsoft.ContainerService/managedClusters@2023-01-01' = {
  name: aksName
  location: location
  tags: {
    environment: environment
  }
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: '${aksName}-dns'
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsId
        }
      }
    }
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: nodeCount
        vmSize: nodeVMSize
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
      }
    ]
    enableRBAC: true
    oidcIssuerProfile: {
      enabled: true
    }
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
    }
  }
}

output aksClusterId string = aks.id
output aksClusterName string = aks.name
output kubeletIdentityObjectId string = aks.properties.identityProfile.kubeletidentity.objectId
