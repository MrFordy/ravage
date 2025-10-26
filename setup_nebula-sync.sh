#!/bin/bash

# FILE: setup_nebula-sync.sh
# DESCRIPTION: A script to install and configure nebula-sync for Pi-hole replication.
# This script downloads the nebula-sync binary, configures it to synchronize
# Pi-hole settings to replica instances, and sets up a cron job for automatic
# synchronization. It is designed to be called from the main setup_all.sh script. 
# Changed from CRLF to LF line endings

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Setting up Nebula-Sync to keep Pi-hole settings in sync..."

### Get Pi-hole password from argument
# The password is passed as the first argument to this script.
PIHOLE_PASSWORD="$1"
if [ -z "$PIHOLE_PASSWORD" ]; then
    echo "ERROR: Pi-hole password was not provided as an argument." >&2
    exit 1
fi

### Define variables
# Configuration directory
CONFIG_DIR="/etc/nebula-sync"

### Install nebula-sync using Go
# This installs the latest version directly from GitHub.
echo "Installing nebula-sync (latest version) using Go..."
export GOBIN=/usr/local/bin
go install github.com/lovelaze/nebula-sync@latest

# Verify installation
if [ ! -f /usr/local/bin/nebula-sync ]; then
    echo "ERROR: nebula-sync installation failed." >&2
    exit 1
fi

echo "nebula-sync installed to /usr/local/bin/nebula-sync"

### Create configuration directory
# This directory will hold the environment configuration file.
echo "Creating configuration directory..."
mkdir -p "$CONFIG_DIR"

### Create environment configuration file
# This file contains the nebula-sync configuration.
# The replica at 192.168.0.251 uses the same password as the primary.
echo "Creating nebula-sync environment file..."
cat > "$CONFIG_DIR/nebula-sync.env" << EOF
# Nebula-Sync Configuration File
# Configured for primary at 192.168.0.250 and replica at 192.168.0.251

# Primary Pi-hole instance (this server)
PRIMARY=http://192.168.0.250|${PIHOLE_PASSWORD}

# Replica Pi-hole instances (comma-separated)
# Format: http://hostname|password,http://hostname2|password2
REPLICAS=http://192.168.0.251|${PIHOLE_PASSWORD}

# Full synchronization mode (true = full Teleporter sync, false = selective)
FULL_SYNC=true

# Run gravity update after sync
RUN_GRAVITY=true

# Cron schedule (runs every hour at minute 0)
# Format: minute hour day month weekday
CRON=0 * * * *

# Timezone for logs and cron
TZ=Europe/London

# Optional: Skip TLS verification (use if you have self-signed certificates)
# CLIENT_SKIP_TLS_VERIFICATION=false

# Optional: HTTP client settings
# CLIENT_RETRY_DELAY_SECONDS=1
# CLIENT_TIMEOUT_SECONDS=20
EOF

chmod 600 "$CONFIG_DIR/nebula-sync.env"

echo "Configuration file created at $CONFIG_DIR/nebula-sync.env"
echo "Configured to sync from primary (192.168.0.250) to replica (192.168.0.251)"

### Create systemd service for manual runs
# This allows running nebula-sync as a systemd service.
echo "Creating systemd service..."
cat > /etc/systemd/system/nebula-sync.service << 'EOF'
[Unit]
Description=Nebula-Sync Pi-hole Replication Service
After=network.target pihole-FTL.service
Wants=pihole-FTL.service

[Service]
Type=oneshot
EnvironmentFile=/etc/nebula-sync/nebula-sync.env
ExecStart=/usr/local/bin/nebula-sync run
StandardOutput=journal
StandardError=journal
SyslogIdentifier=nebula-sync

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize the new service
systemctl daemon-reload

echo "Systemd service created: nebula-sync.service"

### Create systemd timer for scheduled runs
# This timer runs nebula-sync according to the CRON schedule in the env file.
# Note: Systemd timers are more reliable than cron for this use case.
echo "Creating systemd timer..."
cat > /etc/systemd/system/nebula-sync.timer << 'EOF'
[Unit]
Description=Nebula-Sync Pi-hole Replication Timer
Requires=nebula-sync.service

[Timer]
# Run every hour at minute 0 (matches default CRON=0 * * * *)
OnCalendar=hourly
# Run immediately if we missed a scheduled run
Persistent=true
# Randomize start time by up to 5 minutes to avoid thundering herd
RandomizedDelaySec=5min

[Install]
WantedBy=timers.target
EOF

# Enable and start the timer (but not the service itself)
systemctl daemon-reload
systemctl enable nebula-sync.timer
systemctl start nebula-sync.timer

echo "Systemd timer enabled and started: nebula-sync.timer"

### Test nebula-sync installation
# Verify the binary is executable and shows version information.
echo "Testing nebula-sync installation..."
if command -v nebula-sync &> /dev/null; then
    INSTALLED_VERSION=$(nebula-sync version 2>/dev/null || echo "unknown")
    echo "nebula-sync is installed: $INSTALLED_VERSION"
else
    echo "ERROR: nebula-sync binary not found in PATH." >&2
    exit 1
fi

### Display timer status
echo "Checking timer status..."
systemctl status nebula-sync.timer --no-pager || true

### Completion Message
echo ""
echo "=============================================================="
echo "                  Nebula-Sync Setup Complete"
echo "=============================================================="

echo "Configuration Summary:"
echo "  Primary Pi-Hole: Ravage http://192.168.0.250"
echo "  Replica Pi-Hole: Howlback http://192.168.0.251"
echo "  Schedule: Every hour"
echo ""