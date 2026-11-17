function Set-ObjectProperty {
<#
.SYNOPSIS
Sets a property value on an object or dictionary.

.DESCRIPTION
Sets a property value on either:
- a dictionary-like object implementing System.Collections.IDictionary
- a regular PowerShell or .NET object

If the input object is a dictionary, the function assigns the value to the
specified key.

If the input object is a regular object, the function first checks whether a
property with the specified name already exists and is settable. If so, the
property value is assigned directly.

If no such settable property exists, the function adds or updates a note
property with the specified name using Add-Member -Force.

This function mutates the input object in place and does not produce output.

.PARAMETER InputObject
The input object on which to set the property value.

This can be either a dictionary-like object or a regular PowerShell object.

.PARAMETER Name
The name of the property or dictionary key to set.

This parameter must not be null or empty.

.PARAMETER Value
The value to assign to the specified property or dictionary key.

This parameter may be $null.

.EXAMPLE
Set-ObjectProperty -InputObject $obj -Name 'Value' -Value 123

Sets the Value property on the specified object if it exists and is settable;
otherwise adds or updates a note property named Value.

.EXAMPLE
Set-ObjectProperty -InputObject $hash -Name 'description' -Value 'Example text'

Sets the key 'description' on the specified dictionary.

.EXAMPLE
Set-ObjectProperty -InputObject $obj -Name 'x-enumDirectory' -Value 'PAYMENT_TYPE'

Adds or updates a custom extension property on the specified object.

.EXAMPLE
$entry | ForEach-Object {
    Set-ObjectProperty -InputObject $_ -Name 'Value' -Value 'Updated'
    $_
}

Updates the Value property on each object and passes the modified object further
through the pipeline.

.OUTPUTS
None

.NOTES
For regular objects, the function prefers assigning to an existing settable
property when possible.

If the property does not exist, or exists but is not settable, the function
falls back to Add-Member -NotePropertyName ... -Force, which adds or replaces
a note property.

The function mutates the input object but does not return it. If you need the
object in the pipeline after modification, output it explicitly.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $InputObject,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter()]
        [AllowNull()]
        [object] $Value
    )

    if ($InputObject -is [System.Collections.IDictionary]) {
        $InputObject[$Name] = $Value
        return
    }

    $propertyInfo = $InputObject.PSObject.Properties[$Name]

    if ($null -ne $propertyInfo -and $propertyInfo.IsSettable) {
        $propertyInfo.Value = $Value
        return
    }

    $InputObject | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}