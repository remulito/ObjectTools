function ConvertTo-ObjectPropertyMap {
    <#
    .SYNOPSIS
    Converts an object's properties or dictionary entries to a property map.

    .DESCRIPTION
    Creates a new dictionary containing property names and their values.

    If InputObject implements IDictionary, its entries are copied. Otherwise,
    the object's PowerShell properties are read and copied.

    Property names are compared using ordinal, case-insensitive comparison by
    default. Use CaseSensitivePropertyNames for ordinal, case-sensitive
    comparison.

    Conversion is shallow: nested objects and collections are not converted
    or cloned.

    .PARAMETER InputObject
    The object or dictionary to convert. Cannot be null.

    For a dictionary, all keys must be strings.

    .PARAMETER CaseSensitivePropertyNames
    Create a dictionary that compares property names using ordinal,
    case-sensitive comparison.

    By default, property names are compared using ordinal, case-insensitive
    comparison.

    This parameter affects property names only, not their values.

    .INPUTS
    System.Object

    Objects can be passed through the pipeline.

    .OUTPUTS
    System.Collections.Generic.Dictionary[string, object]

    A new dictionary containing property names and values.

    .EXAMPLE
    $obj = [pscustomobject]@{
        Code = 'A1'
        Name = 'Example'
    }

    $map = ConvertTo-ObjectPropertyMap -InputObject $obj
    $map.ContainsKey('Code') # True
    $map.ContainsKey('code') # True

    Property names are case-insensitive by default.

    .EXAMPLE
    $obj = [pscustomobject]@{ Code = 'A1' }

    $map = ConvertTo-ObjectPropertyMap -InputObject $obj -CaseSensitivePropertyNames
    $map.ContainsKey('Code') # True
    $map.ContainsKey('code') # False

    Creates a map with case-sensitive property names.

    .EXAMPLE
    $objects | ConvertTo-ObjectPropertyMap

    Converts each pipeline object to a separate property map.

    .NOTES
    The function reads property values, which may invoke property getters.

    An error is thrown if a dictionary contains a non-string key or if
    multiple names are equal under the selected comparison. For example,
    "Code" and "code" are ambiguous under the default comparison.

    The resulting dictionary may use different key comparison rules from
    the source dictionary. Entries already collapsed by the source
    dictionary cannot be recovered.

    .LINK
    Get-ObjectProperty

    .LINK
    Set-ObjectProperty

    .LINK
    Test-ObjectPropertyExists

    .LINK
    Test-ObjectsEqual
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.Dictionary[string, object]])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [object] $InputObject,

        [switch] $CaseSensitivePropertyNames
    )

    process {
        $comparer = if ($CaseSensitivePropertyNames) {
            [StringComparer]::Ordinal
        }
        else {
            [StringComparer]::OrdinalIgnoreCase
        }

        $map = [System.Collections.Generic.Dictionary[string, object]]::new(
            $comparer
        )

        if ($InputObject -is [System.Collections.IDictionary]) {
            # Access the interface to support explicit implementations.
            $dictionaryType = [System.Collections.IDictionary]
            $keysProperty = $dictionaryType.GetProperty('Keys')
            $itemProperty = $dictionaryType.GetProperty('Item')

            foreach ($key in $keysProperty.GetValue($InputObject)) {
                if ($key -isnot [string]) {
                    throw 'Dictionary keys must be strings.'
                }

                if ($map.ContainsKey($key)) {
                    throw "Duplicate property name under the selected comparison: '$key'."
                }

                $value = $itemProperty.GetValue(
                    $InputObject,
                    [object[]]@($key)
                )
                $map.Add($key, $value)
            }
        } else {
            foreach ($property in $InputObject.PSObject.Properties) {
                if ($map.ContainsKey($property.Name)) {
                    throw (
                        "Duplicate property name under the selected comparison: " +
                        "'$($property.Name)'."
                    )
                }

                $map.Add($property.Name, $property.Value)
            }
        }

        return $map
    }
}