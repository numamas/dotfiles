vk1D & P:: Send, {Blind}{Up}
vk1D & N:: Send, {Blind}{Down}
vk1D & F:: Send, {Blind}{Right}
vk1D & B:: Send, {Blind}{Left}
vk1D & A:: Send, {Blind}{Home}
vk1D & E:: Send, {Blind}{End}
vk1D & S:: Send, {Blind}{Enter}

vk1D & V:: Send, ^v
vk1D & W:: Send, +{Home}^c
vk1D & L:: Send, +{Home}^x
vk1D & K:: Send, +{End}^x

vk1D & [:: Send, {(}
vk1D & ]:: Send, {)}
vk1D & @:: Send, {'}
vk1D & vkBA:: Send, {&}  ; colon
vk1D & vkBB:: Send, {|}  ; semicolon

;vk1D & ^:: Run, DisplaySwitch.exe /internal
vk1D & ^:: Run, "pwsh.ps1" -h

vk1D & F10:: Send, {Volume_Mute}
vk1D & F11:: Send, {Volume_Down}
vk1D & F12:: Send, {Volume_Up}

vk1D & Q:: Send, !{Space}n
vk1D & R:: Run, "powershell.exe" /c %A_ScriptDir%\fzfer.ps1, , Hide

vk1D & Insert:: Run, "cmd.exe" /c "cd %SYSTEMDRIVE%\data\download & pwsh"

;#IfWinActive ahk_exe Code.exe
;    ^c:: Send, {ESC}
;#IfWinActive

#IfWinActive ahk_exe mintty.exe
    !v:: Send, +{Insert}
#IfWinActive

#IfWinActive ahk_exe chrome.exe
    vk1D & D:: Send, {RButton}, k, {RButton}, v
#IfWinActive
