#!/bin/bash

# FILE: setup_ufw.sh
# DESCRIPTION: Script to set up UFW (Firewall)
# This script is designed to be called from the main setup_all.sh script.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Setting up UFW (Firewall)..."

### Default Policy
# deny all incoming, allow all outgoing
ufw default deny incoming
ufw default allow outgoing

### Exceptions
# Explicitly allow necessary services:
ufw allow ssh            # Port 2222 (SSH) - changed from default 22
ufw allow 53/tcp         # Port 53 (DNS TCP) - For zone transfers
ufw allow 53/udp         # Port 53 (DNS UDP) - For queries
ufw allow 80/tcp         # Port 80 (HTTP) - For Pi-hole Web Interface
ufw allow 123/udp        # Port 123 (NTP) - For time synchronization

### Enable Firewall
# Prevents installer from hanging at "Are you sure?"
ufw --force enable

echo "Firewall Setup Complete"