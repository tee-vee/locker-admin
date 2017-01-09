Option Explicit

'Variables
Dim objShell,FSO,dtmStart,dtmEnd
Dim strUserProfile,strAppData
Dim objFolder,objFile,strOSversion

Wscript.echo "Profile cleanup starting"
dtmStart = Timer()

'Get the current users Profile and ApplicationData folders
Set objShell = CreateObject("WScript.Shell")
strUserProfile=objShell.ExpandEnvironmentStrings("%USERPROFILE%")
strAppData=objShell.ExpandEnvironmentStrings("%APPDATA%")
'Wscript.echo strAppData

'Set reference to the file system
Set FSO = createobject("Scripting.FileSystemObject")

'Get the windows version
strOSversion = objShell.RegRead("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentVersion")
'Wscript.echo strOSversion
'Call the DeleteOlder subroutine for each folder

'Application temp files

DeleteOlder 14, strAppData & "\Microsoft\Office\Recent" 'Days to keep recent MS Office files
DeleteOlder 5, strAppData & "\Microsoft\CryptnetUrlCache\Content"  'IE certificate cache
DeleteOlder 5, strAppData & "\Microsoft\CryptnetUrlCache\MetaData" 'IE cert info
DeleteOlder 5, strAppData & "\Sun\Java\Deployment\cache" 'Days to keep Java cache
DeleteOlder 5, strAppData & "\Macromedia\Flash Player"   'Days to keep flash data

'OS specific temp files
if Cint(Left(strOSversion,1)) > 5 Then
   Wscript.echo "Windows Vista/7/2008..."
   DeleteOlder 90, strAppData & "\Microsoft\Windows\Cookies"  'Days to keep cookies
   DeleteOlder 14, strAppData & "\Microsoft\Windows\Recent"   'Days to keep recent files
Else
   Wscript.echo "Windows 2000/2003/XP..."
   DeleteOlder 90, strUserProfile & "\Cookies"  'Days to keep cookies
   DeleteOlder 14, strUserProfile & "\Recent"   'Days to keep recent files
End if

'Print completed message

dtmEnd = Timer()
Wscript.echo "Profile cleanup complete, elapsed time: " & FormatNumber(dtmEnd-dtmStart,2) & " seconds"

'Subroutines below

Sub DeleteOlder(intDays,strPath)
' Delete files from strPath that are more than intDays old
If FSO.FolderExists(strPath) = True Then
   Set objFolder = FSO.GetFolder(strPath)
   For each objFile in objFolder.files
      If DateDiff("d", objFile.DateLastModified,Now) > intDays Then
         'Wscript.echo "File: " & objFile.Name
         objFile.Delete(True)
      End If
   Next
End If
End Sub
