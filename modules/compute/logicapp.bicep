param logicAppName string
param location string
param testUri string = 'https://azure.status.microsoft/status/'
param frequency string = 'Hour'
param interval int = 1
param tags object = {}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        testUri: {
          type: 'string'
        }
      }
      triggers: {
        recurrence: {
          type: 'Recurrence'
          recurrence: {
            frequency: frequency
            interval: interval
          }
        }
      }
      actions: {
        httpCall: {
          type: 'Http'
          inputs: {
            method: 'GET'
            uri: '@parameters(\'testUri\')'
          }
        }
      }
    }
    parameters: {
      testUri: {
        value: testUri
      }
    }
  }
}

output logicAppId string = logicApp.id



