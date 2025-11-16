# Cross-platform backup script for Windows PowerShell

param(
  [string]$PRIVATE_KEY_PATH,
  [string]$USER,
  [string]$INSTANCE_IP,
  [string]$BACKUP_PATH
)

$ErrorActionPreference = "Continue"

# Fallback to environment variables if parameters not provided
if (-not $PRIVATE_KEY_PATH) { $PRIVATE_KEY_PATH = $env:PRIVATE_KEY_PATH }
if (-not $USER) { $USER = $env:USER }
if (-not $INSTANCE_IP) { $INSTANCE_IP = $env:INSTANCE_IP }
if (-not $BACKUP_PATH) { $BACKUP_PATH = $env:BACKUP_PATH }

if (-not $PRIVATE_KEY_PATH -or -not $USER -or -not $INSTANCE_IP -or -not $BACKUP_PATH) {
  Write-Error "Error: Required parameters not set"
  exit 1
}

# Find ssh.exe
$sshPath = $null
$sshCmd = Get-Command ssh -ErrorAction SilentlyContinue
if ($sshCmd) {
  $sshPath = $sshCmd.Source
} else {
  # Try common locations
  $commonPaths = @(
    "$env:ProgramFiles\OpenSSH\ssh.exe",
    "$env:ProgramFiles(x86)\OpenSSH\ssh.exe",
    "C:\Windows\System32\OpenSSH\ssh.exe",
    "$env:SystemRoot\System32\OpenSSH\ssh.exe"
  )
  foreach ($path in $commonPaths) {
    if (Test-Path $path) {
      $sshPath = $path
      break
    }
  }
}

if (-not $sshPath) {
  Write-Error "ssh.exe not found. Please install OpenSSH or add it to PATH."
  exit 1
}

Write-Host "Using SSH: $sshPath"

# Resolve backup directory path
$backupDir = Resolve-Path -Path $BACKUP_PATH -ErrorAction SilentlyContinue
if (-not $backupDir) {
  $backupDir = Join-Path (Get-Location) $BACKUP_PATH
}
$backupDir = $backupDir.ToString()

if (-not (Test-Path $backupDir)) {
  New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
}

if (-not (Test-Path $backupDir)) {
  Write-Error "Failed to create backup directory: $backupDir"
  exit 1
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$year = Get-Date -Format "yyyy"
$yearDir = Join-Path $backupDir $year

Write-Host "Backup directory: $backupDir"
Write-Host "Starting backup at $timestamp"

# Create year directory if it doesn't exist
if (-not (Test-Path $yearDir)) {
  New-Item -ItemType Directory -Force -Path $yearDir | Out-Null
}

# Download files from server (one connection per file)
Write-Host "Downloading wg0.conf from server..."
$confContent = & $sshPath -i $PRIVATE_KEY_PATH -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL "$USER@$INSTANCE_IP" "sudo cat /home/$USER/.amnezia-wg-easy/wg0.conf" 2>&1
if ($LASTEXITCODE -eq 0) {
  # Save as latest (without timestamp) for restore
  $confContent | Out-File -FilePath "$backupDir/wg0.conf" -Encoding utf8 -NoNewline
  Write-Host "wg0.conf downloaded"
  # Create timestamped copy in year directory
  Copy-Item -Path "$backupDir/wg0.conf" -Destination "$yearDir/wg0.conf.backup.$timestamp"
  Write-Host "wg0.conf backup with timestamp created in $yearDir"
} else {
  Write-Warning "Failed to download wg0.conf: $confContent"
}

Write-Host "Downloading wg0.json from server..."
$jsonContent = & $sshPath -i $PRIVATE_KEY_PATH -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL "$USER@$INSTANCE_IP" "sudo cat /home/$USER/.amnezia-wg-easy/wg0.json" 2>&1
if ($LASTEXITCODE -eq 0) {
  # Save as latest (without timestamp) for restore
  $jsonContent | Out-File -FilePath "$backupDir/wg0.json" -Encoding utf8 -NoNewline
  Write-Host "wg0.json downloaded"
  # Create timestamped copy in year directory
  Copy-Item -Path "$backupDir/wg0.json" -Destination "$yearDir/wg0.json.backup.$timestamp"
  Write-Host "wg0.json backup with timestamp created in $yearDir"
} else {
  Write-Warning "Failed to download wg0.json: $jsonContent"
}

Write-Host "Backup completed"

