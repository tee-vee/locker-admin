REM set gitdir="C:\Users\%username%\AppData\Local\GitHub\PortableGit_8810fd5c2c79c73adcc73fd0825f3b32fdb816e7"
for /f "usebackq" %%m in (`dir /b "C:\Users\%username%\AppData\Local\GitHub\PortableGit_*"`) do (
	set gitdir="C:\Users\%username%\AppData\Local\GitHub\%%m"
)
set path=%gitdir%\cmd;%path%

cd C:\IE-Kiosk
git pull
