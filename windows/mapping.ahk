AppsKey:: RAlt

; vk1D & vkBA:: Send, {|}  ; colon
; vk1D & vkBB:: Send, {(}  ; semicolon
; vk1D & L:: Send, {'}
; vk1D & @:: Send, {&}

vk1D & F10:: Send, {Volume_Mute}
; vk1D & F11:: Send, {Volume_Down}
; vk1D & F12:: Send, {Volume_Up}


vk1D & .:: Send, |>
vk1D & ,:: Send, <|

vk1D & H:: Send, {Blind}{Left}
vk1D & J:: Send, {Blind}{Down}
vk1D & K:: Send, {Blind}{Up}
vk1D & L:: Send, {Blind}{Right}

vk1D & P:: Send, {Blind}{Up}
vk1D & N:: Send, {Blind}{Down}

vk1D & A:: Send, {Blind}{Home}
vk1D & E:: Send, {Blind}{End}

vk1D & M:: Send, {Blind}{Enter}
vk1D & D:: Send, {Blind}{Enter}

vk1D & V:: Send, ^v
vk1D & R:: Send, +{Home}^c
vk1D & U:: Send, +{End}^x

vk1D & W:: Send, {Blind}^{Right}
vk1D & B:: Send, {Blind}^{Left}

vk1D & F::
    SendInput, +{End}
    str := GetSelection()
    SendInput, {Left}
    Input, char, L1T1
    FindChar(str, char, "L")
    Return

vk1D & S::
    SendInput, +{Home}
    str := GetSelection()
    SendInput, {Right}
    Input, char, L1T1
    FindChar(str, char, "R")
    Return

vk1D & vkBB:: FindChar()


vk1D & Q:: Send, !{Space}n
; vk1D & R:: Run, "powershell.exe" /c %A_ScriptDir%\fzfwindow.ps1, , Hide
; vk1D & ^:: Run, DisplaySwitch.exe /internal

vkF2::
    IfWinActive, ahk_exe mintty.exe
        WinMinimize, A
    Else IfWinExist, ahk_exe mintty.exe
        WinActivate, ahk_exe mintty.exe
    Else
        Run, "%LocalAppdata%\wsltty\WSL Terminal.lnk"
    Return

F3::
    ;; https://pouhon.net/ahk-keywait/2848/
    ;; http://ahkwiki.net/SampleCodes
    key := "F3"
    KeyWait, %key%, T0.1
    KeyWait, %key%, D, T0.1
    if (ErrorLevel) {
        ;; short single press
        Run, gvim.exe
    } else {
        ;; double press
        Run, notepad.exe
    }
    KeyWait, %key%
    Return


#IfWinActive ahk_exe mintty.exe ahk_exe Code.exe
    ^c::
        Send, ^c
        IME_SET(0)
        Return
#IfWinActive

#IfWinActive ahk_exe mintty.exe
    !v:: Send, +{Insert}
#IfWinActive

#IfWinActive ahk_exe chrome.exe
    vk1D & E:: Send, {RButton}, k, {RButton}, v
#IfWinActive

#IfWinActive ahk_exe DupFileEliminator.exe
    MButton:: Send, {Enter}
#IfWinActive


IME_SET(setSts, WinTitle="") {
    ifEqual WinTitle , , SetEnv, WinTitle, A
    WinGet , hWnd, ID, %WinTitle%
    DefaultIMEWnd := DllCall("imm32\ImmGetDefaultIMEWnd", Uint, hWnd, Uint)
    DetectSave := A_DetectHiddenWindows
    DetectHiddenWindows , ON
    SendMessage 0x283, 0x006, setSts, , ahk_id %DefaultIMEWnd%
    DetectHiddenWindows, %DetectSave%
    Return ErrorLevel
}

FindChar(str="", char="", direction="") {
    static s_str := ""
    static s_char := ""
    static s_direction := ""

    if (str <> "") {
        s_str := str
    }
    if (char <> "") {
        s_char :=char 
    }
    if (direction <> "") {
        s_direction :=direction 
    }

    StringCaseSense On
    StringGetPos, pos, s_str, %s_char%, %s_direction%, 1
    if (pos > 0) {
        if (s_direction = "L") {
            SendInput, {Right %pos%}
            StringTrimLeft, s_str, s_str, %pos%
        } else {
            pos := StrLen(s_str) - pos
            SendInput, {Left %pos%}
            StringTrimRight, s_str, s_str, %pos%
        }
    }
    Return
}

GetSelection() {
    save := ClipboardAll
    Clipboard =
    Send, ^c
    str := Clipboard
    Clipboard := save
    Return str
}
