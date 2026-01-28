#!/bin/bash
###############################################################
# Deployment Script: User Management Script
# Description: Enterprise deployment automation
# Author: Samiul alam Sumel
# Version: 1.0.0
###############################################################

set -euo pipefail

# Configuration
readonly SCRIPT_DIR
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
readonly PROJECT_DIR
PROJECT_DIR=$(dirname "$SCRIPT_DIR")
readonly CONFIG_FILE="$PROJECT_DIR/config/script.conf"
readonly DEPLOYMENT_ENV="${DEPLOYMENT_ENV:-production}"
readonly BACKUP_DIR="${BACKUP_DIR:-/tmp/deploy_backups}"
readonly TIMESTAMP
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Pre-deployment checks
pre_deployment_checks() {
  log_info "Running pre-deployment checks..."

  # Check if running as root
  if [[ $EUID -ne 0 ]]; then
    log_error "Deployment script must be run as root"
    exit 1
  fi

  # Check if project directory exists
  if [[ ! -d "$PROJECT_DIR" ]]; then
    log_error "Project directory not found: $PROJECT_DIR"
    exit 1
  fi

  # Check if main script exists
  if [[ ! -f "$PROJECT_DIR/user_manager.sh" ]]; then
    log_error "Main script not found: $PROJECT_DIR/user_manager.sh"
    exit 1
  fi

  # Check if configuration file exists
  if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Configuration file not found: $CONFIG_FILE"
    exit 1
  fi

  # Check if required commands are available
  local required_commands=("useradd" "usermod" "userdel" "passwd" "tar" "gzip")
  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      log_error "Required command not found: $cmd"
      exit 1
    fi
  done

  log_success "Pre-deployment checks passed"
}

# Backup current deployment
backup_current_deployment() {
  log_info "Creating backup of current deployment..."

  local backup_dir="$BACKUP_DIR/deployment_backup_$TIMESTAMP"
  mkdir -p "$backup_dir"

  # Backup configuration
  if [[ -f "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "$backup_dir/"
    log_info "Configuration backed up"
  fi

  # Backup logs if they exist
  if [[ -d "$PROJECT_DIR/logs" ]]; then
    cp -r "$PROJECT_DIR/logs" "$backup_dir/"
    log_info "Logs backed up"
  fi

  # Backup backups if they exist
  if [[ -d "$PROJECT_DIR/backups" ]]; then
    cp -r "$PROJECT_DIR/backups" "$backup_dir/"
    log_info "Backups backed up"
  fi

  log_success "Backup created: $backup_dir"
}

# Deploy files
deploy_files() {
  log_info "Deploying files..."

  # Set proper permissions
  chmod 755 "$PROJECT_DIR/user_manager.sh"
  chmod 755 "$PROJECT_DIR/tests/test_script.sh"
  chmod 644 "$CONFIG_FILE"

  # Create necessary directories
  mkdir -p "$PROJECT_DIR/logs"
  mkdir -p "$PROJECT_DIR/backups"

  # Set ownership
  chown -R root:root "$PROJECT_DIR"

  log_success "Files deployed successfully"
}

# Run tests
run_tests() {
  log_info "Running deployment tests..."

  # Test script syntax
  if bash -n "$PROJECT_DIR/user_manager.sh"; then
    log_success "Script syntax check passed"
  else
    log_error "Script syntax check failed"
    exit 1
  fi

  # Test configuration
  if bash -n "$CONFIG_FILE"; then
    log_success "Configuration syntax check passed"
  else
    log_error "Configuration syntax check failed"
    exit 1
  fi

  # Test basic functionality
  if sudo "$PROJECT_DIR/user_manager.sh" --version &>/dev/null; then
    log_success "Basic functionality test passed"
  else
    log_error "Basic functionality test failed"
    exit 1
  fi

  log_success "All tests passed"
}

# Configure logging
configure_logging() {
  log_info "Configuring logging..."

  # Set up log rotation
  cat >"/etc/logrotate.d/user-management" <<EOF
$PROJECT_DIR/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        # Reload any services if needed
    endscript
}
EOF

  log_success "Logging configured"
}

# Setup monitoring
setup_monitoring() {
  log_info "Setting up monitoring..."

  # Create health check script
  cat >"$PROJECT_DIR/scripts/health_check.sh" <<'EOF'
#!/bin/bash
# Health check script for user management script

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Check if main script exists and is executable
if [[ ! -x "$PROJECT_DIR/user_manager.sh" ]]; then
    exit 1
fi

# Check if configuration file exists
if [[ ! -f "$PROJECT_DIR/config/script.conf" ]]; then
    exit 1
fi

# Check if script can show version
if ! "$PROJECT_DIR/user_manager.sh" --version &>/dev/null; then
    exit 1
fi

exit 0
EOF

  chmod +x "$PROJECT_DIR/scripts/health_check.sh"

  log_success "Monitoring configured"
}

# Post-deployment verification
post_deployment_verification() {
  log_info "Running post-deployment verification..."

  # Verify script is working
  if sudo "$PROJECT_DIR/user_manager.sh" help &>/dev/null; then
    log_success "Script is working correctly"
  else
    log_error "Script is not working correctly"
    exit 1
  fi

  # Verify directories exist
  local required_dirs=("logs" "backups" "config" "tests" "scripts")
  for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$PROJECT_DIR/$dir" ]]; then
      log_error "Required directory missing: $dir"
      exit 1
    fi
  done

  # Verify permissions
  if [[ -x "$PROJECT_DIR/user_manager.sh" ]]; then
    log_success "Permissions are correct"
  else
    log_error "Permissions are incorrect"
    exit 1
  fi

  log_success "Post-deployment verification passed"
}

# Cleanup old backups
cleanup_old_backups() {
  log_info "Cleaning up old deployment backups..."

  # Keep last 7 days of backups
  find "$BACKUP_DIR" -type d -name "deployment_backup_*" -mtime +7 -exec rm -rf {} \; 2>/dev/null || true

  log_success "Old backups cleaned up"
}

# Main deployment function
main() {
  log_info "Starting deployment for environment: $DEPLOYMENT_ENV"

  pre_deployment_checks
  backup_current_deployment
  deploy_files
  run_tests
  configure_logging
  setup_monitoring
  post_deployment_verification
  cleanup_old_backups

  log_success "Deployment completed successfully!"
  log_info "Deployment environment: $DEPLOYMENT_ENV"
  log_info "Deployment timestamp: $TIMESTAMP"
  log_info "Backup location: $BACKUP_DIR/deployment_backup_$TIMESTAMP"
}

# Handle script arguments
case "${1:-}" in
--dry-run)
  log_info "Running in dry-run mode"
  pre_deployment_checks
  run_tests
  log_success "Dry-run completed successfully"
  ;;
--backup-only)
  log_info "Running backup only"
  backup_current_deployment
  log_success "Backup completed successfully"
  ;;
--help | -h)
  cat <<EOF
Usage: $0 [OPTIONS]

OPTIONS:
    --dry-run      Run checks and tests without deploying
    --backup-only  Create backup without deploying
    --help, -h     Show this help message

ENVIRONMENT VARIABLES:
    DEPLOYMENT_ENV    Deployment environment (default: production)
    BACKUP_DIR        Backup directory (default: /tmp/deploy_backups)

EXAMPLES:
    $0                    # Deploy to production
    $0 --dry-run          # Run checks only
    DEPLOYMENT_ENV=staging $0  # Deploy to staging
EOF
  ;;
"")
  main
  ;;
*)
  log_error "Unknown option: $1"
  echo "Use --help for usage information"
  exit 1
  ;;
esac
