[CmdletBinding()]
param ()

$ResourceProviders = Get-Content -Path $PSScriptRoot\ResourceProviders.json -Raw | ConvertFrom-Json

foreach ($ResourceProvider in $ResourceProviders) {
    Register-AzResourceProvider -ProviderNamespace $ResourceProvider.name
    foreach ($feature in $ResourceProvider.features) {
        Register-AzProviderFeature -ProviderNamespace $ResourceProvider.name -FeatureName $feature
    }
}
