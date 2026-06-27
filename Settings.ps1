$ErrorActionPreference = 'Stop'
$rootPath = if ($env:GLASSFRAME_ROOT) { $env:GLASSFRAME_ROOT } else { $PSScriptRoot }
$configFile = Join-Path $rootPath 'Variables.inc'
$catalogFile = Join-Path $rootPath 'ImageCatalog.txt'
$indexerFile = Join-Path $rootPath 'IndexImages.ps1'
$logFile = Join-Path $rootPath 'error.log'

function Read-Config {
    $result = [ordered]@{}
    foreach ($line in [System.IO.File]::ReadAllLines($configFile)) {
        if ($line -match '^\s*([^;#][^=]*)=(.*)$') {
            $result[$Matches[1].Trim()] = $Matches[2]
        }
    }
    return $result
}

function Write-Config {
    param([System.Collections.IDictionary]$Values)
    $lines = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    foreach ($line in [System.IO.File]::ReadAllLines($configFile)) {
        if ($line -match '^\s*([^;#][^=]*)=(.*)$') {
            $key = $Matches[1].Trim()
            if ($Values.Contains($key)) {
                $lines.Add("$key=$($Values[$key])")
                $seen[$key] = $true
                continue
            }
        }
        $lines.Add($line)
    }
    foreach ($key in $Values.Keys) {
        if (-not $seen.ContainsKey($key)) { $lines.Add("$key=$($Values[$key])") }
    }
    $temp = "$configFile.tmp"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($temp, $lines, $utf8NoBom)
    Move-Item -LiteralPath $temp -Destination $configFile -Force
}

function Detect-Language {
    $culture = [System.Globalization.CultureInfo]::CurrentUICulture.Name
    if ($culture -match '^pt(?:-|$)') { return 'pt' }
    return 'en'
}

$text = @{
    pt = @{
        Title='GlassFrame — Configurações'; Source='Fonte'; Folder='Pasta / slideshow'
        Manual='Quatro imagens manuais'; ChooseFolder='Escolher pasta…'; Refresh='Atualizar catálogo'
        Found='{0} imagens encontradas'; Image='Imagem {0}'; Choose='Escolher…'
        Slideshow='Slideshow'; Interval='Intervalo (segundos)'; Order='Ordem'
        Random='Aleatória sem repetir'; Sequential='Por nome'; Layout='Layout inicial'
        Appearance='Aparência'; Color='Cor da moldura'; Opacity='Opacidade'
        Language='Idioma'; Portuguese='Português'; English='English'
        Defaults='Restaurar padrões'; Apply='Aplicar e fechar'; Cancel='Cancelar'
        FolderMissing='Escolha uma pasta válida para o slideshow.'
        NoImages='A pasta não contém imagens compatíveis.'
        Applied='Configurações aplicadas.'; Error='Erro'
        PickImage='Escolha a imagem {0}'; PickFolder='Escolha a pasta de fotos'
    }
    en = @{
        Title='GlassFrame — Settings'; Source='Source'; Folder='Folder / slideshow'
        Manual='Four manual images'; ChooseFolder='Choose folder…'; Refresh='Refresh catalog'
        Found='{0} images found'; Image='Image {0}'; Choose='Choose…'
        Slideshow='Slideshow'; Interval='Interval (seconds)'; Order='Order'
        Random='Random without repeats'; Sequential='By name'; Layout='Initial layout'
        Appearance='Appearance'; Color='Frame color'; Opacity='Opacity'
        Language='Language'; Portuguese='Português'; English='English'
        Defaults='Restore defaults'; Apply='Apply and close'; Cancel='Cancel'
        FolderMissing='Choose a valid folder for the slideshow.'
        NoImages='The folder contains no supported images.'
        Applied='Settings applied.'; Error='Error'
        PickImage='Choose image {0}'; PickFolder='Choose the photo folder'
    }
}

