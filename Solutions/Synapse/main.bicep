targetScope = 'subscription'

param env string = ''

param appName string = 'appa'

param location string = deployment().location

param aadTeamGroupObjectId string
param synapseResourceGroupName string = 'rg-name-0001'
param synapseWorkspaceName string = 'syn-name-0001'
param omsWorkspaceResourceGroup string = 'rg-name-0001'
param omsWorkspaceName string = 'log-workspace-name-0001'
param storageAccountName string = 'namedev0001'
param defaultStorageUrl string = 'https://$(storageAccountName).dfs.core.windows.net'
param defaultStorageContainerName string = 'syndev'
param storageResourceGroupName string = 'rg-name-0001'
param pepSubscription string = 'xxxxxxxxxx'
param pepResourceGroupName string = 'rg-we-pep-shared-dev-01'
param pepVnetName string = 'vnet-we-pep-shared-dev-01'
param pepSubnetName string = 'snet-we-pep-shared-01'
param pepDnsZoneResourceId string = '/subscriptions/xxxxxxxxxx/resourceGroups/rg-privatelinkzones-prd/providers/Microsoft.Network/privateDnsZones'
param pepDestinationResourceId string = '/subscriptions/xxxxxxxxxxxxx/resourceGroups/$(synapseResourceGroupName)/providers/Microsoft.Synapse/workspaces/$(synapseWorkspaceName)'
param pepDnsZoneNameDevEndpoint string = 'privatelink.dev.azuresynapse.net'
param pepDnsZoneNameOnDemandEndpoint string = 'privatelink.sql.azuresynapse.net'

var deployID = uniqueString(deployment().name, location)
