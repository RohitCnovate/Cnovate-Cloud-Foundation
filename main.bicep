// targetScope = 'subscription'

// param resourceGroups array
// param stgConfigs array
// param keyVaultName string
// param cmkKeyName string
// param keyVaultSku string = 'standard'
// param keyVaultObjectId string
// param uamiConfigs array





// // --------------------------------------
// // 1️⃣ Deploy Resource Groups
// // --------------------------------------
// module rgDeploy './modules/resourcegroup/rg.bicep' = [
//   for rg in resourceGroups: {
//     name: 'rg-${rg.app}${rg.env}${rg.region}${rg.instance}'
//     params: {
//       name: 'rg-${rg.app}${rg.env}${rg.region}${rg.instance}'
//       location: rg.location
//       tags: rg.tags
//       managedBy: empty(rg.managedBy) ? null : rg.managedBy
//     }
//   }
// ]

// // --------------------------------------
// // 2️⃣ Deploy User Assigned Identity
// // --------------------------------------
// module uamiModule './modules/identity/managed-identity.bicep' = [
//   for uami in uamiConfigs: {
//     name: 'uami-${uami.resourceType}${uami.project}${uami.env}${uami.region}${uami.instance}'

//     scope: resourceGroup(
//       'rg-${resourceGroups[uami.resourceGroupIndex].app}${resourceGroups[uami.resourceGroupIndex].env}${resourceGroups[uami.resourceGroupIndex].region}${resourceGroups[uami.resourceGroupIndex].instance}'
//     )

//     params: {
//       name: 'uami-${uami.resourceType}${uami.project}${uami.env}${uami.region}${uami.instance}'
//       location: resourceGroups[uami.resourceGroupIndex].location
//     }

//     dependsOn: [
//       rgDeploy
//     ]
//   }
// ]

// // --------------------------------------
// // 3️⃣ Deploy Key Vault (Corrected Name)
// // --------------------------------------
// module keyVaultModule './modules/keyvault/keyvault.bicep' = {
//   name: keyVaultName

//   scope: resourceGroup(
//     'rg-${resourceGroups[0].app}${resourceGroups[0].env}${resourceGroups[0].region}${resourceGroups[0].instance}'
//   )

//   dependsOn: [
//     rgDeploy
//     uamiModule
//   ]

//   params: {
//     location: resourceGroups[0].location
//     // keyVaultName: keyVaultName
//     // cmkKeyName: cmkKeyName
//     skuName: keyVaultSku
//     objectId: keyVaultObjectId
//     name: keyVaultName  
//   }
// }

// // --------------------------------------
// // 4️⃣ Deploy Storage Accounts
// // --------------------------------------
// module storageAccounts './modules/storageaccount/storageaccount.bicep' = [
//   for stg in stgConfigs: {
//     name: 'stg${stg.project}${stg.env}${stg.region}${stg.instance}'

//     scope: resourceGroup(
//       'rg-${resourceGroups[stg.resourceGroupIndex].app}${resourceGroups[stg.resourceGroupIndex].env}${resourceGroups[stg.resourceGroupIndex].region}${resourceGroups[stg.resourceGroupIndex].instance}'
//     )

//     dependsOn: [
//       rgDeploy
//       keyVaultModule
//     ]

//     params: {
//       project: stg.project
//       env: stg.env
//       region: stg.region
//       instance: stg.instance
//       location: stg.location
//       skuName: stg.skuName
//       kind: stg.kind
//       accessTier: stg.accessTier
//       minimumTlsVersion: stg.minimumTlsVersion
//       enableCMK: stg.enableCMK
//       keyVaultUri: stg.keyVaultUri
//       keyName: cmkKeyName
//       keyVersion: stg.keyVersion
//       userAssignedIdentityId: uamiModule[stg.uamiIndex].outputs.uamiId
//       tags: stg.tags
//     }
//   }
// ]

// // --------------------------------------
// // 5️⃣ Outputs
// // --------------------------------------
// output createdResourceGroups array = [
//   for rg in resourceGroups: {
//     name: 'rg-${rg.app}${rg.env}${rg.region}${rg.instance}'
//     location: rg.location
//   }
// ]

// // -----------------------------
// // Assign Key Vault Crypto User role to a single UAMI
// // -----------------------------
// // Assuming the vault is in the first resource group
// // Resource ID of Key Vault (known at start)
// resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(keyVaultName, 'uami-storageidiscoverydev03', 'KeyVaultCryptoUser')
//   scope: keyVaultModule.outputs.vaultResource  // <-- now a real resource
//   properties: {
//     roleDefinitionId: subscriptionResourceId(
//       'Microsoft.Authorization/roleDefinitions',
//       '00482a5a-887f-4fb3-b363-3b7fe8e74483'
//     )
//     principalId: uamiModule[0].outputs.uamiPrincipalId
//     principalType: 'UserAssignedManagedIdentity'
//   }
//   dependsOn: [
//     keyVaultModule
//     uamiModule[0]
//   ]
// }

// // -----------------------------
// // Outputs for verification
// // -----------------------------
// output keyVaultId string = keyVaultModule.outputs.vaultId
// output uamiId string = uamiModule[0].outputs.uamiId
// output uamiPrincipalId string = uamiModule[0].outputs.uamiPrincipalId

