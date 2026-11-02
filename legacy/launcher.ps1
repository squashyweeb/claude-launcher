# Claude Account Launcher v2
# Side-by-side profile launcher for Claude Desktop (PowerShell + WPF fallback).
# Edit profiles via the UI (right-click a card, or click + Add account).
# See docs/ for architecture notes.

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing

# -----------------------------------------------------------------------------
# Config and persistence
# -----------------------------------------------------------------------------
$script:PROFILES_FILE = Join-Path $PSScriptRoot 'profiles.json'
$script:PREFS_FILE    = Join-Path $PSScriptRoot 'prefs.json'
$script:CONFIG_FILE   = Join-Path $PSScriptRoot 'config.json'
$script:DOCS_DIR      = Join-Path $PSScriptRoot 'docs'
$script:WHOIS_SCRIPT  = Join-Path $PSScriptRoot 'scripts\whois.py'

$script:SWATCHES = @('#ef4444','#f97316','#f59e0b','#eab308','#84cc16',
                     '#22c55e','#10b981','#14b8a6','#06b6d4','#0ea5e9',
                     '#3b82f6','#6366f1','#8b5cf6','#a855f7','#d946ef',
                     '#ec4899','#f43f5e','#64748b')

# First-run profiles: empty. Add accounts via the UI (right-click +Add tile).
$script:DEFAULT_PROFILES = @()

function Resolve-ClaudeExe {
    if (Test-Path $script:CONFIG_FILE) {
        try {
            $cfg = Get-Content $script:CONFIG_FILE -Raw | ConvertFrom-Json
            if ($cfg.exePath -and (Test-Path $cfg.exePath)) { return $cfg.exePath }
        } catch {}
    }
    if ($env:CLAUDE_EXE -and (Test-Path $env:CLAUDE_EXE)) { return $env:CLAUDE_EXE }
    foreach ($c in @(
        "$env:LOCALAPPDATA\Programs\Claude\Claude.exe",
        "$env:LOCALAPPDATA\Claude\Claude.exe",
        'C:\Program Files\Claude\Claude.exe',
        'C:\Program Files (x86)\Claude\Claude.exe'
    )) {
        if (Test-Path $c) { return $c }
    }
    # Last resort: prompt user to pick, persist choice.
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = 'Locate Claude.exe'
    $dlg.Filter = 'Claude|Claude.exe|All executables (*.exe)|*.exe'
    if ($dlg.ShowDialog() -eq 'OK' -and $dlg.FileName) {
        $cfg = @{}
        if (Test-Path $script:CONFIG_FILE) {
            try { $cfg = Get-Content $script:CONFIG_FILE -Raw | ConvertFrom-Json | ConvertTo-Hashtable } catch {}
        }
        $cfg.exePath = $dlg.FileName
        $cfg | ConvertTo-Json | Set-Content $script:CONFIG_FILE -Encoding UTF8
        return $dlg.FileName
    }
    throw 'Claude.exe not located; aborting.'
}

$script:EXE = Resolve-ClaudeExe

function Load-Profiles {
    if (Test-Path $script:PROFILES_FILE) {
        try {
            $raw = Get-Content $script:PROFILES_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
            return @($raw | ForEach-Object {
                @{
                    Id     = [string]$_.Id
                    Name   = [string]$_.Name
                    Email  = [string]$_.Email
                    Plan   = [string]$_.Plan
                    Accent = [string]$_.Accent
                    Dir    = [string]$_.Dir
                    Mode   = [string]$_.Mode
                }
            })
        } catch {
            Write-Warning "profiles.json unreadable, using defaults: $_"
        }
    }
    return $script:DEFAULT_PROFILES
}

function Save-Profiles {
    $script:PROFILES | ConvertTo-Json -Depth 5 | Set-Content $script:PROFILES_FILE -Encoding UTF8
}

