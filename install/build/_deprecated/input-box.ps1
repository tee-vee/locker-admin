# —————————————————————————————————
# DotNetInputBoxV2.ps1
# ed wilson, msft, 10/9/2008
#
# uses the .Net framework interaction class with the inputbox method to
# create an inputbox using the dot net framework classes. the microsoft.visualbasic
# namespace is not loaded by default
#
# —————————————————————————————————
#Requires -version 2.0

$prompt = “Enter your command”
$title = “.net example”
$default = “default value”

Add-Type  -AssemblyName microsoft.visualbasic

$return = [Microsoft.VisualBasic.interaction]::inputbox($prompt,$title,$default)

$return

