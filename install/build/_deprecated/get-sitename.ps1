function CustomInputBox([string] $title, [string] $message, [string] $defaultText) {
    $inputObject = new-object -comobject MSScriptControl.ScriptControl
    $inputObject.language = "vbscript" 
    $inputObject.addcode("function getInput() getInput = inputbox(`"$message`",`"$title`" , `"$defaultText`") end function" ) 
    $_userInput = $inputObject.eval("getInput") 

    return $_userInput
}


$userInput = CustomInputBox "User Name" "Please enter your name." ""
if ( $userInput -ne $null ) {
    echo "Input was [$userInput]"
}
else {
    echo "User cancelled the form!"
}
