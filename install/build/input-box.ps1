# 覧覧覧覧覧覧覧覧覧覧覧覧覧覧覧覧�
# DotNetInputBoxV2.ps1
# ed wilson, msft, 10/9/2008
#
# uses the .Net framework interaction class with the inputbox method to
# create an inputbox using the dot net framework classes. the microsoft.visualbasic
# namespace is not loaded by default
#
# 覧覧覧覧覧覧覧覧覧覧覧覧覧覧覧覧�
#Requires -version 2.0

$prompt = 摘nter your command�
$title = �.net example�
$default = 電efault value�

Add-Type  -AssemblyName microsoft.visualbasic

$return = [Microsoft.VisualBasic.interaction]::inputbox($prompt,$title,$default)

$return

