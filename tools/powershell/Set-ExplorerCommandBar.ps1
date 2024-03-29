# -----------------------------------------------------------------------------
# Script: Set-ExplorerCommandBar.ps1
# Author: ed wilson, msft
# Date: 02/22/2011 14:16:43
# Keywords: Scripting Techniques, Graphical, Desktop Management, Windows Explorer
# comments: This command requires Admin rights to edit the registry
# 1. It can be run without admin rights to view current settings.
# 2. You must select one of the four libraries
# 3. You must select one of the Task Items
# 4. You can then choose to "Get The Current Value" of the registry key
# 5. You should always view the current value of the registry key prior to 
#    attempting to change the registry key value.
# 6. Once you have seen the current value, you can select to add commands to
#    the explorer bar. You can hold down the <ctrl> key to add multiple 
#    commands at once. 
# *** There is NO UNDO command *** 
# *** NOT all commands are guaranted to work with all combinations of libraries
#     and tasks ******************
# *** You should only add commands that make sense to the task at hand. 
# *** You should immediately check out the results, so you can manually edit the
# registry to remove what you added while it is still fresh on your mind.
#
# See Hey Scripting Guy! Blog Feburary 26, 2010  
# -----------------------------------------------------------------------------
function Test-IsAdministrator
{
    <#
    .Synopsis
    Tells whether the current user is an administrator.

    .Description
    The Test-IsAdministrator function determines whether the current user is a member of the 
    Administrators group on the local computer.
    It returns TRUE if a user is an administrator and FALSE otherwise.
    This function has no parameters.

    .Example
    C:\PS> Test-IsAdministrator
    False

    .Example
    # This prompt uses the Test-IsAdministrator function to change the prompt when the user
    is an administrator.

    function prompt 
    {
       if (Test-IsAdministrator) { '[ADMIN]: ' }

        elseif $(if (test-path variable:/PSDebugContext) { '[DBG]: ' } 

        else { '' }) + 'PS ' + $(Get-Location) + $(if ($nestedpromptlevel -ge 1) { '>>' }) + '> '
    }
    #>   
    param() 
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
#----------------------------------------------
#region Application Functions
#----------------------------------------------

function OnApplicationLoad {
	#Note: This function runs before the form is created
	#Note: To get the script directory in the Packager use: Split-Path $hostinvocation.MyCommand.path
	#Note: To get the console output in the Packager (Windows Mode) use: $ConsoleOutput (Type: System.Collections.ArrayList)
	#Important: Form controls cannot be accessed in this function
	#TODO: Add snapins and custom code to validate the application load
	
	return $true #return true for success or false for failure
}

function OnApplicationExit {
	#Note: This function runs after the form is closed
	#TODO: Add custom code to clean up and unload snapins when the application exits
	
	$script:ExitCode = 0 #Set the exit code for the Packager
}

#endregion

#----------------------------------------------
# Generated Form Function
#----------------------------------------------
function GenerateForm {

	#----------------------------------------------
	#region Import Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	[void][reflection.assembly]::Load("mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	#endregion
	
	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$form1 = New-Object System.Windows.Forms.Form
	$label3 = New-Object System.Windows.Forms.Label
	$label2 = New-Object System.Windows.Forms.Label
	$button1 = New-Object System.Windows.Forms.Button
	$listbox2 = New-Object System.Windows.Forms.ListBox
	$groupbox1 = New-Object System.Windows.Forms.GroupBox
	$radiobutton2 = New-Object System.Windows.Forms.RadioButton
	$radiobutton1 = New-Object System.Windows.Forms.RadioButton
	$label1 = New-Object System.Windows.Forms.Label
	$textbox1 = New-Object System.Windows.Forms.TextBox
	$btn_Add = New-Object System.Windows.Forms.Button
	$listbox1 = New-Object System.Windows.Forms.ListBox
	$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------

		
	$FormEvent_Load={
		$arrayCommands = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell | 
		select-object pschildname | ForEach-Object{$_.pschildname.tostring()}
		foreach($command in $arrayCommands)
		{
		$ListBox2.items.add($command)
		} #end foreach command
        $arrayFolders = "Documents","Music","Pictures","Videos"
        foreach($folder in $arrayFolders) {$listbox1.items.add($folder)}
        
	} #end FormEvent_Load
	
		
	$handler_btn_Add_Click={
   	$textbox1.clear()
    $textbox1.refresh()
    $textbox1.resetText()
    If(!(Test-IsAdministrator)) { $Textbox1.text = "You must be an administrator to set registry values" ; start-sleep 2; $form1.close()}
	Foreach($listItem in $listbox1.SelectedItems)
     {
       Switch ($listItem)
       {
        "Documents" {$regKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{fbb3477e-c9e4-4b3b-a2ba-d3f5d3cd46f9}' }
        "Music" {$regKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{3f2a72a7-99fa-4ddb-a5a8-c604edf61d6b}' }
        "Pictures" {$regKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{0b2baaeb-0042-4dca-aa4d-3ee8648d03e5}' }
        "Videos" {$regKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{631958a6-ad0f-4035-a745-28ac066dc6ed}' }
        "Generic" {$regKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{5c4f28b5-f869-4e84-8e60-f11db97c5cc7}' }
        Default {$textbox1.text = "You must choose one of the items in the listbox" }
       } #end switch
     } #end foreach listitem
     
     If($radiobutton1.checked) { $regKey += "\TasksItemsSelected" }
     If($radiobutton2.checked) { $regKey += "\TasksNoItemsSelected" }
     $DefaultValue = (Get-Itemproperty -path $regkey -name "(default)")."(default)"

     $DefaultValue += ";" + [string]$ListBox2.selectedItems -replace " ",";"    
     $label1.text = "Modifying Registry:"
     $label1.visible = $true
     $textbox1.text = $regKey + "`r`n" + $DefaultValue
     Set-Item -Path $regKey -Value $DefaultValue -type String
	} #end handler_btn_Add_Click
	

	
	$handler_button1_Click={
	$textbox1.clear()
    $textbox1.refresh()
    $textbox1.resetText()

	Foreach($listItem in $listbox1.SelectedItems)
     {
       Switch ($listItem)
       {
        "Documents" {$regKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{fbb3477e-c9e4-4b3b-a2ba-d3f5d3cd46f9}' }
        "Music" {$regKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{3f2a72a7-99fa-4ddb-a5a8-c604edf61d6b}' }
        "Pictures" {$regKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{0b2baaeb-0042-4dca-aa4d-3ee8648d03e5}' }
        "Videos" {$regKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{631958a6-ad0f-4035-a745-28ac066dc6ed}' }
        "Generic" {$regKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{5c4f28b5-f869-4e84-8e60-f11db97c5cc7}' }
        Default {$regKey = "You must choose one of the items in the listbox" ; exit }
       } #end switch
     } #end foreach listitem
     
     If($radiobutton1.checked) { $regKey += "\TasksItemsSelected" }
     If($radiobutton2.checked) { $regKey += "\TasksNoItemsSelected" }
     $DefaultValue = (Get-Itemproperty -path $regkey -name "(default)")."(default)"
    
     $label1.text = "Current value:"
     $label1.visible = $true
     $textbox1.text = $regKey + "`r`n`r`n" + $DefaultValue

	
	} #end handler_button1_click
	
	#----------------------------------------------
	# Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$form1.WindowState = $InitialFormWindowState
	}
	
	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	#
	# form1
	#
	$form1.Controls.Add($label3)
	$form1.Controls.Add($label2)
	$form1.Controls.Add($button1)
	$form1.Controls.Add($listbox2)
	$form1.Controls.Add($groupbox1)
	$form1.Controls.Add($label1)
	$form1.Controls.Add($textbox1)
	$form1.Controls.Add($btn_Add)
	$form1.Controls.Add($listbox1)
	$form1.ClientSize = New-Object System.Drawing.Size(518,375)
	$form1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$form1.Name = "form1"
	$form1.Text = "Add Folder Commands"
	$form1.add_Load($FormEvent_Load)
	#
	# label3
	#
	$label3.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$label3.Location = New-Object System.Drawing.Point(192,11)
	$label3.Name = "label3"
	$label3.Size = New-Object System.Drawing.Size(100,23)
	$label3.TabIndex = 10
	$label3.Text = "Command"
	#
	# label2
	#
	$label2.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$label2.Location = New-Object System.Drawing.Point(19,12)
	$label2.Name = "label2"
	$label2.Size = New-Object System.Drawing.Size(100,23)
	$label2.TabIndex = 9
	$label2.Text = "Library "
	#
	# button1
	#
	$button1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$button1.Location = New-Object System.Drawing.Point(340,200)
	$button1.Name = "button1"
	$button1.Size = New-Object System.Drawing.Size(166,23)
	$button1.TabIndex = 8
	$button1.Text = "Get Current Value"
	$button1.UseVisualStyleBackColor = $True
	$button1.add_Click($handler_button1_Click)
	#
	# listbox2
	#
	$listbox2.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$listbox2.FormattingEnabled = $True
	$listbox2.Location = New-Object System.Drawing.Point(192,38)
	$listbox2.Name = "listbox2"
	$listbox2.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiExtended 
	$listbox2.Size = New-Object System.Drawing.Size(314,108)
	$listbox2.TabIndex = 7
	#
	# groupbox1
	#
	$groupbox1.Controls.Add($radiobutton2)
	$groupbox1.Controls.Add($radiobutton1)
	$groupbox1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$groupbox1.Location = New-Object System.Drawing.Point(19,154)
	$groupbox1.Name = "groupbox1"
	$groupbox1.Size = New-Object System.Drawing.Size(171,77)
	$groupbox1.TabIndex = 6
	$groupbox1.TabStop = $False
	$groupbox1.Text = "Task Items"
	#
	# radiobutton2
	#
	$radiobutton2.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$radiobutton2.Location = New-Object System.Drawing.Point(7,50)
	$radiobutton2.Name = "radiobutton2"
	$radiobutton2.Size = New-Object System.Drawing.Size(152,24)
	$radiobutton2.TabIndex = 1
	$radiobutton2.TabStop = $True
	$radiobutton2.Text = "Items Not Selected"
	$radiobutton2.UseVisualStyleBackColor = $True
	#
	# radiobutton1
	#
	$radiobutton1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$radiobutton1.Location = New-Object System.Drawing.Point(7,20)
	$radiobutton1.Name = "radiobutton1"
	$radiobutton1.Size = New-Object System.Drawing.Size(104,24)
	$radiobutton1.TabIndex = 0
	$radiobutton1.TabStop = $True
	$radiobutton1.Text = "Items Selected"
	$radiobutton1.UseVisualStyleBackColor = $True
	#
	# label1
	#
	$label1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$label1.Location = New-Object System.Drawing.Point(19,234)
	$label1.Name = "label1"
	$label1.Size = New-Object System.Drawing.Size(171,23)
	$label1.TabIndex = 4
	$label1.Text = "PowerShell Command To Run"
	#
	# textbox1
	#
	$textbox1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$textbox1.Location = New-Object System.Drawing.Point(19,260)
	$textbox1.Multiline = $True
	$textbox1.Name = "textbox1"
	$textbox1.Size = New-Object System.Drawing.Size(487,103)
	$textbox1.TabIndex = 3
	#
	# btn_Add
	#
	$btn_Add.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$btn_Add.Location = New-Object System.Drawing.Point(340,229)
	$btn_Add.Name = "btn_Add"
	$btn_Add.Size = New-Object System.Drawing.Size(166,23)
	$btn_Add.TabIndex = 2
	$btn_Add.Text = "Add Commands To Registry"
	$btn_Add.UseVisualStyleBackColor = $True
	$btn_Add.add_Click($handler_btn_Add_Click)
	#
	# listbox1
	#
	$listbox1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$listbox1.FormattingEnabled = $True
	$listbox1.Location = New-Object System.Drawing.Point(19,38)
	$listbox1.Name = "listbox1"
	$listbox1.Size = New-Object System.Drawing.Size(90,108)
	$listbox1.TabIndex = 1
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $form1.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$form1.add_Load($Form_StateCorrection_Load)
	#Show the Form
	return $form1.ShowDialog()

} #End Function

#Call OnApplicationLoad to initialize
if(OnApplicationLoad -eq $true)
{
	#Create the form
	GenerateForm | Out-Null
	#Perform cleanup
	OnApplicationExit
}
