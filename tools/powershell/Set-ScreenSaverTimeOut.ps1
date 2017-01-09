# -----------------------------------------------------------------------------
# Script: Set-ScreenSaverTimeOut.ps1
# Author: ed wilson, msft
# Date: 08/26/2013 17:49:58
# Keywords: Registry
# comments: Transactions
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 6
# -----------------------------------------------------------------------------


Function Set-ScreenSaverTimeOut
{
 [cmdletbinding()]
 Param( [int]$timeOutValue = 600,
        [string]$path = 'HKCU:\Control Panel\Desktop',
        [string]$name = 'ScreenSaveTimeOut' )
 Write-Verbose "$($MyInvocation.MyCommand.name) function called"
 Write-Verbose "Current value of $name $((Get-ItemProperty -path $path -name $name).$name)"
 Start-Transaction 
 Set-ItemProperty -Path $path -name $name -value $timeOutValue -UseTransaction 
 Write-Verbose "New value of $name $((Get-ItemProperty -path $path -name $name -UseTransaction).$name)"
 Complete-Transaction
} #end Set-ScreenSaverTimeOut

