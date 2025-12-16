targetScope = 'subscription'

param resourceGroups array   

module rgDeploy './modules/resourcegroup/rg.bicep' = [
  for rg in resourceGroups: {
    name: 'rg-${rg.app}-${rg.env}-${rg.region}-${rg.instance}'

    params: {
      name: 'rg-${rg.app}-${rg.env}-${rg.region}-${rg.instance}'
      location: rg.region
      tags: rg.tags
      managedBy: empty(rg.managedBy) ? null : rg.managedBy   
    }
  }
]

output createdResourceGroups array = [
  for rg in resourceGroups: {
    name: 'rg-${rg.app}-${rg.env}-${rg.region}-${rg.instance}'
    location: rg.location
  }
]
