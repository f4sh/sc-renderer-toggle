Add-Type -AssemblyName PresentationFramework

# --- BUILD SELECTION WINDOW ---
$buildWindow = New-Object System.Windows.Window
$buildWindow.Title = "Star Citizen Renderer"
$buildWindow.Width = 320
$buildWindow.Height = 150
$buildWindow.WindowStartupLocation = "CenterScreen"
$buildWindow.ResizeMode = "NoResize"

$stack = New-Object System.Windows.Controls.StackPanel
$stack.Margin = "15"

$text = New-Object System.Windows.Controls.TextBlock
$text.Text = "Select build:"
$text.Margin = "0,0,0,15"
$stack.Children.Add($text)

$buttons = New-Object System.Windows.Controls.StackPanel
$buttons.Orientation = "Horizontal"
$buttons.HorizontalAlignment = "Center"

$btnLive = New-Object System.Windows.Controls.Button
$btnLive.Content = "LIVE"
$btnLive.Width = 100
$btnLive.Margin = "5"

$btnPtu = New-Object System.Windows.Controls.Button
$btnPtu.Content = "PTU"
$btnPtu.Width = 100
$btnPtu.Margin = "5"

$buttons.Children.Add($btnLive)
$buttons.Children.Add($btnPtu)
$stack.Children.Add($buttons)

$buildWindow.Content = $stack

$build = $null
$btnLive.Add_Click({ $buildWindow.Tag = "LIVE"; $buildWindow.DialogResult = $true })
$btnPtu.Add_Click({ $buildWindow.Tag = "PTU"; $buildWindow.DialogResult = $true })

$buildWindow.ShowDialog() | Out-Null
$build = $buildWindow.Tag
if (-not $build) { exit }


# --- RENDERER WINDOW ---
$window = New-Object System.Windows.Window
$window.Title = "Star Citizen Renderer"
$window.Width = 320
$window.Height = 150
$window.WindowStartupLocation = "CenterScreen"
$window.ResizeMode = "NoResize"

$stack = New-Object System.Windows.Controls.StackPanel
$stack.Margin = "15"

$text = New-Object System.Windows.Controls.TextBlock
$text.Text = "Choose renderer option:"
$text.Margin = "0,0,0,15"
$stack.Children.Add($text)

$buttons = New-Object System.Windows.Controls.StackPanel
$buttons.Orientation = "Horizontal"
$buttons.HorizontalAlignment = "Center"

$btnForce = New-Object System.Windows.Controls.Button
$btnForce.Content = "Force renderer 0"
$btnForce.Width = 120
$btnForce.Margin = "5"

$btnRemove = New-Object System.Windows.Controls.Button
$btnRemove.Content = "Remove override"
$btnRemove.Width = 120
$btnRemove.Margin = "5"

$buttons.Children.Add($btnForce)
$buttons.Children.Add($btnRemove)
$stack.Children.Add($buttons)

$window.Content = $stack

$choice = $null
$btnForce.Add_Click({ $window.Tag = "force"; $window.DialogResult = $true })
$btnRemove.Add_Click({ $window.Tag = "remove"; $window.DialogResult = $true })

$window.ShowDialog() | Out-Null
$choice = $window.Tag
if (-not $choice) { exit }


# --- FIND INSTALL ---
$relative = "Roberts Space Industries\StarCitizen\$build\user.cfg"
$programFolders = @("C:\Program Files", "C:\Program Files (x86)")

$userCfgPath = $null

# First search only Program Files
foreach ($pf in $programFolders) {
    $candidate = Join-Path $pf $relative
    if (Test-Path $candidate) {
        $userCfgPath = $candidate
        break
    }
}

# If not found, expand search but only RSI folder
if (-not $userCfgPath) {
    foreach ($d in Get-PSDrive -PSProvider FileSystem) {
        $base = Join-Path $d.Root "Roberts Space Industries\StarCitizen\$build"
        if (Test-Path $base) {
            $userCfgPath = Join-Path $base "user.cfg"
            break
        }
    }
}

if (-not $userCfgPath) {
    [System.Windows.MessageBox]::Show("Build not found.", "Star Citizen Renderer")
    exit
}

# --- MODIFY CONFIG ---
$content = Get-Content $userCfgPath -ErrorAction SilentlyContinue |
    Where-Object { $_ -notmatch '^\s*r\.graphicsRenderer\s*=' }

if ($choice -eq "force") {
    $content += "r.graphicsRenderer = 0"
    $msg = "$build renderer override enabled."
}
else {
    $msg = "$build renderer override removed."
}

$content | Set-Content -Path $userCfgPath -Encoding UTF8

# --- CONFIRM ---
[System.Windows.MessageBox]::Show($msg, "Star Citizen Renderer")
