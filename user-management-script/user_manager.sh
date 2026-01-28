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
log_message() { # Function: log_message
	local level="$1"
	local message="$2"
	local timestamp
	timestamp=$(date +"%Y-%m-%d %H:%M:%S")

	mkdir -p "$LOG_PATH"
	echo "[$timestamp] [$level] $message" >>"$OPERATION_LOG_FILE"
	echo -e "${BLUE}[$timestamp] [$level] $message${NC}"
}

log_error() { # Function: log_error
	local message="$1"
	local timestamp
	timestamp=$(date +"%Y-%m-%d %H:%M:%S")

	mkdir -p "$LOG_PATH"
	echo "[$timestamp] [ERROR] $message" >>"$ERROR_LOG_FILE"
	echo "[$timestamp] [ERROR] $message" >>"$OPERATION_LOG_FILE"
	echo -e "${RED}[$timestamp] [ERROR] $message${NC}" >&2
}

log_success() { # Function: log_success
	local message="$1"
	local timestamp
	timestamp=$(date +"%Y-%m-%d %H:%M:%S")

	mkdir -p "$LOG_PATH"
	echo "[$timestamp] [SUCCESS] $message" >>"$OPERATION_LOG_FILE"
	echo -e "${GREEN}[$timestamp] [SUCCESS] $message${NC}"
}

check_root() { # Function: check_root
	if [[ $EUID -ne 0 ]]; then
		log_error "This script must be run as root or with sudo"
		echo "Usage: sudo $SCRIPT_NAME [options]"
		exit $Exit_error_permissions
	fi
	log_message "INFO" "Root privilege check: PASSED"
}

validate_username() { # Function: validate_username
	local username="$1"

	# check if username is empty
	# -x checks if string length is zero
	if [[ -z "$username" ]]; then
		log_error "Username cannot be empty"
		return 1
	fi

	# Check username length
	# ${#variable} givs length of variable
	if [[ ${#username} -gt 32 ]]; then
		log_error "Username too long (max 32 characters): $username"
		return 1
	fi

	# Check username format using regex
	# ^[a-z] = must start with lower case
	# [a-z0-9_-]* = followed by lowercase, numbers, underscore, hyphen
	# $ = end of string
	if [[ ! "$username" =~ ^[a-z][a-z0-9_-]*$ ]]; then
		log_error "Invalid username format: $username"
		echo "Username must:"
		echo "- Start with a lowercase letter"
		echo "- Contain only lowercase letters, numbers, underscores, and hyphens"
		echo "- Be no longer than 32 characters"
		return 1
	fi

	log_message "info" "username validation passed: $username"
	return 0
}
