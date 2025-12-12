targetScope = 'subscription'

param resourceGroups array
param stgConfigs array
param keyVaultName string
param cmkKeyName string
param keyVaultSku string = 'standard'
param keyVaultObjectId string
param uamiConfigs array





// --------------------------------------
// 1️⃣ Deploy Resource Groups
// --------------------------------------
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

// --------------------------------------
// 2️⃣ Deploy User Assigned Identity
// --------------------------------------
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

    dependsOn: [
      rgDeploy
    ]
  }
]

// --------------------------------------
// 3️⃣ Deploy Key Vault (Corrected Name)
// --------------------------------------
module keyVaultModule './modules/keyvault/keyvault.bicep' = {
  name: keyVaultName

  scope: resourceGroup(
    'rg-${resourceGroups[0].app}${resourceGroups[0].env}${resourceGroups[0].region}${resourceGroups[0].instance}'
  )

  dependsOn: [
    rgDeploy
    uamiModule
  ]

  params: {
    location: resourceGroups[0].location
    // keyVaultName: keyVaultName
    // cmkKeyName: cmkKeyName
    skuName: keyVaultSku
    objectId: keyVaultObjectId
    name: keyVaultName  
  }
}

// --------------------------------------
// 4️⃣ Deploy Storage Accounts
// --------------------------------------
module storageAccounts './modules/storageaccount/storageaccount.bicep' = [
  for stg in stgConfigs: {
    name: 'stg${stg.project}${stg.env}${stg.region}${stg.instance}'

    scope: resourceGroup(
      'rg-${resourceGroups[stg.resourceGroupIndex].app}${resourceGroups[stg.resourceGroupIndex].env}${resourceGroups[stg.resourceGroupIndex].region}${resourceGroups[stg.resourceGroupIndex].instance}'
    )

    dependsOn: [
      rgDeploy
      keyVaultModule
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
      keyVaultUri: stg.keyVaultUri
      keyName: cmkKeyName
      keyVersion: stg.keyVersion
      userAssignedIdentityId: uamiModule[stg.uamiIndex].outputs.uamiId
      tags: stg.tags
    }
  }
]

// --------------------------------------
// 5️⃣ Outputs
// --------------------------------------
output createdResourceGroups array = [
  for rg in resourceGroups: {
    name: 'rg-${rg.app}${rg.env}${rg.region}${rg.instance}'
    location: rg.location
  }
]

output keyVaultName string = keyVaultModule.outputs.vaultName
output cmkKeyId string = keyVaultModule.outputs.keyId

// param location string
// param aiAccountName string
// param modelName string
// param deploymentName string

//ai-services//

// module aiAccount './modules/ai-services/openai-account.bicep' = {
//   name: 'openaiAccountModule'
//   params: {
//     aiAccountName: aiAccountName
//     location: location
//   }
// }

// module aiDeployment './modules/ai-services/openai-deployment.bicep' = {
//   name: 'modelDeploymentModule'
//   params: {
//     aiAccountName: aiAccountName
//     modelName: modelName
//     deploymentName: deploymentName
//   }
// }
