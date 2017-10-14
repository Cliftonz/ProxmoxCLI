<#
.SYNOPSIS
Get version of Proxmox server

.DESCRIPTION
Get version information of connected Proxmox Server

.EXAMPLE
Get-PveVersion

.NOTES
Run Connect-PveServer first
#>
function Get-PveVersion {
    [CmdletBinding()]
    [OutputType([Object])]
    Param()
    return (callREST -Resource "version")
}


Export-ModuleMember -Cmdlet @('Get-PveVersion')