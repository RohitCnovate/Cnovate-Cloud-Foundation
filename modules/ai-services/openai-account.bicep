// param name string
// param location string
// param enablePrivateEndpoint bool = false
// param subnetId string = ''

// resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
//   name: name
//   location: location
//   kind: 'OpenAI'
//   sku: {
    
//     name: 'S0'
//   }
//   properties: {
//     customSubDomainName: name
//     publicNetworkAccess: enablePrivateEndpoint ? 'Disabled' : 'Enabled'
//   }
// }

// // Optional Private Endpoint
// resource pe 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enablePrivateEndpoint) {
//   name: '${name}-pe'
//   location: location
//   properties: {
//     subnet: { id: subnetId }
//     privateLinkServiceConnections: [
//       {
//         name: 'openai-connection'
//         properties: {
//           privateLinkServiceId: openAi.id
//           groupIds: ['account']
//         }
//       }
//     ]
//   }
// }

// output openAiId string = openAi.id
// output openAiEndpoint string = openAi.properties.endpoint


param name string
param location string
param enablePrivateEndpoint bool = false
param subnetId string = ''

// 🔐 SAME UAMI (created in same RG or earlier in same deployment)
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'uami-storageidiscoverydeveastus03'
}

// 🔐 SAME KEY VAULT
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: 'kvidiscoverydeveastus10'
}

// 🔐 SAME CMK (created in same deployment)
resource cmk 'Microsoft.KeyVault/vaults/keys@2022-07-01' existing = {
  parent: keyVault
  name: 'cmk-data-key'
}

resource openAi 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: name
  location: location
  kind: 'OpenAI'

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }

  sku: {
    name: 'S0'
  }

  properties: {
    customSubDomainName: name
    publicNetworkAccess: enablePrivateEndpoint ? 'Disabled' : 'Enabled'

    encryption: {
      keySource: 'Microsoft.KeyVault'
      keyVaultProperties: {
        keyVaultUri: keyVault.properties.vaultUri
        keyName: cmk.name
        keyVersion: last(split(cmk.properties.keyUriWithVersion, '/'))
        identityClientId: uami.properties.clientId
      }
    }
  }
}

// Optional Private Endpoint
resource pe 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enablePrivateEndpoint) {
  name: '${name}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'openai-connection'
        properties: {
          privateLinkServiceId: openAi.id
          groupIds: ['account']
        }
      }
    ]
  }
}

output openAiId string = openAi.id
output uamiPrincipalId string = uami.properties.principalId

