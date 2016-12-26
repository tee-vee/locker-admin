# Set Public Mode Kiosk kickstart 	#
# Derek Yuen 				#
# December 2016 			#

First, NO GUARANTEES! This is only an attempt to help make the machine more secure. 

In this repo there are 4 files. They are:

    * disallow.reg
    * reallow.reg
    * runonlogon.reg
    * terminate.bat

## disallow.reg ##
You should run this file while logged as Kiosk user before you jail with GPEDIT.msc.
This file adds a DisallowRun key wth 1 value and a key container with the applications disallowed.
The applications disallowed are cmd.exe, explorer.exe and command.exe.
This way the user won't have any desktop, neither a way to try to start it or try to start any application for that matter.

## reallow.reg ##
For rollback of Disallow.reg

## runonlogon.reg ##
This file results in only LockerLife.exe and LockerLife_TV.exe starts for this user and terminates explorer.exe.
explorer.exe starts at log on screen and running terminate.bat will terminate explorer.exe (and the user won't be allowed to run it again).
Terminating explorer.exe must take place at log in screen but before user desktop appears. 
It is important to check the path of where the terminate.bat it's going to be executed.
On this file I specified the path C:\KioskFiles\terminate.bat, if you have (or plan to have) a different path you should change this before importing this keys.

## terminate.bat ##
Finds the pid of explorer.exe using \IM flag and kills it.

## Remember ##
If setting up manually, first configure the user environment.

Remember to change the default "admin" password and to hide any UI (if you want this Kiosk to look like it's running a native app).

