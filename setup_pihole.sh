#!/bin/bash

# FILE: setup_pihole.sh
# DESCRIPTION: A script to install and configure Pi-hole with a secure, hardened setup.
# VERSION: 1.0
# DATE: 2025-09-21

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting Pi-hole setup..."

# Read the password from the file passed as the first command-line argument.
# This file is temporary and created by the preseed late_command.
PASSWORD_FILE="$1"
if [ ! -f "$PASSWORD_FILE" ]; then
    echo "ERROR: Password file not found! The preseed command may have failed." >&2
    exit 1
fi
PIHOLE_PASSWORD=$(cat "$PASSWORD_FILE")
rm "$PASSWORD_FILE" # For security, delete the temporary password file immediately.

# 1. Disable `systemd-resolved` to prevent conflicts on port 53.
echo "Disabling systemd-resolved to prevent port 53 conflict..."
systemctl disable systemd-resolved
systemctl stop systemd-resolved

# 2. Perform a non-interactive installation of Pi-hole.
echo "Performing non-interactive Pi-hole installation..."
export DNSMASQ_LISTENING=all
export PIHOLE_DNS_="127.0.0.1#5353"
export INSTALL_WEB_SERVER=true
export INSTALL_WEB_INTERFACE=true
export DHCP_ACTIVE=true
export DHCP_START="192.168.1.100"
export DHCP_END="192.168.1.250"
export NTP_SERVER="ntp.org"
export PIHOLE_SKIP_INSTALL_CHECK=true

curl -sSL https://install.pi-hole.net | bash /dev/stdin

# 3. Set a secure password for the Pi-hole web interface.
echo "Setting Pi-hole web interface password..."
pihole -a -p "$PIHOLE_PASSWORD"

# 4. Add additional ad-block lists and update the gravity database.
echo "Adding OISD blocklists and updating gravity database..."
echo "https://big.oisd.nl/" | tee /etc/pihole/adlists.list >/dev/null
echo "https://nsfw.oisd.nl/" | tee -a /etc/pihole/adlists.list >/dev/null

pihole -g

# 5. Add static DHCP leases from a separate file.
echo "Adding static DHCP leases from separate file..."
if [ ! -f "static_leases.txt" ]; then
    echo "WARNING: No static_leases.txt file found. Skipping static lease configuration."
else
    cp static_leases.txt /etc/dnsmasq.d/04-static-leases.conf
    pihole restartdns
fi

# 6. Final hardening and system configuration.
echo "Configuring host system DNS to use Pi-hole..."
echo "nameserver 127.0.0.1" > /etc/resolv.conf

# 7. Test Pi-hole to ensure it is working correctly.
echo "Testing Pi-hole ad-blocking..."
if dig @127.0.0.1 doubleclick.net | grep "0.0.0.0" > /dev/null; then
    echo "Pi-hole is blocking ads correctly. Test successful."
else
    echo "ERROR: Pi-hole test failed. 'doubleclick.net' was not blocked."
    exit 1
fi

echo "Testing Pi-hole resolves a legitimate domain..."
if dig @127.0.0.1 google.com | grep -v "0.0.0.0" > /dev/null; then
    echo "Pi-hole is resolving legitimate domains correctly. Test successful."
else
    echo "ERROR: Pi-hole test failed. 'google.com' was incorrectly blocked."
    exit 1
fi

echo "Pi-hole setup complete."
