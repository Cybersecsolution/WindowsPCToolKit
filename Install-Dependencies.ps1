# ===============================================================
# Install-Dependencies.ps1
# PowerShell Installer for PC Maintenance Toolkit Dependencies
# ===============================================================

# --- Ensure the script is run as Administrator ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "Re-launching script as Administrator..." -ForegroundColor Yellow
    $arguments = "-NoExit -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

# --- Set PowerShell window colors: black background, white text ---
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# --- Function to pause execution until a key is pressed ---
function Pause-ForKey {
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# 1. Check for Python
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "Python: Not Installed" -ForegroundColor Red
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id Python.Python.3 -e | Out-Null
        Start-Sleep -Seconds 10
        Write-Host "Python: Installed" -ForegroundColor Green
    }
    else {
        Write-Host "winget: Not Installed" -ForegroundColor Red
        Write-Host "Please install Python manually from: https://www.python.org/downloads/" -ForegroundColor Red
        Pause-ForKey
        exit
    }
}
else {
    Write-Host "Python: Installed" -ForegroundColor Green
}

# 2. Upgrade pip and install required Python modules
python -m pip install --upgrade pip | Out-Null
Write-Host "pip: Upgraded" -ForegroundColor Green
python -m pip install psutil colorama | Out-Null
Write-Host "psutil and colorama: Installed" -ForegroundColor Green

# 3. Ensure winget is available
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget: Not Installed" -ForegroundColor Red
    Write-Host "Please install external dependencies manually." -ForegroundColor Red
    Pause-ForKey
    exit
}
else {
    Write-Host "winget: Installed" -ForegroundColor Green
}

# 4. Check and Install Speedtest CLI
if (-not (Get-Command speedtest -ErrorAction SilentlyContinue)) {
    winget install --id Ookla.Speedtest.CLI -e | Out-Null
    Start-Sleep -Seconds 10
    Write-Host "Speedtest CLI: Installed" -ForegroundColor Green
}
else {
    Write-Host "Speedtest CLI: Installed" -ForegroundColor Green
}

# 5. Check and Install Nmap
if (-not (Get-Command nmap -ErrorAction SilentlyContinue)) {
    $NMAP_INSTALLER = "C:\Windows\Temp\nmap-setup.exe"
    Invoke-WebRequest -Uri "https://nmap.org/dist/nmap-7.80-setup.exe" -OutFile $NMAP_INSTALLER
    Start-Process -FilePath $NMAP_INSTALLER -ArgumentList "/S" -Wait
    if (-not (Get-Command nmap -ErrorAction SilentlyContinue)) {
        if (Test-Path "C:\Program Files (x86)\Nmap\nmap.exe") {
            Write-Host "Nmap: Installed (Not in PATH)" -ForegroundColor Green
        }
        else {
            Write-Host "Nmap: Installation Failed" -ForegroundColor Red
            Pause-ForKey
            exit
        }
    }
    else {
        Write-Host "Nmap: Installed" -ForegroundColor Green
    }
}
else {
    Write-Host "Nmap: Installed" -ForegroundColor Green
}

# 6. Check and Install WSL (Windows Subsystem for Linux)
$wslExe = Join-Path $env:windir "System32\wsl.exe"
if (-not (Test-Path $wslExe)) {
    Write-Host "WSL: Not Installed" -ForegroundColor Red
    wsl --install | Out-Null
    Start-Sleep -Seconds 1   # Reduced sleep duration
    Write-Host "WSL: Installation Initiated. Please reboot to complete installation." -ForegroundColor Green
}
else {
    Write-Host "WSL: Installed" -ForegroundColor Green
}

# 7. Check and Install MTR (WinMTR)
if (-not (Get-Command mtr -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id WinMTR.WinMTR -e | Out-Null
        Start-Sleep -Seconds 1   # Reduced sleep duration
        Write-Host "MTR (WinMTR): Installed" -ForegroundColor Green
    }
    else {
        Write-Host "winget: Not Installed" -ForegroundColor Red
        Write-Host "Please install WinMTR manually from: https://sourceforge.net/projects/winmtr/" -ForegroundColor Red
        Pause-ForKey
        exit
    }
}
else {
    Write-Host "MTR (WinMTR): Installed" -ForegroundColor Green
}

