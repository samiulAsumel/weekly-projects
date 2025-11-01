#!/bin/bash

# System Information Collection Module
# Gather comprehensive hardware and OS details
# Author: samiulAsumel

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR"/utils/logger.sh
source "$SCRIPT_DIR"/utils/colors.sh

# Function to collect system information
collect_system_info() {
	print_header "System Information"
	log_info "Collecting system information..."

	# Hostname and Domain
	print_section "Hostname & Network Identity"
	echo "Hostname: $(hostname)"
	echo "FQDN: $(hostname -f 2>/dev/null || echo 'Not Configured')"
	echo "Domain: $(hostname -d 2>/dev/null || echo 'Not Configured')"
	echo "IP Address: $(hostname -I | awk '{print $1}')"

	# Operating System
	print_section "Operating System"
	echo "Distribution: $(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"')"
	echo "Kernel Version: $(uname -r)"
	echo "Architecture: $(uname -m)"
	echo "Uptime: $(uptime -p)"

	# Hardware Information
	print_section "Hardware Resources"
	echo "CPU Model: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
	echo "CPU Cores: $(nproc)"
	echo "Total RAM: $(free -h | grep Mem | awk '{print $2}')"
	echo "Used RAM: $(free -h | grep Mem | awk '{print $3}')"
	echo "Free RAM: $(free -h | grep Mem | awk '{print $4}')"

	# Disk Information
	print_section "Disk Usage"
	df -h

	# Load Average
	print_section "Load Average"
	echo "Load Average (1/5/15 min): $(awk '{print $1, $2, $3}' /proc/loadavg)"

	# Process Count
	print_section "Process Statistics"
	echo "Total Processes: $(ps -e --no-headers | wc -l)"
	echo "Running Processes: $(ps -eo state --no-headers | grep -c '^R')"
	echo "Sleeping Processes: $(ps -eo state --no-headers | grep -c '^S')"
	echo "Stopped Processes: $(ps -eo state --no-headers | grep -c '^T')"
	echo "Zombie Processes: $(ps -eo state --no-headers | grep -c '^Z')"
	echo "Uninterruptible Sleeps: $(ps -eo state --no-headers | grep -c '^D')"

	log_info "System information collection completed successfully."
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	collect_system_info
fi