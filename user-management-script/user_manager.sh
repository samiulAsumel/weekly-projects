#!/bin/bash
###############################################################
# Script Name: user_manager.sh
# Description: Enterprise-grade user management automation script
# Author: Samiul alam Sumel
# Version: 1.0.0
# Usage: ./user_manager.sh [create|modify|delete|list] [username] [options]
###############################################################

#-------------------------------------------------------------
# Global Variables
#-------------------------------------------------------------

# Script metadata
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
readonly SCRIPT_DIR
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME
VERSION="${VERSION:-1.0.0}"
readonly VERSION
DATE=$(date +"%Y%m%d_%H%M%S")
readonly DATE
TIMESTAMP="$DATE"
readonly TIMESTAMP

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR_GENERAL=1
readonly EXIT_ERROR_PERMISSIONS=2
readonly EXIT_ERROR_INVALID_INPUT=3
readonly EXIT_ERROR_USER_EXISTS=4
readonly EXIT_ERROR_USER_NOT_FOUND=5

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Load configuration file
readonly CONFIG_FILE="$SCRIPT_DIR/config/script.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: Configuration file not found: $CONFIG_FILE" >&2
  exit "$EXIT_ERROR_GENERAL"
fi

# shellcheck source=/dev/null
if ! source "$CONFIG_FILE"; then
  echo "ERROR: Failed to load configuration file: $CONFIG_FILE" >&2
  exit "$EXIT_ERROR_GENERAL"
fi

# Logging paths
readonly LOG_PATH="$SCRIPT_DIR/$LOG_DIR"
readonly OPERATION_LOG_FILE="$LOG_PATH/$OPERATION_LOG"
readonly ERROR_LOG_FILE="$LOG_PATH/$ERROR_LOG"

# Default values for missing configuration are set in config file
# Variables are already readonly from config file
# Construct full backup path
BACKUP_PATH="$SCRIPT_DIR/$BACKUP_DIR"

# Backup file name
readonly BACKUP_FILE="$BACKUP_PATH/passwd_backup_$DATE.tar.gz"

#----------------------------------------------------
# Logging Functions
#----------------------------------------------------
log_message() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  if ! mkdir -p "$LOG_PATH"; then
    echo "ERROR: Cannot create log directory: $LOG_PATH" >&2
    return 1
  fi

  echo "[$timestamp] [$level] $message" >>"$OPERATION_LOG_FILE" || return 1
  echo -e "${BLUE}[$timestamp] [$level] $message${NC}"
  return 0
}

log_error() {
  local message="$1"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  if ! mkdir -p "$LOG_PATH"; then
    echo "ERROR: Cannot create log directory: $LOG_PATH" >&2
    return 1
  fi

  echo "[$timestamp] [ERROR] $message" >>"$ERROR_LOG_FILE" || return 1
  echo "[$timestamp] [ERROR] $message" >>"$OPERATION_LOG_FILE" || return 1
  echo -e "${RED}[$timestamp] [ERROR] $message${NC}" >&2
  return 0
}

log_success() {
  local message="$1"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  if ! mkdir -p "$LOG_PATH"; then
    echo "ERROR: Cannot create log directory: $LOG_PATH" >&2
    return 1
  fi

  echo "[$timestamp] [SUCCESS] $message" >>"$OPERATION_LOG_FILE" || return 1
  echo -e "${GREEN}[$timestamp] [SUCCESS] $message${NC}"
  return 0
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root or with sudo"
    echo "Usage: sudo $SCRIPT_NAME [options]"
    exit "$EXIT_ERROR_PERMISSIONS"
  fi
  log_message "INFO" "Root privilege check: PASSED"
}

