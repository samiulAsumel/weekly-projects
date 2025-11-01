# TechCorp System Administration Toolkit

## Overview

Comprehensive Linux system administration and audit tool designed for
enterprise environments running RHEL-based distributions.

## Features

- System hardware and OS information collection
- User account and permission auditing
- Security compliance scanning
- Automated report generation
- Detailed logging for troubleshooting

## Requirements

- Rocky Linux / AlmaLinux / RHEL 8+
- Bash 4.0+
- Root privileges for security checks

## Installation

### Quick Setup

```bash
git clone https://github.com/techcorp/sysadmin-toolkit.git
cd sysadmin-toolkit
chmod +x bin/sysadmin-tool.sh
```

### System-Wide Installation (Optional)

```bash
sudo cp bin/sysadmin-tool.sh /usr/local/bin/sysadmin-tool
sudo chmod 755 /usr/local/bin/sysadmin-tool
```

## Usage

### Basic Commands

```bash
# Display help
./bin/sysadmin-tool.sh --help

# Run full system audit
sudo ./bin/sysadmin-tool.sh full

# Security scan only
sudo ./bin/sysadmin-tool.sh security

# Generate comprehensive report
sudo ./bin/sysadmin-tool.sh report
```

### View Reports

```bash
# List all reports
ls -lh data/reports/

# View latest report
cat data/reports/system_report_*.txt | tail -n 100
```

## TechCorp Integration

This tool is designed for TechCorp's multi-environment infrastructure:

| Environment | Hostname Pattern | Usage                     |
| ----------- | ---------------- | ------------------------- |
| Development | dev-\*           | Daily health checks       |
| Staging     | stage-\*         | Pre-deployment validation |
| Production  | prod-\*          | Security compliance audit |

## Automation with Cron

```bash
# Run daily security audit at 2 AM
0 2 * * * /usr/local/bin/sysadmin-tool security > /dev/null 2>&1

# Generate weekly report every Sunday
0 3 * * 0 /usr/local/bin/sysadmin-tool report
```

## Troubleshooting

### Permission Denied Errors

Ensure you run with sudo for full functionality:

```bash
sudo ./bin/sysadmin-tool.sh full
```

### Module Not Found Errors

Always run from project root or use absolute paths:

```bash
cd /path/to/linux-sysadmin-toolkit
./bin/sysadmin-tool.sh full
```

## Contributing

Contact DevOps Team: devops@techcorp.local

## License

Internal TechCorp Use Only
