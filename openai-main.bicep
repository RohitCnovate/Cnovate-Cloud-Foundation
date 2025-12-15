targetScope = 'resourceGroup'

// OpenAI parameters
param location string = resourceGroup().location
param openAiName string
param enablePrivateEndpoint bool = false
param subnetId string = ''
param deployments array

// Deploy OpenAI Account
module openaiAccount './modules/ai-services/openai-account.bicep' = {
  name: 'openai-account'
  params: {
    name: openAiName
    location: location
    enablePrivateEndpoint: enablePrivateEndpoint
    subnetId: subnetId
  }
}

// Deploy OpenAI Deployments
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


