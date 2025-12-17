
param name string
param location string
param tags object

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
   tags: tags
}

output uamiId string = uami.id
output uamiName string = uami.name
output uamiPrincipalId string = uami.properties.principalId








