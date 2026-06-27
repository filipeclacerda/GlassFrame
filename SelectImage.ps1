param([int]$ImageNumber = 1)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create an invisible form owner so the dialog displays even with console hidden
$owner = New-Object System.Windows.Forms.Form
$owner.TopMost          = $true
$owner.Opacity          = 0
$owner.ShowInTaskbar    = $false
$owner.Size             = New-Object System.Drawing.Size(1, 1)
$owner.StartPosition    = [System.Windows.Forms.FormStartPosition]::Manual
$owner.Location         = New-Object System.Drawing.Point(-200, -200)
$owner.Show()

$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Title           = "Image $ImageNumber — Choose File"
$dialog.Filter          = "Images|*.png;*.jpg;*.jpeg;*.bmp;*.gif;*.webp|All Files|*.*"
$dialog.InitialDirectory = [Environment]::GetFolderPath("MyPictures")

if ($dialog.ShowDialog($owner) -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedPath = $dialog.FileName
    $configFile   = Join-Path $PSScriptRoot "Variables.inc"

    $lines   = Get-Content $configFile
    $updated = $lines | ForEach-Object {
        if ($_ -match "^Image$ImageNumber=") { "Image$ImageNumber=$selectedPath" }
        else { $_ }
    }
    Set-Content -Path $configFile -Value $updated -Encoding UTF8

    # Tell Rainmeter to refresh the skin using current directory and .ini file
    $skinConfigName = Split-Path -Leaf $PSScriptRoot
    $iniFile = (Get-ChildItem -Path $PSScriptRoot -Filter "*.ini" | Select-Object -First 1).Name
    if (-not $iniFile) { $iniFile = "$skinConfigName.ini" }

    $rmPaths = @(
        "$env:ProgramFiles\Rainmeter\Rainmeter.exe",
        "${env:ProgramFiles(x86)}\Rainmeter\Rainmeter.exe"
    )
    foreach ($rm in $rmPaths) {
        if (Test-Path $rm) {
            Start-Process -FilePath $rm -ArgumentList "!Refresh `"$skinConfigName`" `"$iniFile`""
            break
        }
    }
}

$owner.Dispose()
