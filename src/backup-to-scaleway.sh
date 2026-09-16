#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"
LOG_FILE="${LOG_FILE:-/mnt/data/samba/share/Backups/backup-scaleway.log}"
LOCK_FILE="${SCRIPT_DIR}/backup-scaleway.lock"

BACKUP_PATH="/mnt/data"
EXCLUDES=(
  --exclude="/mnt/data/netdata"
  --exclude="/mnt/data/prometheus"
  --exclude="/mnt/data/grafana"
  --exclude="/mnt/data/portainer/backups"
  --exclude="/mnt/data/navidrome/data/plugins"
  --exclude="*/cache"
  --exclude="*.tmp"
  --exclude="*.log"
)
RETENTION=(
  --keep-daily 7
  --keep-weekly 5
  --keep-monthly 12
)

# Scaleway storage class: ONEZONE_IA (Standard One Zone) or STANDARD (Multi-AZ)
STORAGE_CLASS="${STORAGE_CLASS:-ONEZONE_IA}"

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$LOCK_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

log() {
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
}

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "ERROR: another backup instance is already running, aborting."
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  log "ERROR: env file not found at $ENV_FILE."
  log "       Set ENV_FILE in the crontab or edit this script to point at it."
  exit 1
fi
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${SCW_ACCESS_KEY:?SCW_ACCESS_KEY must be set in $ENV_FILE}"
: "${SCW_SECRET_KEY:?SCW_SECRET_KEY must be set in $ENV_FILE}"
: "${RESTIC_REPOSITORY:?RESTIC_REPOSITORY must be set in $ENV_FILE}"
: "${RESTIC_PASSWORD:?RESTIC_PASSWORD must be set in $ENV_FILE}"

export AWS_ACCESS_KEY_ID="$SCW_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SCW_SECRET_KEY"
export RESTIC_REPOSITORY RESTIC_PASSWORD

if ! command -v restic >/dev/null 2>&1; then
  log "restic not found on PATH, installing via apt..."
  apt-get update -qq && apt-get install -y restic
fi

if ! restic cat config >/dev/null 2>&1; then
  log "Repository not initialized yet, running 'restic init' for $RESTIC_REPOSITORY ..."
  restic init -o s3.storage-class="$STORAGE_CLASS"
fi

if pgrep -x rsync >/dev/null 2>&1; then
  log "WARNING: the local rsync to /mnt/backup is still running, skipping this run."
  exit 0
fi

log "Starting restic backup of $BACKUP_PATH (storage class: $STORAGE_CLASS) ..."
restic backup "$BACKUP_PATH" "${EXCLUDES[@]}" \
  -o s3.storage-class="$STORAGE_CLASS"

log "Applying retention policy and pruning unreferenced data ..."
restic forget --prune "${RETENTION[@]}" \
  -o s3.storage-class="$STORAGE_CLASS"

log "Remote backup complete."
