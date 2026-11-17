# ObjectTools

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![PowerShell 7.2+](https://img.shields.io/badge/PowerShell-7.2%2B-blue.svg)

A PowerShell module with small utilities for working with objects, property
bags, and dictionaries through a single uniform interface.

PowerShell code often has to deal with two kinds of "property holders":
`PSCustomObject` instances (accessed through `PSObject.Properties`) and
`IDictionary` instances such as hashtables (accessed through keys). ObjectTools
provides one set of commands that handles both, plus converters and a deep
comparison helper.

## Features

- **Uniform access** — read, write, and test properties or dictionary keys with
  the same commands, regardless of the underlying type.
- **Null-safe** — `Get-ObjectProperty` and `Test-ObjectPropertyExists` accept
  `$null` input and never throw on it.
- **Conversion** — turn property-like entries into objects (or ordered
  dictionaries) and back into property maps.
- **Deep comparison** — recursive equality with cycle detection, order-significant
  list comparison, and configurable property-name case sensitivity.
- **No dependencies** — plain script module, PowerShell 7.2 or later.

## Commands

| Command | Purpose |
| --- | --- |
| `Get-ObjectProperty` | Read a property value or dictionary key; returns `$null` for missing input. |
| `Set-ObjectProperty` | Set a property or dictionary key in place. |
| `Test-ObjectPropertyExists` | Check whether a property or key exists (a null value still counts as present). |
| `Get-PropertyLikeEntries` | Enumerate an object or dictionary as uniform `Name`/`Value` entries. |
| `ConvertTo-ObjectFromProperties` | Build a `PSCustomObject` or ordered dictionary from `Name`/`Value` entries. |
| `ConvertTo-ObjectPropertyMap` | Copy properties or dictionary entries into a `Dictionary[string, object]`. |
| `Test-ObjectsEqual` | Recursively compare two values for equality. |

## Installation

The module is not published to the PowerShell Gallery yet. Install from source:

```powershell
git clone https://github.com/remulito/ObjectTools.git
Import-Module ./ObjectTools/ObjectTools.psd1
```

To make it permanently available, copy the module folder into one of the
directories listed in `$env:PSModulePath` (for example
`~/.local/share/powershell/Modules` on Linux or
`$HOME\Documents\PowerShell\Modules` on Windows).

## Examples

### Read and write properties and keys with one command

```powershell
$object = [pscustomobject]@{ Name = 'Example' }
$map    = @{ Name = 'Example' }

Get-ObjectProperty -InputObject $object -Name 'Name'   # Example
Get-ObjectProperty -InputObject $map    -Name 'Name'   # Example

Set-ObjectProperty -InputObject $object -Name 'Code' -Value 'A1'
Set-ObjectProperty -InputObject $map    -Name 'Code' -Value 'A1'
```

`Set-ObjectProperty` assigns to an existing settable property when possible and
falls back to `Add-Member -Force`, so extension properties work too:

```powershell
Set-ObjectProperty -InputObject $object -Name 'x-enumDirectory' -Value 'PAYMENT_TYPE'
```

### Check property existence without confusing $null with absence

```powershell
$item = [pscustomobject]@{ Description = $null }

Test-ObjectPropertyExists -InputObject $item -Name 'Description'
# True — the property exists, its value just happens to be null

Get-ObjectProperty -InputObject $null -Name 'Anything'
# $null — input objects are never rejected
```

### Convert between dictionaries and objects

```powershell
$hash = @{ Code = 'A1'; Name = 'Example' }

$hash | Get-PropertyLikeEntries | ConvertTo-ObjectFromProperties
# Code Name
# ---- ----
# A1   Example

$hash | Get-PropertyLikeEntries | ConvertTo-ObjectFromProperties -AsHashtable
# Ordered dictionary with the same entries
```

Entries missing the expected `Name`/`Value` properties can be skipped or warned
about instead of failing:

```powershell
$entries | ConvertTo-ObjectFromProperties -InvalidInputAction Warn
```

### Build a property map

```powershell
$map = ConvertTo-ObjectPropertyMap -InputObject $object
$map['Name']                    # Example
$map.ContainsKey('name')        # True — case-insensitive by default

ConvertTo-ObjectPropertyMap -InputObject $object -CaseSensitivePropertyNames
```

### Deep comparison of two values

```powershell
$a = [pscustomobject]@{ Name = 'Example'; Items = @(1, 2) }
$b = @{ name = 'Example'; Items = @(1, 2) }

Test-ObjectsEqual -Left $a -Right $b
# True — PSCustomObject vs hashtable, property names case-insensitive,
# values compared recursively

Test-ObjectsEqual -Left $a -Right $b -CaseSensitivePropertyNames
# False — 'Name' and 'name' no longer match

Test-ObjectsEqual -Left 'Example' -Right 'example'
# False — string values are always compared case-sensitively
```

Lists are compared element by element in order, cyclic references are reported
as errors instead of recursing forever, and `Test-ObjectsEqual` never throws on
`$null` arguments.

### Round-trip an object through entries

```powershell
$copy = $object | Get-PropertyLikeEntries | ConvertTo-ObjectFromProperties
```

`Get-PropertyLikeEntries` produces uniform `Name`/`Value` entries for both
objects and dictionaries, which makes it easy to feed either kind of value into
the same conversion pipeline.

## Requirements

- PowerShell 7.2 or later (see `PowerShellVersion` in
  [ObjectTools.psd1](ObjectTools.psd1))
- No external module dependencies

## Building

After adding or renaming files in `Public/`, regenerate the manifest's
`FunctionsToExport` list:

```powershell
./build-module.ps1 [-Version <x.y.z>]
```

> `build-module.ps1` runs `Update-ModuleManifest`, which regenerates the
> manifest file (comments are rewritten and keys reflowed). Re-check
> hand-written edits such as `Tags` or `Description` after running it.

## License

This project is licensed under the [MIT License](LICENSE).
