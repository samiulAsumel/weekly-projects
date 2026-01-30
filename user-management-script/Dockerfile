# User Management Script Dockerfile
FROM ubuntu:22.04

LABEL maintainer="samiul@example.com"
LABEL version="1.0.0"
LABEL description="Enterprise-grade user management automation"

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SCRIPT_DIR=/opt/user-management
ENV LOG_DIR=/var/log/user-management
ENV BACKUP_DIR=/var/backups/user-management

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    coreutils \
    shadow \
    tar \
    gzip \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p $SCRIPT_DIR \
    $LOG_DIR \
    $BACKUP_DIR \
    /etc/logrotate.d

# Copy files
COPY user_manager.sh $SCRIPT_DIR/
COPY config/ $SCRIPT_DIR/config/
COPY scripts/ $SCRIPT_DIR/scripts/
COPY tests/ $SCRIPT_DIR/tests/
COPY README.md $SCRIPT_DIR/
COPY LICENSE.md $SCRIPT_DIR/
COPY SECURITY.md $SCRIPT_DIR/

# Set permissions
RUN chmod 755 $SCRIPT_DIR/user_manager.sh \
    $SCRIPT_DIR/scripts/*.sh \
    $SCRIPT_DIR/tests/*.sh \
    && chmod 644 $SCRIPT_DIR/config/* \
    $SCRIPT_DIR/*.md

# Create logrotate configuration
RUN echo "$LOG_DIR/*.log {\n    daily\n    missingok\n    rotate 30\n    compress\n    delaycompress\n    notifempty\n    create 644 root root\n}" > /etc/logrotate.d/user-management

# Create entrypoint script
RUN echo '#!/bin/bash\n\
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then\n\
    cat $SCRIPT_DIR/README.md\n\
elif [ "$1" = "--version" ]; then\n\
    echo "User Management Script v1.0.0"\n\
elif [ "$1" = "test" ]; then\n\
    cd $SCRIPT_DIR && ./tests/test_script.sh\n\
elif [ "$1" = "shellcheck" ]; then\n\
    shellcheck $SCRIPT_DIR/*.sh\n\
else\n\
    cd $SCRIPT_DIR && ./user_manager.sh "$@"\n\
fi' > /usr/local/bin/user-manager && chmod 755 /usr/local/bin/user-manager

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD $SCRIPT_DIR/scripts/health_check.sh || exit 1

# Set working directory
WORKDIR $SCRIPT_DIR

# Default command
CMD ["--help"]
