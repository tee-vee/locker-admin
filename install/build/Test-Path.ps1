$FileCheck = get-content C:\Users\XXXXX\desktop\Bacth1_FileCheck.txt

ForEach ($File in $FileCheck) {if (test-path $File) {"$file exists">>C:\temp\Batch1_exists.log} else {"$file does not exist">>C:\temp\Batch1_doesnotexist.log}}