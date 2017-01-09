// Windows Shell Script: Enable/Disable UAC on Secure Desktop
// Written by Alexander Avdonin - alexander@ntwind.com
// 
// Run the script using the following command line:
//
//   hstart /NOUAC "WScript //nologo "D:\Scripts\uac.js""
//

var WshShell = WScript.CreateObject ("WScript.Shell");

var PromptOnSecureDesktop = WshShell.RegRead("HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System\\PromptOnSecureDesktop");

var BtnCode = -1;
if (PromptOnSecureDesktop == 0) {
	BtnCode = WshShell.Popup("Do you want to enable 'UAC on Secure Desktop' option?", -1, "UAC on Secure Desktop", 4 + 32 + 4096);
	PromptOnSecureDesktop = 1;
} else {
	BtnCode = WshShell.Popup("Do you want to disable 'UAC on Secure Desktop' option?", -1, "UAC on Secure Desktop", 4 + 32 + 4096);
	PromptOnSecureDesktop = 0;
}

switch (BtnCode) {
	case 6:
		WshShell.RegWrite("HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System\\PromptOnSecureDesktop", PromptOnSecureDesktop, "REG_DWORD");
		break;
	case 7:
		break;
	case -1:
		//WScript.Echo("Is there anybody out there?");
		break;
}
