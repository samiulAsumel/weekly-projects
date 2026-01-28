# User Management Script

Enterprise-grade user management automation script for Linux systems with comprehensive security features, logging, and backup capabilities.

## Overview

This script provides a secure, production-ready solution for managing user accounts on Linux systems. It includes automated backups, comprehensive logging, password validation, and protection against accidental system user deletion.

## Features

- **User Operations**: Create, modify, delete, and list user accounts
- **Security Features**:
  - Password complexity validation
  - System user protection (UID < 1000)
  - Automatic system backups before modifications
  - Comprehensive audit logging
- **Backup & Recovery**: Automated backups of critical system files
- **Configuration Management**: Centralized configuration with security defaults
- **Comprehensive Testing**: Full test suite for validation

## Installation

1. Clone or download the script to your system
2. Ensure the script is executable:
   ```bash
   chmod +x user_manager.sh
   ```
3. Review and customize the configuration file:
   ```bash
   vim config/script.conf
   ```

## Requirements

- Linux system with root/sudo access
- Standard Unix utilities: useradd, usermod, userdel, passwd, tar, etc.
- Bash shell (version 4.0+)

## Usage

### Basic Syntax

```bash
sudo ./user_manager.sh <operation> [arguments]
```

### Operations

#### Create User

```bash
# Create user with password
sudo ./user_manager.sh create username "Password123!"

# Create user without password (will prompt later)
sudo ./user_manager.sh create username
```

#### Modify User

```bash
# Change shell
sudo ./user_manager.sh modify username shell /bin/zsh

# Update comment/GECOS field
sudo ./user_manager.sh modify username comment "New Description"

# Change home directory
sudo ./user_manager.sh modify username home /new/home/dir

# Lock user account
sudo ./user_manager.sh modify username lock

# Unlock user account
sudo ./user_manager.sh modify username unlock
```

#### Delete User

```bash
# Delete user and backup home directory
sudo ./user_manager.sh delete username

# Delete user without backing up home directory
sudo ./user_manager.sh delete username no
```

#### List Users

```bash
# List regular users (UID >= 1000)
sudo ./user_manager.sh list regular

# List system users (UID < 1000)
sudo ./user_manager.sh list system

# List all users
sudo ./user_manager.sh list all
```

#### Help and Information

```bash
# Show help
sudo ./user_manager.sh help

# Show version
sudo ./user_manager.sh --version
```

## Configuration

The script uses `config/script.conf` for centralized configuration:

### Key Settings

- **Password Policy**:
  - `PASSWORD_MIN_LENGTH`: Minimum password length (default: 8)
  - `REQUIRED_STRONG_PASSWORD`: Enable complex password requirements (default: true)
- **Backup Settings**:
  - `BACKUP_RETENTION_DAYS`: Days to keep backups (default: 30)
  - `BACKUP_PATH`: Backup storage location

- **Logging**:
  - `LOG_LEVEL`: Logging verbosity (DEBUG, INFO, WARNING, ERROR, CRITICAL)
  - `LOG_DIR`: Directory for log files

### Security Defaults

- Strong password enforcement enabled
- System user protection active
- Automatic backups before modifications
- Comprehensive audit logging

## Security Features

### Password Validation

When strong passwords are enabled, passwords must contain:

- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character
- Minimum length as configured

### System Protection

- Prevents deletion of system users (UID < 1000)
- Requires root privileges for all operations
- Creates automatic backups before any modification

### Audit Trail

All operations are logged with:

- Timestamp
- Operation details
- User who performed the action
- Success/failure status

## Backup and Recovery

### Automatic Backups

The script automatically creates backups of:

- `/etc/passwd`
- `/etc/shadow`
- `/etc/group`
- `/etc/gshadow`

### Backup Location

Backups are stored in the configured backup directory with timestamps:

```
/tmp/user_manager_backups/passwd_backup_YYYYMMDD_HHMMSS.tar.gz
```

### Manual Recovery

To restore from backup:

```bash
cd /tmp/user_manager_backups
tar -xzf passwd_backup_YYYYMMDD_HHMMSS.tar.gz -C /
```

## Testing

Run the comprehensive test suite:

```bash
# Make test script executable
chmod +x tests/test_script.sh

# Run tests (requires sudo)
sudo ./tests/test_script.sh
```

The test suite validates:

- Script functionality
- Error handling
- Security features
- Backup operations
- Permission requirements

## Logging

### Log Files

- **Operations Log**: `logs/user_operations.log`
- **Error Log**: `logs/error.log`

### Log Format

```
[YYYY-MM-DD HH:MM:SS] [LEVEL] Message
```

### Log Rotation

Configure log rotation in the configuration file:

- `LOG_MAX_SIZE`: Maximum log file size in MB
- `LOG_RETENTION_COUNT`: Number of log files to retain

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure running with sudo
2. **Config File Not Found**: Verify `config/script.conf` exists
3. **Backup Failed**: Check disk space and permissions
4. **User Already Exists**: Use modify operation instead

### Debug Mode

Enable debug logging by setting `LOG_LEVEL="DEBUG"` in configuration.

## File Structure

```
user-management-script/
├── user_manager.sh          # Main script
├── config/
│   └── script.conf          # Configuration file
├── tests/
│   └── test_script.sh       # Test suite
├── logs/                    # Log files (created automatically)
├── backups/                 # Backup files (created automatically)
└── README.md               # This documentation
```

## Security Considerations

1. **Store securely**: Keep the script and configuration in a protected directory
2. **Review permissions**: Ensure appropriate file permissions
3. **Monitor logs**: Regularly review operation logs for unusual activity
4. **Backup verification**: Periodically verify backup integrity
5. **Password policy**: Adjust password requirements to meet security standards

## License

This script is provided as-is for educational and production use. Modify according to your organization's security requirements.

## Support

For issues or questions:

1. Check the log files for error details
2. Run the test suite to validate functionality
3. Review configuration settings
4. Ensure system requirements are met

## Version History

- **v1.0.0**: Initial production release with full feature set
