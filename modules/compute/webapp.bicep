param webAppName string
param sku string
param linuxFxVersion string
param location string
param repositoryUrl string
param branch string
param uamiId string   // FULL resource ID of UAMI
param tags object

/* =====================
   APP SERVICE PLAN
   ===================== */
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${webAppName}-plan'
  location: location
  kind: 'linux'
  sku: {
    name: sku
    tier: 'Standard'
  }
  properties: {
    reserved: true
    
  }
   tags: tags 
}

/* =====================
   WEB APP (POLICY COMPLIANT)
   ===================== */
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id

    httpsOnly: true                    // ✅ HTTPS only
    clientCertEnabled: true            // ✅ Client cert required

    siteConfig: {
      linuxFxVersion: linuxFxVersion

      http20Enabled: true              // ✅ Latest HTTP version
      ftpsState: 'FtpsOnly'            // ✅ FTPS only
      remoteDebuggingEnabled: false    // ✅ No remote debugging

      cors: {
        allowedOrigins: []             // ✅ No wildcard CORS
      }

      appSettings: [
        { name: 'REPO_URL', value: repositoryUrl }
        { name: 'BRANCH', value: branch }
        { name: 'WEBSITE_RUN_FROM_PACKAGE', value: '1' }
      ]
    }
  }
  dependsOn: [
    appServicePlan
  ]
}

/* =====================
   OUTPUT
   ===================== */
output webAppNameOutput string = webApp.name
