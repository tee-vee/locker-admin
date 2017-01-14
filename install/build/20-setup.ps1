# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# INSTALLCFG=%LOCKERINSTALL%\_pkg\jre-install.properties /L %SETUPLOGS%\jre-install.log"

# Disable hibernate
Start-Process 'powercfg.exe' -Verb runAs -ArgumentList '/h off'

New-Item -Path C:\local\src -ItemType directory -Force
& "$Env:ProgramFiles\git\cmd\git.exe" clone -v --progress https://lockerlife-kiosk:Locision123@github.com/tee-vee/locker-admin.git c:\local\src

#schtasks.exe /Create /SC ONLOGON /TN "StartSeleniumNode" /TR "cmd /c ""C:\SeleniumGrid\startnode.bat"""


