param openAiAccountName string
param deploymentName string
param modelName string
param modelVersion string

// Reference existing OpenAI account
resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAiAccountName
}

// Deployment under the OpenAI account
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  name: deploymentName
  parent: openAi
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
    // ⚡ Remove scaleSettings entirely for GPT-4o
  }
}








