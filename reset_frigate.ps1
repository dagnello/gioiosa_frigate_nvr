param(
  [switch]$FullReset  # Pass -FullReset to also delete media + (most) config
)

# ----- Helpers -----
function Remove-ContainerIfExists {
  param([string]$Name)
  $ids = docker ps -a --filter "name=^/$Name$" -q
  if ($ids) {
    Write-Host "Removing existing container '$Name' ($ids)..."
    docker rm -f $ids | Out-Null
  }
}

# ----- Always run from script folder -----
Set-Location -Path $PSScriptRoot

# Support compose.yaml or docker-compose.yaml
$composeFileCandidates = @(
  (Join-Path $PSScriptRoot "compose.yaml"),
  (Join-Path $PSScriptRoot "docker-compose.yaml"),
  (Join-Path $PSScriptRoot "docker-compose.yml")
)
$composeFile = $composeFileCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $composeFile) {
  Write-Error "No compose file found (compose.yaml or docker-compose.yaml) in $PSScriptRoot"
  exit 1
}

Write-Host "Stopping and removing Frigate stack (and orphans)..."
docker compose -f $composeFile down --remove-orphans

# Clean up any stragglers that might conflict with names
Remove-ContainerIfExists -Name "frigate"
Remove-ContainerIfExists -Name "frigate-backup"

if ($FullReset) {
  Write-Host "Full reset: clearing media and most config..."

  $dbFiles = @(
    ".\config\frigate.db",
    ".\config\frigate.db-shm",
    ".\config\frigate.db-wal"
  )
  foreach ($f in $dbFiles) {
    if (Test-Path $f) {
      Write-Host "Removing $f"
      Remove-Item -Force $f
    }
  }

  # Handle both layouts:
  #   - ./media/{clips,recordings,cache}
  #   - ./media/frigate/{clips,recordings,cache}
  $mediaRoots = @(".\media", ".\media\frigate")
  $mediaGlobs = @("clips\*", "recordings\*", "cache\*")
  foreach ($root in $mediaRoots) {
    foreach ($glob in $mediaGlobs) {
      $path = Join-Path $root $glob
      if (Test-Path $path) {
        Write-Host "Clearing $path"
        Remove-Item -Recurse -Force $path
      }
    }
  }

  # Wipe config EXCEPT config.yaml (so Frigate still has a valid config)
  if (Test-Path ".\config") {
    Get-ChildItem ".\config" -Recurse |
      Where-Object { $_.PSIsContainer -or $_.Name -notmatch '^config\.yaml$' } |
      Remove-Item -Recurse -Force
  }
} else {
  Write-Host "Partial reset: keeping media and config."
}

Write-Host "Starting stack..."
docker compose -f $composeFile up -d --remove-orphans

Write-Host "Tailing Frigate logs..."
docker compose -f $composeFile logs -f frigate
