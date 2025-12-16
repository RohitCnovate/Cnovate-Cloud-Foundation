param webAppName string
param sku string
param linuxFxVersion string
param location string
param repositoryUrl string
param branch string
param keyVaultName string
param cmkKeyName string
param uamiObjectId string

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Reference existing Key
resource cmk 'Microsoft.KeyVault/vaults/keys@2023-07-01' existing = {
  name: cmkKeyName
  parent: keyVault
}

// Web App with UAMI and CMK
resource webApp 'Microsoft.Web/sites@2023-10-01' = {
  name: webAppName
  location: location
  kind: 'app'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiObjectId}': {}
    }
  }
  properties: {
    serverFarmId: '<your-app-service-plan-id>'
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
    keyVaultReferenceIdentity: 'UserAssigned'
    keyVaultKeyId: cmk.id
  }
}

// Outputs
output webAppNameOutput string = webApp.name

