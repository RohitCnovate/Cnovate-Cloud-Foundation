targetScope = 'resourceGroup'

param location string = resourceGroup().location
param openAiName string
param enablePrivateEndpoint bool = false
param subnetId string = ''

// CMK params
param keyName string
param keyVersion string = ''

param deployments array

module openaiAccount './modules/ai-services/openai-account.bicep' = {
  name: 'openai-account'
  params: {
    name: openAiName
    location: location
    enablePrivateEndpoint: enablePrivateEndpoint
    subnetId: subnetId
    keyName: keyName
    keyVersion: keyVersion
  }
}

module openaiDeployments './modules/ai-services/openai-deployment.bicep' = [
  for d in deployments: {
    name: 'deploy-${d.deploymentName}'
    params: {
      openAiAccountName: openAiName
      deploymentName: d.deploymentName
      modelName: d.modelName
      modelVersion: d.modelVersion
    }
    dependsOn: [
      openaiAccount
    ]
  }
]
