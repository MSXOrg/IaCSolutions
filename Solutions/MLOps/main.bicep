targetScope = 'subscription'

@allowed([
    'dev'
    'test'
    'prod'
])
param env string = 'dev'

param appName string = 'appa'

param location string = 'westeurope'

var rgName = '${appName}${env}rg'

var deployID = uniqueString(deployment().name, location)

module rg '../../Modules/Microsoft.Resources/resourceGroups/deploy.bicep' = {
    name: '${deployID}-rg'
    scope: subscription()
    params: {
        name: rgName
        location: location
        tags: {
            environment: env
            app: appName
        }
    }
}

module storage '../../Modules/Microsoft.Storage/storageAccounts/deploy.bicep' = {
    name: 'dep-${deployID}-sa'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}sa'
        location: location
        allowBlobPublicAccess: false
        diagnosticWorkspaceId: logAnalytics.outputs.resourceId
    }
    dependsOn: [
        rg
    ]
}

module keyVault '../../Modules/Microsoft.KeyVault/vaults/deploy.bicep' = {
    name: 'dep-${deployID}-kv'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}kv'
        location: location
        diagnosticWorkspaceId: logAnalytics.outputs.resourceId
    }
    dependsOn: [
        rg
    ]
}

module logAnalytics '../../Modules/Microsoft.OperationalInsights/workspaces/deploy.bicep' = {
    name: 'dep-${deployID}-la'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}la'
        location: location
    }
    dependsOn: [
        rg
    ]
}

module appInsights '../../Modules/Microsoft.Insights/components/deploy.bicep' = {
    name: 'dep-${deployID}-ic'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}ic'
        location: location
        workspaceResourceId: logAnalytics.outputs.resourceId
    }
    dependsOn: [
        rg
    ]
}

module containerRegistry '../../Modules/Microsoft.ContainerRegistry/registries/deploy.bicep' = {
    name: 'dep-${deployID}-cr'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}cr'
        location: location
        diagnosticWorkspaceId: logAnalytics.outputs.resourceId
    }
    dependsOn: [
        rg
    ]
}

module mlworkspaces '../../Modules/Microsoft.MachineLearningServices/workspaces/deploy.bicep' = {
    name: 'dep-${deployID}-ml'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}ml'
        location: location
        associatedApplicationInsightsResourceId: appInsights.outputs.resourceId
        associatedKeyVaultResourceId: keyVault.outputs.resourceId
        associatedStorageAccountResourceId: storage.outputs.resourceId
        associatedContainerRegistryResourceId: containerRegistry.outputs.resourceId
        sku: 'Basic'
        systemAssignedIdentity: true
        diagnosticWorkspaceId: logAnalytics.outputs.resourceId
    }
    dependsOn: [
        rg
    ]
}

output rgName string = rg.outputs.name
output mlname string = mlworkspaces.outputs.name
output mlprincipalId string = mlworkspaces.outputs.principalId
