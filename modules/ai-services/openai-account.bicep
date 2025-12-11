// @description('Name of the Azure OpenAI account')
// param aiAccountName string

// @description('Azure region')
// param location string = resourceGroup().location

// @description('SKU for OpenAI')
// param skuName string = 'S0'

// resource aiAccount 'Microsoft.CognitiveServices/accounts@2023-10-01' = {
//   name: aiAccountName
//   location: location
//   kind: 'OpenAI'
//   sku: {
//     name: skuName
//   }
//   properties: {
//     apiProperties: {
//       statisticsEnabled: true
//     }
//   }
// }

// output aiAccountId string = aiAccount.id
