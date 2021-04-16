Set-StrictMode -Version 5.0
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\utils.ps1"
Elevate-Permission $PSCommandPath $Args

function Setup-User {
    Association @{
        ".bb"  = "bb.bat"
        ".clj" = "clj.bat"
        ".ps1" = "powershell.exe"
        ".py"  = "python.exe"
    }

    ContextMenu @{
        "Open with gvim"  = 'gvim "%1"'
        "Run in terminal" = 'cmd /k "%1"'
    }

    EnvironmentVar @{
        "HOME"     = "%UserProfile%\Documents\home"
        "PATHEXT"  = ".EXE;.COM;.CMD;.BAT;.CLJ;.PS1;.PY"
        "WINHOME"  = "%HOME%"
        "WSLENV"   = "WINHOME"
    }

    # EnvironmentPath @(
    #     "C:\data\system\bin"
    #     "C:\data\system\bin\vim"
    #     "C:\software\Oracle\VirtualBox"
    #     "%UserProfile%\dev\go\bin"
    #     "%UserProfile%\dev\jdk\bin"
    # )

    Keymap @{
        0x3A = 0x1D  # Caps   (0x3A) => Ctrl_L (0x1D)
        0x79 = 0x0E  # Henkan (0x79) => BS     (0x0E) 
    }

    # ScoopInstall @(
    #     "7zip"
    #     "git"
    #     "sudo"
    # )
}

function Remove-Preinstalls {
    # http://miyamon-se-exp.hatenablog.jp/entry/2016/11/06/143734
    @(
        "Microsoft.ZuneMusic",    # Groove Music
        "Microsoft.ZuneVideo",    # Movies&TV
        "Microsoft.People",       # People
        "Microsoft.WindowCamera", # Camera
        "Microsoft.GetHelp",      # 問い合わせ
        "Microsoft.YourPhone",    # スマホ同期アプリ
        "Microsoft.WindowsMaps",  # Maps
        "Microsoft.Messaging"     # Messaging
    ) | % { Get-AppxPackage -Name $_ | Remove-AppxPackage }
}

function Setup-Powershell {
    # Change powershell policy
    Set-ExecutionPolicy RemoteSigned

    # Install PowerSehllGallaery
    # Install-Module -Name PowerShellGet -Force

    # Install PSReadLine [https://github.com/PowerShell/PSReadLine]
    Install-Module -Force -Scope CurrentUser PSReadLine
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineKeyHandler -Key Ctrl+v -Function Paste
}

function Overwrite-DefaultConfig {
    reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" @{
        # Show file extensions.
        "HideFileExt" = 0
    }

    reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" @{
        # ゴミ箱/削除の確認メーセージを表示する 
        "ConfirmFileDelete" = 1
    }

    reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" @{
        # Hide People button on taskbar.
        "PeopleBand" = 0
    }

    reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" @{
        # 設定/プライバシー/アクティビティの履歴:このデバイスでのアクティビティの履歴を保存する = false
        "EnableActivityFeed" = 0
    } 

    reg "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" @{
        # Hide OneDrive in explorer.
        "System.IsPinnedToNameSpaceTree" = 0
    }

    reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" @{
        # Hide system desktop icons.
        "{645FF040-5081-101B-9F08-00AA002F954E}" = 1  # ゴミ箱
    }

    reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" @{
        # フォルダーオプション:最近使ったファイルをクイックアクセスに表示する = false
        "ShowRecent" = 0
        # フォルダーオプション:よく使うフォルダーをクイックアクセスに表示する = false
        "ShowFrequent" = 0
    }

    reg "HKLM:\Software\Policies\Microsoft\WindowsStore" @{
        # Store/設定/アプリ更新:アプリを自動的に更新 = false
        "AutoDownload" = 4
    }

    reg "HKCU:\Control Panel\Mouse" @{
        # Mouse config
        "MouseSensitivity" = "8"
        "MouseSpeed" = "0"
        "MouseThreshold1" = "0"
        "MouseThreshold2" = "0"
    }

    reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" @{
        # Disable automatically installing suggested apps.
        "SilentInstalledAppsEnabled" = 0
        # 設定/システム/通知とアクション/通知:Windowsへようこそ = false
        "SubscribedContent-310093Enabled" = 0
        # 設定/システム/通知とアクション/通知:ヒントやおすすめ = false
        "SubscribedContent-338389Enabled" = 0
        # 設定/システム/マルチタスク/タイムライン:タイムラインにおすすめを表示する = false
        "SubscribedContent-353698Enabled" = 0
        # 設定/個人用設定/スタート:ときどきスタートメニューにおすすめのアプリを表示する = false
        "SystemPaneSuggestionsEnabled" = 0
    }

    reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" @{
        # 設定/システム/通知とアクション/通知:アプリやその他の送信者からの通知を取得する = false
        "ToastEnabled" = 0
    }

    reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" @{
        # 設定/個人用設定/スタート:よく使われるアプリを表示する = false
        "Start_TrackProgs" = 0
    }

    # サウンド/サウンド設定:サウンドなし
    # https://answers.microsoft.com/ja-jp/windows/forum/all/windows/32f2aa5d-f0ab-4b64-872a-fcce424b0f8c
    # https://renenyffenegger.ch/notes/Windows/registry/tree/HKEY_CURRENT_USER/AppEvents/Schemes/Apps/index
    Get-ChildItem -Recurse -Path 'HKCU:\AppEvents\Schemes\Apps\*\.Current' | % { $_.Name.Replace('HKEY_CURRENT_USER', 'HKCU:') } | % {
        reg $_ @{
            '(default)' = ''
        }
    }
}

if ($Args.Length -eq 0) {
    Setup-User
} elseif ($Args[0] -eq 'user') {
    Setup-User
} elseif ($Args[0] -eq 'sys') {
    Remove-Preinstalls
    Setup-Powershell
    Overwrite-DefaultConfig
} else {
    'do nothing'
}