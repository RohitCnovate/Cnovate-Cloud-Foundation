param name string
param location string
param enablePrivateEndpoint bool = false
param subnetId string = ''

resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  kind: 'OpenAI'
  sku: {

    
    name: 'S0'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: enablePrivateEndpoint ? 'Disabled' : 'Enabled'
  }
}

// Optional Private Endpoint
resource pe 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enablePrivateEndpoint) {
  name: '${name}-pe'
  location: location
  properties: {
    subnet: { id: subnetId }
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
output openAiEndpoint string = openAi.properties.endpoint








