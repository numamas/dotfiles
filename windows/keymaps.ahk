;; vim: foldmethod=marker foldmarker={,} :
SendMode, Input

;; Alt {
LAlt & Q:: Send, #1
LAlt & W:: Send, #2
LAlt & E:: Send, #3
LAlt & R:: Send, #4
LAlt & T:: Reload
LAlt & vkBB:: Send, 【】

LAlt & G::
    Send, +{Insert}
    Send, {Space}
    Send, (before-highres-fix)
    Return

LAlt & Z::
    Send, {F2}
    Send, ^c
    Send, +{Tab}
    Send, +{Insert}{Space}(before-highres-fix)
    Send, {Enter}
    Send, {Down}{Down}{Down}
    Return

;; diacritical marks
LAlt & S:: if_shift("ẞ", "ß")
LAlt & A:: if_shift("Ä", "ä")
LAlt & Y:: if_shift("É", "é")
LAlt & O:: if_shift("Ö", "ö")
LAlt & U:: if_shift("Ü", "ü")

;; do nothing when tapping Alt 
Alt:: Send, {vkFF}
;; }

;; Muhenkan {
vk1D & Q::    Send, !{Up}
vk1D & W::    Send, {Blind}{Left}
vk1D & E::    Send, {Blind}{End}
vk1D & R::    Send, {Blind}{$}
vk1D & T::    Send, {Blind}{`%}
vk1D & Y::    Send, {Blind}{`&}
vk1D & U::    Send, {Blind}{|}
vk1D & I::    Send, {Blind}{(}
vk1D & O::    Send, {Blind}{)}
vk1D & P::    Send, {Blind}{Up}
vk1D & @::    Send, {Blind}{-}
vk1D & -::    Send, {Blind}{@}
vk1D & A::    Send, {Blind}{Home}
vk1D & S::    Send, {Blind}{Enter}
vk1D & D::    Send, {Blind}{Delete}
vk1D & F::    Send, {Blind}{Right}
vk1D & G::    Send, {Blind}{Esc}
vk1D & H::    Send, {Blind}{BS}
vk1D & J::    Send, {Blind}{Enter}
vk1D & K::    Send, {Blind}{'}
vk1D & L::    Send, {Blind}{"}
vk1D & vkBB:: Send, {Blind}{{}      ;; (semicolon)
vk1D & vkBA:: Send, {Blind}{}}      ;; (colon)
vk1D & Z::    Send, !{Left}
vk1D & X::    Send, !{Right}
vk1D & C::    Send, {Blind}{F2}
vk1D & V::    Send, +{Insert}
vk1D & B::    Send, {Blind}{F1}
vk1D & N::    Send, {Blind}{Down}
vk1D & M::    Send, {Blind}{#}
vk1D & ,::    Send, {Blind}{[}
vk1D & .::    Send, {Blind}{]}
vk1D & /::    Send, {Blind}{!}
vk1D & vkE2:: Send, {Blind}{^}      ;; (backslash: INT1)
vk1D & Tab::  Send, +#{Left}        ;; move a window to right screen
vk1D & Down:: Send, #^{Left}        ;; change to previous workspace
vk1D & Up::   Send, #^{Right}       ;; change to next workspace
;; }

#If WinActive("ahk_exe chrome.exe")
    XButton1:: Send, ^{PgDn}
    XButton2:: Send, ^{PgUp}
#If WinActive("ahk_exe explorer.exe") || WinActive("ahk_exe TE64.exe") || WinActive("ahk_exe ZipPla.exe")
    XButton1:: Send, +{LButton}
    XButton2:: Send, ^{LButton}
#If WinActive("ahk_exe mintty.exe") || WinActive("ahk_exe ttermpro.exe") || WinActive("ahk_exe nvy.exe")
    ~Esc:: IME_SET(0)
    ~^g::  IME_SET(0)
    ^BS::  Send, {Blind}^w
    ^Del:: Send, !d
    vk1D & H:: if_ctrl("^w", "{BS}")
    vk1D & D:: if_ctrl("!d", "{Delete}")
#If WinActive("ahk_exe ZipPla.exe")
     ^r:: Send, {F5}                   ;; Reload
     F2:: Send, {AppsKey}{End}{Enter}  ;; Open Property to change filename
#If

if_ctrl(true_kc, false_kc) {
    keycode := ""
    if (GetKeyState("Ctrl")) {
        keycode := true_kc
    } else {
        keycode := false_kc
    }
    if (InStr(keycode, "^")) {
        Send, {Blind}%keycode%
    } else {
        Send, %keycode%
    }
}

if_shift(true_kc, false_kc) {
    if GetKeyState("Shift", "P") {
        Send, %true_kc%
    } else {
        Send, %false_kc%
    }
}

;; -------------------------------------------

;; SendWithImeOff(s) {
;; }

;; Hotstrings {{{
::@0::192.168.0
::@1::192.168.1
::@2::192.168.2
::@9::99.99.99
;; }}}


;; LAlt & Z:: Send, +{Home}^c  ;; copy texts before cursor
LAlt & X:: Send, +{End}^x   ;; cut texts after cursor
LAlt & B:: insert_date()

;; IME lib {{{
;; https://w.atwiki.jp/eamat/pages/17.html

;-----------------------------------------------------------
; IMEの状態の取得
;   WinTitle="A"    対象Window
;   戻り値          1:ON / 0:OFF
;-----------------------------------------------------------
IME_GET(WinTitle="A")  {
	ControlGet,hwnd,HWND,,,%WinTitle%
	if	(WinActive(WinTitle))	{
		ptrSize := !A_PtrSize ? 4 : A_PtrSize
	    VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
	    NumPut(cbSize, stGTI,  0, "UInt")   ;	DWORD   cbSize;
		hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
	             ? NumGet(stGTI,8+PtrSize,"UInt") : hwnd
	}

    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwnd)
          , UInt, 0x0283  ;Message : WM_IME_CONTROL
          ,  Int, 0x0005  ;wParam  : IMC_GETOPENSTATUS
          ,  Int, 0)      ;lParam  : 0
}

;-----------------------------------------------------------
; IMEの状態をセット
;   SetSts          1:ON / 0:OFF
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;-----------------------------------------------------------
IME_SET(SetSts, WinTitle="A")    {
	ControlGet,hwnd,HWND,,,%WinTitle%
	if	(WinActive(WinTitle))	{
		ptrSize := !A_PtrSize ? 4 : A_PtrSize
	    VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
	    NumPut(cbSize, stGTI,  0, "UInt")   ;	DWORD   cbSize;
		hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
	             ? NumGet(stGTI,8+PtrSize,"UInt") : hwnd
	}

    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwnd)
          , UInt, 0x0283  ;Message : WM_IME_CONTROL
          ,  Int, 0x006   ;wParam  : IMC_SETOPENSTATUS
          ,  Int, SetSts) ;lParam  : 0 or 1
}

;==========================================================================
;  IME 文字入力の状態を返す
;  (パクリ元 : http://sites.google.com/site/agkh6mze/scripts#TOC-IME- )
;    標準対応IME : ATOK系 / MS-IME2002 2007 / WXG / SKKIME
;    その他のIMEは 入力窓/変換窓を追加指定することで対応可能
;
;       WinTitle="A"   対象Window
;       ConvCls=""     入力窓のクラス名 (正規表現表記)
;       CandCls=""     候補窓のクラス名 (正規表現表記)
;       戻り値      1 : 文字入力中 or 変換中
;                   2 : 変換候補窓が出ている
;                   0 : その他の状態
;
;   ※ MS-Office系で 入力窓のクラス名 を正しく取得するにはIMEのシームレス表示を
;      OFFにする必要がある
;      オプション-編集と日本語入力-編集中の文字列を文書に挿入モードで入力する
;      のチェックを外す
;==========================================================================
IME_GetConverting(WinTitle="A",ConvCls="",CandCls="") {

    ;IME毎の 入力窓/候補窓Class一覧 ("|" 区切りで適当に足してけばOK)
    ConvCls .= (ConvCls ? "|" : "")                 ;--- 入力窓 ---
            .  "ATOK\d+CompStr"                     ; ATOK系
            .  "|imejpstcnv\d+"                     ; MS-IME系
            .  "|WXGIMEConv"                        ; WXG
            .  "|SKKIME\d+\.*\d+UCompStr"           ; SKKIME Unicode
            .  "|MSCTFIME Composition"              ; Google日本語入力

    CandCls .= (CandCls ? "|" : "")                 ;--- 候補窓 ---
            .  "ATOK\d+Cand"                        ; ATOK系
            .  "|imejpstCandList\d+|imejpstcand\d+" ; MS-IME 2002(8.1)XP付属
            .  "|mscandui\d+\.candidate"            ; MS Office IME-2007
            .  "|WXGIMECand"                        ; WXG
            .  "|SKKIME\d+\.*\d+UCand"              ; SKKIME Unicode
   CandGCls := "GoogleJapaneseInputCandidateWindow" ;Google日本語入力

	ControlGet,hwnd,HWND,,,%WinTitle%
	if	(WinActive(WinTitle))	{
		ptrSize := !A_PtrSize ? 4 : A_PtrSize
	    VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
	    NumPut(cbSize, stGTI,  0, "UInt")   ;	DWORD   cbSize;
		hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
	             ? NumGet(stGTI,8+PtrSize,"UInt") : hwnd
	}

    WinGet, pid, PID,% "ahk_id " hwnd
    tmm:=A_TitleMatchMode
    SetTitleMatchMode, RegEx
    ret := WinExist("ahk_class " . CandCls . " ahk_pid " pid) ? 2
        :  WinExist("ahk_class " . CandGCls                 ) ? 2
        :  WinExist("ahk_class " . ConvCls . " ahk_pid " pid) ? 1
        :  0
    SetTitleMatchMode, %tmm%
    return ret
}
;; }}}


