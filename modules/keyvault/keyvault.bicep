param name string
param location string
param skuName string = 'standard'

param keyName string = 'cmk-key'
param tags object = {}
param objectId string   // Required for accessPolicies

var tenantId = subscription().tenantId

resource name_resource 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 90
    tenantId: tenantId

    accessPolicies: [
      {
        tenantId: tenantId
        objectId: objectId
        permissions: {
          keys: [
            'get'
            'list'
            'create'
            'delete'
            'update'
            'sign'
            'verify'
            'wrapKey'
            'unwrapKey'
          ]
        }
      }
    ]

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
      exp: 1767225599 // Unix timestamp for 31-Dec-2026 23:59:59 UTC
    }
  }
}

output vaultName string = name
output keyId string = name_key.id

