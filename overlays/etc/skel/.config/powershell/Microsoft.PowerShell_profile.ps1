# Hemo: PowerShell uses the same Starship prompt as zsh, so it follows whatever
# is picked in Appearance > Prompt (~/.config/starship.toml) and the theme colors.
# Falls back to Kali's two-line prompt if starship is missing.

# hemo:engagement — `eng` is a wrapper (not a plain alias) so it can cd into
# the engagement directory after `use` or `new`. Everything else passes through.
function eng {
  hemo-engagement @args
  if ($args.Count -gt 0 -and ($args[0] -eq 'use' -or $args[0] -eq 'new')) {
    $d = & hemo-engagement path 2>$null
    if ($LASTEXITCODE -eq 0 -and $d -and (Test-Path -LiteralPath $d)) { Set-Location $d }
  }
}

# hemo:fetch — the Hemo lizard + system info when a terminal opens, like zsh. Only
# in a real terminal (not pwsh -c / -File scripts, pipes or Neovim). Turn it off
# for one shell with HEMO_NO_FETCH=1.
$hemoScript = [Environment]::GetCommandLineArgs() | Where-Object { $_ -match '^-(c|command|f|file|ec|encodedcommand)$' }
if (-not $hemoScript -and -not [Console]::IsOutputRedirected -and -not $env:HEMO_NO_FETCH -and -not $env:NVIM -and
    (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
  fastfetch
}
Remove-Variable hemoScript

# hemo:keys — line editing like the zsh setup: ctrl+arrows jump words, Tab opens a
# completion menu, history suggestions in palette color 8 (zsh-autosuggestions'
# fg=8). PSReadLine's defaults assume a dark background (typed text in color 7,
# a fixed dark-grey list highlight), so plain text uses the terminal foreground
# and the F2 list view highlights in reverse video; both modes stay readable.
if (Get-Module PSReadLine) {
  Set-PSReadLineOption -EditMode Emacs -Colors @{
    InlinePrediction       = "`e[90m"
    Default                = "`e[39m"
    Type                   = "`e[39m"
    Member                 = "`e[39m"
    ContinuationPrompt     = "`e[39m"
    ListPredictionSelected = "`e[7m"
    ListPredictionTooltip  = "`e[90;3m"
  }
  Set-PSReadLineKeyHandler -Chord Ctrl+LeftArrow  -Function BackwardWord
  Set-PSReadLineKeyHandler -Chord Ctrl+RightArrow -Function ForwardWord
  Set-PSReadLineKeyHandler -Chord Tab             -Function MenuComplete
}

# hemo:stamp — stamp each command's execution time right before it runs, ONLY
# when an engagement is active. Pulls the same configuration zsh does
# (~/.config/hemo/stamp-format and stamp-tz; $env:HEMO_STAMP = '0' disables for
# one shell; an empty stamp-format file means both date and time are off). Also
# records the IP a target would see at that moment (shield + VPN IP when the
# tunnel is up, arrow + public egress when it is not), via `hemo-bar-ip stamp`.
# AddToHistoryHandler fires once per Enter at the interactive prompt only, so
# `pwsh -c` / `pwsh -File` and non-interactive hosts stay silent.
function global:__hemo_stamp {
  if ($env:HEMO_STAMP -eq '0') { return }
  $null = & hemo-engagement path 2>$null
  if ($LASTEXITCODE -ne 0) { return }
  $cfg  = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { "$HOME/.config" }
  $ff  = Join-Path $cfg 'hemo/stamp-format'
  $tzf = Join-Path $cfg 'hemo/stamp-tz'
  $fmt = $null
  if (Test-Path -LiteralPath $ff) {
    if ((Get-Item -LiteralPath $ff).Length -gt 0) {
      $fmt = ((Get-Content -LiteralPath $ff -TotalCount 1) -replace '[\r\n]+$','')
    } else { return }   # explicitly empty: date + time both off
  } else {
    $fmt = '%Y-%m-%d %H:%M:%S'
  }
  $tz = ''
  if ((Test-Path -LiteralPath $tzf) -and (Get-Item -LiteralPath $tzf).Length -gt 0) {
    $tz = ((Get-Content -LiteralPath $tzf -TotalCount 1) -replace '[\r\n]+$','')
  }
  $stamp = if ($tz) { & env "TZ=$tz" date "+$fmt" } else { & date "+$fmt" }
  $ipseg = ''
  if (Get-Command hemo-bar-ip -ErrorAction SilentlyContinue) {
    $s = & hemo-bar-ip stamp 2>$null
    if ($s) { $ipseg = " · $s" }
  }
  Write-Host "`e[38;5;8m── $stamp$ipseg ──`e[0m"
}
if (Get-Module PSReadLine) {
  Set-PSReadLineOption -AddToHistoryHandler {
    param($line)
    if ($line -and $line.Trim()) { __hemo_stamp }
    return $true   # keep the normal history behavior
  }
}

# Window title "PS <dir>" so a PowerShell window is told apart from zsh in i3 and
# the bar. Starship calls this before each prompt; the fallback prompt calls it too.
function Invoke-Starship-PreCommand {
  $d = $PWD.ProviderPath
  if ($d -eq $HOME -or $d.StartsWith("$HOME/")) { $d = '~' + $d.Substring($HOME.Length) }
  $Host.UI.RawUI.WindowTitle = "PS $d"
}

$hemoStarship = (Get-Command starship -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if ($hemoStarship) {
  # Starship's full init script, cached (saves ~0.2s per window). Rebuilt when
  # starship is upgraded, i.e. whenever the binary is newer than the cache.
  $hemoCache = Join-Path ($env:XDG_CACHE_HOME ?? "$HOME/.cache") 'hemo/starship-init.ps1'
  if (-not (Test-Path $hemoCache) -or (Get-Item $hemoStarship).LastWriteTime -gt (Get-Item $hemoCache).LastWriteTime) {
    New-Item -ItemType Directory -Force -Path (Split-Path $hemoCache) | Out-Null
    & $hemoStarship init powershell --print-full-init | Out-File -Encoding utf8 $hemoCache
  }
  . $hemoCache
  Remove-Variable hemoStarship, hemoCache
  return
}
Remove-Variable hemoStarship

function prompt {
  Invoke-Starship-PreCommand
  $esc = [char]27
  $bold = "$esc[1m"
  $reset = "$esc[0m"
  Write-Host
  Write-Host "┌──(" -NoNewLine -ForegroundColor Blue
  Write-Host "${bold}$([environment]::username)㉿$([system.environment]::MachineName)${reset}" -NoNewLine -ForegroundColor Magenta
  Write-Host ")-[" -NoNewLine -ForegroundColor Blue
  Write-Host "${bold}$(Get-Location)${reset}" -NoNewLine -ForegroundColor White
  Write-Host "]" -ForegroundColor Blue
  Write-Host "└─" -NoNewLine -ForegroundColor Blue
  Write-Host "${bold}PS>${reset}" -NoNewLine -ForegroundColor Blue
  return " "
}
