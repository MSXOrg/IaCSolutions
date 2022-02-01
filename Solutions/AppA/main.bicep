targetScope = 'subscription'

@allowed([
    'dev'
    'test'
    'prod'
])
param env string = 'dev'

param appName string = 'appa'

var rgName = '${appName}${env}rg'

var deployID = '${uniqueString(deployment().name, deployment().location)}'

module rg '../../Modules/Microsoft.Resources/resourceGroups/deploy.bicep' = {
    name: '${deployID}-rg'
    scope: subscription()
    params: {
        name: rgName
        tags: {
            environment: env
            app: appName
        }
    }
}

module storage '../../Modules/Microsoft.Storage/storageAccounts/deploy.bicep' = {
    name: '${deployID}-sa'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}sa'
        allowBlobPublicAccess: false
    }
    dependsOn: [
        rg
    ]
}

module keyVault '../../Modules/Microsoft.KeyVault/vaults/deploy.bicep' = {
    name: '${deployID}-kv'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}kv'
    }
    dependsOn: [
        rg
    ]
}

module logAnalytics '../../Modules/Microsoft.OperationalInsights/workspaces/deploy.bicep' = {
    name: '${deployID}-la'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}la'
    }
    dependsOn: [
        rg
    ]
}

module appInsights '../../Modules/Microsoft.Insights/components/deploy.bicep' = {
    name: '${deployID}-ic'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}ic'
        appInsightsWorkspaceResourceId: logAnalytics.outputs.logAnalyticsResourceId
    }
    dependsOn: [
        rg
    ]
}

module containerRegistry '../../Modules/Microsoft.ContainerRegistry/registries/deploy.bicep' = {
    name: '${deployID}-cr'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}cr'
    }
    dependsOn: [
        rg
    ]
}

module mlworkspaces '../../Modules/Microsoft.MachineLearningServices/workspaces/deploy.bicep' = {
    name: '${deployID}-ml'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}ml'
        associatedApplicationInsightsResourceId: appInsights.outputs.appInsightsResourceId
        associatedKeyVaultResourceId: keyVault.outputs.keyVaultResourceId
        associatedStorageAccountResourceId: storage.outputs.storageAccountResourceId
        associatedContainerRegistryResourceId: containerRegistry.outputs.acrResourceId
        sku: 'Basic'
        systemAssignedIdentity: true
    }
    dependsOn: [
        rg
    ]
}

output rgName string = rg.outputs.resourceGroupName
output mlname string = mlworkspaces.outputs.machineLearningServiceName
output mlprincipalId string = mlworkspaces.outputs.principalId
