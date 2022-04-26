targetScope = 'subscription'

@allowed([
    'dev'
    'test'
    'prod'
])
param env string = 'dev'

param appName string = 'appa'

param location string = 'westeurope'

var CakeSpinnerRoleProperties = json(loadTextContent('./CakeSpinnerRole.json'))

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

module CakeSpinnerRole '../../Modules/Microsoft.Authorization/roleDefinitions/subscription/deploy.bicep' = {
    name: 'dep-${deployID}-CakeSpinnerRole-roledef'
    params: {
        roleName: CakeSpinnerRoleProperties.name
        actions: CakeSpinnerRoleProperties.actions
        dataActions: CakeSpinnerRoleProperties.dataActions
        description: CakeSpinnerRoleProperties.description
        notActions: CakeSpinnerRoleProperties.notActions
        notDataActions: CakeSpinnerRoleProperties.notDataActions
    }
}

module FunctionApp '../../Modules/Microsoft.Web/sites/deploy.bicep' = {
    name: 'dep-${deployID}-fa'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}fa'
        location: location
        kind: 'functionapp'
        appServicePlanObject: {
            name: '${appName}${env}asp'
            serverOS: 'Linux'
            skuName: 'P1v2'
            skuCapacity: 2
            skuTier: 'PremiumV2'
            skuSize: 'P1v2'
            skuFamily: 'Pv2'
        }
        appInsightId: appInsights.outputs.appInsightsResourceId
        siteConfig: {
            alwaysOn: true
        }
        functionsWorkerRuntime: 'powershell'
        systemAssignedIdentity: true
        diagnosticWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    }
}

module storage '../../Modules/Microsoft.Storage/storageAccounts/deploy.bicep' = {
    name: 'dep-${deployID}-sa'
    scope: resourceGroup(rgName)
    params: {
        name: '${appName}${env}sa'
        location: location
        allowBlobPublicAccess: false
        diagnosticWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
        roleAssignments: [
            {
                roleDefinitionIdOrName: CakeSpinnerRole.outputs.resourceId
                principalIds: [
                    FunctionApp.outputs.systemAssignedPrincipalId
                ]
            }
        ]
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
        diagnosticWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
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
        appInsightsWorkspaceResourceId: logAnalytics.outputs.logAnalyticsResourceId
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
        diagnosticWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
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
        associatedApplicationInsightsResourceId: appInsights.outputs.appInsightsResourceId
        associatedKeyVaultResourceId: keyVault.outputs.keyVaultResourceId
        associatedStorageAccountResourceId: storage.outputs.storageAccountResourceId
        associatedContainerRegistryResourceId: containerRegistry.outputs.acrResourceId
        sku: 'Basic'
        systemAssignedIdentity: true
        diagnosticWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    }
    dependsOn: [
        rg
    ]
}

output rgName string = rg.outputs.resourceGroupName
output mlname string = mlworkspaces.outputs.machineLearningServiceName
output mlprincipalId string = mlworkspaces.outputs.principalId
