[CmdletBinding(PositionalBinding=$false)]
param (
    [Parameter(HelpMessage="module path")]$Path=$PSScriptRoot,
    [Parameter(HelpMessage="Version")][string]$Version
) 

$moduleName = Split-Path -Path $Path -Leaf

$manifestPath = Join-Path -Path $Path -ChildPath "$moduleName.psd1"

$functions = Get-ChildItem (Join-Path -Path $Path -ChildPath 'Public') -Filter '*.ps1' | Select-Object -ExpandProperty BaseName | Sort-Object

$params = @{
    RootModule = "$moduleName.psm1"
    FunctionsToExport = $functions
}
if ($Version) {
    $params.ModuleVersion = $version
}

Update-ModuleManifest -Path $manifestPath @params