# 8. Check and Install Paping
$papingCmd = Get-Command paping.exe -ErrorAction SilentlyContinue
if (-not $papingCmd) {
    $userProfile = $env:USERPROFILE
    $defaultPath = Join-Path $userProfile "paping.exe"
    if (-not (Test-Path $defaultPath)) {
        Write-Host "Paping is not installed." -ForegroundColor Yellow
        $installChoice = Read-Host "Do you want to download and install Paping? (yes/no)"
        if ($installChoice.ToLower() -eq "yes") {
            $papingURL  = "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/paping/paping_1.5.5_x86_windows.zip"
            Write-Host "Downloading Paping..." -ForegroundColor Yellow
            $zipPath = Join-Path $env:TEMP "Paping.zip"
            Invoke-WebRequest -Uri $papingURL -OutFile $zipPath
            Write-Host "Extracting Paping..." -ForegroundColor Yellow
            Expand-Archive -Path $zipPath -DestinationPath $userProfile -Force
            Remove-Item $zipPath
            Write-Host "Paping installed successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Paping installation aborted. Exiting." -ForegroundColor Yellow
            Pause-ForKey
            exit
        }
    }
    else {
        Write-Host "Paping is installed." -ForegroundColor Green
    }
}
else {
    Write-Host "Paping is already installed." -ForegroundColor Green
}

# 9. Check and Install tshark (Wireshark)
if (-not (Get-Command tshark -ErrorAction SilentlyContinue)) {
    Write-Host "tshark: Not Installed" -ForegroundColor Red
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id WiresharkFoundation.Wireshark -e | Out-Null
        Start-Sleep -Seconds 10
        # Check again if tshark is now available
        if (-not (Get-Command tshark -ErrorAction SilentlyContinue)) {
            # If still not detected, attempt to add Wireshark's default installation folder to PATH
            $wsPath = "C:\Program Files\Wireshark"
            if (Test-Path "$wsPath\tshark.exe") {
                Write-Host "tshark not detected. Adding $wsPath to PATH..." -ForegroundColor Yellow
                $newPath = $env:PATH + ";$wsPath"
                [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
                $env:PATH = $newPath
                if (Get-Command tshark -ErrorAction SilentlyContinue) {
                    Write-Host "tshark is now detected." -ForegroundColor Green
                }
                else {
                    Write-Host "tshark still not detected even after adding to PATH." -ForegroundColor Red
                    Pause-ForKey
                    exit
                }
            }
            else {
                Write-Host "tshark executable not found in $wsPath. Please verify Wireshark installation." -ForegroundColor Red
                Pause-ForKey
                exit
            }
        }
        else {
            Write-Host "tshark (Wireshark) installed successfully." -ForegroundColor Green
        }
    }
    else {
        Write-Host "winget is not available. Please install Wireshark (which includes tshark) manually and add it to your PATH." -ForegroundColor Red
        Pause-ForKey
        exit
    }
}
else {
    Write-Host "tshark: Installed" -ForegroundColor Green
}

# 10. Check and Install iftop in WSL (Silent)
if (Test-Path $wslExe) {
    # --- Disable Ookla Speedtest repository in WSL if it exists ---
    wsl bash -c "if [ -f /etc/apt/sources.list.d/ookla-speedtest-cli.list ]; then sudo mv /etc/apt/sources.list.d/ookla-speedtest-cli.list /etc/apt/sources.list.d/ookla-speedtest-cli.list.disabled; fi"

    # Try to see if iftop is installed (no messages)
    $iftopCheck = wsl which iftop 2>&1
    if ($LASTEXITCODE -ne 0 -or -not $iftopCheck) {
        # Install iftop silently
        wsl sudo apt-get update -y | Out-Null
        wsl sudo apt-get install iftop -y | Out-Null
    }
    
    # --- Install traceroute and whois in WSL ---
    wsl sudo apt-get update -y | Out-Null
    wsl sudo apt-get install traceroute whois -y | Out-Null
}
# If no WSL, we silently skip

Write-Host "==================================================================" -ForegroundColor Green
Write-Host "All dependencies installed successfully!" -ForegroundColor Green
Pause-ForKey

# --- Forcefully close the window ---
Stop-Process -Id $PID
