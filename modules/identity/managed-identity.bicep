
param name string
param location string

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
}

output uamiId string = uami.id
output uamiName string = uami.name
output uamiPrincipalId string = uami.properties.principalId








