// ============================================================================
// Monitor Module (monitor.bicep)
// Responsibility: provision Log Analytics Workspace and Application Insights
// (linked to workspace) for observability and telemetry.
//
// Parameters (detailed):
// - environment (string): environment label
// - location (string): Azure region
// - logAnalyticsName (string): workspace name
// - appInsightsName (string): App Insights name
// - logAnalyticsId (string): workspace resourceId (to link App Insights)
// Notes:
// - Adjust retentionInDays and SKU according to cost/retention requirements.
// ============================================================================

// Main Parameters
param environment string
param location string = resourceGroup().location
param logAnalyticsName string
param appInsightsName string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsName
  location: location
  tags: {
    environment: environment
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: {
    environment: environment
  }
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

output logAnalyticsId string = logAnalytics.id
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
