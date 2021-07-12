#Persistent
#SingleInstance

Menu, Tray, NoDefault
Menu, Tray, NoStandard

Menu, Tray, Icon, emacs.exe
Menu, Tray, Add, New Frame, &NewFrame
Menu, Tray, Add, Restart Daemon, &RestartDaemon
Menu, Tray, Add
Menu, Tray, Add, Reload This Script, ReloadScript
Menu, Tray, Add, Edit This Script, EditScript
Menu, Tray, Add, &Close
Gosub &RestartDaemon
Return

&NewFrame:
    Run, emacsclientw.exe -c -n
    Return

&RestartDaemon:
    Run, emacsclient.exe -e "(kill-emacs)", , Hide
    Run, runemacs.exe --daemon
    Return

ReloadScript:
    Reload
    Return

EditScript:
    Edit
    Return

&Close:
    Run, emacsclient.exe -e "(kill-emacs)", , Hide
    ExitApp 0