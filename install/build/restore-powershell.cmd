:: Return the security policy to defaults, restricted...
powershell -command "& {Set-ExecutionPolicy -Scope LocalMachine Restricted -Force}"
powershell -command "& {Set-ExecutionPolicy -Scope CurrentUser Undefined -Force}"
powershell -command "& {Set-ExecutionPolicy -Scope Process Undefined -Force}"
