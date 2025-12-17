targetScope = 'resourceGroup'

param uamiName string
param keyVaultName string
param cmkKeyName string
param storageName string
param openAiName string
param openAiDeployments array
param deployerObjectId string
param location string = resourceGroup().location

var tenantId = subscription().tenantId

// --------------------------------------------------
// 1️⃣ User Assigned Managed Identity
// --------------------------------------------------
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName
  location: location
}

// --------------------------------------------------
// 2️⃣ Key Vault
// --------------------------------------------------
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    enableRbacAuthorization: false
    enableSoftDelete: true
    enablePurgeProtection: true

    accessPolicies: [
      {
        tenantId: tenantId
        objectId: deployerObjectId
        permissions: {
          keys: ['get','list','create','delete','wrapKey','unwrapKey']
        }
      }
      {
        tenantId: tenantId
        objectId: uami.properties.principalId
        permissions: {
          keys: ['get','list','wrapKey','unwrapKey']
        }
      }
    ]

    sku: {
      family: 'A'
      name: 'standard'
    }
  }
}

// --------------------------------------------------
// 3️⃣ CMK Key
// --------------------------------------------------
resource cmk 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: keyVault
  name: cmkKeyName
  properties: {
    kty: 'RSA'
    keySize: 2048
  }
}

// --------------------------------------------------
// 4️⃣ Storage Account (CMK)
// --------------------------------------------------
resource storage 'Microsoft.Storage/storageAccounts@2025-06-01' = {
  name: storageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }

  properties: {
    encryption: {
      keySource: 'Microsoft.KeyVault'
      identity: {
        userAssignedIdentity: uami.id
      }
      keyvaultproperties: {
        keyvaulturi: 'https://${keyVault.name}.vault.azure.net/'
        keyname: cmk.name
        keyversion: last(split(cmk.properties.keyUriWithVersion, '/'))
      }
      services: {
        blob: { enabled: true }
      }
    }
  }

  dependsOn: [cmk]
}

// --------------------------------------------------
// 5️⃣ Azure OpenAI (CMK + SAME UAMI)
// --------------------------------------------------
resource openAi 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: openAiName
  location: location
  kind: 'OpenAI'

  sku: {
    name: 'S0'
  }

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }

  properties: {
    customSubDomainName: openAiName

    encryption: {
      keySource: 'Microsoft.KeyVault'
      keyVaultProperties: {
        keyVaultUri: 'https://${keyVault.name}.vault.azure.net/'
        keyName: cmk.name
        keyVersion: last(split(cmk.properties.keyUriWithVersion, '/'))
        identityClientId: uami.properties.clientId
      }
    }
  }

  dependsOn: [
    cmk
  ]
}


// --------------------------------------------------
// 6️⃣ OpenAI Deployments
// --------------------------------------------------
resource deployments 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = [
  for d in openAiDeployments: {
    name: d.deploymentName
    parent: openAi
    properties: {
      model: {
        format: 'OpenAI'
        name: d.modelName
        version: d.modelVersion
      }
    }
  }
]



// --------------------------------------------------
// 7️⃣ App Service Plan + Web App with CMK
// --------------------------------------------------

param webAppName string
param sku string 
param linuxFxVersion string 
param repositoryUrl string
param branch string

// 1️⃣ Create a new App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${webAppName}-plan'
  location: location
  kind: 'linux'
  sku: {
    name: sku
    tier: 'Standard'
  }
  properties: {
    reserved: true    //important//
  }
}



// 2️⃣ Create Web App with UAMI
resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: webAppName
  location: location
  kind: 'app'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}  // ← Use UAMI resource ID, not principalId
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: [
        { name: 'REPO_URL', value: repositoryUrl }
        { name: 'BRANCH', value: branch }
      ]
    }
  }
  dependsOn: [
    appServicePlan
    uami
  ]
}

// 3️⃣ Output
output webAppNameOutput string = webApp.name
