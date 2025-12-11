
targetScope = 'subscription'

param name string
param location string
param tags object = {}
param managedBy string = ''

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location
  tags: tags
  managedBy: empty(managedBy) ? null : managedBy
}

output name string = rg.name
output location string = rg.location