function Show-Settings {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    if (-not (Test-Path -LiteralPath $configFile)) { throw "Variables.inc not found." }
    $config = Read-Config
    $initialLanguage = if ($config.Language -in @('pt','en')) { $config.Language } else { Detect-Language }
    $script:T = $text[$initialLanguage]

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $script:T.Title
    $form.ClientSize = New-Object System.Drawing.Size(600, 680)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(22,23,31)
    $form.ForeColor = [System.Drawing.Color]::FromArgb(230,231,239)
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

    function New-Group([string]$title, [int]$y, [int]$height) {
        $group = New-Object System.Windows.Forms.GroupBox
        $group.Text = $title; $group.Location = New-Object System.Drawing.Point(16,$y)
        $group.Size = New-Object System.Drawing.Size(568,$height)
        $group.ForeColor = $form.ForeColor
        $form.Controls.Add($group)
        return $group
    }
    function New-DarkButton([string]$caption, [int]$x, [int]$y, [int]$w, [int]$h) {
        $button = New-Object System.Windows.Forms.Button
        $button.Text=$caption; $button.Location=New-Object System.Drawing.Point($x,$y)
        $button.Size=New-Object System.Drawing.Size($w,$h)
        $button.FlatStyle='Flat'; $button.BackColor=[System.Drawing.Color]::FromArgb(43,45,59)
        $button.ForeColor=$form.ForeColor
        return $button
    }

    $sourceGroup = New-Group $script:T.Source 12 282
    $folderRadio = New-Object System.Windows.Forms.RadioButton
    $folderRadio.Text=$script:T.Folder; $folderRadio.Location=New-Object System.Drawing.Point(14,24)
    $folderRadio.Size=New-Object System.Drawing.Size(200,24)
    $manualRadio = New-Object System.Windows.Forms.RadioButton
    $manualRadio.Text=$script:T.Manual; $manualRadio.Location=New-Object System.Drawing.Point(270,24)
    $manualRadio.Size=New-Object System.Drawing.Size(240,24)
    $sourceGroup.Controls.AddRange(@($folderRadio,$manualRadio))

    $folderBox = New-Object System.Windows.Forms.TextBox
    $folderBox.Location=New-Object System.Drawing.Point(14,54); $folderBox.Size=New-Object System.Drawing.Size(390,25)
    $folderBox.Text=[string]$config.FolderPath
    $folderButton = New-DarkButton $script:T.ChooseFolder 414 51 138 30
    $refreshButton = New-DarkButton $script:T.Refresh 414 87 138 30
    $countLabel = New-Object System.Windows.Forms.Label
    $countLabel.Location=New-Object System.Drawing.Point(14,91); $countLabel.Size=New-Object System.Drawing.Size(380,22)
    $countLabel.Text=($script:T.Found -f 0)
    $sourceGroup.Controls.AddRange(@($folderBox,$folderButton,$refreshButton,$countLabel))

    $imageButtons = @()
    $imageValues = @('', '', '', '')
    for ($i=0; $i -lt 4; $i++) {
        $imageValues[$i] = [string]$config["Image$($i+1)"]
        $label = New-Object System.Windows.Forms.Label
        $label.Text=($script:T.Image -f ($i+1)); $label.Location=New-Object System.Drawing.Point(14,(128+$i*34))
        $label.Size=New-Object System.Drawing.Size(75,24)
        $button = New-DarkButton '' 94 (123+$i*34) 458 29
        $button.Text = if ($imageValues[$i]) { [IO.Path]::GetFileName($imageValues[$i]) } else { $script:T.Choose }
        $button.Tag=$i
        $button.Add_Click({
            $dialog=New-Object System.Windows.Forms.OpenFileDialog
            $dialog.Title=$script:T.PickImage -f ([int]$this.Tag+1)
            $dialog.Filter='Images|*.png;*.jpg;*.jpeg;*.bmp;*.gif;*.webp'
            if ($dialog.ShowDialog($form) -eq 'OK') {
                $imageValues[[int]$this.Tag]=$dialog.FileName
                $this.Text=[IO.Path]::GetFileName($dialog.FileName)
            }
            $dialog.Dispose()
        })
        $imageButtons += $button
        $sourceGroup.Controls.AddRange(@($label,$button))
    }

    $slideGroup = New-Group $script:T.Slideshow 304 82
    $intervalLabel=New-Object System.Windows.Forms.Label
    $intervalLabel.Text=$script:T.Interval; $intervalLabel.Location=New-Object System.Drawing.Point(14,30)
    $intervalLabel.Size=New-Object System.Drawing.Size(145,22)
    $intervalBox=New-Object System.Windows.Forms.NumericUpDown
    $intervalBox.Minimum=5; $intervalBox.Maximum=86400
    $intervalBox.Value=[Math]::Max(5,[Math]::Min(86400,[int]$config.SlideInterval))
    $intervalBox.Location=New-Object System.Drawing.Point(164,27); $intervalBox.Size=New-Object System.Drawing.Size(85,25)
    $orderLabel=New-Object System.Windows.Forms.Label
    $orderLabel.Text=$script:T.Order; $orderLabel.Location=New-Object System.Drawing.Point(280,30)
    $orderLabel.Size=New-Object System.Drawing.Size(55,22)
    $orderCombo=New-Object System.Windows.Forms.ComboBox
    $orderCombo.DropDownStyle='DropDownList'; $orderCombo.Location=New-Object System.Drawing.Point(340,27)
    $orderCombo.Size=New-Object System.Drawing.Size(212,25)
    [void]$orderCombo.Items.AddRange(@($script:T.Random,$script:T.Sequential))
    $orderCombo.SelectedIndex=if ($config.PlayOrder -eq 'Sequential') {1}else{0}
    $slideGroup.Controls.AddRange(@($intervalLabel,$intervalBox,$orderLabel,$orderCombo))

    $lookGroup = New-Group $script:T.Appearance 396 126
    $layoutLabel=New-Object System.Windows.Forms.Label
    $layoutLabel.Text=$script:T.Layout; $layoutLabel.Location=New-Object System.Drawing.Point(14,29)
    $layoutLabel.Size=New-Object System.Drawing.Size(130,22)
    $layoutCombo=New-Object System.Windows.Forms.ComboBox
    $layoutCombo.DropDownStyle='DropDownList'; $layoutCombo.Location=New-Object System.Drawing.Point(150,26)
    $layoutCombo.Size=New-Object System.Drawing.Size(80,25)
    [void]$layoutCombo.Items.AddRange(@('1','2','3','4','5'))
    $layoutCombo.SelectedIndex=[Math]::Max(0,[Math]::Min(4,[int]$config.Mode-1))
    $colorLabel=New-Object System.Windows.Forms.Label
    $colorLabel.Text=$script:T.Color; $colorLabel.Location=New-Object System.Drawing.Point(270,29)
    $colorLabel.Size=New-Object System.Drawing.Size(110,22)
    $rgb=@($config.Accent -split ',') | ForEach-Object {[int]$_}
    if ($rgb.Count -ne 3) {$rgb=@(24,26,36)}
    $colorButton=New-DarkButton '' 390 23 162 31
    $colorButton.BackColor=[Drawing.Color]::FromArgb($rgb[0],$rgb[1],$rgb[2])
    $opacityLabel=New-Object System.Windows.Forms.Label
    $opacityLabel.Text=$script:T.Opacity; $opacityLabel.Location=New-Object System.Drawing.Point(14,77)
    $opacityLabel.Size=New-Object System.Drawing.Size(130,22)
    $opacityTrack=New-Object System.Windows.Forms.TrackBar
    $opacityTrack.Minimum=20; $opacityTrack.Maximum=255; $opacityTrack.TickStyle='None'
    $opacityTrack.Value=[Math]::Max(20,[Math]::Min(255,[int]$config.BgAlpha))
    $opacityTrack.Location=New-Object System.Drawing.Point(150,69); $opacityTrack.Size=New-Object System.Drawing.Size(402,40)
    $lookGroup.Controls.AddRange(@($layoutLabel,$layoutCombo,$colorLabel,$colorButton,$opacityLabel,$opacityTrack))

    $languageGroup = New-Group $script:T.Language 532 68
    $languageCombo=New-Object System.Windows.Forms.ComboBox
    $languageCombo.DropDownStyle='DropDownList'; $languageCombo.Location=New-Object System.Drawing.Point(14,27)
    $languageCombo.Size=New-Object System.Drawing.Size(230,25)
    [void]$languageCombo.Items.AddRange(@($script:T.Portuguese,$script:T.English))
    $languageCombo.SelectedIndex=if ($initialLanguage -eq 'pt'){0}else{1}
    $languageGroup.Controls.Add($languageCombo)

    $defaults=New-DarkButton $script:T.Defaults 16 620 170 42
    $apply=New-DarkButton $script:T.Apply 264 620 182 42
    $apply.BackColor=[Drawing.Color]::FromArgb(38,104,72)
    $cancel=New-DarkButton $script:T.Cancel 454 620 130 42
    $form.Controls.AddRange(@($defaults,$apply,$cancel))

    $folderRadio.Checked=$config.SourceMode -ne 'Manual'
    $manualRadio.Checked=-not $folderRadio.Checked

    $folderButton.Add_Click({
        $dialog=New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description=$script:T.PickFolder
        if ($dialog.ShowDialog($form) -eq 'OK') {$folderBox.Text=$dialog.SelectedPath}
        $dialog.Dispose()
    })
    $refreshButton.Add_Click({
        if (Test-Path -LiteralPath $folderBox.Text -PathType Container) {
            $count=@(Get-ChildItem -LiteralPath $folderBox.Text -File | Where-Object {$_.Extension -match '^\.(png|jpe?g|bmp|gif|webp)$'}).Count
            $countLabel.Text=$script:T.Found -f $count
        } else {$countLabel.Text=$script:T.Found -f 0}
    })
    $colorButton.Add_Click({
        $dialog=New-Object System.Windows.Forms.ColorDialog
        $dialog.Color=$colorButton.BackColor; $dialog.FullOpen=$true
        if ($dialog.ShowDialog($form) -eq 'OK') {$colorButton.BackColor=$dialog.Color}
        $dialog.Dispose()
    })
    $defaults.Add_Click({
        $folderRadio.Checked=$true; $folderBox.Text=''; $intervalBox.Value=30
        $orderCombo.SelectedIndex=0; $layoutCombo.SelectedIndex=0; $opacityTrack.Value=210
        $colorButton.BackColor=[Drawing.Color]::FromArgb(24,26,36)
        for($i=0;$i -lt 4;$i++){$imageValues[$i]='';$imageButtons[$i].Text=$script:T.Choose}
    })
    $cancel.Add_Click({$form.DialogResult='Cancel';$form.Close()})
    $apply.Add_Click({
        try {
            if ($folderRadio.Checked) {
                if (-not (Test-Path -LiteralPath $folderBox.Text -PathType Container)) {
                    [void][Windows.Forms.MessageBox]::Show($script:T.FolderMissing,$script:T.Error,'OK','Warning'); return
                }
                $count=[int](& $indexerFile -FolderPath $folderBox.Text -CatalogPath $catalogFile)
                if ($count -eq 0) {
                    $answer=[Windows.Forms.MessageBox]::Show($script:T.NoImages,$script:T.Error,'OKCancel','Warning')
                    if ($answer -ne 'OK') {return}
                }
            }
            $values=[ordered]@{
                SourceMode=if($folderRadio.Checked){'Folder'}else{'Manual'}
                FolderPath=$folderBox.Text
                Image1=$imageValues[0]; Image2=$imageValues[1]; Image3=$imageValues[2]; Image4=$imageValues[3]
                SlideInterval=[int]$intervalBox.Value
                PlayOrder=if($orderCombo.SelectedIndex -eq 1){'Sequential'}else{'Random'}
                Paused='0'; Language=if($languageCombo.SelectedIndex -eq 0){'pt'}else{'en'}
                Mode=$layoutCombo.SelectedIndex+1; Scale=if($config.Scale){$config.Scale}else{'1.0'}
                Accent=('{0},{1},{2}' -f $colorButton.BackColor.R,$colorButton.BackColor.G,$colorButton.BackColor.B)
                BgAlpha=$opacityTrack.Value
            }
            Write-Config $values
            $form.DialogResult='OK'
            $form.Close()
        } catch {[void][Windows.Forms.MessageBox]::Show($_.Exception.Message,$script:T.Error,'OK','Error')}
    })

    [void]$form.ShowDialog()
    $form.Dispose()
}

try { Show-Settings }
catch {
    $message="GlassFrame:`r`n$($_.Exception.Message)`r`n$($_.ScriptStackTrace)"
    try {[System.IO.File]::WriteAllText($logFile,$message,(New-Object Text.UTF8Encoding($false)))} catch {}
    try {Add-Type -AssemblyName System.Windows.Forms; [void][Windows.Forms.MessageBox]::Show($message,'GlassFrame')} catch {}
}
