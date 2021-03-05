$rg   = "rg --files"
$fzf  = "fzf --reverse"
$dir  = "C:\data\system"
$exts = ("exe", "bat", "lnk", "ps1")

$glob = ""
foreach ($e in $exts) {
    $glob += "--glob *.$e "
}

$importDll = @"
[DllImport("user32.dll")]
public static extern int MoveWindow(IntPtr hwnd, int x, int y, int nWidth, int nHeight, int bRepaint);
[DllImport("user32.dll")]
public static extern int ShowWindow(IntPtr hwnd, int nCmdShow);
"@
$Win32 = & { add-type -memberDefinition $importDll -name "Win32API" -passthru }

$p = start-process "powershell.exe" -Working $dir -Arg "/c $rg $glob | $fzf | % { start `$_ }" -PassThru 
while ($p.MainWindowHandle -eq 0) {}
$Win32::MoveWindow($p.MainWindowHandle, 3, 7, 650, 320, 1)