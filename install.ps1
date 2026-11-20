# windows version of install.sh: copies the css, writes betterfox + user-overrides.js + layout.json to user.js,
# and policies.json (extensions, their settings and firefox policies) to firefox's policies.
# usage, from an admin powershell: powershell -ExecutionPolicy Bypass -File install.ps1 [-ProfileDir <dir>]
#Requires -RunAsAdministrator
param([string]$ProfileDir)
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
# no bom, firefox may not read json or user.js with one
$utf8 = New-Object System.Text.UTF8Encoding $false

function Write-Text([string]$path, [string]$text) {
  [IO.File]::WriteAllText($path, $text, $utf8)
}

# keep only the first backup, so a rerun can't replace the original with the theme
function Backup-Once([string]$path) {
  if ((Test-Path $path) -and -not (Test-Path "$path.bak")) { Copy-Item $path "$path.bak" }
}

# --- profile: from the argument or the profiles firefox knows about
if (-not $ProfileDir) {
  $root = Join-Path $env:APPDATA 'Mozilla\Firefox'
  $ini = Join-Path $root 'profiles.ini'
  if (-not (Test-Path $ini)) { throw 'no firefox profile found, pass its path as an argument' }
  $profiles = @(Get-Content $ini | Where-Object { $_ -like 'Path=*' } | ForEach-Object {
    $p = $_.Substring(5)
    if ([IO.Path]::IsPathRooted($p)) { $p } else { Join-Path $root $p }
  })
  if (-not $profiles) { throw 'no firefox profile found, pass its path as an argument' }
  # tst.css is only ever put there by this script, so it marks an existing install to update
  $installed = @($profiles | Where-Object { Test-Path (Join-Path $_ 'chrome\tst.css') })
  if ($installed) { $profiles = $installed }
  if ($profiles.Count -eq 1) {
    $ProfileDir = $profiles[0]
  } else {
    for ($i = 0; $i -lt $profiles.Count; $i++) { Write-Host "$($i + 1)) $($profiles[$i])" }
    do { $n = (Read-Host 'install into which profile?') -as [int] } until ($n -ge 1 -and $n -le $profiles.Count)
    $ProfileDir = $profiles[$n - 1]
  }
}
if (-not (Test-Path $ProfileDir -PathType Container)) { throw "not a directory: $ProfileDir" }
Write-Host "profile: $ProfileDir"

# --- css into the profile's chrome folder
$chrome = Join-Path $ProfileDir 'chrome'
New-Item -ItemType Directory -Force $chrome | Out-Null
foreach ($f in 'userChrome.css', 'userContent.css', 'tst.css') {
  $dst = Join-Path $chrome $f
  Backup-Once $dst
  Copy-Item (Join-Path $src $f) $dst
}

# --- user.js: betterfox, smoothfox's natural scrolling, user-overrides.js and the toolbar layout
# betterfox's user.js is the base and gets replaced on every run, so it stays at the latest version
$bf = 'https://raw.githubusercontent.com/yokoffing/Betterfox/main'
$betterfox = (Invoke-WebRequest -UseBasicParsing "$bf/user.js").Content -split "`r?`n"
$smoothfox = (Invoke-WebRequest -UseBasicParsing "$bf/Smoothfox.js").Content -split "`r?`n"
# smoothfox lists every scrolling option uncommented, so take just the natural one
$smooth = @(); $on = $false
foreach ($line in $smoothfox) {
  if ($line -match 'OPTION: NATURAL SMOOTH SCROLLING') { $on = $true; continue }
  if ($on -and $line -match '^/\*{4}') { break }
  if ($on -and $line -match '^user_pref') { $smooth += $line }
}
if (-not $smooth) { throw 'natural smooth scrolling section not found in Smoothfox.js' }

# the layout pref is the json as one escaped string
$layout = Get-Content -Raw (Join-Path $src 'layout.json') | ConvertFrom-Json | ConvertTo-Json -Depth 100 -Compress
$layoutPref = "user_pref(`"browser.uiCustomization.state`", $(ConvertTo-Json $layout));"
$overrides = @(Get-Content (Join-Path $src 'user-overrides.js')) + $layoutPref

# drop earlier lines for the prefs the theme sets, so its values win
$ours = @($overrides | Select-String '^user_pref\("[^"]*",' | ForEach-Object { $_.Matches[0].Value })
$base = @($betterfox + '' + '// smoothfox: natural smooth scrolling' + $smooth) | Where-Object {
  $line = $_
  -not ($ours | Where-Object { $line.Contains($_) })
}

$js = Join-Path $ProfileDir 'user.js'
Backup-Once $js
Write-Text $js ((@($base) + '' + $overrides) -join "`n")

# --- policies.json with tst.css added to tst's settings, merged into firefox's policies
# policies are per firefox install, not per profile; windows reads them from the install's distribution folder
$policies = Join-Path $env:ProgramFiles 'Mozilla Firefox\distribution\policies.json'

function Set-Prop($obj, [string]$name, $value) {
  $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value -Force
}
# shallow merge, like jq's +=: each key of $from replaces the old one whole
function Merge-Props($into, $from) {
  foreach ($p in $from.PSObject.Properties) { Set-Prop $into $p.Name $p.Value }
}
# the object at $obj.$name, created empty if missing
function Get-Child($obj, [string]$name) {
  if ($null -eq $obj.$name) { Set-Prop $obj $name ([pscustomobject]@{}) }
  $obj.$name
}

# tst stores its user style sheet base64 encoded, split into 6kb chunks over 8 slots, unused slots stay empty
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $src 'tst.css')))
if ($b64.Length -gt 8 * 6144) { throw 'tst.css is too large for tree style tab' }
$theme = Get-Content -Raw (Join-Path $src 'policies.json') | ConvertFrom-Json
$tst = $theme.policies.'3rdparty'.Extensions.'treestyletab@piro.sakura.ne.jp'
for ($i = 0; $i -lt 8; $i++) {
  $start = $i * 6144
  $chunk = if ($start -lt $b64.Length) { $b64.Substring($start, [Math]::Min(6144, $b64.Length - $start)) } else { '' }
  Set-Prop $tst "chunkedUserStyleRules$i" $chunk
}

if (Test-Path $policies) {
  # merge so other policies survive. each of our entries replaces its old one whole, a deep merge would keep
  # keys an earlier run wrote and this one dropped
  $out = Get-Content -Raw $policies | ConvertFrom-Json
  $old = Get-Child $out 'policies'
  foreach ($p in $theme.policies.PSObject.Properties) {
    if ($p.Name -notin 'ExtensionSettings', '3rdparty') { Set-Prop $old $p.Name $p.Value }
  }
  Merge-Props (Get-Child $old 'ExtensionSettings') $theme.policies.ExtensionSettings
  Merge-Props (Get-Child (Get-Child $old '3rdparty') 'Extensions') $theme.policies.'3rdparty'.Extensions
} else {
  $out = $theme
}
Write-Host "writing policies, extensions and their settings to $policies"
New-Item -ItemType Directory -Force (Split-Path $policies) | Out-Null
Backup-Once $policies
Write-Text $policies ($out | ConvertTo-Json -Depth 100)

Write-Host ''
Write-Host 'done, restart firefox to load it.'