validate_username() {
  local username="$1"

  if [[ -z "$username" ]]; then
    log_error "Username cannot be empty"
    return 1
  fi

  if [[ ${#username} -gt 32 ]]; then
    log_error "Username too long (max 32 characters): $username"
    return 1
  fi

  if [[ ! "$username" =~ ^[a-z][a-z0-9_-]*$ ]]; then
    log_error "Invalid username format: $username"
    echo "Username must:"
    echo "- Start with a lowercase letter"
    echo "- Contain only lowercase letters, numbers, underscores, and hyphens"
    echo "- Be no longer than 32 characters"
    return 1
  fi

  log_message "INFO" "Username validation passed: $username"
  return 0
}

user_exists() {
  local username="$1"

  if id "$username" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

validate_password() {
  local password="$1"

  if [[ ${#password} -lt $PASSWORD_MIN_LENGTH ]]; then
    log_error "Password too short (min $PASSWORD_MIN_LENGTH characters)"
    return 1
  fi

  if [[ "$REQUIRED_STRONG_PASSWORD" == "true" ]]; then
    if [[ ! "$password" =~ [A-Z] ]]; then
      log_error "Password must contain at least one uppercase letter"
      return 1
    fi

    if [[ ! "$password" =~ [a-z] ]]; then
      log_error "Password must contain at least one lowercase letter"
      return 1
    fi

    if [[ ! "$password" =~ [0-9] ]]; then
      log_error "Password must contain at least one number"
      return 1
    fi

    if [[ ! "$password" =~ [^a-zA-Z0-9] ]]; then
      log_error "Password must contain at least one special character"
      return 1
    fi
  fi

  log_message "INFO" "Password validation passed"
  return 0
}

#----------------------------------------------------------------
# Backup functions
# Always backup before modification - allows recovery if something fails
#----------------------------------------------------------------
create_backup() {
  log_message "INFO" "Creating system backup before operation"

  if ! mkdir -p "$BACKUP_PATH"; then
    log_error "Cannot create backup directory: $BACKUP_PATH"
    return 1
  fi

  if ! tar -czf "$BACKUP_FILE" \
    /etc/passwd \
    /etc/shadow \
    /etc/group \
    /etc/gshadow \
    2>/dev/null; then
    log_error "Failed to create backup"
    return 1
  fi

  log_success "Backup created: $BACKUP_FILE"

  local backup_size
  backup_size=$(du -h "$BACKUP_FILE" | cut -f1)
  log_message "INFO" "Backup size: $backup_size"
  return 0
}

cleanup_old_backups() {
  log_message "INFO" "Cleaning up old backups (retention: $BACKUP_RETENTION_DAYS days)"

  if [[ ! -d "$BACKUP_PATH" ]]; then
    log_message "WARN" "Backup directory does not exist: $BACKUP_PATH"
    return 0
  fi

  find "$BACKUP_PATH" \
    -type f \
    -name "passwd_backup_*.tar.gz" \
    -mtime +"$BACKUP_RETENTION_DAYS" \
    -delete 2>/dev/null

  log_message "INFO" "Old backup cleanup completed"
}

create_user() {
  local username="$1"
  local password="$2"

  log_message "INFO" "Creating user: $username"

  if ! validate_username "$username"; then
    exit "$EXIT_ERROR_INVALID_INPUT"
  fi

  if user_exists "$username"; then
    log_error "User already exists: $username"
    exit "$EXIT_ERROR_USER_EXISTS"
  fi

  if ! create_backup; then
    log_error "Backup failed, aborting user creation"
    exit "$EXIT_ERROR_GENERAL"
  fi

  log_message "INFO" "Executing: useradd -m -s $DEFAULT_SHELL $username"

  if ! useradd -m -s "$DEFAULT_SHELL" -c "Created by $SCRIPT_NAME on $TIMESTAMP" "$username"; then
    log_error "Failed to create user: $username"
    exit "$EXIT_ERROR_GENERAL"
  fi

  log_success "User account created: $username"

  if [[ -n "$password" ]]; then
    if validate_password "$password"; then
      if echo "$password" | passwd --stdin "$username" &>/dev/null; then
        log_success "Password set for user: $username"
        chage -d 0 "$username"
        log_message "INFO" "Password change required on first login"
      else
        log_error "Failed to set password for user: $username"
      fi
    fi
  else
    log_message "WARN" "No password provided - account created without password"
    echo "RUN: sudo passwd $username to set password"
  fi

  log_message "INFO" "User details: $(id "$username")"
  log_message "INFO" "Home directory: $(getent passwd "$username" | cut -d: -f6)"
}

modify_user() {
  local username="$1"
  local mod_type="$2"
  local new_value="$3"

  log_message "INFO" "Starting user modification: $username ($mod_type)"

  if ! user_exists "$username"; then
    log_error "User does not exist: $username"
    exit "$EXIT_ERROR_USER_NOT_FOUND"
  fi

  if ! create_backup; then
    exit "$EXIT_ERROR_GENERAL"
  fi

  case "$mod_type" in
  shell)
    if ! usermod -s "$new_value" "$username"; then
      log_error "Failed to change shell for user: $username"
      exit "$EXIT_ERROR_GENERAL"
    fi
    log_success "Changed shell to $new_value for user: $username"
    ;;
  comment)
    if ! usermod -c "$new_value" "$username"; then
      log_error "Failed to update comment for user: $username"
      exit "$EXIT_ERROR_GENERAL"
    fi
    log_success "Updated comment for user: $username"
    ;;
  home)
    if ! usermod -d "$new_value" -m "$username"; then
      log_error "Failed to change home directory for user: $username"
      exit "$EXIT_ERROR_GENERAL"
    fi
    log_success "Changed home directory to $new_value for user: $username"
    ;;
  lock)
    if ! usermod -L "$username"; then
      log_error "Failed to lock user account: $username"
      exit "$EXIT_ERROR_GENERAL"
    fi
    log_success "Locked user account: $username"
    ;;
  unlock)
    if ! usermod -U "$username"; then
      log_error "Failed to unlock user account: $username"
      exit "$EXIT_ERROR_GENERAL"
    fi
    log_success "Unlocked user account: $username"
    ;;
  *)
    log_error "Invalid modification type: $mod_type"
    echo "Valid types: shell, comment, home, lock, unlock"
    exit "$EXIT_ERROR_INVALID_INPUT"
    ;;
  esac
}

delete_user() {
  local username="$1"
  local backup_home="${2:-yes}"

  log_message "INFO" "Deleting user: $username (backup_home=$backup_home)"

  if ! user_exists "$username"; then
    log_error "User does not exist: $username"
    exit "$EXIT_ERROR_USER_NOT_FOUND"
  fi

  local uid
  uid=$(id -u "$username")
  if [[ $uid -lt 1000 ]]; then
    log_error "Refusing to delete system user with UID < 1000: $username"
    exit "$EXIT_ERROR_PERMISSIONS"
  fi

  if ! create_backup; then
    exit "$EXIT_ERROR_GENERAL"
  fi

  if [[ "$backup_home" == "yes" ]]; then
    local home_dir
    home_dir=$(getent passwd "$username" | cut -d: -f6)

    if [[ -d "$home_dir" ]]; then
      local home_backup="$BACKUP_PATH/${username}_home_$DATE.tar.gz"

      log_message "INFO" "Backing up home directory: $home_dir"

      if tar -czf "$home_backup" -C "$(dirname "$home_dir")" "$(basename "$home_dir")" 2>/dev/null; then
        log_success "Home directory backed up: $home_backup"
      else
        log_error "Failed to backup home directory: $home_dir"
      fi
    fi
  fi

  log_message "INFO" "Executing: userdel -r $username"

  if userdel -r "$username" 2>/dev/null; then
    log_success "User deleted: $username"
  else
    log_message "WARN" "Deleting user without removing home directory"
    if userdel "$username"; then
      log_success "User deleted without home directory: $username"
    else
      log_error "Failed to delete user: $username"
      exit "$EXIT_ERROR_GENERAL"
    fi
  fi
}

list_users() {
  local filter="${1:-regular}"

  log_message "INFO" "Listing users (filter: $filter)"

  printf "%-20s %-5s %-5s %-30s %-30s\n" "Username" "UID" "GID" "Home Directory" "Shell"
  printf "%-20s %-5s %-5s %-30s %-30s\n" "--------" "---" "----" "--------------" "-----"

  while IFS=: read -r username _ uid gid _comment home_dir shell; do
    case "$filter" in
    all)
      printf "%-20s %-5s %-5s %-30s %-30s\n" "$username" "$uid" "$gid" "$home_dir" "$shell"
      ;;
    system)
      if [[ $uid -lt 1000 ]]; then
        printf "%-20s %-5s %-5s %-30s %-30s\n" "$username" "$uid" "$gid" "$home_dir" "$shell"
      fi
      ;;
    regular)
      if [[ $uid -ge 1000 ]] && [[ $uid -ne 65534 ]]; then
        printf "%-20s %-5s %-5s %-30s %-30s\n" "$username" "$uid" "$gid" "$home_dir" "$shell"
      fi
      ;;
    esac
  done <"/etc/passwd"

  printf "\nTotal users listed.\n"
  log_message "INFO" "User listing completed"
}

