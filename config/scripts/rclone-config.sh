#!/usr/bin/env sh
set -eu
LOG="/tmp/rclone-config-$(date +%Y%m%d-%H%M%S).log"

rclone copy /config :s3,provider=AWS,env_auth=true,region=eu-west-3,no_check_bucket=true:gioiosa-security/frigate/config-backups \
  --fast-list --no-traverse \
  --transfers 2 --checkers 4 \
  --retries 3 --low-level-retries 3 --retries-sleep 2s \
  --s3-upload-concurrency 2 \
  --min-age 30s \
  --filter "+ /db-backups/**" \
  --filter "- /frigate.db" \
  --filter "- /frigate.db-shm" \
  --filter "- /frigate.db-wal" \
  --stats-one-line --stats 0 -v \
  --log-file "$LOG" --log-format "date,time" || RC=$?

RC=${RC:-0}

trim() { printf '%s' "$1" | tr -d '\r\n'; }
NEW=$(trim "$(grep -Ec 'Copied \(|Created dir:' "$LOG" 2>/dev/null || echo 0)")
UPD=$(trim "$(grep -Ec 'Updated \(|replaced existing' "$LOG" 2>/dev/null || echo 0)")
DEL=$(trim "$(grep -Ec '^.* Deleted ' "$LOG" 2>/dev/null || echo 0)")
ERR=$(trim "$(grep -c '^ERROR' "$LOG" 2>/dev/null || echo 0)")

echo "rclone-summary config: new=$NEW updated=$UPD deleted=$DEL errors=$ERR"
exit $RC