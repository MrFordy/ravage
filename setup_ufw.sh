#!/bin/bash

# FILE: setup_ufw.sh
# DESCRIPTION: Script to set up UFW (Firewall)
# This script is designed to be called from the main setup_all.sh script.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Setting up Firewall..."

# Set default policy to deny all incoming, allow all outgoing
ufw default deny incoming
ufw default allow outgoing

# Explicitly allow necessary services:
ufw allow ssh            # Port 2222 (SSH) - changed from default 22
ufw allow 53/tcp         # Port 53 (DNS TCP) - For zone transfers
ufw allow 53/udp         # Port 53 (DNS UDP) - For queries
ufw allow 80/tcp         # Port 80 (HTTP) - For Pi-hole Web Interface
ufw allow 123/udp        # Port 123 (NTP) - For time synchronization

# Enable the firewall (the --force option prevents the installer 
# from hanging on the "Are you sure?" prompt)
ufw --force enable

echo "Firewall Setup Complete"