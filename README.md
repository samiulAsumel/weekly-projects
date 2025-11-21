# Weekly DevOps Project – Linux System Administration Automation Toolkit

This repository contains my weekly DevOps project aligned with the **DevOps Learning Priority Guide (AWS-Focused)** and the **24-Month DevOps Mastery Plan**.

The goal of this week is to build a fully functional **Linux System Administration Automation Toolkit**, demonstrating core skills required for DevOps, AWS, CI/CD, cloud engineering, and RHCSA readiness.

---

## 📌 Project Overview

This project focuses on strengthening Linux fundamentals through real, practical automation tasks.  
The toolkit includes scripts and utilities that resemble day-to-day responsibilities of a system administrator or DevOps engineer.

It covers:

- User and group management
- Backup and restore operations
- System health monitoring
- Log analysis and reporting
- Cron-based task automation
- Basic networking diagnostics

All components are implemented using standard Linux tools and Bash scripting.

---

## 🎯 Learning Objectives

This weekly project is designed to improve:

### **Linux Administration Skills**

- File system navigation and management
- File permissions and ownership
- User/group provisioning
- Package installation and service management
- Systemd, logging, and process monitoring
- Shell scripting essentials

### **DevOps-Relevant Skills**

- Writing reusable automation scripts
- Handling system logs for troubleshooting
- Building modular tools suitable for production environments
- Strengthening foundational knowledge required for AWS, Docker, Terraform, and Kubernetes

---

## 🛠 Toolkit Components

### **1. User Provisioning Script**

Automates:

- User creation
- Group assignment
- Home directory setup
- Password & sudo configuration
- Logging of created accounts

### **2. Backup Utility**

- Compresses selected directories
- Saves archives with timestamps
- Performs integrity checks

### **3. Restore Utility**

- Restores backup archives
- Validates restored content

### **4. System Health Check Script**

Collects:

- CPU usage
- Memory usage
- Disk utilization
- Running and failed services
- Network connectivity

Outputs a clean system report.

### **5. Log Analyzer**

Parses `/var/log` to summarize:

- Errors
- Warnings
- Authentication failures
- Login attempts

### **6. Cron Automation**

Schedules:

- Backups
- Health checks
- Log cleanup

---

## 📂 Repository Structure

├── scripts/
│ ├── user_provision.sh
│ ├── backup_tool.sh
│ ├── restore_tool.sh
│ ├── health_check.sh
│ └── log_analyzer.sh
│
├── cron/
│ ├── backup.cron
│ ├── healthcheck.cron
│ └── cleanup.cron
│
├── reports/
│ ├── system_report.txt
│ └── logs_summary.txt
│
└── README.md
