# Registry
function reg([string]$key, [hashtable]$map) {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    New-PSDrive -Name HKCC -PSProvider Registry -Root HKEY_CURRENT_CONFIG | Out-Null
    New-PSDrive -Name HKU  -PSProvider Registry -Root HKEY_USERS | Out-Null

    if (-not (Test-Path -LiteralPath $key)) {
        New-Item -Force $key | Out-Null
        Write-Host "Created $key"
    }

    Write-Host $key
    foreach ($entry in $map.GetEnumerator()) {
        switch ($entry.Value) {
            { $_ -is [string]    } { $type = "String"; $value = $_ }
            { $_ -is [int]       } { $type = "DWord";  $value = $_ }
            { $_ -is [hashtable] } { $type = $_.type;  $value = $_.data }
        }

        New-ItemProperty -Force -LiteralPath $key -name $entry.Key -value $value -PropertyType $type | Out-Null
        Write-Host "    $($entry.Key) = [$type] $value"
    }
    Write-Host ""
}

function reg-hex([string]$data) {
    @{ "type" = "Binary"
       "data" = [byte[]]($data.Split(",") | % { [Convert]::ToInt32($_, 16) }) }
}

function reg-expand([string]$data) {
    @{ "type" = "ExpandString" 
       "data" = $data }
}

function reg-multi([string[]]$data) {
    @{ "type" = "MultiString"
       "data" = $data }
}

function setenv([string]$var, [string]$value, [switch]$system) {
    if ($system) {
        if (-not (admin?)) {
            Write-Host -fore Red "Need to run as administorator."
            throw "NoAuthorityException"
        }
        $target = "Machine"
    } else {
        $target = "User"
    }
    [System.Environment]::SetEnvironmentVariable($var, $value, $target)
}

function add-contextmenu([string]$desc, [string]$command) {
    $first, $params = $command.Split()
    $path = Get-Command $first | % Source
    $cmd  = Split-Path -Leaf $path | & { $input.Split(".")[0] }
    reg "HKCR:\*\shell\$cmd" @{
        "(default)" = $desc
        "Icon"      = $path
    }
    reg "HKCR:\*\shell\$cmd\command" @{
        "(default)" = "$path $params"
    }
}

function associate-extension([string]$ext, [string]$cmd) {
    # https://stackoverrun.com/ja/q/11776374
    # https://mindlesstechnology.wordpress.com/2008/03/29/make-python-scripts-droppable-in-windows/
    $path = Get-Command $cmd | % Source
    $progID = $ext.Trim(".") + "File"
    Write-Host "$ext -> $progID -> $path"
    
    # HKEY_CLASSES_ROOT\<ext>
    cmd /c "assoc $ext=$progID" | Out-Null

    # HKEY_CLASSES_ROOT\<progID>\Shell\Open\Command (its value is registered as REG_EXPAND_SZ)
    cmd /c "ftype $progID=`"$path`" `"%1`" %*" | Out-Null

    # DropHandler
    reg "HKCR:\$progID\shellex\DropHandler" @{
        "(default)" = "{60254CA5-953B-11CF-8C96-00AA00B8708C}"
    }
}

function admin? {
    $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Elevate-Permission([string]$cmd, [string[]]$params) {
    if (-not (admin?)) {
        Start-Process powershell -Verb runas -Arg @("-noexit"; "-command"; $cmd; $Args)
        exit 0
    }
}

function Association([hashtable]$items) {
    foreach ($item in $items.GetEnumerator()) {
        associate-extension "$($item.Key)" "$($item.Value)"
    }
}

function ContextMenu([hashtable]$items) {
    foreach ($item in $items.GetEnumerator()) {
        add-contextmenu "$($item.Key)" "$($item.Value)"
    }
}

function EnvironmentVar([hashtable]$items) {
    foreach ($item in $items.GetEnumerator()) {
        setenv "$($item.Key)" "$($item.Value)"
    }
}

function Keymap([hashtable]$pairs) {
    # https://tepp91.github.io/contents/misc/remap-keyboard-with-scancode-map.html
    $n = ($pairs.Count + 1).ToString("X2")
    $header = "00,00,00,00,00,00,00,00,$n,00,00,00,"
    $term   = "00,00,00,00"
    $map    = ""

    foreach ($entry in $pairs.GetEnumerator()) {
        if (($entry.Key -isnot [int]) -or ($entry.Value -isnot [int])) {
            throw "TypeMismatchExpectedInt"
        }
        $from = $entry.Key.ToString("X2")
        $into = $entry.Value.ToString("X2")
        $map += "$into,00,$from,00,"
    }

    reg "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout" @{
        "Scancode Map" = hex ($header + $map + $term)
    }
}

function ScoopInstall([array]$packages) {
    if (-not (Get-Command 'scoop')) {
        iwr -useb "https://get.scoop.sh" | iex
    }

    foreach ($package in $packages) {
        scoop install $package
    }
}