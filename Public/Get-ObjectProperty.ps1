function Get-ObjectProperty {
<#
.SYNOPSIS
Gets a property value from an object or dictionary.

.DESCRIPTION
Returns the value of a property from either:
- a dictionary-like object implementing System.Collections.IDictionary
- a regular PowerShell or .NET object

If the input object is a dictionary, the function looks up the specified key.

If the input object is a regular object, the function looks up the specified
PowerShell property through the PSObject property adapter.

If the input object is $null, or if the requested property does not exist,
the function returns $null.

.PARAMETER InputObject
The input object from which to retrieve the property value.

This can be either a dictionary-like object or a regular PowerShell object.

If InputObject is $null, the function returns $null.

.PARAMETER Name
The name of the property or dictionary key to retrieve.

This parameter must not be null or empty.

.EXAMPLE
Get-ObjectProperty -InputObject $obj -Name 'Value'

Returns the value of the Value property from the specified object.

.EXAMPLE
Get-ObjectProperty -InputObject $hash -Name 'description'

Returns the value associated with the key 'description' from the specified dictionary.

.EXAMPLE
$entry | ForEach-Object {
    Get-ObjectProperty -InputObject $_ -Name 'Value'
}

Gets the Value property from each object in the pipeline.

.EXAMPLE
Get-ObjectProperty -InputObject $null -Name 'Value'

Returns $null.

.OUTPUTS
System.Object

Returns the property value if found; otherwise returns $null.

.NOTES
This function does not distinguish between:
- a property that does not exist
- a property that exists but has the value $null

If that distinction is required, use a richer helper that returns existence
metadata in addition to the value.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $InputObject,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }

        return $null
    }

    $propertyInfo = $InputObject.PSObject.Properties[$Name]
    if ($null -ne $propertyInfo) {
        return $propertyInfo.Value
    }

    $null
}