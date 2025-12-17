targetScope = 'resourceGroup'

/* =====================
   PARAMETERS
   ===================== */
param location string = resourceGroup().location
param tags object

param uamiConfigs array
param stgConfigs array
param openAiConfigs array
param openAiDeployments array

param keyVaultName string
param cmkKeyName string
param keyVaultObjectId string
param keyVaultSku string
param webAppConfigs array


/* =====================
   USER ASSIGNED MANAGED IDENTITIES
   ===================== */
module uamiModule './modules/identity/managed-identity.bicep' = [
  for uami in uamiConfigs: {
    name: 'uami-${uami.resourceType}-${uami.project}-${uami.env}-${uami.region}-${uami.instance}'
    params: {
      name: 'uami-${uami.resourceType}-${uami.project}-${uami.env}-${uami.region}-${uami.instance}'
      location: location
      tags: union(resourceGroup().tags, {
        ResourceType: 'uami'
        Project: uami.project
        Environment: uami.env
        Region: uami.region
      })
    }
  }
]

/* =====================
   KEY VAULT + CMK
   ===================== */
module keyVaultModule './modules/keyvault/keyvault.bicep' = {
  name: keyVaultName
  dependsOn: [
    uamiModule
  ]
  params: {
    name: keyVaultName
    location: location
    skuName: keyVaultSku
    objectId: keyVaultObjectId
    keyName: cmkKeyName
    uamiPrincipalIds: [
      uamiModule[0].outputs.uamiPrincipalId
    ]
    tags: union(resourceGroup().tags, {
      ResourceType: 'keyvault'
      Component: 'security'
    })
  }
}

/* =====================
   STORAGE ACCOUNTS
   ===================== */
module storageAccounts './modules/storageaccount/storageaccount.bicep' = [
  for stg in stgConfigs: {
    name: 'stg${stg.project}${stg.env}${stg.region}${stg.instance}'
    dependsOn: [
      keyVaultModule
      uamiModule
    ]
    params: {
      project: stg.project
      env: stg.env
      region: stg.region
      instance: stg.instance
      location: location
      skuName: stg.skuName
      kind: stg.kind
      accessTier: stg.accessTier
      minimumTlsVersion: stg.minimumTlsVersion
      enableCMK: stg.enableCMK

      keyVaultUri: 'https://${keyVaultModule.outputs.vaultName}${environment().suffixes.keyvaultDns}'
      keyName: keyVaultModule.outputs.keyName
      keyVersion: keyVaultModule.outputs.keyVersion
      userAssignedIdentityId: uamiModule[stg.uamiIndex].outputs.uamiId

      tags: union(resourceGroup().tags, {
        ResourceType: 'storage'
        Project: stg.project
        Environment: stg.env
        Region: stg.region
      })
    }
  }
]

// /* =====================
//    AZURE OPENAI ACCOUNTS
//    ===================== */
// module openAiAccount './modules/ai-services/openai-account.bicep' = [
//   for ai in openAiConfigs: {
//     name: ai.name
//     dependsOn: [
//       keyVaultModule
//       uamiModule
//     ]
//     params: {
//       name: ai.name
//       location: location
//       tags: union(tags, {
//         ResourceType: 'openai'
//       })

//       uamiName: 'uami-${uamiConfigs[ai.uamiIndex].resourceType}-${uamiConfigs[ai.uamiIndex].project}-${uamiConfigs[ai.uamiIndex].env}-${uamiConfigs[ai.uamiIndex].region}-${uamiConfigs[ai.uamiIndex].instance}'
//       keyVaultName: keyVaultName
//       cmkKeyName: cmkKeyName

//       enablePrivateEndpoint: ai.enablePrivateEndpoint
//       subnetId: ai.subnetId
//     }
//   }
// ]

// /* =====================
//    OPENAI DEPLOYMENTS
//    ===================== */
// module openAiDeploymentsModule './modules/ai-services/openai-deployment.bicep' = [
//   for d in openAiDeployments: {
//     name: d.deploymentName
//     dependsOn: [
//       openAiAccount
//     ]
//     params: {
//       openAiAccountName: d.openAiName
//       deploymentName: d.deploymentName
//       modelName: d.modelName
//       modelVersion: d.modelVersion
//     }
//   }
// ]


/* =====================
   WEB APP DEPLOYMENTS
   ===================== */

module webAppModule './modules/compute/webapp.bicep' = [
  for (webApp, index) in webAppConfigs: {
    name: 'webapp-${webApp.name}'
    params: {
      webAppName: webApp.name
      sku: webApp.sku
      linuxFxVersion: webApp.linuxFxVersion
      location: location
      repositoryUrl: webApp.repositoryUrl
      branch: webApp.branch

      // User Assigned Managed Identity
      uamiId: uamiModule[webApp.uamiIndex].outputs.uamiId

      // ✅ TAGS
      tags: union(tags, {
        ResourceType: 'webapp'
        Project: webApp.project
        Environment: webApp.env
        Region: webApp.region
      })
    }
  }
]




/* =====================
   OUTPUTS
   ===================== */
output keyVaultId string = keyVaultModule.outputs.vaultId
output keyVaultName string = keyVaultModule.outputs.vaultName
output cmkKeyId string = keyVaultModule.outputs.keyId

output uamiId string = uamiModule[0].outputs.uamiId
output uamiPrincipalId string = uamiModule[0].outputs.uamiPrincipalId


/* =====================
   LOGIC APP DEPLOYMENTS
   ===================== */


param logicApps array

module logicAppsModule './modules/compute/logicapp.bicep' = [
  for app in logicApps: {
    name: 'logicapp-${app.name}'
    params: {
      logicAppName: app.name
      location: location
      testUri: app.testUri ?? 'https://azure.status.microsoft/status/'
      frequency: app.frequency ?? 'Hour'
      interval: app.interval ?? 1
      tags: union(tags, app.tags ?? {})
    }
  }
]


/* =====================
   FUNCTION APP DEPLOYMENTS
   ===================== */

param resourceToken string

@description('Function App configurations')
param functionApps array

// Existing resource names
param storageAccountName string
param userAssignedIdentityName string
param applicationInsightsName string

// Existing UAMI
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userAssignedIdentityName
}

// Existing Storage
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Existing App Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

module functionAppModule './modules/compute/functionapp.bicep' = [
  for app in functionApps: {
    name: 'func-${app.appName}'
    params: {
      location: location
      resourceToken: resourceToken

      appName: app.appName
      maximumInstanceCount: app.maximumInstanceCount
      instanceMemoryMB: app.instanceMemoryMB
      functionAppRuntime: app.functionAppRuntime
      functionAppRuntimeVersion: app.functionAppRuntimeVersion
      deploymentStorageContainerName: app.deploymentStorageContainerName

      // Existing resources
      userAssignedIdentityId: userAssignedIdentity.id
      userAssignedClientId: userAssignedIdentity.properties.clientId

      storageAccountName: storage.name
      blobEndpoint: storage.properties.primaryEndpoints.blob

      appInsightsKey: applicationInsights.properties.InstrumentationKey
    }
  }
]

