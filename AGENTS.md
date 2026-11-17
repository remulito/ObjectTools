# AGENTS.md — ObjectTools

## Purpose

ObjectTools is a PowerShell 7.2+ script module for uniform property access on
`PSCustomObject` instances and `IDictionary` (hashtable) values, plus
object↔dictionary conversion and deep equality comparison. Single-user project
authored by Andrey Lumyanski; published under the MIT license.

## Layout

- `ObjectTools.psd1` — manifest. Hand-edited; defines exports and `PowerShellVersion = '7.2'`.
- `ObjectTools.psm1` — root module. Dot-sources every `.ps1` under `Private/`
  (optional, may not exist) and `Public/`; exports only `Public/*.ps1` basenames.
  Also caches .NET reflection handles in script-scope constants
  (`ListItemProperty`, `CollectionCountProperty`, `MapContainsMethod`).
- `Public/` — one exported function per file; **file name must equal the function name**.
- `Private/` — optional helper files; dot-sourced but never exported. Missing or
  empty directory is fine (loader uses `-ErrorAction SilentlyContinue`).
- `build-module.ps1` — regenerates `FunctionsToExport` (and optionally the
  version) via `Update-ModuleManifest`.
- `README.md`, `LICENSE` (MIT) — user-facing docs, in English.

## Commands

- Smoke-test after changes (run from outside the repo dir so `Import-Module`
  picks up a fresh copy):
  `pwsh -NoProfile -Command 'Import-Module <repo-path>/ObjectTools.psd1; Get-Command -Module ObjectTools'`
- Sync manifest exports after adding/renaming/removing a `Public/` file:
  `pwsh -NoProfile -File build-module.ps1 [-Version x.y.z]` (requires `Update-ModuleManifest`).
- No Pester test suite exists yet.

## Architecture rules

- Every public function follows the **IDictionary-first pattern**: branch on
  `-is [System.Collections.IDictionary]` for key access, fall back to the
  `PSObject` property adapter for everything else.
- When invoking `IList`/`ICollection`/`IDictionary` members reflectively, use
  the cached script-scope handles from the `.psm1` — direct member calls miss
  explicitly implemented interface members (e.g. `Test-ObjectPropertyExists`
  must call `$Script:MapContainsMethod`).
- Property-name comparisons default to ordinal case-insensitive; switches named
  `CaseSensitivePropertyNames` opt into ordinal case-sensitive. String *values*
  are always compared ordinal case-sensitive (`Test-ObjectsEqual`).
- Null input is tolerated by getters/predicates (`Get-ObjectProperty`,
  `Test-ObjectPropertyExists`) but rejected where it would be ambiguous.
- Comment-based help (.SYNOPSIS/.DESCRIPTION/.PARAMETER/.EXAMPLE/.OUTPUTS/.NOTES/.LINK)
  in English is mandatory for `Public/` functions; README examples must stay
  executable against pwsh 7 — validate them after editing.

## Gotchas

- `build-module.ps1` rewrites the whole manifest via `Update-ModuleManifest`
  (regenerates comments, reflows keys) — hand-written manifest edits such as
  `Tags` or `Description` may be reformatted, not lost, but re-check them.
- `Test-ObjectPropertyExists` ≠ `Get-ObjectProperty -ne $null`: a property with a
  null value exists but reads as null.
- `Test-ObjectsEqual` throws on cyclic references and multidimensional arrays;
  repeated (non-cyclic) references are supported via recursion-path tracking.
- `ConvertTo-ObjectPropertyMap` throws on non-string dictionary keys and on
  duplicate names under the active comparison (e.g. `Code`/`code` with the
  default case-insensitive comparer).

## Publishing status

LICENSE (MIT) and README.md exist. `LicenseUri`/`ProjectUri` in the manifest
PSData are still commented out — uncomment them with the real GitHub URL once
the repository exists. Manifest `Description` and `Tags` are filled in.
