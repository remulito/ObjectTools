function ConvertTo-ObjectFromProperties {
<#
.SYNOPSIS
Builds an object from property-like entries.

.DESCRIPTION
Creates a new object from input entries by reading one property as the output
property name and another property as the output property value.

The command accepts entries either from the pipeline or through the -Property
parameter.

Input entries are collected into an ordered dictionary, preserving insertion
order.

By default, the function expects input objects to expose properties named
'Name' and 'Value'.

By default, the result is returned as a PSCustomObject.

If -AsHashtable is specified, the result is returned as an ordered dictionary.

Invalid input handling is controlled by the -InvalidInputAction parameter.

.PARAMETER Property
Input entries used to construct the output object.

This parameter accepts pipeline input and explicit argument input.

.PARAMETER NameProperty
The name of the property on each input entry that provides the output property name.

The default value is 'Name'.

.PARAMETER ValueProperty
The name of the property on each input entry that provides the output property value.

The default value is 'Value'.

.PARAMETER AsHashtable
Returns the resulting object as an ordered dictionary instead of a PSCustomObject.

.PARAMETER InvalidInputAction
Controls how invalid input entries are handled.

Valid values are:
- Error : write a terminating error and stop processing
- Skip  : silently skip invalid entries
- Warn  : write a warning and skip invalid entries

The default value is Error.

.EXAMPLE
$object.PSObject.Properties | ConvertTo-ObjectFromProperties

Builds a new PSCustomObject from the properties of an existing object.

.EXAMPLE
ConvertTo-ObjectFromProperties -Property $object.PSObject.Properties

Builds a new PSCustomObject from the provided property collection.

.EXAMPLE
$hash | Get-PropertyLikeEntries | ConvertTo-ObjectFromProperties

Builds a PSCustomObject from dictionary entries.

.EXAMPLE
$entries | ConvertTo-ObjectFromProperties -NameProperty Key -ValueProperty Data

Builds an object using the Key property as the output property name and the Data
property as the output property value.

.EXAMPLE
ConvertTo-ObjectFromProperties -Property $entries -AsHashtable

Builds an ordered dictionary instead of a PSCustomObject.

.EXAMPLE
$entries | ConvertTo-ObjectFromProperties -InvalidInputAction Warn

Skips invalid entries and emits warnings.

.OUTPUTS
By default:
    System.Management.Automation.PSCustomObject

With -AsHashtable:
    System.Collections.Specialized.OrderedDictionary

.NOTES
If multiple input entries produce the same output property name, the last one wins.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]] $Property,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $NameProperty = 'Name',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $ValueProperty = 'Value',

        [Parameter()]
        [switch] $AsHashtable,

        [Parameter()]
        [ValidateSet('Error', 'Skip', 'Warn')]
        [string] $InvalidInputAction = 'Error'
    )

    begin {
        $properties = [ordered]@{}

        function New-InvalidInputErrorRecord {
            param(
                [Parameter(Mandatory)]
                [string] $ErrorId,

                [Parameter(Mandatory)]
                [string] $Message,

                [Parameter()]
                [object] $TargetObject,

                [Parameter()]
                [System.Exception] $Exception
            )

            if ($null -eq $Exception) {
                $Exception = [System.ArgumentException]::new($Message)
            }

            [System.Management.Automation.ErrorRecord]::new(
                $Exception,
                $ErrorId,
                [System.Management.Automation.ErrorCategory]::InvalidData,
                $TargetObject
            )
        }
    }

    process {
        foreach ($entry in $Property) {
            $errorRecord = $null
            $namePropertyInfo = $null
            $valuePropertyInfo = $null

            if ($null -eq $entry) {
                $errorRecord = New-InvalidInputErrorRecord `
                    -ErrorId 'NullInputEntry' `
                    -Message 'Input entry must not be null.' `
                    -TargetObject $null `
                    -Exception ([System.ArgumentNullException]::new('Property', 'Input entry must not be null.'))
            } else {
                $entryTypeName = $entry.GetType().FullName
                $namePropertyInfo  = $entry.PSObject.Properties[$NameProperty]
                $valuePropertyInfo = $entry.PSObject.Properties[$ValueProperty]

                if ($null -eq $namePropertyInfo) {
                    $errorRecord = New-InvalidInputErrorRecord `
                        -ErrorId 'MissingNameProperty' `
                        -Message "Input object of type '$entryTypeName' does not contain a property named '$NameProperty'." `
                        -TargetObject $entry
                } elseif ($null -eq $valuePropertyInfo) {
                    $errorRecord = New-InvalidInputErrorRecord `
                        -ErrorId 'MissingValueProperty' `
                        -Message "Input object of type '$entryTypeName' does not contain a property named '$ValueProperty'." `
                        -TargetObject $entry
                }
            }

            if ($null -ne $errorRecord) {
                switch ($InvalidInputAction) {
                    'Error' {
                        $PSCmdlet.ThrowTerminatingError($errorRecord)
                    }
                    'Warn' {
                        Write-Warning $errorRecord.Exception.Message
                        continue
                    }
                    'Skip' {
                        continue
                    }
                }
            }

            $properties[[string]$namePropertyInfo.Value] = $valuePropertyInfo.Value
        }
    }

    end {
        if ($AsHashtable) {
            $properties
        }
        else {
            [pscustomobject]$properties
        }
    }
}