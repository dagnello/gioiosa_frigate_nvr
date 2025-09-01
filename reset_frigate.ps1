# reset-frigate.ps1
# Stop and remove the Frigate stack
docker compose down

# Remove Frigate database files (if they exist)
$files = @(
  ".\config\frigate.db",
  ".\config\frigate.db-shm",
  ".\config\frigate.db-wal"
)
foreach ($f in $files) {
    if (Test-Path $f) {
        Write-Host "Removing $f"
        Remove-Item -Force $f
    }
}

# Remove all existing recordings and snapshots
$mediaDirs = @(
  ".\media\clips\*",
  ".\media\recordings\*",
  ".\media\cache\*"
)
foreach ($d in $mediaDirs) {
    if (Test-Path $d) {
        Write-Host "Clearing $d"
        Remove-Item -Recurse -Force $d
    }
}

# Bring the stack back up
docker compose up -d

# Tail Frigate logs
docker compose logs -f frigate
