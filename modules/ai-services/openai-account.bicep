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


// --------------------------------------------------
// PARAMETERS (MODULE CONTRACT)
// --------------------------------------------------
// --------------------------------------------------
// PARAMETERS
// --------------------------------------------------
param name string
param location string
param tags object


param uamiName string
param keyVaultName string
param cmkKeyName string

param enablePrivateEndpoint bool = false
param subnetId string = ''

// --------------------------------------------------
// EXISTING RESOURCES
// --------------------------------------------------
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: uamiName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource cmk 'Microsoft.KeyVault/vaults/keys@2022-07-01' existing = {
  parent: keyVault
  name: cmkKeyName
}

// --------------------------------------------------
// OPENAI ACCOUNT
// --------------------------------------------------
resource openAi 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: name
  location: location
  kind: 'OpenAI'
  tags: tags

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
        keyVaultUri:'https://${keyVault.name}.vault.azure.net/'
        keyName: cmk.name
        keyVersion: last(split(cmk.properties.keyUriWithVersion, '/'))
        identityClientId: uami.properties.clientId
      }
    }
  }
}

// --------------------------------------------------
// OPTIONAL PRIVATE ENDPOINT
// --------------------------------------------------
resource openAiPe 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enablePrivateEndpoint) {
  name: '${name}-pe'
  location: location
  tags: tags

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

// --------------------------------------------------
// OUTPUTS
// --------------------------------------------------
output openAiId string = openAi.id
output uamiPrincipalId string = uami.properties.principalId