// output keyVaultName string = keyVaultModule.outputs.vaultName
// output cmkKeyId string = keyVaultModule.outputs.keyId


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

// targetScope = 'subscription'

// param resourceGroups array
// param stgConfigs array
// param keyVaultName string
// // param cmkKeyName string
// param keyVaultSku string = 'standard'
// param keyVaultObjectId string
// param uamiConfigs array

// // --------------------------------------
// // 1️⃣ Deploy Resource Groups
// // --------------------------------------
// module rgDeploy './modules/resourcegroup/rg.bicep' = [
//   for rg in resourceGroups: {
//     name: 'rg-${rg.app}${rg.env}${rg.region}${rg.instance}'
//     params: {
//       name: 'rg-${rg.app}${rg.env}${rg.region}${rg.instance}'
//       location: rg.location
//       tags: rg.tags
//       managedBy: empty(rg.managedBy) ? null : rg.managedBy
//     }
//   }
// ]

// // --------------------------------------
// // 2️⃣ Deploy User Assigned Identity
// // --------------------------------------
// module uamiModule './modules/identity/managed-identity.bicep' = [
//   for uami in uamiConfigs: {
//     name: 'uami-${uami.resourceType}${uami.project}${uami.env}${uami.region}${uami.instance}'

//     scope: resourceGroup(
//       'rg-${resourceGroups[uami.resourceGroupIndex].app}${resourceGroups[uami.resourceGroupIndex].env}${resourceGroups[uami.resourceGroupIndex].region}${resourceGroups[uami.resourceGroupIndex].instance}'
//     )

//     params: {
//       name: 'uami-${uami.resourceType}${uami.project}${uami.env}${uami.region}${uami.instance}'
//       location: resourceGroups[uami.resourceGroupIndex].location
//     }

//     dependsOn: [
//       rgDeploy
//     ]
//   }
// ]

// // --------------------------------------
// // 3️⃣ Deploy Key Vault
// // --------------------------------------
// module keyVaultModule './modules/keyvault/keyvault.bicep' = {
//   name: keyVaultName

//   scope: resourceGroup(
//     'rg-${resourceGroups[0].app}${resourceGroups[0].env}${resourceGroups[0].region}${resourceGroups[0].instance}'
//   )

//   dependsOn: [
//     rgDeploy
//     uamiModule
//   ]

//   params: {
//     name: keyVaultName
//     location: resourceGroups[0].location
//     skuName: keyVaultSku
//     objectId: keyVaultObjectId
//     uamiConfigs: uamiConfigs
//   }
// }




// // --------------------------------------
// // 4️⃣ Deploy Storage Accounts
// // --------------------------------------
// module storageAccounts './modules/storageaccount/storageaccount.bicep' = [
//   for stg in stgConfigs: {
//     name: 'stg${stg.project}${stg.env}${stg.region}${stg.instance}'

//     scope: resourceGroup(
//       'rg-${resourceGroups[stg.resourceGroupIndex].app}${resourceGroups[stg.resourceGroupIndex].env}${resourceGroups[stg.resourceGroupIndex].region}${resourceGroups[stg.resourceGroupIndex].instance}'
//     )

//     dependsOn: [
//       rgDeploy
//       //  keyVaultModule
  
//     ]

//     params: {
//       project: stg.project
//       env: stg.env
//       region: stg.region
//       instance: stg.instance
//       location: stg.location
//       skuName: stg.skuName
//       kind: stg.kind
//       accessTier: stg.accessTier
//       minimumTlsVersion: stg.minimumTlsVersion
//       enableCMK: stg.enableCMK
//       keyVaultUri: 'https://${keyVaultModule.outputs.vaultName}.vault.azure.net/'
//       keyName: keyVaultModule.outputs.keyName
//       keyVersion: keyVaultModule.outputs.keyVersion
//       userAssignedIdentityId: uamiModule[stg.uamiIndex].outputs.uamiId  

      
     
//       tags: stg.tags
//     }
//   }
// ]


// // --------------------------------------
// // 6️⃣ Outputs
// // --------------------------------------
// output createdResourceGroups array = [
//   for rg in resourceGroups: {
//     name: 'rg-${rg.app}${rg.env}${rg.region}${rg.instance}'
//     location: rg.location
//   }
// ]

// output keyVaultId string = keyVaultModule.outputs.vaultId
// output keyVaultName_out string = keyVaultModule.outputs.vaultName
// output cmkKeyId string = keyVaultModule.outputs.keyId

// output uamiId string = uamiModule[0].outputs.uamiId
// output uamiPrincipalId string = uamiModule[0].outputs.uamiPrincipalId


// 5️⃣ Assign Key Vault Crypto User role to UAMI
// --------------------------------------

// Key Vault resource ID (calculated at compile time)
// resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
// name: guid(keyVaultName, uamiModule[0].name, 'KeyVaultCryptoUser') 
//   scope: subscription()  // subscription-scoped
//   properties: {
//     roleDefinitionId: subscriptionResourceId(
//       'Microsoft.Authorization/roleDefinitions',
//       '00482a5a-887f-4fb3-b363-3b7fe8e74483'
//     )
//     principalId: uamiModule[0].outputs.uamiPrincipalId
//     principalType: 'UserAssignedManagedIdentity'  // Correct type
//   }
//   dependsOn: [
//     keyVaultModule
//     uamiModule[0]
//   ]
// }




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
