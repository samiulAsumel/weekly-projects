#!/bin/bash

##############################################
# Central Report Aggregation Script
# Purpose: Collect reports from all servers
# Author: samiulAsumel
##############################################

SERVERS=(
    "dev-web:192.168.56.10"
    "stage-db:192.168.56.11"
    "prod-web:192.168.56.12"
    "cicd-jenkins:192.168.56.13"
)

SSH_USER="devops"
CENTRAL_REPORT_DIR="/opt/system-health-monitor/central-reports"
DATE="$(date +%Y-%m-%d)"

mkdir -p "$CENTRAL_REPORT_DIR/$DATE"

echo "Collecting reports from all servers..."

for server_info in "${SERVERS[@]}"; do
	SERVER_NAME=$(echo $server_info | cut -d: -f1)
	SERVER_IP=$(echo $server_info | cut -d: -f2)

	echo "Fatching report from $SERVER_NAME ($SERVER_IP)..."

	# Copy latest report
	scp -i $SSH_KEY $SSH_USER@$SERVER_IP:/opt/system-health-monitor/reports/* $CENTRAL_REPORT_DIR/$DATE/ >/dev/null 2>&1

