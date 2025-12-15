param name string
param location string
param enablePrivateEndpoint bool = false
param subnetId string = ''
param logAnalyticsId string = ''


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


// Diagnostic settings (optional)
resource diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (logAnalyticsId != '') {
name: '${name}-diag'
scope: openAi
properties: {
workspaceId: logAnalyticsId
logs: [
{
category: 'Audit'
enabled: true
}
]
metrics: [
{
category: 'AllMetrics'
enabled: true
}
]
}
}


// Private Endpoint (optional)
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
groupIds: [ 'account' ]
}
}
]
}
}


output openAiId string = openAi.id
