// @description('Azure OpenAI account name')
// param aiAccountName string

// @description('Model name such as gpt-4o, gpt-4-turbo, text-embedding-3-large')
// param modelName string

// @description('Deployment name for the model')
// param deploymentName string

// resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01' = {
//   name: '${aiAccountName}/${deploymentName}'
//   properties: {
//     model: {
//       format: 'OpenAI'
//       name: modelName
//       version: '1'   // optional
//     }
//     sku: {
//       name: 'Standard'
//     }
//   }
// }
