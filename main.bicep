targetScope = 'subscription'

param resourceGroups array
param stgConfigs array
param keyVaultName string
param keyVaultSku string = 'standard'
param keyVaultObjectId string
param cmkKeyName string = 'cmk-key'
param uamiConfigs array

// ------------------------
// 1️⃣ Deploy Resource Groups
// ------------------------
module rgDeploy './modules/resourcegroup/rg.bicep' = [
  for rg in resourceGroups: {
    name: 'rg-${rg.app}${rg.env}${rg.region}${rg.instance}'
    params: {
      name: 'rg-${rg.app}${rg.env}${rg.region}${rg.instance}'
      location: rg.location
      tags: rg.tags
      managedBy: empty(rg.managedBy) ? null : rg.managedBy
    }
  }
]

// ------------------------
// 2️⃣ Deploy User Assigned Identities
// ------------------------
module uamiModule './modules/identity/managed-identity.bicep' = [
  for uami in uamiConfigs: {
    name: 'uami-${uami.resourceType}${uami.project}${uami.env}${uami.region}${uami.instance}'
    scope: resourceGroup(
      'rg-${resourceGroups[uami.resourceGroupIndex].app}${resourceGroups[uami.resourceGroupIndex].env}${resourceGroups[uami.resourceGroupIndex].region}${resourceGroups[uami.resourceGroupIndex].instance}'
    )
    params: {
      name: 'uami-${uami.resourceType}${uami.project}${uami.env}${uami.region}${uami.instance}'
      location: resourceGroups[uami.resourceGroupIndex].location
    }
    dependsOn: [rgDeploy]
  }
]

// ------------------------
// 3️⃣ Deploy Key Vault
// ------------------------

module keyVaultModule './modules/keyvault/keyvault.bicep' = {
  name: keyVaultName
  scope: resourceGroup('rg-${resourceGroups[0].app}${resourceGroups[0].env}${resourceGroups[0].region}${resourceGroups[0].instance}')
  dependsOn: [
    rgDeploy
    uamiModule
  ]
  params: {
    name: keyVaultName
    location: resourceGroups[0].location
    skuName: keyVaultSku
    objectId: keyVaultObjectId
    uamiPrincipalIds: uamiPrincipalIds
    keyName: cmkKeyName
  }
}
// For a single UAMI module
var uamiPrincipalIds = [
  uamiModule[0].outputs.uamiPrincipalId
]


// ------------------------
// 4️⃣ Deploy Storage Accounts
// ------------------------
module storageAccounts './modules/storageaccount/storageaccount.bicep' = [
  for stg in stgConfigs: {
    name: 'stg${stg.project}${stg.env}${stg.region}${stg.instance}'
    scope: resourceGroup(
      'rg-${resourceGroups[stg.resourceGroupIndex].app}${resourceGroups[stg.resourceGroupIndex].env}${resourceGroups[stg.resourceGroupIndex].region}${resourceGroups[stg.resourceGroupIndex].instance}'
    )
    dependsOn: [
      rgDeploy
      keyVaultModule
      uamiModule
    ]
    params: {
      project: stg.project
      env: stg.env
      region: stg.region
      instance: stg.instance
      location: stg.location
      skuName: stg.skuName
      kind: stg.kind
      accessTier: stg.accessTier
      minimumTlsVersion: stg.minimumTlsVersion
      enableCMK: stg.enableCMK

      keyVaultUri: 'https://${keyVaultModule.outputs.vaultName}.vault.azure.net/'
      keyName: keyVaultModule.outputs.keyName
      keyVersion: keyVaultModule.outputs.keyVersion
      userAssignedIdentityId: uamiModule[stg.uamiIndex].outputs.uamiId

      tags: stg.tags
    }
  }
]

// ------------------------
// Outputs
// ------------------------
output createdResourceGroups array = [
  for rg in resourceGroups: {
    name: 'rg-${rg.app}${rg.env}${rg.region}${rg.instance}'
    location: rg.location
  }
]

output keyVaultId string = keyVaultModule.outputs.vaultId
output keyVaultName_out string = keyVaultModule.outputs.vaultName
output cmkKeyId string = keyVaultModule.outputs.keyId

output uamiId string = uamiModule[0].outputs.uamiId
output uamiPrincipalId string = uamiModule[0].outputs.uamiPrincipalId
