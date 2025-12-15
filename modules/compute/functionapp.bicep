param location string
param resourceToken string
param appName string
param maximumInstanceCount int
param instanceMemoryMB int
param functionAppRuntime string
param functionAppRuntimeVersion string
param deploymentStorageContainerName string

param userAssignedIdentityId string
param userAssignedClientId string

param storageAccountName string
param blobEndpoint string

param appInsightsKey string

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'plan-${resourceToken}'
  location: location
  kind: 'functionapp'
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: appName
  location: location
  kind: 'functionapp,linux'

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }

  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      http20Enabled: true 
    }

    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${blobEndpoint}${deploymentStorageContainerName}'
          authentication: {
            type: 'UserAssignedIdentity'
            userAssignedIdentityResourceId: userAssignedIdentityId
          }
        }
      }

      scaleAndConcurrency: {
        maximumInstanceCount: maximumInstanceCount
        instanceMemoryMB: instanceMemoryMB
      }

      runtime: { 
        name: functionAppRuntime
        version: functionAppRuntimeVersion
      }
    }
  }

  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: {
      AzureWebJobsStorage__accountName: storageAccountName
      AzureWebJobsStorage__credential: 'managedidentity'
      AzureWebJobsStorage__clientId: userAssignedClientId
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsKey
      APPLICATIONINSIGHTS_AUTHENTICATION_STRING: 'ClientId=${userAssignedClientId};Authorization=AAD'
    }
  }
}
