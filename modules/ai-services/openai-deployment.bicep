param openAiAccountName string
param deploymentName string
param modelName string
param modelVersion string
param capacity int


resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
name: openAiAccountName
}


resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
name: deploymentName
parent: openAi
properties: {
model: {
format: 'OpenAI'
name: modelName
version: modelVersion
}
scaleSettings: {
scaleType: 'Standard'
capacity: capacity
}
}
}
