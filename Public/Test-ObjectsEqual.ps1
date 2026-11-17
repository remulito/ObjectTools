function Test-ObjectsEqual {
    <#
    .SYNOPSIS
    Performs a deep comparison of two objects.

    .DESCRIPTION
    Recursively compares two values.

    PSCustomObject instances and IDictionary instances are compared by their
    property names or dictionary keys and their values. A PSCustomObject and
    an IDictionary can be equal if their names and values match. The order
    of properties and dictionary entries is not significant.

    Property names and dictionary keys are compared using ordinal,
    case-insensitive comparison by default. Use CaseSensitivePropertyNames
    to compare them using ordinal, case-sensitive comparison.

    IList instances are compared element by element. Their order is
    significant. Multidimensional arrays are not supported.

    String values are always compared using ordinal, case-sensitive
    comparison, regardless of CaseSensitivePropertyNames.

    Other values must have the same .NET type and are compared using their
    Equals method. Collections that do not implement IList or IDictionary
    are also compared this way.

    Cyclic references encountered during recursive comparison cause an
    error. Repeated references that do not form a cycle are supported.

    .PARAMETER Left
    The first value to compare. Can be null.

    .PARAMETER Right
    The second value to compare. Can be null.

    .PARAMETER CaseSensitivePropertyNames
    Compare property names and dictionary keys using ordinal,
    case-sensitive comparison.

    By default, names are compared using ordinal, case-insensitive
    comparison. This parameter applies recursively and does not affect
    the comparison of string values.

    .INPUTS
    None.

    .OUTPUTS
    System.Boolean

    Returns True if the values are equal; otherwise, returns False.

    .EXAMPLE
    $a = [pscustomobject]@{ Code = 'A1' }
    $b = [pscustomobject]@{ code = 'A1' }

    Test-ObjectsEqual -Left $a -Right $b
    # True

    Property names are case-insensitive by default.

    .EXAMPLE
    $a = [pscustomobject]@{ Code = 'A1' }
    $b = [pscustomobject]@{ code = 'A1' }

    Test-ObjectsEqual -Left $a -Right $b -CaseSensitivePropertyNames
    # False

    Property names are compared with case sensitivity.

    .EXAMPLE
    $a = [pscustomobject]@{ Name = 'Example' }
    $b = [pscustomobject]@{ Name = 'example' }

    Test-ObjectsEqual -Left $a -Right $b
    # False

    String values are always compared with case sensitivity.

    .EXAMPLE
    $a = [pscustomobject]@{ Items = @(1, 2) }
    $b = [pscustomobject]@{ Items = @(2, 1) }

    Test-ObjectsEqual -Left $a -Right $b
    # False

    The order of list elements is significant.

    .NOTES
    Requires PowerShell 7.2 or later.

    Dictionary keys must be strings. An error is thrown if an object or
    dictionary contains multiple names that are equal under the selected
    name comparison. For example, "Code" and "code" are ambiguous under
    the default comparison.

    The comparison reads property values, which may invoke property getters.

    .LINK
    ConvertTo-ObjectPropertyMap
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [object] $Left,

        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [object] $Right,

        [switch] $CaseSensitivePropertyNames
    )

    # Track only the current recursion path, not every object visited.
    $leftPath = [System.Collections.Generic.HashSet[object]]::new(
        [System.Collections.Generic.ReferenceEqualityComparer]::Instance
    )

    $rightPath = [System.Collections.Generic.HashSet[object]]::new(
        [System.Collections.Generic.ReferenceEqualityComparer]::Instance
    )

    function Compare-ObjectValue {
        param(
            [AllowNull()]
            [AllowEmptyString()]
            [AllowEmptyCollection()]
            [object] $LeftValue,

            [AllowNull()]
            [AllowEmptyString()]
            [AllowEmptyCollection()]
            [object] $RightValue
        )

        $leftIsNull = [object]::ReferenceEquals($LeftValue, $null)
        $rightIsNull = [object]::ReferenceEquals($RightValue, $null)

        if ($leftIsNull -or $rightIsNull) {
            return ($leftIsNull -and $rightIsNull)
        }

        $leftIsObject = (
            $LeftValue -is [System.Collections.IDictionary] -or
            $LeftValue -is [pscustomobject]
        )

        $rightIsObject = (
            $RightValue -is [System.Collections.IDictionary] -or
            $RightValue -is [pscustomobject]
        )

        $leftIsList = $LeftValue -is [System.Collections.IList]
        $rightIsList = $RightValue -is [System.Collections.IList]

        # Object-like values can be compared with other object-like values,
        # and lists can be compared with other lists.
        if ($leftIsObject -or $rightIsObject) {
            if (-not ($leftIsObject -and $rightIsObject)) {
                return $false
            }

            $comparisonKind = 'Object'
        } elseif ($leftIsList -or $rightIsList) {
            if (-not ($leftIsList -and $rightIsList)) {
                return $false
            }

            if (
                ($LeftValue -is [array] -and $LeftValue.Rank -ne 1) -or
                ($RightValue -is [array] -and $RightValue.Rank -ne 1)
            ) {
                throw 'Multidimensional arrays are not supported.'
            }

            $comparisonKind = 'List'
        } else {
            # Scalar values must have the same .NET type.
            if ($LeftValue.GetType() -ne $RightValue.GetType()) {
                return $false
            }

            if ($LeftValue -is [string]) {
                return [string]::Equals(
                    $LeftValue,
                    $RightValue,
                    [StringComparison]::Ordinal
                )
            }

            return $LeftValue.Equals($RightValue)
        }

        if (-not $leftPath.Add($LeftValue)) {
            throw 'A cyclic reference was detected in the left value.'
        }

        try {
            if (-not $rightPath.Add($RightValue)) {
                throw 'A cyclic reference was detected in the right value.'
            }

            try {
                if ($comparisonKind -eq 'Object') {
                    $leftMap = ConvertTo-ObjectPropertyMap `
                        -InputObject $LeftValue `
                        -CaseSensitivePropertyNames:$CaseSensitivePropertyNames

                    $rightMap = ConvertTo-ObjectPropertyMap `
                        -InputObject $RightValue `
                        -CaseSensitivePropertyNames:$CaseSensitivePropertyNames

                    if ($leftMap.get_Count() -ne $rightMap.get_Count()) {
                        return $false
                    }

                    foreach ($name in $leftMap.get_Keys()) {
                        if (-not $rightMap.ContainsKey($name)) {
                            return $false
                        }

                        $leftPropertyValue = $leftMap.get_Item($name)
                        $rightPropertyValue = $rightMap.get_Item($name)

                        if (-not (Compare-ObjectValue -LeftValue $leftPropertyValue -RightValue $rightPropertyValue)) {
                            return $false
                        }
                    }

                    return $true
                }

                # Compare IList elements in order.
                $leftCount = $Script:CollectionCountProperty.GetValue($LeftValue)
                $rightCount = $Script:CollectionCountProperty.GetValue($RightValue)

                if ($leftCount -ne $rightCount) {
                    return $false
                }

                for ($i = 0; $i -lt $leftCount; $i++) {
                    $leftItem = $Script:ListItemProperty.GetValue($LeftValue, [object[]]@($i))

                    $rightItem = $Script:ListItemProperty.GetValue($RightValue, [object[]]@($i))

                    if (-not (Compare-ObjectValue -LeftValue $leftItem -RightValue $rightItem)) {
                        return $false
                    }
                }

                return $true
            } finally {
                [void] $rightPath.Remove($RightValue)
            }
        } finally {
            [void] $leftPath.Remove($LeftValue)
        }
    }

    Compare-ObjectValue -LeftValue $Left -RightValue $Right
}