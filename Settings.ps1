$ErrorActionPreference = 'Stop'
$logFile    = Join-Path $PSScriptRoot 'error.log'
$configFile = Join-Path $PSScriptRoot 'Variables.inc'

# Updates (or adds) a Key=Value in Variables.inc
function Set-ConfigValue {
    param([string]$Key, [string]$Value)
    $lines = @(Get-Content $configFile)
    $found = $false
    $out = foreach ($l in $lines) {
        if ($l -match "^$Key=") { $found = $true; "$Key=$Value" } else { $l }
    }
    if (-not $found) { $out = @($out) + "$Key=$Value" }
    Set-Content -Path $configFile -Value $out -Encoding Default
}

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    if (-not (Test-Path $configFile)) { throw "Variables.inc not found: $configFile" }

    # ── Read current values ────────────────────────────────────────
    $names   = @{ 1=''; 2=''; 3=''; 4='' }
    $accent  = '120,165,255'
    $bgAlpha = 200
    foreach ($line in (Get-Content $configFile)) {
        if ($line -match '^Image(\d)=(.+)$') { $names[[int]$Matches[1]] = $Matches[2].Trim() }
        elseif ($line -match '^Accent=(.+)$') { $accent = $Matches[1].Trim() }
        elseif ($line -match '^BgAlpha=(\d+)') { $bgAlpha = [int]$Matches[1] }
    }
    $ar,$ag,$ab = ($accent -split ',') | ForEach-Object { [int]$_ }

    # ── Form ───────────────────────────────────────────────────────
    $form                 = New-Object System.Windows.Forms.Form
    $form.Text            = 'GlassFrame - Settings'
    $form.ClientSize      = New-Object System.Drawing.Size(440, 400)
    $form.StartPosition   = 'CenterScreen'
    $form.TopMost         = $true
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox     = $false
    $form.BackColor       = [System.Drawing.Color]::FromArgb(22, 22, 32)
    $form.ForeColor       = [System.Drawing.Color]::FromArgb(215, 215, 228)
    $form.Font            = New-Object System.Drawing.Font('Segoe UI', 9)

    # Images
    for ($i = 1; $i -le 4; $i++) {
        $y = 12 + ($i - 1) * 44

        $lbl          = New-Object System.Windows.Forms.Label
        $lbl.Text     = "Image $i"
        $lbl.Location = New-Object System.Drawing.Point(16, ($y + 6))
        $lbl.Size     = New-Object System.Drawing.Size(70, 22)
        $form.Controls.Add($lbl)

        $disp = if ($names[$i]) { [System.IO.Path]::GetFileName($names[$i]) } else { '(choose)' }

        $btn           = New-Object System.Windows.Forms.Button
        $btn.Text      = $disp
        $btn.Location  = New-Object System.Drawing.Point(92, $y)
        $btn.Size      = New-Object System.Drawing.Size(332, 32)
        $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btn.BackColor = [System.Drawing.Color]::FromArgb(38, 38, 56)
        $btn.ForeColor = [System.Drawing.Color]::FromArgb(205, 205, 222)
        $btn.TextAlign = 'MiddleLeft'
        $btn.Tag       = $i
        $btn.Add_Click({
            try {
                $s = $this.Tag
                $pk = New-Object System.Windows.Forms.OpenFileDialog
                $pk.Title  = "Image $s"
                $pk.Filter = 'Images|*.png;*.jpg;*.jpeg;*.bmp;*.gif;*.webp|All Files|*.*'
                $pk.InitialDirectory = [Environment]::GetFolderPath('MyPictures')
                if ($pk.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                    Set-ConfigValue "Image$s" $pk.FileName
                    $this.Text = [System.IO.Path]::GetFileName($pk.FileName)
                }
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)")
            }
        })
        $form.Controls.Add($btn)
    }

    # ── Background color ─────────────────────────────────────────────
    $lblC          = New-Object System.Windows.Forms.Label
    $lblC.Text     = 'Background color'
    $lblC.Location = New-Object System.Drawing.Point(16, 206)
    $lblC.Size     = New-Object System.Drawing.Size(120, 24)
    $form.Controls.Add($lblC)

    $colorBtn           = New-Object System.Windows.Forms.Button
    $colorBtn.Location  = New-Object System.Drawing.Point(142, 200)
    $colorBtn.Size      = New-Object System.Drawing.Size(282, 32)
    $colorBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $colorBtn.Text      = ''
    $colorBtn.BackColor = [System.Drawing.Color]::FromArgb($ar, $ag, $ab)
    $form.Controls.Add($colorBtn)
    $colorBtn.Add_Click({
        try {
            $cd = New-Object System.Windows.Forms.ColorDialog
            $cd.Color     = $colorBtn.BackColor
            $cd.FullOpen  = $true
            if ($cd.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                $c = $cd.Color
                $colorBtn.BackColor = $c
                Set-ConfigValue 'Accent' ("{0},{1},{2}" -f $c.R, $c.G, $c.B)
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)")
        }
    })

    # ── Background opacity ───────────────────────────────────────────
    $lblT          = New-Object System.Windows.Forms.Label
    $lblT.Text     = 'Background opacity'
    $lblT.Location = New-Object System.Drawing.Point(16, 248)
    $lblT.Size     = New-Object System.Drawing.Size(180, 22)
    $form.Controls.Add($lblT)

    $valT          = New-Object System.Windows.Forms.Label
    $valT.Location = New-Object System.Drawing.Point(360, 248)
    $valT.Size     = New-Object System.Drawing.Size(64, 22)
    $valT.TextAlign = 'MiddleRight'
    $form.Controls.Add($valT)

    $track            = New-Object System.Windows.Forms.TrackBar
    $track.Minimum    = 20
    $track.Maximum    = 255
    $track.TickStyle  = 'None'
    $track.Value      = [Math]::Max(20, [Math]::Min(255, $bgAlpha))
    $track.Location   = New-Object System.Drawing.Point(14, 274)
    $track.Size       = New-Object System.Drawing.Size(410, 40)
    $form.Controls.Add($track)
    $pct = [int]([Math]::Round($track.Value / 255 * 100))
    $valT.Text = "$pct%"
    $track.Add_Scroll({
        $p = [int]([Math]::Round($track.Value / 255 * 100))
        $valT.Text = "$p%"
        Set-ConfigValue 'BgAlpha' $track.Value
    })

    # ── Apply and Close Buttons ──────────────────────────────────────
    $apply           = New-Object System.Windows.Forms.Button
    $apply.Text      = 'Apply'
    $apply.Location  = New-Object System.Drawing.Point(92, 340)
    $apply.Size      = New-Object System.Drawing.Size(160, 40)
    $apply.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $apply.BackColor = [System.Drawing.Color]::FromArgb(30, 85, 55)
    $apply.ForeColor = [System.Drawing.Color]::White
    $apply.Font      = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $apply.Add_Click({
        try {
            # Ensure color/transparency values are saved
            Set-ConfigValue 'Accent' ("{0},{1},{2}" -f $colorBtn.BackColor.R, $colorBtn.BackColor.G, $colorBtn.BackColor.B)
            Set-ConfigValue 'BgAlpha' $track.Value

            $skinConfigName = Split-Path -Leaf $PSScriptRoot
            $iniFile = (Get-ChildItem -Path $PSScriptRoot -Filter "*.ini" | Select-Object -First 1).Name
            if (-not $iniFile) { $iniFile = "$skinConfigName.ini" }

            $rmPaths = @(
                (Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'),
                (Join-Path ${env:ProgramFiles(x86)} 'Rainmeter\Rainmeter.exe')
            )
            foreach ($rm in $rmPaths) {
                if (Test-Path $rm) {
                    Start-Process -FilePath $rm -ArgumentList "!Refresh `"$skinConfigName`" `"$iniFile`""
                    break
                }
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error applying settings: $($_.Exception.Message)")
        }
    })
    $form.Controls.Add($apply)

    $close           = New-Object System.Windows.Forms.Button
    $close.Text      = 'Close'
    $close.Location  = New-Object System.Drawing.Point(264, 340)
    $close.Size      = New-Object System.Drawing.Size(160, 40)
    $close.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $close.BackColor = [System.Drawing.Color]::FromArgb(58, 58, 76)
    $close.ForeColor = [System.Drawing.Color]::White
    $close.Font      = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $close.Add_Click({
        $form.Close()
    })
    $form.Controls.Add($close)

    [void]$form.ShowDialog()
}
catch {
    $msg = "GlassFrame - error:`n$($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    try { Set-Content -Path $logFile -Value $msg -Encoding Default } catch {}
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($msg, 'GlassFrame')
    } catch { Write-Host $msg; Start-Sleep -Seconds 20 }
}
