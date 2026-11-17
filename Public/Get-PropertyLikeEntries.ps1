filter Get-PropertyLikeEntries {
<#
.SYNOPSIS
Returns property-like name/value entries from an object or dictionary.

.DESCRIPTION
Enumerates an input object and returns a uniform sequence of property-like
entries with the fields Name and Value.

If the input object implements System.Collections.IDictionary, the function
enumerates dictionary keys and values and converts them into PSCustomObject
instances with Name and Value properties.

Otherwise, the function returns the object's PowerShell properties from
InputObject.PSObject.Properties.

This is useful when you want to process both regular objects and dictionary-like
objects through a single code path.

.PARAMETER InputObject
The input object whose properties or dictionary entries should be enumerated.

Accepts pipeline input.

.EXAMPLE
$obj | Get-PropertyLikeEntries

Returns property-like entries for a regular PowerShell object.

.EXAMPLE
$hash | Get-PropertyLikeEntries

Returns dictionary entries as objects with Name and Value properties.

.EXAMPLE
Get-PropertyLikeEntries $obj | ForEach-Object {
    '{0} = {1}' -f $_.Name, $_.Value
}

Enumerates all properties in a uniform way.

.OUTPUTS
For dictionary input:
    System.Management.Automation.PSCustomObject

For non-dictionary input:
    System.Management.Automation.PSPropertyInfo

.NOTES
For dictionary input, the output objects are normalized to contain Name and Value
properties.

For regular objects, the original PSObject.Properties entries are returned, which
also expose Name and Value.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][object] $InputObject
    )

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($entry in $InputObject.GetEnumerator()) {
            [pscustomobject]@{
                Name  = [string]$entry.Key
                Value = $entry.Value
            }
        }
    } else {
        $InputObject.PSObject.Properties
    }
}
