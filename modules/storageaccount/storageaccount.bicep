
param project string
param env string
param region string
param instance string
param location string
param skuName string
param kind string
param accessTier string
param minimumTlsVersion string
param enableCMK bool
param keyVaultUri string
param keyName string
param keyVersion string
param userAssignedIdentityId string
param tags object = {}


// ------------------------
// Generate storage account name using convention

var storageName = toLower('stg${project}${env}${region}${instance}')
var storageNameTrimmed = substring(storageName, 0, 24)

resource stg 'Microsoft.Storage/storageAccounts@2025-06-01' = {
  name: storageNameTrimmed
  location: location
  kind: kind
  tags: tags

  sku: {
    name: skuName
  }

  identity: enableCMK ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  } : {
    type: 'None'
  }

  properties: {
    accessTier: accessTier
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'

    encryption: {
      keySource: enableCMK ? 'Microsoft.Keyvault' : 'Microsoft.Storage'
      requireInfrastructureEncryption: true
      identity: enableCMK ? {
        userAssignedIdentity: userAssignedIdentityId
      } : null
      keyvaultproperties: enableCMK ? {
        keyname: keyName
        keyversion: keyVersion
        keyvaulturi: keyVaultUri
      } : null
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
  }
}

// ------------------------
// Outputs
output id string = stg.id
output storageName string = storageNameTrimmed
output storageLocation string = location
