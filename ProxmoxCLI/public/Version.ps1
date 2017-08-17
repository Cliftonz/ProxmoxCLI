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
    Param()
    return (callREST -Resource "version")
}


Export-ModuleMember -Function @('Get-PveVersion')