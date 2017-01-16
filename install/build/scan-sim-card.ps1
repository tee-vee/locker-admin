# Derek Yuen <derekyuen@lockerlife.hk>
# December 2016
#
# uses the .Net framework interaction class with the inputbox method to
# create an inputbox using the dot net framework classes. the microsoft.visualbasic
# namespace is not loaded by default

#Requires -version 2.0

$title = "LockerLife Deployment"
$caption = "Scan SIM Card"
$default = ""

## https://msdn.microsoft.com/en-us/library/12xc5368%28v=vs.110%29.aspx?f=255&MSPPError=-2147217396
Add-Type  -AssemblyName Microsoft.VisualBasic
$env:iccid = [Microsoft.VisualBasic.interaction]::inputbox($caption,$title,"$env:iccid")
$iccid


