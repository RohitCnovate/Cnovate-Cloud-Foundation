targetScope = 'resourceGroup'
param location string = resourceGroup().location
param resourceToken string
param appName string
param maximumInstanceCount int
param instanceMemoryMB int
param functionAppRuntime string
param functionAppRuntimeVersion string
param deploymentStorageContainerName string

// Existing resources (ONLY names)
param storageAccountName string
param userAssignedIdentityName string
param applicationInsightsName string

// Existing UAMI
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userAssignedIdentityName
}

// Existing Storage
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Existing App Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

module functionAppModule './modules/compute/functionapp.bicep' = {
  name: 'functionAppDeploy'
  params: {
    location: location
    resourceToken: resourceToken
    appName: appName
    maximumInstanceCount: maximumInstanceCount
    instanceMemoryMB: instanceMemoryMB
    functionAppRuntime: functionAppRuntime
    functionAppRuntimeVersion: functionAppRuntimeVersion
    deploymentStorageContainerName: deploymentStorageContainerName

    // Passing values to module  
    userAssignedIdentityId: userAssignedIdentity.id
    userAssignedClientId: userAssignedIdentity.properties.clientId

    storageAccountName: storage.name
    blobEndpoint: storage.properties.primaryEndpoints.blob

    appInsightsKey: applicationInsights.properties.InstrumentationKey
  }
}

targetScope = 'resourceGroup'


param location string
param openAiName string
param enablePrivateEndpoint bool = false
param subnetId string = ''
param logAnalyticsId string = ''
param deployments array


module openaiAccount './modules/openai-account.bicep' = {
name: 'openai-account'
params: {
name: openAiName
location: location
enablePrivateEndpoint: enablePrivateEndpoint
subnetId: subnetId
logAnalyticsId: logAnalyticsId
}
}


module openaiDeployments './modules/openai-deployment.bicep' = [
for d in deployments: {
name: 'deploy-${d.deploymentName}'
params: {
openAiAccountName: openAiName
deploymentName: d.deploymentName
modelName: d.modelName
modelVersion: d.modelVersion
capacity: d.capacity
}
dependsOn: [ openaiAccount ]
}
]