function Load-Prefs {
    if (Test-Path $script:PREFS_FILE) {
        try { return Get-Content $script:PREFS_FILE -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
    }
    return [pscustomobject]@{ hintsEnabled = $true; hintIndex = 0 }
}

function Save-Prefs { $script:PREFS | ConvertTo-Json | Set-Content $script:PREFS_FILE -Encoding UTF8 }

$script:PROFILES = Load-Profiles
$script:PREFS = Load-Prefs

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
function Brush($hex) { [Windows.Media.BrushConverter]::new().ConvertFrom($hex) }

function Get-Initials($name) {
    if (-not $name) { return '?' }
    $parts = $name -split '\s+' | Where-Object { $_ }
    if ($parts.Count -ge 2) {
        return ($parts[0].Substring(0,1) + $parts[-1].Substring(0,1)).ToUpper()
    }
    return $name.Substring(0,[Math]::Min(2,$name.Length)).ToUpper()
}

function Get-AvatarBrush($seed, $accentHex) {
    # Deterministic 2-stop gradient based on seed string; falls back to accent if seed empty.
    if (-not $seed) {
        $base = [Windows.Media.ColorConverter]::ConvertFromString($accentHex)
        $brush = New-Object Windows.Media.LinearGradientBrush
        $brush.StartPoint = '0,0'; $brush.EndPoint = '1,1'
        [void]$brush.GradientStops.Add((New-Object Windows.Media.GradientStop $base, 0))
        [void]$brush.GradientStops.Add((New-Object Windows.Media.GradientStop $base, 1))
        return $brush
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($seed.ToLower()))
    $sha.Dispose()
    $h1 = ($bytes[0] / 255.0) * 360
    $h2 = ($h1 + 30 + ($bytes[1] % 90)) % 360
    $c1 = HSL-ToColor $h1 0.65 0.52
    $c2 = HSL-ToColor $h2 0.65 0.38
    $brush = New-Object Windows.Media.LinearGradientBrush
    $brush.StartPoint = '0,0'; $brush.EndPoint = '1,1'
    [void]$brush.GradientStops.Add((New-Object Windows.Media.GradientStop $c1, 0))
    [void]$brush.GradientStops.Add((New-Object Windows.Media.GradientStop $c2, 1))
    return $brush
}

function HSL-ToColor([double]$h, [double]$s, [double]$l) {
    $c = (1 - [Math]::Abs(2*$l - 1)) * $s
    $hp = $h / 60.0
    $x = $c * (1 - [Math]::Abs(($hp % 2) - 1))
    switch ([Math]::Floor($hp) % 6) {
        0 { $r=$c; $g=$x; $b=0 }
        1 { $r=$x; $g=$c; $b=0 }
        2 { $r=0;  $g=$c; $b=$x }
        3 { $r=0;  $g=$x; $b=$c }
        4 { $r=$x; $g=0;  $b=$c }
        5 { $r=$c; $g=0;  $b=$x }
    }
    $m = $l - $c/2
    $R = [byte][Math]::Round(($r + $m) * 255)
    $G = [byte][Math]::Round(($g + $m) * 255)
    $B = [byte][Math]::Round(($b + $m) * 255)
    return [Windows.Media.Color]::FromRgb($R, $G, $B)
}

function Format-Bytes([long]$b) {
    if ($b -lt 1024) { return "$b B" }
    if ($b -lt 1048576) { return ("{0:N0} KB" -f ($b/1024)) }
    if ($b -lt 1073741824) { return ("{0:N0} MB" -f ($b/1048576)) }
    return ("{0:N1} GB" -f ($b/1073741824))
}

function Format-Uptime([TimeSpan]$ts) {
    if ($ts.TotalMinutes -lt 1) { return "<1m" }
    if ($ts.TotalHours -lt 1)   { return "{0:N0}m" -f $ts.TotalMinutes }
    if ($ts.TotalDays -lt 1)    { return "{0:N1}h" -f $ts.TotalHours }
    return "{0:N1}d" -f $ts.TotalDays
}

# -----------------------------------------------------------------------------
# Process query / launch / close
# -----------------------------------------------------------------------------
function Get-RunningMap {
    $map = @{}
    try {
        $procs = Get-CimInstance Win32_Process -Filter "Name='claude.exe'" -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            $cl = $p.CommandLine
            if ($null -eq $cl) { continue }
            $key = $null
            if ($cl -match '--user-data-dir=(?:"([^"]+)"|(\S+))') {
                $key = (if ($Matches[1]) { $Matches[1] } else { $Matches[2] }).TrimEnd('\').ToLower()
            } elseif ($cl -match '--profile=([A-Za-z0-9_\-]+)') {
                $key = (Join-Path (Join-Path $env:LOCALAPPDATA 'Claude-Data-Profiles') $Matches[1]).TrimEnd('\').ToLower()
            } else {
                $key = (Join-Path $env:APPDATA 'Claude').TrimEnd('\').ToLower()
            }
            if (-not $map.ContainsKey($key)) {
                $map[$key] = @{ Count = 0; Mem = [long]0; Oldest = $null }
            }
            $map[$key].Count++
            $map[$key].Mem += [long]$p.WorkingSetSize
            if ($p.CreationDate) {
                try { $ct = [Management.ManagementDateTimeConverter]::ToDateTime([string]$p.CreationDate) }
                catch { $ct = $p.CreationDate }
                if ($null -eq $map[$key].Oldest -or $ct -lt $map[$key].Oldest) { $map[$key].Oldest = $ct }
            }
        }
    } catch {}
    return $map
}

function Get-ProfileTokens($dir) {
    $f = Join-Path $dir 'buddy-tokens.json'
    if (-not (Test-Path $f)) { return $null }
    try {
        $j = Get-Content $f -Raw | ConvertFrom-Json
        $today = (Get-Date).ToString('yyyy-MM-dd')
        if ($j.'tokens-today' -and $j.'tokens-today'.date -eq $today) {
            return [long]$j.'tokens-today'.tokens
        }
    } catch {}
    return $null
}

function Launch-Profile($dir, $mode) {
    if ($mode -eq 'profile') {
        $name = Split-Path $dir -Leaf
        Start-Process $script:EXE -ArgumentList "--profile=$name" | Out-Null
    } else {
        Start-Process $script:EXE -ArgumentList "--user-data-dir=`"$dir`"" | Out-Null
    }
}

function Close-Profile($dir) {
    $target = $dir.ToLower()
    Get-CimInstance Win32_Process -Filter "Name='claude.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine.ToLower().Contains($target) } |
        ForEach-Object {
            try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
        }
}

function Launch-ByIndex($idx) {
    if ($idx -lt 0 -or $idx -ge $script:PROFILES.Count) { return }
    $p = $script:PROFILES[$idx]
    Launch-Profile $p.Dir $p.Mode
    Start-Sleep -Milliseconds 400
    Update-Status
}

function Close-ByIndex($idx) {
    if ($idx -lt 0 -or $idx -ge $script:PROFILES.Count) { return }
    Close-Profile $script:PROFILES[$idx].Dir
    Start-Sleep -Milliseconds 300
    Update-Status
}

# -----------------------------------------------------------------------------
# Main window XAML
# -----------------------------------------------------------------------------
[xml]$xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Title='Claude Account Launcher'
        Width='680' Height='720'
        Background='#09090b'
        WindowStartupLocation='CenterScreen'
        FontFamily='Segoe UI'
        ResizeMode='CanResize'
        MinWidth='560' MinHeight='500'>
  <Window.Resources>
    <SolidColorBrush x:Key='Theme.Bg'        Color='#09090b'/>
    <SolidColorBrush x:Key='Theme.Surface'   Color='#141416'/>
    <SolidColorBrush x:Key='Theme.SurfaceAlt' Color='#0d0d0f'/>
    <SolidColorBrush x:Key='Theme.Hover'     Color='#1c1c20'/>
    <SolidColorBrush x:Key='Theme.Border'    Color='#1f1f23'/>
    <SolidColorBrush x:Key='Theme.BorderStrong' Color='#3f3f46'/>
    <SolidColorBrush x:Key='Theme.Text'      Color='#fafafa'/>
    <SolidColorBrush x:Key='Theme.TextMuted' Color='#a1a1aa'/>
    <SolidColorBrush x:Key='Theme.TextDim'   Color='#71717a'/>
    <SolidColorBrush x:Key='Theme.TextMicro' Color='#52525b'/>
    <SolidColorBrush x:Key='Theme.Running'   Color='#22c55e'/>
    <SolidColorBrush x:Key='Theme.Warn'      Color='#f59e0b'/>

    <Style x:Key='PrimaryBtn' TargetType='Button'>
      <Setter Property='Foreground' Value='White'/>
      <Setter Property='Background' Value='#3f3f46'/>
      <Setter Property='BorderThickness' Value='0'/>
      <Setter Property='Padding' Value='20,10'/>
      <Setter Property='FontSize' Value='13'/>
      <Setter Property='FontWeight' Value='SemiBold'/>
      <Setter Property='Cursor' Value='Hand'/>
      <Setter Property='Template'>
        <Setter.Value>
          <ControlTemplate TargetType='Button'>
            <Border x:Name='bd' Background='{TemplateBinding Background}' CornerRadius='8'>
              <ContentPresenter HorizontalAlignment='Center' VerticalAlignment='Center' Margin='{TemplateBinding Padding}'/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property='IsMouseOver' Value='True'>
                <Setter TargetName='bd' Property='Opacity' Value='0.88'/>
              </Trigger>
              <Trigger Property='IsPressed' Value='True'>
                <Setter TargetName='bd' Property='Opacity' Value='0.72'/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key='GhostBtn' TargetType='Button'>
      <Setter Property='Foreground' Value='{StaticResource Theme.TextMuted}'/>
      <Setter Property='Background' Value='Transparent'/>
      <Setter Property='BorderBrush' Value='{StaticResource Theme.Border}'/>
      <Setter Property='BorderThickness' Value='1'/>
      <Setter Property='Padding' Value='14,8'/>
      <Setter Property='FontSize' Value='13'/>
      <Setter Property='Cursor' Value='Hand'/>
      <Setter Property='Template'>
        <Setter.Value>
          <ControlTemplate TargetType='Button'>
            <Border x:Name='bd' Background='{TemplateBinding Background}'
                    BorderBrush='{TemplateBinding BorderBrush}'
                    BorderThickness='{TemplateBinding BorderThickness}' CornerRadius='8'>
              <ContentPresenter HorizontalAlignment='Center' VerticalAlignment='Center' Margin='{TemplateBinding Padding}'/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property='IsMouseOver' Value='True'>
                <Setter TargetName='bd' Property='Background' Value='{StaticResource Theme.Hover}'/>
                <Setter Property='Foreground' Value='{StaticResource Theme.Text}'/>
              </Trigger>
              <Trigger Property='IsEnabled' Value='False'>
                <Setter Property='Opacity' Value='0.4'/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key='IconBtn' TargetType='Button' BasedOn='{StaticResource GhostBtn}'>
      <Setter Property='Padding' Value='8,7'/>
      <Setter Property='MinWidth' Value='36'/>
    </Style>

    <Style x:Key='FieldLabel' TargetType='TextBlock'>
      <Setter Property='Foreground' Value='{StaticResource Theme.TextMuted}'/>
      <Setter Property='FontSize' Value='12'/>
      <Setter Property='Margin' Value='0,0,0,6'/>
    </Style>

    <Style x:Key='FieldBox' TargetType='TextBox'>
      <Setter Property='Background' Value='{StaticResource Theme.Surface}'/>
      <Setter Property='Foreground' Value='White'/>
      <Setter Property='BorderBrush' Value='{StaticResource Theme.Border}'/>
      <Setter Property='Padding' Value='10,8'/>
      <Setter Property='FontSize' Value='13'/>
      <Setter Property='CaretBrush' Value='White'/>
    </Style>

    <Style TargetType='ContextMenu'>
      <Setter Property='Background' Value='{StaticResource Theme.Surface}'/>
      <Setter Property='BorderBrush' Value='{StaticResource Theme.Border}'/>
      <Setter Property='BorderThickness' Value='1'/>
      <Setter Property='Padding' Value='4'/>
    </Style>
    <Style TargetType='MenuItem'>
      <Setter Property='Foreground' Value='{StaticResource Theme.Text}'/>
      <Setter Property='Padding' Value='10,6'/>
      <Setter Property='FontSize' Value='13'/>
    </Style>
  </Window.Resources>

  <Grid Margin='24'>
    <Grid.RowDefinitions>
      <RowDefinition Height='Auto'/>
      <RowDefinition Height='Auto'/>
      <RowDefinition Height='*'/>
      <RowDefinition Height='Auto'/>
    </Grid.RowDefinitions>

    <Grid Grid.Row='0' Margin='0,0,0,16'>
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width='*'/>
        <ColumnDefinition Width='Auto'/>
      </Grid.ColumnDefinitions>
      <StackPanel Grid.Column='0'>
        <TextBlock Text='Claude Accounts' Foreground='{DynamicResource Theme.Text}' FontSize='26' FontWeight='SemiBold'/>
        <TextBlock Text='Launch any account side-by-side. No re-login.' Foreground='{DynamicResource Theme.TextDim}' FontSize='13' Margin='0,4,0,0'/>
      </StackPanel>
      <StackPanel Grid.Column='1' Orientation='Horizontal' VerticalAlignment='Bottom'>
        <TextBlock x:Name='SummaryText' Foreground='{DynamicResource Theme.TextDim}' FontSize='12' VerticalAlignment='Center' Margin='0,0,10,0'/>
        <Button x:Name='HelpBtn' Content='?' Style='{StaticResource IconBtn}' FontWeight='Bold' FontSize='14' ToolTip='Help  (F1)'/>
      </StackPanel>
    </Grid>

    <Border Grid.Row='1' x:Name='HintStrip' CornerRadius='8' Padding='14,10' Margin='0,0,0,14'
            Background='#1a1507' BorderBrush='#78350f' BorderThickness='1'>
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width='Auto'/>
          <ColumnDefinition Width='*'/>
          <ColumnDefinition Width='Auto'/>
        </Grid.ColumnDefinitions>
        <TextBlock Grid.Column='0' Text='Tip' Foreground='#fbbf24' FontWeight='Bold' FontSize='11' VerticalAlignment='Center' Margin='0,0,10,0'/>
        <TextBlock Grid.Column='1' x:Name='HintText' Foreground='#fde68a' FontSize='12' VerticalAlignment='Center' TextWrapping='Wrap'/>
        <Button Grid.Column='2' x:Name='HintDismiss' Content='x' Style='{StaticResource IconBtn}' Padding='8,4' MinWidth='28' FontSize='11' ToolTip='Hide hints'/>
      </Grid>
    </Border>

    <ScrollViewer Grid.Row='2' VerticalScrollBarVisibility='Auto' HorizontalScrollBarVisibility='Disabled'>
      <StackPanel x:Name='ProfileList'/>
    </ScrollViewer>

    <Grid Grid.Row='3' Margin='0,16,0,0'>
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width='*'/>
        <ColumnDefinition Width='Auto'/>
        <ColumnDefinition Width='Auto'/>
      </Grid.ColumnDefinitions>
      <TextBlock Grid.Column='0' x:Name='StatusBar' Foreground='{DynamicResource Theme.TextMicro}' FontSize='11' VerticalAlignment='Center'/>
      <Button Grid.Column='1' x:Name='CloseAll'  Content='Close all'  Style='{StaticResource GhostBtn}' Margin='0,0,8,0' ToolTip='Ctrl+W'/>
      <Button Grid.Column='2' x:Name='LaunchAll' Content='Launch all' Style='{StaticResource GhostBtn}' ToolTip='Ctrl+L'/>
    </Grid>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$script:window = [Windows.Markup.XamlReader]::Load($reader)
$script:cardRefs = New-Object System.Collections.ArrayList
$script:panel = $window.FindName('ProfileList')

# -----------------------------------------------------------------------------
# Card builder
# -----------------------------------------------------------------------------
function New-ProfileCard([hashtable]$prof, [int]$index) {
    $accent = $prof.Accent
    $card = New-Object Windows.Controls.Border
    $card.CornerRadius = '12'
    $card.Padding = '18'
    $card.Margin = '0,0,0,12'
    $card.BorderBrush = Brush '#1f1f23'
    $card.BorderThickness = '1'
    $card.Background = Brush '#141416'
    $card.Focusable = $true
    $card.Tag = $index

    $grid = New-Object Windows.Controls.Grid
    [void]$grid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition -Property @{ Width = 'Auto' }))
    [void]$grid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition -Property @{ Width = '*' }))
    [void]$grid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition -Property @{ Width = 'Auto' }))

    # Avatar
    $avatar = New-Object Windows.Controls.Grid
    $avatar.Width = 54; $avatar.Height = 54
    $avatar.Margin = '0,0,16,0'
    $avatar.VerticalAlignment = 'Top'
    [Windows.Controls.Grid]::SetColumn($avatar, 0)

    $circle = New-Object Windows.Shapes.Ellipse
    $circle.Fill = Get-AvatarBrush ($prof.Email + '|' + $prof.Id) $accent
    [void]$avatar.Children.Add($circle)

    $letter = New-Object Windows.Controls.TextBlock
    $letter.Text = Get-Initials $prof.Name
    $letter.Foreground = [Windows.Media.Brushes]::White
    $letter.FontSize = 20
    $letter.FontWeight = 'Bold'
    $letter.HorizontalAlignment = 'Center'
    $letter.VerticalAlignment = 'Center'
    [void]$avatar.Children.Add($letter)

    # Keycap overlay (bottom-right of avatar)
    if ($index -lt 9) {
        $keycap = New-Object Windows.Controls.Border
        $keycap.CornerRadius = '4'
        $keycap.Background = Brush '#09090b'
        $keycap.BorderBrush = Brush '#3f3f46'
        $keycap.BorderThickness = '1'
        $keycap.Padding = '4,0'
        $keycap.HorizontalAlignment = 'Right'
        $keycap.VerticalAlignment = 'Bottom'
        $keycap.Margin = '0,0,-4,-4'
        $keycapText = New-Object Windows.Controls.TextBlock
        $keycapText.Text = [string]($index + 1)
        $keycapText.Foreground = Brush '#a1a1aa'
        $keycapText.FontSize = 10
        $keycapText.FontFamily = 'Consolas'
        $keycapText.FontWeight = 'Bold'
        $keycap.Child = $keycapText
        $keycap.ToolTip = "Press $($index + 1) to launch"
        [void]$avatar.Children.Add($keycap)
    }
    [void]$grid.Children.Add($avatar)

    # Info stack
    $info = New-Object Windows.Controls.StackPanel
    [Windows.Controls.Grid]::SetColumn($info, 1)

    $nameRow = New-Object Windows.Controls.StackPanel
    $nameRow.Orientation = 'Horizontal'

    $nameText = New-Object Windows.Controls.TextBlock
    $nameText.Text = $prof.Name
    $nameText.Foreground = [Windows.Media.Brushes]::White
    $nameText.FontSize = 18
    $nameText.FontWeight = 'SemiBold'
    $nameText.VerticalAlignment = 'Center'
    [void]$nameRow.Children.Add($nameText)

    if ($prof.Plan) {
        $planBadge = New-Object Windows.Controls.Border
        $planBadge.Background = Brush $accent
        $planBadge.CornerRadius = '10'
        $planBadge.Padding = '9,3'
        $planBadge.Margin = '12,2,0,0'
        $planBadge.VerticalAlignment = 'Center'
        $planText = New-Object Windows.Controls.TextBlock
        $planText.Text = $prof.Plan
        $planText.Foreground = [Windows.Media.Brushes]::White
        $planText.FontSize = 10
        $planText.FontWeight = 'Bold'
        $planBadge.Child = $planText
        [void]$nameRow.Children.Add($planBadge)
    }
    [void]$info.Children.Add($nameRow)

    $email = New-Object Windows.Controls.TextBlock
    $email.Text = $prof.Email
    $email.Foreground = Brush '#a1a1aa'
    $email.FontSize = 13
    $email.Margin = '0,4,0,0'
    [void]$info.Children.Add($email)

    # Status row (dot + status text)
    $statusRow = New-Object Windows.Controls.StackPanel
    $statusRow.Orientation = 'Horizontal'
    $statusRow.Margin = '0,10,0,0'

    $statusDot = New-Object Windows.Shapes.Ellipse
    $statusDot.Width = 8; $statusDot.Height = 8
    $statusDot.Fill = Brush '#3f3f46'
    $statusDot.Margin = '0,0,8,0'
    $statusDot.VerticalAlignment = 'Center'
    [void]$statusRow.Children.Add($statusDot)

    $statusText = New-Object Windows.Controls.TextBlock
    $statusText.Text = 'Not running'
    $statusText.Foreground = Brush '#71717a'
    $statusText.FontSize = 12
    $statusText.FontWeight = 'Medium'
    $statusText.VerticalAlignment = 'Center'
    [void]$statusRow.Children.Add($statusText)
    [void]$info.Children.Add($statusRow)

    # Telemetry sub-row
    $telemetry = New-Object Windows.Controls.TextBlock
    $telemetry.Text = ''
    $telemetry.Foreground = Brush '#52525b'
    $telemetry.FontSize = 11
    $telemetry.Margin = '16,3,0,0'
    [void]$info.Children.Add($telemetry)

    [void]$grid.Children.Add($info)

    # Buttons
    $btnStack = New-Object Windows.Controls.StackPanel
    $btnStack.Orientation = 'Horizontal'
    $btnStack.VerticalAlignment = 'Center'
    [Windows.Controls.Grid]::SetColumn($btnStack, 2)

    $folderBtn = New-Object Windows.Controls.Button
    $folderBtn.Style = $window.FindResource('IconBtn')
    $folderBtn.Content = [char]::ConvertFromUtf32(0x1F4C1)
    $folderBtn.FontSize = 14
    $folderBtn.ToolTip = "Open profile folder (Ctrl+$($index + 1))`n$($prof.Dir)"
    $folderBtn.Margin = '0,0,6,0'
    $folderBtn.Add_Click({ Start-Process explorer.exe -ArgumentList ('"' + $prof.Dir + '"') }.GetNewClosure())
    [void]$btnStack.Children.Add($folderBtn)

    $closeBtn = New-Object Windows.Controls.Button
    $closeBtn.Style = $window.FindResource('GhostBtn')
    $closeBtn.Content = 'Close'
    $closeBtn.Margin = '0,0,6,0'
    $closeBtn.Visibility = 'Collapsed'
    $closeBtn.ToolTip = "Close all windows for this account (Shift+$($index + 1))"
    $closeBtn.Add_Click({
        Close-Profile $prof.Dir
        Start-Sleep -Milliseconds 300
        Update-Status
    }.GetNewClosure())
    [void]$btnStack.Children.Add($closeBtn)

    $launchBtn = New-Object Windows.Controls.Button
    $launchBtn.Style = $window.FindResource('PrimaryBtn')
    $launchBtn.Background = Brush $accent
    $launchBtn.Content = 'Launch'
    $launchBtn.ToolTip = "Launch (press $($index + 1))"
    $launchBtn.Add_Click({
        Launch-Profile $prof.Dir $prof.Mode
        Start-Sleep -Milliseconds 500
        Update-Status
    }.GetNewClosure())
    [void]$btnStack.Children.Add($launchBtn)

    [void]$grid.Children.Add($btnStack)
    $card.Child = $grid

    # Right-click context menu
    $menu = New-Object Windows.Controls.ContextMenu
    $miEdit      = New-Object Windows.Controls.MenuItem -Property @{ Header = 'Edit...' }
    $miDup       = New-Object Windows.Controls.MenuItem -Property @{ Header = 'Duplicate' }
    $miUp        = New-Object Windows.Controls.MenuItem -Property @{ Header = 'Move up' }
    $miDown      = New-Object Windows.Controls.MenuItem -Property @{ Header = 'Move down' }
    $miSep       = New-Object Windows.Controls.Separator
    $miWhois     = New-Object Windows.Controls.MenuItem -Property @{ Header = 'Who is signed in?' }
    $miRemove    = New-Object Windows.Controls.MenuItem -Property @{ Header = 'Remove' }
    $myIdx = $index
    $miEdit.Add_Click(   { Edit-Profile   $myIdx }.GetNewClosure())
    $miDup.Add_Click(    { Duplicate-Profile $myIdx }.GetNewClosure())
    $miUp.Add_Click(     { Move-Profile   $myIdx -1 }.GetNewClosure())
    $miDown.Add_Click(   { Move-Profile   $myIdx  1 }.GetNewClosure())
    $miWhois.Add_Click(  { Show-WhoIs     $myIdx }.GetNewClosure())
    $miRemove.Add_Click( { Remove-Profile $myIdx }.GetNewClosure())
    foreach ($mi in @($miEdit,$miDup,$miUp,$miDown,$miSep,$miWhois,$miRemove)) { [void]$menu.Items.Add($mi) }
    $card.ContextMenu = $menu

    # Store refs
    $ref = @{
        Key        = $prof.Dir.TrimEnd('\').ToLower()
        Accent     = $accent
        Card       = $card
        StatusDot  = $statusDot
        StatusText = $statusText
        Telemetry  = $telemetry
        LaunchBtn  = $launchBtn
        CloseBtn   = $closeBtn
    }
    [void]$script:cardRefs.Add($ref)
    return $card
}

function New-AddTile {
    $tile = New-Object Windows.Controls.Border
    $tile.CornerRadius = '12'
    $tile.Padding = '18'
    $tile.Margin = '0,0,0,12'
    $tile.Background = Brush '#0d0d0f'
    $tile.BorderThickness = '0'
    $tile.Cursor = [Windows.Input.Cursors]::Hand

    $rect = New-Object Windows.Shapes.Rectangle
    $rect.Stroke = Brush '#3f3f46'
    $rect.StrokeThickness = 1.5
    $rect.StrokeDashArray = [Windows.Media.DoubleCollection]'5,4'
    $rect.RadiusX = 12; $rect.RadiusY = 12
    $rect.IsHitTestVisible = $false

    $content = New-Object Windows.Controls.StackPanel
    $content.Orientation = 'Horizontal'
    $content.HorizontalAlignment = 'Center'
    $content.VerticalAlignment = 'Center'

    $plus = New-Object Windows.Controls.TextBlock
    $plus.Text = '+'
    $plus.Foreground = Brush '#71717a'
    $plus.FontSize = 20
    $plus.FontWeight = 'Bold'
    $plus.Margin = '0,0,10,0'
    [void]$content.Children.Add($plus)

    $label = New-Object Windows.Controls.TextBlock
    $label.Text = 'Add account   (Ctrl+N)'
    $label.Foreground = Brush '#a1a1aa'
    $label.FontSize = 14
    $label.FontWeight = 'SemiBold'
    $label.VerticalAlignment = 'Center'
    [void]$content.Children.Add($label)

    $outer = New-Object Windows.Controls.Grid
    [void]$outer.Children.Add($rect)
    [void]$outer.Children.Add($content)
    $tile.Child = $outer

    $tile.Add_MouseLeftButtonUp({ Invoke-AddAccountDialog })
    $tile.Add_MouseEnter({ $this.Background = Brush '#141416' })
    $tile.Add_MouseLeave({ $this.Background = Brush '#0d0d0f' })
    return $tile
}

function Rebuild-Cards {
    $script:cardRefs.Clear()
    $script:panel.Children.Clear()
    for ($i = 0; $i -lt $script:PROFILES.Count; $i++) {
        [void]$script:panel.Children.Add((New-ProfileCard $script:PROFILES[$i] $i))
    }
    [void]$script:panel.Children.Add((New-AddTile))
    Update-Status
}

# -----------------------------------------------------------------------------
# Status refresh
# -----------------------------------------------------------------------------
function Update-Status {
    $running = Get-RunningMap
    $activeAccounts = 0
    $totalWindows = 0
    foreach ($ref in $script:cardRefs) {
        $info = $running[$ref.Key]
        if ($info) {
            $activeAccounts++
            $totalWindows += $info.Count
            $ref.Card.Background      = Brush '#111113'
            $ref.Card.BorderBrush     = Brush $ref.Accent
            $ref.Card.BorderThickness = '2'
            $ref.StatusDot.Fill       = Brush '#22c55e'
            $procWord = if ($info.Count -eq 1) { 'process' } else { 'processes' }
            $ref.StatusText.Text      = "Running  $($info.Count) $procWord"
            $ref.StatusText.Foreground = Brush '#22c55e'
            $tParts = @()
            $tParts += Format-Bytes $info.Mem
            if ($info.Oldest) { $tParts += "up " + (Format-Uptime ((Get-Date) - $info.Oldest)) }
            $ref.Telemetry.Text       = $tParts -join '  |  '
            $ref.LaunchBtn.Content    = '+ New window'
            $ref.CloseBtn.Visibility  = 'Visible'
        } else {
            $ref.Card.Background      = Brush '#141416'
            $ref.Card.BorderBrush     = Brush '#1f1f23'
            $ref.Card.BorderThickness = '1'
            $ref.StatusDot.Fill       = Brush '#3f3f46'
            $ref.StatusText.Text      = 'Not running'
            $ref.StatusText.Foreground = Brush '#71717a'
            $ref.Telemetry.Text       = ''
            $ref.LaunchBtn.Content    = 'Launch'
            $ref.CloseBtn.Visibility  = 'Collapsed'
        }
    }
    $window.FindName('SummaryText').Text = ("{0} of {1} live" -f $activeAccounts, $script:cardRefs.Count)
    $window.FindName('StatusBar').Text  = ("{0} windows total   |   auto-refresh 2s   |   updated {1:HH:mm:ss}" -f $totalWindows, (Get-Date))
}

# -----------------------------------------------------------------------------
# Profile CRUD
# -----------------------------------------------------------------------------
function Edit-Profile($idx) {
    if ($idx -lt 0 -or $idx -ge $script:PROFILES.Count) { return }
    $result = Invoke-ProfileDialog -title 'Edit account' -existing $script:PROFILES[$idx]
    if ($result) {
        $script:PROFILES[$idx] = $result
        Save-Profiles
        Rebuild-Cards
    }
}

function Duplicate-Profile($idx) {
    if ($idx -lt 0 -or $idx -ge $script:PROFILES.Count) { return }
    $src = $script:PROFILES[$idx]
    $copy = @{}
    foreach ($k in $src.Keys) { $copy[$k] = $src[$k] }
    $copy.Id = $src.Id + '-copy-' + (Get-Random -Minimum 100 -Maximum 999)
    $copy.Name = $src.Name + ' (copy)'
    $new = [System.Collections.ArrayList]::new($script:PROFILES)
    [void]$new.Insert($idx + 1, $copy)
    $script:PROFILES = $new.ToArray()
    Save-Profiles
    Rebuild-Cards
    Edit-Profile ($idx + 1)
}

function Move-Profile($idx, $dir) {
    $target = $idx + $dir
    if ($target -lt 0 -or $target -ge $script:PROFILES.Count) { return }
    $list = [System.Collections.ArrayList]::new($script:PROFILES)
    $item = $list[$idx]
    $list.RemoveAt($idx)
    $list.Insert($target, $item)
    $script:PROFILES = $list.ToArray()
    Save-Profiles
    Rebuild-Cards
}

function Remove-Profile($idx) {
    if ($idx -lt 0 -or $idx -ge $script:PROFILES.Count) { return }
    $p = $script:PROFILES[$idx]
    $msg = "Remove '$($p.Name)' from the launcher?`n`nThis does NOT delete the profile folder on disk:`n$($p.Dir)"
    $r = [Windows.MessageBox]::Show($msg, 'Remove account', 'OKCancel', 'Warning')
    if ($r -ne 'OK') { return }
    $list = [System.Collections.ArrayList]::new($script:PROFILES)
    $list.RemoveAt($idx)
    $script:PROFILES = $list.ToArray()
    Save-Profiles
    Rebuild-Cards
}

function Show-WhoIs($idx) {
    if ($idx -lt 0 -or $idx -ge $script:PROFILES.Count) { return }
    $dir = $script:PROFILES[$idx].Dir
    if (-not (Test-Path (Join-Path $dir 'config.json'))) {
        [Windows.MessageBox]::Show("No config.json in profile dir.`n`n$dir", 'Who is signed in?', 'OK', 'Information') | Out-Null
        return
    }
    try {
        $out = & python $script:WHOIS_SCRIPT $dir 2>&1 | Out-String
        [Windows.MessageBox]::Show($out, 'Who is signed in?', 'OK', 'Information') | Out-Null
    } catch {
        [Windows.MessageBox]::Show("whois.py failed: $_", 'Who is signed in?', 'OK', 'Error') | Out-Null
    }
}

# -----------------------------------------------------------------------------
# Add / Edit dialog
# -----------------------------------------------------------------------------
function Invoke-AddAccountDialog { Invoke-ProfileDialog -title 'Add account' -existing $null | Out-Null }

function Invoke-ProfileDialog([string]$title, [hashtable]$existing) {
    $isNew = ($null -eq $existing)
    if ($isNew) {
        $existing = @{
            Id = 'acct-' + (Get-Random -Minimum 1000 -Maximum 9999)
            Name = ''
            Email = ''
            Plan = 'Max'
            Accent = $script:SWATCHES[(Get-Random -Minimum 0 -Maximum $script:SWATCHES.Count)]
            Dir = ''
            Mode = 'profile'
        }
    }

    [xml]$dxaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Title='$title'
        Width='500' Height='660'
        Background='#09090b'
        WindowStartupLocation='CenterOwner'
        FontFamily='Segoe UI'
        ResizeMode='NoResize'
        ShowInTaskbar='False'>
  <Grid Margin='22'>
    <Grid.RowDefinitions>
      <RowDefinition Height='Auto'/>
      <RowDefinition Height='Auto'/>
      <RowDefinition Height='*'/>
      <RowDefinition Height='Auto'/>
    </Grid.RowDefinitions>

    <StackPanel Grid.Row='0'>
      <TextBlock Text='$title' Foreground='#fafafa' FontSize='20' FontWeight='SemiBold'/>
      <TextBlock Text='Edit fields, pick a color, then save.' Foreground='#71717a' FontSize='12' Margin='0,4,0,14'/>
    </StackPanel>

    <Grid Grid.Row='1' Margin='0,0,0,14'>
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width='Auto'/>
        <ColumnDefinition Width='*'/>
      </Grid.ColumnDefinitions>
      <Grid x:Name='AvatarBox' Width='52' Height='52' VerticalAlignment='Center'>
        <Ellipse x:Name='AvatarFill' Fill='#3f3f46'/>
        <TextBlock x:Name='AvatarLetter' Text='?' Foreground='White' FontSize='22' FontWeight='Bold' HorizontalAlignment='Center' VerticalAlignment='Center'/>
      </Grid>
      <StackPanel Grid.Column='1' Margin='14,0,0,0' VerticalAlignment='Center'>
        <TextBlock x:Name='PreviewName' Text='Preview' Foreground='White' FontSize='15' FontWeight='SemiBold'/>
        <TextBlock x:Name='PreviewSub'  Text='no email yet' Foreground='#71717a' FontSize='12' Margin='0,2,0,0'/>
      </StackPanel>
    </Grid>

    <ScrollViewer Grid.Row='2' VerticalScrollBarVisibility='Auto'>
      <StackPanel>
        <TextBlock Text='Display name *' Foreground='#a1a1aa' FontSize='12' Margin='0,0,0,4'/>
        <TextBox x:Name='NameBox' Background='#141416' Foreground='White' BorderBrush='#2a2a2e' CaretBrush='White' Padding='10,8' FontSize='13'/>

        <TextBlock Text='Email' Foreground='#a1a1aa' FontSize='12' Margin='0,14,0,4'/>
        <TextBox x:Name='EmailBox' Background='#141416' Foreground='White' BorderBrush='#2a2a2e' CaretBrush='White' Padding='10,8' FontSize='13'/>

        <TextBlock Text='Plan badge' Foreground='#a1a1aa' FontSize='12' Margin='0,14,0,4'/>
        <TextBox x:Name='PlanBox' Background='#141416' Foreground='White' BorderBrush='#2a2a2e' CaretBrush='White' Padding='10,8' FontSize='13'/>

        <TextBlock Text='Launch mode' Foreground='#a1a1aa' FontSize='12' Margin='0,14,0,4'/>
        <StackPanel>
          <RadioButton x:Name='ModeProfile' GroupName='mode' IsChecked='True' Foreground='#e4e4e7' FontSize='13'>
            <StackPanel Margin='4,0,0,0'>
              <TextBlock Text='New portable profile'/>
              <TextBlock Text='Fresh window via --profile=NAME shim; sign in once' Foreground='#71717a' FontSize='11'/>
            </StackPanel>
          </RadioButton>
          <RadioButton x:Name='ModeDir' GroupName='mode' Foreground='#e4e4e7' FontSize='13' Margin='0,6,0,0'>
            <StackPanel Margin='4,0,0,0'>
              <TextBlock Text='Attach existing folder'/>
              <TextBlock Text='Reuse an existing userData dir (e.g. MSIX install)' Foreground='#71717a' FontSize='11'/>
            </StackPanel>
          </RadioButton>
        </StackPanel>

        <StackPanel x:Name='ProfilePanel' Margin='0,12,0,0'>
          <TextBlock Text='Profile key' Foreground='#a1a1aa' FontSize='12' Margin='0,0,0,4'/>
          <TextBox x:Name='KeyBox' Background='#141416' Foreground='White' BorderBrush='#2a2a2e' CaretBrush='White' Padding='10,8' FontSize='13'/>
          <TextBlock x:Name='KeyHint' Foreground='#52525b' FontSize='11' Margin='0,4,0,0'/>
        </StackPanel>

        <StackPanel x:Name='DirPanel' Margin='0,12,0,0' Visibility='Collapsed'>
          <TextBlock Text='Folder' Foreground='#a1a1aa' FontSize='12' Margin='0,0,0,4'/>
          <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition Width='*'/><ColumnDefinition Width='Auto'/></Grid.ColumnDefinitions>
            <TextBox x:Name='DirBox' Background='#141416' Foreground='White' BorderBrush='#2a2a2e' CaretBrush='White' Padding='10,8' FontSize='13'/>
            <Button Grid.Column='1' x:Name='BrowseBtn' Content='Browse...' Margin='8,0,0,0' Padding='12,7' Background='Transparent' BorderBrush='#3f3f46' Foreground='#d4d4d8' FontSize='12'/>
          </Grid>
          <Button x:Name='DetectBtn' Content='Detect identity from this folder' Margin='0,8,0,0' Padding='12,7' Background='Transparent' BorderBrush='#3f3f46' Foreground='#d4d4d8' FontSize='12' HorizontalAlignment='Left'/>
          <TextBlock x:Name='DetectMsg' Foreground='#52525b' FontSize='11' Margin='0,6,0,0' TextWrapping='Wrap'/>
        </StackPanel>

        <TextBlock Text='Accent color' Foreground='#a1a1aa' FontSize='12' Margin='0,14,0,6'/>
        <WrapPanel x:Name='SwatchPanel' Orientation='Horizontal'/>
      </StackPanel>
    </ScrollViewer>

    <Grid Grid.Row='3' Margin='0,14,0,0'>
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width='*'/>
        <ColumnDefinition Width='Auto'/>
        <ColumnDefinition Width='Auto'/>
      </Grid.ColumnDefinitions>
      <TextBlock Grid.Column='0' x:Name='ValidationMsg' Foreground='#f87171' FontSize='11' VerticalAlignment='Center' TextWrapping='Wrap'/>
      <Button Grid.Column='1' x:Name='CancelBtn' Content='Cancel' Padding='18,9' Margin='0,0,8,0' Background='Transparent' BorderBrush='#3f3f46' Foreground='#d4d4d8' FontSize='13'/>
      <Button Grid.Column='2' x:Name='SaveBtn' Content='Save' Padding='22,9' Background='#3b82f6' BorderBrush='Transparent' Foreground='White' FontSize='13' FontWeight='SemiBold'/>
    </Grid>
  </Grid>
</Window>
"@
    $dr = New-Object System.Xml.XmlNodeReader $dxaml
    $dlg = [Windows.Markup.XamlReader]::Load($dr)
    $dlg.Owner = $script:window
    $script:dialogResult = $null
    $accentChoice = $existing.Accent

    # Prefill
    $dlg.FindName('NameBox').Text  = $existing.Name
    $dlg.FindName('EmailBox').Text = $existing.Email
    $dlg.FindName('PlanBox').Text  = $existing.Plan
    $dlg.FindName('KeyBox').Text   = $existing.Id
    $dlg.FindName('DirBox').Text   = $existing.Dir
    if ($existing.Mode -eq 'user-data-dir') {
        $dlg.FindName('ModeDir').IsChecked = $true
        $dlg.FindName('ProfilePanel').Visibility = 'Collapsed'
        $dlg.FindName('DirPanel').Visibility = 'Visible'
    }

    # Live avatar preview
    $updatePreview = {
        $name = $dlg.FindName('NameBox').Text
        $email = $dlg.FindName('EmailBox').Text
        $plan = $dlg.FindName('PlanBox').Text
        $dlg.FindName('AvatarFill').Fill = Get-AvatarBrush ($email + '|' + $existing.Id) $accentChoice
        $dlg.FindName('AvatarLetter').Text = Get-Initials $name
        $dlg.FindName('PreviewName').Text = if ($name) { $name } else { 'Preview' }
        $sub = @()
        if ($email) { $sub += $email }
        if ($plan)  { $sub += $plan }
        $dlg.FindName('PreviewSub').Text = if ($sub) { $sub -join ' * ' } else { 'no email yet' }
        $key = $dlg.FindName('KeyBox').Text
        if ($key) {
            $dlg.FindName('KeyHint').Text = "becomes " + (Join-Path (Join-Path $env:LOCALAPPDATA 'Claude-Data-Profiles') $key)
        } else {
            $dlg.FindName('KeyHint').Text = 'becomes %LOCALAPPDATA%\Claude-Data-Profiles\<key>'
        }
    }
    $dlg.FindName('NameBox').Add_TextChanged({
        & $updatePreview
        # Auto-slug Key box if it's empty or default
        $kb = $dlg.FindName('KeyBox')
        if (-not $kb.Tag -or $kb.Text -match '^acct-\d+$' -or $kb.Text -eq '') {
            $kb.Text = ($dlg.FindName('NameBox').Text.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
            if (-not $kb.Text) { $kb.Text = 'acct-' + (Get-Random -Minimum 1000 -Maximum 9999) }
        }
    })
    $dlg.FindName('EmailBox').Add_TextChanged({ & $updatePreview })
    $dlg.FindName('PlanBox').Add_TextChanged({ & $updatePreview })
    $dlg.FindName('KeyBox').Add_TextChanged({ $dlg.FindName('KeyBox').Tag = $true; & $updatePreview })

    # Mode radios
    $dlg.FindName('ModeProfile').Add_Checked({
        $dlg.FindName('ProfilePanel').Visibility = 'Visible'
        $dlg.FindName('DirPanel').Visibility = 'Collapsed'
    })
    $dlg.FindName('ModeDir').Add_Checked({
        $dlg.FindName('ProfilePanel').Visibility = 'Collapsed'
        $dlg.FindName('DirPanel').Visibility = 'Visible'
    })

    # Browse folder
    $dlg.FindName('BrowseBtn').Add_Click({
        Add-Type -AssemblyName System.Windows.Forms
        $fb = New-Object System.Windows.Forms.FolderBrowserDialog
        $fb.SelectedPath = if ($dlg.FindName('DirBox').Text) { $dlg.FindName('DirBox').Text } else { $env:LOCALAPPDATA }
        if ($fb.ShowDialog() -eq 'OK') { $dlg.FindName('DirBox').Text = $fb.SelectedPath }
    })

    # Detect identity via whois.py
    $dlg.FindName('DetectBtn').Add_Click({
        $d = $dlg.FindName('DirBox').Text
        if (-not $d -or -not (Test-Path $d)) {
            $dlg.FindName('DetectMsg').Text = 'Pick a valid folder first.'
            return
        }
        $dlg.FindName('DetectMsg').Text = 'Decrypting tokens...'
        try {
            $out = & python $script:WHOIS_SCRIPT $d 2>&1 | Out-String
            # Parse out email/name/plan lines
            foreach ($ln in $out -split "`n") {
                if ($ln -match 'email:\s*(.+)') { $dlg.FindName('EmailBox').Text = $Matches[1].Trim() }
                elseif ($ln -match 'name:\s*(.+)') { $dlg.FindName('NameBox').Text = $Matches[1].Trim() }
                elseif ($ln -match 'plan:\s*(\S+)\s*\((.+)\)') {
                    $tier = $Matches[2].Trim()
                    if ($tier -match 'max_(\d+)x') { $dlg.FindName('PlanBox').Text = "Max $($Matches[1])x" }
                    elseif ($Matches[1] -match 'Pro') { $dlg.FindName('PlanBox').Text = 'Pro' }
                    else { $dlg.FindName('PlanBox').Text = $Matches[1].Trim() }
                }
            }
            $dlg.FindName('DetectMsg').Text = 'Done.'
        } catch {
            $dlg.FindName('DetectMsg').Text = "whois.py failed: $_"
        }
    })

    # Swatches
    $swatchPanel = $dlg.FindName('SwatchPanel')
    foreach ($hex in $script:SWATCHES) {
        $sw = New-Object Windows.Controls.Border
        $sw.Width = 28; $sw.Height = 28
        $sw.CornerRadius = '14'
        $sw.Background = Brush $hex
        $sw.Margin = '0,0,6,6'
        $sw.Cursor = [Windows.Input.Cursors]::Hand
        $sw.BorderThickness = if ($hex -eq $accentChoice) { '3' } else { '0' }
        $sw.BorderBrush = Brush '#fafafa'
        $hexCopy = $hex
        $sw.Tag = $hexCopy
        $sw.Add_MouseLeftButtonUp({
            $accentChoice = $this.Tag
            foreach ($child in $swatchPanel.Children) {
                $child.BorderThickness = if ($child.Tag -eq $accentChoice) { '3' } else { '0' }
            }
            & $updatePreview
        }.GetNewClosure())
        [void]$swatchPanel.Children.Add($sw)
    }

    # Save / Cancel
    $dlg.FindName('CancelBtn').Add_Click({ $script:dialogResult = $null; $dlg.Close() })
    $dlg.FindName('SaveBtn').Add_Click({
        $name = $dlg.FindName('NameBox').Text.Trim()
        if (-not $name) { $dlg.FindName('ValidationMsg').Text = 'Name is required.'; return }
        $mode = if ($dlg.FindName('ModeProfile').IsChecked) { 'profile' } else { 'user-data-dir' }
        if ($mode -eq 'profile') {
            $key = $dlg.FindName('KeyBox').Text.Trim()
            if (-not ($key -match '^[A-Za-z0-9_\-]{1,40}$')) {
                $dlg.FindName('ValidationMsg').Text = 'Profile key must be 1-40 chars: letters, digits, _, -.'
                return
            }
            $dir = Join-Path (Join-Path $env:LOCALAPPDATA 'Claude-Data-Profiles') $key
        } else {
            $dir = $dlg.FindName('DirBox').Text.Trim()
            if (-not $dir) { $dlg.FindName('ValidationMsg').Text = 'Folder is required for attach mode.'; return }
        }
        $script:dialogResult = @{
            Id     = if ($mode -eq 'profile') { $dlg.FindName('KeyBox').Text.Trim() } else { $existing.Id }
            Name   = $name
            Email  = $dlg.FindName('EmailBox').Text.Trim()
            Plan   = $dlg.FindName('PlanBox').Text.Trim()
            Accent = $accentChoice
            Dir    = $dir
            Mode   = $mode
        }
        $dlg.Close()
    })

    & $updatePreview
    [void]$dlg.ShowDialog()

    if ($isNew -and $script:dialogResult) {
        $script:PROFILES = @($script:PROFILES) + ,$script:dialogResult
        Save-Profiles
        Rebuild-Cards
    }
    return $script:dialogResult
}

# -----------------------------------------------------------------------------
# Hints and help
# -----------------------------------------------------------------------------
$script:HINTS = @(
    'Press 1-9 to launch an account by its keycap number.',
    'Shift+1-9 closes an account. Ctrl+1-9 opens its folder.',
    'Right-click a card to Edit, Duplicate, Move or Remove it.',
    '"Who is signed in?" in the right-click menu runs whois.py locally and shows the live account identity.',
    'Ctrl+N adds an account. Ctrl+L launches all; Ctrl+W closes all.',
    'The dot: gray = not running, green = running. Running cards get an accent-colored border.',
    'The number next to the plus (+2 processes) counts live Claude.exe helpers; one window spawns many.'
)

function Show-NextHint {
    if (-not $script:PREFS.hintsEnabled) {
        $window.FindName('HintStrip').Visibility = 'Collapsed'
        return
    }
    $i = [int]$script:PREFS.hintIndex % $script:HINTS.Count
    $window.FindName('HintText').Text = $script:HINTS[$i]
    $script:PREFS.hintIndex = ($i + 1) % $script:HINTS.Count
}

function Show-Help {
    $txt = @'
Claude Account Launcher - Help

Keyboard shortcuts:
  1-9          Launch account N
  Shift+1-9    Close account N
  Ctrl+1-9     Open account N's folder
  Ctrl+N       Add new account
  Ctrl+L       Launch all
  Ctrl+W       Close all
  F1           This help
  Esc          Close launcher

Right-click any card for Edit / Duplicate / Move / Who is signed in / Remove.

Dot color:
  gray   not running
  green  running (count shown)

Running cards get an accent-colored border and show RAM + uptime.

Config file:  profiles.json  (next to launcher.ps1)
Full docs:    docs\  folder
'@
    [Windows.MessageBox]::Show($txt, 'Help', 'OK', 'Information') | Out-Null
}

# -----------------------------------------------------------------------------
# Wire-up
# -----------------------------------------------------------------------------
Rebuild-Cards
Show-NextHint

$window.FindName('LaunchAll').Add_Click({
    foreach ($p in $script:PROFILES) { Launch-Profile $p.Dir $p.Mode; Start-Sleep -Milliseconds 400 }
    Update-Status
})
$window.FindName('CloseAll').Add_Click({
    foreach ($p in $script:PROFILES) { Close-Profile $p.Dir }
    Start-Sleep -Milliseconds 400
    Update-Status
})
$window.FindName('HelpBtn').Add_Click({ Show-Help })
$window.FindName('HintDismiss').Add_Click({
    $script:PREFS.hintsEnabled = $false
    Save-Prefs
    $window.FindName('HintStrip').Visibility = 'Collapsed'
})

$window.Add_PreviewKeyDown({
    param($sender, $e)
    $src = $e.OriginalSource
    if ($src -is [Windows.Controls.TextBox] -or $src -is [Windows.Controls.PasswordBox]) { return }
    $ctrl  = ([Windows.Input.Keyboard]::Modifiers -band [Windows.Input.ModifierKeys]::Control) -ne 0
    $shift = ([Windows.Input.Keyboard]::Modifiers -band [Windows.Input.ModifierKeys]::Shift) -ne 0
    if ($e.Key -eq [Windows.Input.Key]::Escape) { $window.Close(); $e.Handled = $true; return }
    if ($e.Key -eq [Windows.Input.Key]::F1) { Show-Help; $e.Handled = $true; return }
    if ($ctrl -and $e.Key -eq [Windows.Input.Key]::N) { Invoke-AddAccountDialog; $e.Handled = $true; return }
    if ($ctrl -and $e.Key -eq [Windows.Input.Key]::L) { $window.FindName('LaunchAll').RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Primitives.ButtonBase]::ClickEvent)); $e.Handled = $true; return }
    if ($ctrl -and $e.Key -eq [Windows.Input.Key]::W) { $window.FindName('CloseAll').RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Primitives.ButtonBase]::ClickEvent)); $e.Handled = $true; return }
    $kv = [int]$e.Key
    $d1 = [int][Windows.Input.Key]::D1
    $d9 = [int][Windows.Input.Key]::D9
    $np1 = [int][Windows.Input.Key]::NumPad1
    $np9 = [int][Windows.Input.Key]::NumPad9
    $idx = -1
    if ($kv -ge $d1 -and $kv -le $d9)    { $idx = $kv - $d1 }
    elseif ($kv -ge $np1 -and $kv -le $np9) { $idx = $kv - $np1 }
    if ($idx -ge 0 -and $idx -lt $script:PROFILES.Count) {
        if ($ctrl)      { Start-Process explorer.exe -ArgumentList ('"' + $script:PROFILES[$idx].Dir + '"') }
        elseif ($shift) { Close-ByIndex $idx }
        else            { Launch-ByIndex $idx }
        $e.Handled = $true
    }
})

$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(2)
$timer.Add_Tick({ Update-Status })
$timer.Start()

$hintTimer = New-Object Windows.Threading.DispatcherTimer
$hintTimer.Interval = [TimeSpan]::FromSeconds(10)
$hintTimer.Add_Tick({ Show-NextHint })
$hintTimer.Start()

Save-Profiles  # seed profiles.json on first run

[void]$window.ShowDialog()
