// param name string
// param location string
// param skuName string = 'standard'

// param keyName string = 'cmk-key'
// param tags object = {}
// param objectId string   // Required for accessPolicies

// var tenantId = subscription().tenantId




// resource name_resource 'Microsoft.KeyVault/vaults@2023-02-01' = {
//   name: name
//   location: location
//   tags: tags
//   properties: {
//     enabledForDeployment: true
//     enabledForDiskEncryption: true
//     enableRbacAuthorization: false
//     enableSoftDelete: true
//     enablePurgeProtection: true
//     softDeleteRetentionInDays: 90
//     tenantId: tenantId

//     accessPolicies: [
//       {
//         tenantId: tenantId
//         objectId: objectId
//         permissions: {
//           keys: [
//             'get'
//             'list'
//             'create'
//             'delete'
//             'update'
//             'sign'
//             'verify'
//             'wrapKey'
//             'unwrapKey'
//           ]
          
//         }
//       }
//     ]

//     sku: {
//       family: 'A'
//       name: skuName
//     }
//   }
// }

// resource name_key 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
//   parent: name_resource
//   name: keyName
//   properties: {
//     kty: 'RSA'
//     keySize: 2048
//     attributes: {
//       enabled: true
//       exp: 1767225599 // Unix timestamp for 31-Dec-2026 23:59:59 UTC
//     }
//   }
// }

// output vaultName string = name
// output keyId string = name_key.id
// output vaultId string = name_resource.id


param name string
param location string
param skuName string = 'standard'
param keyName string = 'cmk-key'
param tags object = {}
param objectId string
param uamiPrincipalIds array = []

var tenantId = subscription().tenantId

// Combine main object + UAMI policies in one array
// Main object policy
var mainPolicy = [
  {
    tenantId: tenantId
    objectId: objectId
    permissions: { keys: ['get','list','create','delete','update','sign','verify','wrapKey','unwrapKey'] }
  }
]

var uamiPolicies = [
  for uamiId in uamiPrincipalIds: {
    tenantId: tenantId
    objectId: uamiId
    permissions: { keys: ['get','list','wrapKey','unwrapKey'] }
  }
]

var accessPolicies = union(mainPolicy, uamiPolicies)



// Key Vault
resource vault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: false
    enableSoftDelete: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 90
    tenantId: tenantId
    accessPolicies: accessPolicies
    sku: {
      family: 'A'
      name: skuName
    }
  }
}

// Key inside Key Vault
resource key 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: vault
  name: keyName
  properties: {
    kty: 'RSA'
    keySize: 2048
    attributes: {
      enabled: true
      exp: 1767225599 // 31-Dec-2026
    }
  }
}

// Outputs
output vaultName string = name
output vaultId string = vault.id
output keyName string = key.name
output keyVersion string = last(split(key.properties.keyUriWithVersion, '/'))
output keyId string = key.properties.keyUriWithVersion
