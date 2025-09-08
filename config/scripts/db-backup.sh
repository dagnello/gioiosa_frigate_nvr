#!/usr/bin/env sh
set -eu
mkdir -p /config/db-backups
TS="$(date +%Y%m%d-%H%M%S)"
sqlite3 /config/frigate.db ".timeout 15000" ".backup /config/db-backups/frigate-${TS}.db"
echo "dbbackup: wrote frigate-${TS}.db"
