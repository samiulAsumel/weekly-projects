#!/bin/bash
###############################################################
# Script Name: user_manager.sh
# Description: Enterprise-grade user management automation script
# Author: Samiul alam Sumel
# Version: 1.0.0
# Usages: ./user_manager.sh [create|modify|delete|list] [username] [options]
###############################################################
#
# Purpose: Automate user account lifecycle management with:
# - Input validation and error handling
# - Comprehensive logging
# - Automatic backup creation
# - Security compliance
#
# Requirements:
# - Root/sudo privileges required
# - RHEL/CentOS/Rocky Linux 8+ compatible
# - Standard Unix utilities (useradd, usermod, userdel)
###############################################################

#-------------------------------------------------------------
# Global Variables
# These variables are accessible throughout entire script
#-------------------------------------------------------------

# Script metadata
# $0 contains script name as called
# basename extracts filename from path
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
VERSION="1.0.0"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CURRENT_DATE=$(date +%Y-%m-%d)
CURRENT_TIME=$(date +%H:%M:%S)

# Load configuration file
# Source command executes config file in current shell
# Imports all variables defined in config file
CONFIG_FILE="$SCRIPT_DIR/config/script.conf"
if [[ -f "$CONFIG_FILE" ]]; then
	source "$CONFIG_FILE"
else
	# Exit if config missing - script cannot run without settings
	echo "ERROR: Configuration file not found: $CONFIG_FILE"
	exit 1
fi
