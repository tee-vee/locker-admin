'*******************************************************************************
'* File:	Install-Drivers.vbs
'* Author:	Jonathon Mitchell	
'* Purpose:	Enumerates INF files in the parent directory
'*		Each INF is added to the driver store and installed	
'* Usage:       cscript.exe DriverInstall.vbs
'* Version:     1.0
'* History:		
'*		Version		Author		Date			What
'*		1.0		JM219		01/11/2013		Initial Version
'*******************************************************************************

'*************************
'* Declare Variables
'*************************
Dim rootFolder 		: rootFolder = IsString(Replace(WScript.ScriptFullName,WScript.ScriptName,""))
Dim driverInstalled : driverInstalled = "Number successfully imported:"
Dim nInstalled		: nInstalled = 0

Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = CreateObject("WScript.Shell")

WScript.Echo "Driver install begin."
WScript.Echo "Driver install folder " & LogVar(rootFolder)
RecurseFolders(rootFolder)
WScript.Echo "Sucessfully installed " & nInstalled & " driver(s)."
WScript.Echo "Driver install complete."

'*************************
'* Subroutines & Functions
'*************************

Sub RecurseFolders(sPath)

	On Error Resume Next

	Dim oFile, sInstall, oFolder, infInstalled 

	With oFSO.GetFolder(sPath)
		If .Files.Count > 0 Then
			For Each oFile In .Files
				If UCase(Right(oFile.Name,3)) = "INF" Then
					sInstall = "pnputil -i -a " & Chr(34) & oFile.Path & Chr(34)
					WScript.Echo "Executing " & LogVar(sInstall)
					infInstalled = vbCommand(sInstall, driverInstalled)
					If infInstalled > 0 Then
						nInstalled = nInstalled + infInstalled
						WScript.Echo "Sucessfully installed " & infInstalled & " device driver(s)."
					Else
						WScript.Echo "No drivers installed from this INF."
					End If
				End If
			Next
		End If
		If .SubFolders.Count > 0 Then
			For Each oFolder in .SubFolders
				' Recurse to check for further subfolders
				RecurseFolders oFolder.Path
			Next
		End If
	End With

End Sub

'This function is modified to search for the number of drivers successfully installed
'Customized to return the int found in the string rather than boolean
Function vbCommand(ByVal sCommand,ByVal boolSuccess)

	Dim oShell,oExec,oStdOut,sResult,sLine,sMatch,iInstalled,iExecCount,iExecMax
	
	'Number of times to allow execution
	iExecMax = 120
	
	'Check both values are strings
	sCommand = IsString(sCommand)
	boolSuccess = IsString(boolSuccess)
	
	Set oShell = WScript.CreateObject("WScript.shell")
	Set oRegEx = CreateObject("VBScript.RegExp")
	oRegEx.Global = True   
	oRegEx.Pattern = "\d"
	Set oExec = oShell.Exec(sCommand)
	Set oStdOut = oExec.StdOut

	'Allow the command the execute before reading the result
	iExecCount = 0
	Do While oExec.Status = 0
		If iExecCount > 120 Then
			WScript.Echo "120 seconds elapsed, killing current execution."
			oExec.Terminate()
			Exit Do
		End If
		iExecCount = iExecCount + 1
		WScript.Sleep 100
	Loop
			
	Do While Not oStdOut.AtEndOfStream
		'Looking for our marker that indicates success somewhere in the output
		sLine = oStdOut.ReadLine
		If Len(sLine) > 0 Then
			If InStr(sLine,boolSuccess) > 0 Then
				sResult = sLine
				Exit Do
			End If
		End If
		Set sLine = Nothing
	Loop
	
	'Execute the search for numbers in the resultant string
	Set cMatches = oRegEx.Execute(sResult)
	If cMatches.Count > 0 Then
		For Each sMatch in cMatches
			iInstalled = sMatch.Value
		Next
	End If
	
	'Return the number of drivers successfully installed
	vbCommand = iInstalled 
	
End Function

Function IsString(ByVal sString)

	If Not TypeName(sString) = "String" Then
		IsString = CStr(sString)
	Else
		IsString = sString
	End If

End Function

Function LogVar(ByVal sVariable)

	sVariable = IsString(sVariable)
	LogVar = "[" & sVariable & "]"

End Function