#------------------------------------------------------------
# Main program logic
# Entry point - process command line arguments and calls appropriate functions
#------------------------------------------------------------

show_usage() {
  cat <<EOF
${BLUE}=================================${NC}
${BLUE}User management script v$VERSION${NC}
${BLUE}=================================${NC}

	Usage: sudo $SCRIPT_NAME <operation> [arguments]

	Operations:
		create <username> [password]
		modify <username> <type> <value>
		delete <username> [backup_home]
		list [filter]

	Modify Types: shell, comment, home, lock, unlock

	Options:
		-h, --help          Show this help message
		-v, --version       Show script version
		-d, --debug         Enable debug mode
		-c, --config FILE   Use custom configuration file
		-o, --output FILE   Output report to file

	Examples:
		sudo $SCRIPT_NAME create john_doe 'StrongP@ssw0rd!'
		sudo $SCRIPT_NAME modify john_doe shell /bin/zsh
		sudo $SCRIPT_NAME delete john_doe yes
		sudo $SCRIPT_NAME list regular

Logs: $LOG_PATH/
Backups: $BACKUP_PATH/

EOF
}

main() {
  check_root

  log_message "INFO" "==================== Script Execution Started ===================="
  log_message "INFO" "Script: $SCRIPT_NAME v$VERSION"
  log_message "INFO" "User: $(whoami)"
  log_message "INFO" "Date: $TIMESTAMP"
  log_message "INFO" "Arguments: $*"

  if [[ $# -eq 0 ]]; then
    show_usage
    exit "$EXIT_ERROR_INVALID_INPUT"
  fi

  local operation="$1"
  shift

  case "$operation" in
  create)
    if [[ $# -lt 1 ]]; then
      log_error "Username required for create operation"
      show_usage
      exit "$EXIT_ERROR_INVALID_INPUT"
    fi
    create_user "$1" "$2"
    ;;

  modify)
    if [[ $# -lt 3 ]]; then
      log_error "Insufficient arguments for modify operation"
      show_usage
      exit "$EXIT_ERROR_INVALID_INPUT"
    fi
    modify_user "$1" "$2" "$3"
    ;;

  delete)
    if [[ $# -lt 1 ]]; then
      log_error "Username required for delete operation"
      show_usage
      exit "$EXIT_ERROR_INVALID_INPUT"
    fi
    delete_user "$1" "${2:-yes}"
    ;;

  list)
    list_users "${1:-regular}"
    ;;

  help | --help | -h)
    show_usage
    exit "$EXIT_SUCCESS"
    ;;

  *)
    log_error "Unknown operation: $operation"
    show_usage
    exit "$EXIT_ERROR_INVALID_INPUT"
    ;;
  esac

  cleanup_old_backups

  log_success "Operation completed successfully"
  log_message "INFO" "==================== Script Execution Completed ===================="

  exit "$EXIT_SUCCESS"
}

# Call main function with all script arguments
# "$@" preserves all arguments with proper quoting
main "$@"
