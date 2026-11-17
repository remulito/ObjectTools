$private = @(Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue)
$public  = @(Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1")

# Interface properties also support explicitly implemented IList members.
Set-Variable -Name ListItemProperty -Value ([System.Collections.IList].GetProperty('Item')) -Scope Script -Option Constant
Set-Variable -Name CollectionCountProperty -Value ([System.Collections.ICollection].GetProperty('Count')) -Scope Script -Option Constant

# IDictionary::Contains method reference:
Set-Variable -Name MapContainsMethod -Value ([System.Collections.IDictionary].GetMethod('Contains')) -Scope Script -Option Constant


foreach ($file in $private + $public) {
    . $file.FullName
}


Export-ModuleMember -Function $public.BaseName   