;; Paste plain text
^+Insert::
    clipboard := clipboard
    Send, +{Insert}
    Return


insert_date() {
    FormatTime, s, , yyyy-MM-dd
    Send, %s%
}

win_minimize_window() {
    Send, !{Space}n
}

win_maximize_window() {
    Send, !{Space}x
}

show_or_run(exe, exepath="") {
    if (exepath = "") {
        exepath := exe
    }
    IfWinExist, ahk_exe %exe%
        WinActivate, ahk_exe %exe%
    Else
        Run, %exepath%
    Return
}

;; ----------------------------------------------------

open_in_explorer(path) {
    opts := "/select," . path
    Run, "explorer.exe" %opts%
}

refine_path(s) {
    ;; double-quotes
    ;; winpath
    ;; file uri
}

is_winpath(s) {
    if RegExMatch(s, "[A-Z]:\\") == 1 || RegExMatch(s, "\\") == 1 {
        return true
    } else {
        return false
    }
}

is_file_uri(s) {
    if InStr(s, "file://") == 1 {
        return true
    } else {
        return false
    }
}

;; is_http(s) {
;;     if InStr(s, "http://") == 1 || InStr(s, "https://") == 1 {
;;         return true
;;     } else {
;;         return false
;;     }
;; }

;; Layer 2: Tab {{{
;; Tab::
;;     if (TabDown = true) {
;;         Return    
;;     }
;;     TabDownBegin := A_TickCount
;;     TabDown := true
;;     Input, TabDownKey, L1 V
;;     Return
;; 
;; Tab Up::
;;     Input ;; terminate running Input commnad
;;     if (TabDown = false) {
;;         TabDownKey := ""
;;         Return
;;     }
;;     if ((A_TickCount - TabDownBegin < 200) && (TabDownKey = "")) {
;;         SendInput, {Tab}
;;     }
;;     TabDown := false
;;     Return

#If (TabDown == true)
    H::     Send, {BS}
    BS::    Send, {0}
    M::     Send, {1}
    ,::     Send, {2}
    .::     Send, {3}
    J::     Send, {4}
    K::     Send, {5}
    L::     Send, {6}
    U::     Send, {7}
    I::     Send, {8}
    O::     Send, {9}
    /::     Send, {+}
    vkBB::  Send, {*} ;; semicolon
    P::     Send, {`%}
    @::     Send, {Esc}
    vkBA::  Send, {/} ;; colon
    vkE2::  Send, {-} ;; backslash
    Right:: Send, {=}

    Q::    Send, !{Up}
    W::    Send, !{Left}
    E::    Send, !{Right}
    R::    Send, {F2}
    S::    Send, !{Enter}

    T::    Send, {RButton}, k, {RButton}, v  ;; chrome right click menu
#If
;; }}}

;; show and hide mintty
;; vkF2::
;;     IfWinActive, ahk_exe mintty.exe
;;         WinMinimize, A
;;     Else IfWinExist, ahk_exe mintty.exe
;;         WinActivate, ahk_exe mintty.exe
;;     Else
;;         Run, "%LocalAppdata%\wsltty\WSL Terminal.lnk"
;;     Return

