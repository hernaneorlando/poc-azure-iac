// ============================================================================
// Root Module (main.bicep)
// Responsibility: orchestrate creation of infrastructure resources
// (Key Vault, Log Analytics + App Insights, AKS, APIM) and, optionally,
// workload identity (UAMI + FIC) for use with AKS OIDC.
//
// Main Parameters (detailed):
// - environment (string): environment label (dev/qa/prod)
// - location (string): Azure region (default: resourceGroup().location)
// - keyVaultName (string): Key Vault name
// - logAnalyticsName (string): Log Analytics Workspace name
// - appInsightsName (string): Application Insights name
// - aksName (string): AKS cluster name
// - apimName (string): API Management name
// - apimSku (string): APIM SKU (default: Developer)
// - enableWorkloadIdentity (bool): creates UAMI + FIC per workload (default: true)
// - workloadNamespace (string): ServiceAccount namespace (default: "default")
// - workloadServiceAccount (string): ServiceAccount name (default: "workload-sa")
// - uamiName (string): workload UAMI name (default: "${aksName}-wi")
//
// Design Notes:
// - Sensitive RBAC (e.g., UAMI access to Key Vault) is applied manually
//   for security and least privilege principle.
// - What-If runs in CI; CD performs incremental deployment.
// - AKS is created with OIDC enabled to support Workload Identity.
// ============================================================================

// Main Parameters
@description('Environment name (dev, qa, prod)')
@allowed([
  'dev'
  'qa'
  'prod'
])
param environment string

@description('Azure region for all resources')
param location string = resourceGroup().location

// Resource Parameters
param keyVaultName string
param logAnalyticsName string
param appInsightsName string
param aksName string
param acrName string
param apimName string

@description('API Management SKU')
@allowed([
  'Developer'
  'Basic'
  'Standard'
  'Premium'
])
param apimSku string = 'Developer'

// Workload Identity Parameters (single structure for all environments)
@description('Enables creation of workload managed identity (UAMI) and federated credential for use with AKS OIDC. Default: true')
param enableWorkloadIdentity bool = true
@description('Kubernetes namespace of the workload that will use the identity.')
param workloadNamespace string = 'default'
@description('Kubernetes ServiceAccount of the workload that will use the identity.')
param workloadServiceAccount string = 'workload-sa'
@description('Name of the UAMI to be created for the workload. Default derives from AKS name.')
param uamiName string = '${aksName}-wi'

// Function Apps Parameters
@description('Array of Function App configurations to be created. Each object must contain: name, storageAccountName, runtime, workerRuntime')
param functionApps array = []

// Logic Apps Parameters
@description('Array of Logic App configurations to be created. Each object must contain: name, appServicePlanName, storageAccountName')
param logicApps array = []

// Modules
module keyVaultModule 'modules/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    keyVaultName: keyVaultName
    location: location
    environment: environment
  }
}

module monitorModule 'modules/monitor.bicep' = {
  name: 'monitorDeployment'
  params: {
    location: location
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
    environment: environment
  }
}

// ============================================================================
// ACR Module: provisions Azure Container Registry to store
// Docker images for AKS services.
// ============================================================================
module acr 'modules/acr.bicep' = {
  name: 'acrDeployment'
  params: {
    environment: environment
    location: location
    acrName: acrName
    acrSku: 'Basic' // Adjust to Standard/Premium in production
    adminUserEnabled: true // For POC; use Managed Identity in production
  }
}

module aks './modules/aks.bicep' = {
  name: 'aksDeployment'
  params: {
    location: location
    aksName: aksName
    environment: environment
    logAnalyticsId: monitorModule.outputs.logAnalyticsId
  }
  dependsOn: [
    acr
  ]
}

module apim './modules/apim.bicep' = {
  name: 'apimDeployment'
  params: {
    location: location
    apimName: apimName
    environment: environment
    sku: apimSku
  }
}

// Workload Identity: UAMI + Federated Credential (for use with AKS OIDC)
module workloadIdentity 'modules/workload-identity.bicep' = if (enableWorkloadIdentity) {
  name: 'workloadIdentityDeployment'
  params: {
    location: location
    environment: environment
    aksName: aksName
    uamiName: uamiName
    workloadNamespace: workloadNamespace
    workloadServiceAccount: workloadServiceAccount
  }
  dependsOn: [
    aks
  ]
}

// Function Apps: provisions Azure Functions with Storage Account and App Service Plan
module functionAppsModule 'modules/function-app.bicep' = if (length(functionApps) > 0) {
  name: 'functionAppsDeployment'
  params: {
    location: location
    environment: environment
    functionApps: functionApps
    appInsightsConnectionString: monitorModule.outputs.appInsightsConnectionString
    appInsightsInstrumentationKey: monitorModule.outputs.appInsightsInstrumentationKey
  }
}

// Logic Apps: provisions Logic Apps Standard with Storage Account and App Service Plan
module logicAppsModule 'modules/logicapp.bicep' = [for (logicApp, index) in logicApps: if (length(logicApps) > 0) {
  name: 'logicApp-${logicApp.name}-Deployment'
  params: {
    location: location
    logicAppName: logicApp.name
    appServicePlanName: logicApp.appServicePlanName
    storageAccountName: logicApp.storageAccountName
    appInsightsInstrumentationKey: monitorModule.outputs.appInsightsInstrumentationKey
    tags: {
      Environment: environment
      ManagedBy: 'Bicep'
    }
  }
}]

// ============================================================================
// Role Assignment: AcrPull for AKS Kubelet Identity
// Allows AKS to pull images from ACR without requiring secrets.
// ============================================================================
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aksName, 'AcrPull')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: aks.outputs.kubeletIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}

