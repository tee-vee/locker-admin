<#
   .Synopsis
    Backs up files in a folder to a mapped drive. 
   .Description
    This script backs up files in a folder to a mapped drive. The destination folder does not have to exist.
   .Example
    BackupFolderToServer.ps1 -source c:\fso -destination h:\fso
    Backs up all files and folders in c:\fso on local machine to a mapped drive called h. 
   .Inputs
    [string]
   .OutPuts
    [string]
   .Notes
    NAME:  Windows 7 Resource Kit
    AUTHOR: Ed Wilson
    LASTEDIT: 5/20/2009
    KEYWORDS:
   .Link
     Http://www.ScriptingGuys.com
#Requires -Version 2.0
#>
[cmdletbinding()]
Param(
  [Parameter(mandatory=$true)]
  $source,
  [Parameter(mandatory=$true)]
  $destination
) #end param

if(!$source -or !$destination)
  {
    $(throw "You must supply both source and destination.")
  }
Copy-Item -Path $source -destination $destination -recurse
