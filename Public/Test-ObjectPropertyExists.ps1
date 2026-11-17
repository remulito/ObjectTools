function Test-ObjectPropertyExists {
    <#
    .SYNOPSIS
    Checks whether an object has a property with the specified name.

    .DESCRIPTION
    Checks for a named property or dictionary key.

    For an IDictionary, the function checks whether the dictionary contains
    the specified key. The dictionary's own key comparer determines whether
    the lookup is case-sensitive.

    For other objects, the function checks the object's PowerShell properties.
    Property name lookup is case-insensitive.

    The function checks for the presence of the property or key, not its value.
    A property or key with a null value is considered present.

    .PARAMETER InputObject
    The object or dictionary to inspect. If null, the function returns False.

    .PARAMETER Name
    The property name or dictionary key to find.

    .OUTPUTS
    System.Boolean

    True if the property or key exists; otherwise False.

    .EXAMPLE
    $obj = [pscustomobject]@{
        Code = 'A1'
        Name = $null
    }

    Test-ObjectPropertyExists -InputObject $obj -Name 'Name'
    # True

    Returns True because the property exists, even though its value is null.

    .EXAMPLE
    $map = [ordered]@{
        Code = 'A1'
    }

    Test-ObjectPropertyExists -InputObject $map -Name 'Code'
    # True

    Checks for a key in an ordered dictionary.

    .EXAMPLE
    Test-ObjectPropertyExists -InputObject $null -Name 'Code'
    # False

    .LINK
    Get-ObjectProperty

    .LINK
    Set-ObjectProperty
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $InputObject,

        [Parameter(Mandatory)]
        [string] $Name
    )

    if ($null -eq $InputObject) {
        return $false
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        # Calling through the interface also supports dictionaries
        # that implement IDictionary.Contains explicitly.
        return $Script:MapContainsMethod.Invoke($InputObject, [object[]]@($Name))
    }

    return $null -ne $InputObject.PSObject.Properties[$Name]
}