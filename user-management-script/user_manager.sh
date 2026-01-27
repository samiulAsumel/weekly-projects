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

# Load configuration file
CONFIG_FILE="$SCRIPT_DIR/config/script.conf"
if [[ -f "$CONFIG_FILE" ]]; then
	# shellcheck source=/dev/null
	source "$CONFIG_FILE"
else
	echo "ERROR: Configuration file not found: $CONFIG_FILE" >&2
	exit 1
fi

# Logging paths
LOG_PATH="$SCRIPT_DIR/$LOG_DIR"
OPERATION_LOG_FILE="$LOG_PATH/$OPERATION_LOG"
ERROR_LOG_FILE="$LOG_PATH/$ERROR_LOG"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

#----------------------------------------------------
# Logging Functions
#----------------------------------------------------
log_message() {
	local level="$1"
	local message="$2"
	local timestamp
	timestamp=$(date +"%Y-%m-%d %H:%M:%S")

	mkdir -p "$LOG_PATH"
	echo "[$timestamp] [$level] $message" >>"$OPERATION_LOG_FILE"
	echo -e "${BLUE}[$timestamp] [$level] $message${NC}"
}

log_error() {
	local message="$1"
	local timestamp
	timestamp=$(date +"%Y-%m-%d %H:%M:%S")

	mkdir -p "$LOG_PATH"
	echo "[$timestamp] [ERROR] $message" >>"$ERROR_LOG_FILE"
	echo "[$timestamp] [ERROR] $message" >>"$OPERATION_LOG_FILE"
	echo -e "${RED}[$timestamp] [ERROR] $message${NC}" >&2
}

log_success() {
	local message="$1"
	local timestamp
	timestamp=$(date +"%Y-%m-%d %H:%M:%S")

	mkdir -p "$LOG_PATH"
	echo "[$timestamp] [SUCCESS] $message" >>"$OPERATION_LOG_FILE"
	echo -e "${GREEN}[$timestamp] [SUCCESS] $message${NC}"
}
