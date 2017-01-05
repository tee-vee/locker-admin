@echo off

%COMSPEC% /C %windir%\System32\reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f

:: taskkill /f /im explorer.exe
:: start explorer.exe

