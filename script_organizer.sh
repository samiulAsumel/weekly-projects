#!/bin/bash
# ==========================================================
# Intelligent Script Auto-Organizer (Event-Based)
# Author: AI-assisted | Operator: You
# ==========================================================

set -euo pipefail

# Resolve base directory dynamically (run from anywhere)
BASE_DIR="$(pwd)"
LOG_FILE="$BASE_DIR/script_organizer.log"
PID_FILE="$BASE_DIR/.organizer.pid"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo "$(date '+%F %T') - $1" >> "$LOG_FILE"
}

print_status() {
    echo -e "$1$2$NC"
}

# Cleanup function
cleanup() {
    local exit_code=$?
    print_status "$BLUE" "🛑 Cleaning up..."
    [[ -f "$PID_FILE" ]] && rm -f "$PID_FILE"
    log "Script organizer stopped (exit code: $exit_code)"
    exit $exit_code
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Check if already running
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    print_status "$RED" "✗ Script organizer is already running (PID: $(cat "$PID_FILE"))"
    exit 1
fi

# Write PID file
echo $$ > "$PID_FILE"
log "Script organizer started (PID: $$)"

# Detect script file
is_script() {
    local f="$1"
    [[ -f "$f" ]] || return 1

    case "${f##*.}" in
        sh|bash|py|yml|yaml|tf|json|pl|rb) return 0 ;;
    esac

    head -n1 "$f" 2>/dev/null | grep -q '^#!'
}

# Analyze script content
analyze_script() {
    local f="$1"
    local c
    c="$(tr '[:upper:]' '[:lower:]' < "$f")"

    declare -A rules=(
        [system]="systemctl mount umount useradd passwd lvm fdisk"
        [network]="ping nmap ssh iptables firewalld nmcli curl wget"
        [security]="selinux fail2ban audit chmod chown semanage"
        [monitoring]="top htop vmstat iostat sar prometheus"
        [backup]="rsync tar backup restore snapshot"
        [database]="mysql postgresql sql psql mysqldump"
        [cloud]="aws ec2 s3 azure gcp terraform"
        [docker]="docker podman docker-compose"
        [kubernetes]="kubectl k8s helm ingress"
        [git]="git commit push pull merge clone"
        [ansible]="ansible playbook inventory"
        [terraform]="terraform resource provider"
        [python]="import def class flask django"
        [logs]="journalctl /var/log error warning"
        [performance]="tuning benchmark stress latency"
    )

    local best="utilities"
    local score=0

    for k in "${!rules[@]}"; do
        local s=0
        for w in ${rules[$k]}; do
            grep -q "$w" <<< "$c" && ((s++))
        done
        (( s > score )) && { score=$s; best=$k; }
    done

    echo "$best"
}

organize_script() {
    local f="$1"
    local category

    category="$(analyze_script "$f")"
    local target_dir="$BASE_DIR/$category"

    [[ -d "$target_dir" ]] || {
        mkdir -p "$target_dir" || {
            print_status "$RED" "✗ Failed to create directory $target_dir"
            log "ERROR: Failed to create directory $target_dir"
            return 1
        }
        log "Created directory $target_dir"
    }

    if mv "$f" "$target_dir/"; then
        print_status "$GREEN" "✓ $(basename "$f") → $category/"
        log "Moved $f to $category/"
    else
        print_status "$RED" "✗ Failed to move $(basename "$f")"
        log "ERROR: Failed to move $f to $category/"
        return 1
    fi
}

watch_directory() {
    print_status "$BLUE" "👀 Real-time watch enabled on: $BASE_DIR"
    print_status "$BLUE" "Listening for new or modified scripts..."

    inotifywait -m -r -e close_write,create --format '%w%f' "$BASE_DIR" | while read -r filepath; do
        # Skip self, log file, and any files in subdirectories
        [[ "$filepath" == "$0" ]] && continue
        [[ "$filepath" == "$LOG_FILE" ]] && continue
        [[ "$filepath" == */.* ]] && continue
        [[ "$(dirname "$filepath")" != "$BASE_DIR" ]] && continue

        if is_script "$filepath"; then
            print_status "$YELLOW" "🔍 Detected new script: $(basename "$filepath")"
            organize_script "$filepath"
        fi
    done
}

# ================= MAIN =================
watch_directory
