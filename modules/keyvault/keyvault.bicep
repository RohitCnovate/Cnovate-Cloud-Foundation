param name string
param location string
param skuName string = 'standard'

param keyName string = 'cmk-key'
// param expirationYears int = 2
param tags object = {}
// param keyVaultName string


// param cmkKeyName string = 'cmk-key'

// param objectId string // UAMI or user for CMK access

var tenantId = subscription().tenantId

@description('Current timestamp (auto generated)')
// param currentTime string = utcNow()

// var expiryDate = dateTimeAdd(currentTime, '${expirationYears}Y')

resource name_resource 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    enableRbacAuthorization: true
    enableSoftDelete: true
    enablePurgeProtection: true
    tenantId: tenantId
    sku: {
      family: 'A'
      name: skuName
    }
  }
}

resource name_key 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: name_resource
  name: keyName
  properties: {
    kty: 'RSA'
    keySize: 2048
    attributes: {
      enabled: true
      exp: 1767225599  // Unix timestamp for 31-Dec-2026 23:59:59 UTC
    }
  }
}

output vaultName string = name
output keyId string = name_key.id
