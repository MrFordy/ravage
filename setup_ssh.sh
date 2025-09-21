#!/bin/bash

# FILE: setup_ssh.sh
# DESCRIPTION: A script to install and configure the SSH service with security best practices.
# This script is designed to be called from the main setup_all.sh script.
# VERSION: 1.0
# DATE: 2025-09-21

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting SSH setup and hardening..."

# Backup the original SSH configuration file.
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Update the SSH configuration for security.
# This command uses sed to modify the /etc/ssh/sshd_config file in place.
# It sets three important security options.
sed -i 's/^#\?Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# This line ensures that public key authentication is enabled, which it is by default.
# It is included, in case the default is ever changed.
sed -i 's/^#\?PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Restart the SSH service to apply the new configuration.
echo "Restarting SSH service to apply changes..."
systemctl restart ssh

echo "SSH setup and hardening complete."
