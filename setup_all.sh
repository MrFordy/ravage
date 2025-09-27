#!/bin/bash

# FILE: setup_all.sh
# DESCRIPTION: Main setup script executed by the preseed late_command.
# It calls individual setup scripts for ufw, ssh, unbound, pihole, keepalived,
# and nebula-sync. It collects the pi-hole password and passes it to 
# the pihole setup script.

### Retrieve Pi-hole password
# This is passed as the first argument from the late_command in the 
# preseed.cfg.
PIHOLE_PASSWORD="$1"
# Check if the Pi-hole password was received.
if [ -z "$PIHOLE_PASSWORD" ]; then
    echo "Error: Pi-hole password was not passed as an argument."
    exit 1
fi

echo "--- Starting all setup scripts ---"

### Firewall (UFW) Setup
# ufw was insalled by 'tasksel' in the preseed file. This script
# applies configuration settings.
echo "Running setup_ufw.sh..."
/root/setup_scripts/setup_ufw.sh

### SSH Server Setup
# ssh was installed by 'tasksel' in the preseed file. This script
# applies additional configuration settings.
echo "Running setup_ssh.sh..."
/root/setup_scripts/setup_ssh.sh

### Unbound Setup
# Install and configure the Unbound recursive DNS resolver.
echo "Running setup_unbound.sh..."
/root/setup_scripts/setup_unbound.sh

### Pi-hole Setup
# Install and configure Pi-hole, using the collected password.
# The password is passed as an argument to the script.
echo "Running setup_pihole.sh..."
/root/setup_scripts/setup_pihole.sh "$PIHOLE_PASSWORD"

### Keepalived Setup
# Install and configure Keepalived for IP redundancy.
# The 'keepalived' package is included in pkgsel/include.
echo "Running setup_keepalived.sh..."
/root/setup_scripts/setup_keepalived.sh

### Nebula-Sync Setup
# Install and configure the Nebula-Sync service.
echo "Running setup_nebula-sync.sh..."
/root/setup_scripts/setup_nebula-sync.sh

echo "--- All setup scripts complete ---"

exit 0