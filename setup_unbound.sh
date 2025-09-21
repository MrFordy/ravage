#!/bin/bash

# FILE: setup_unbound.sh
# DESCRIPTION: A script to install and configure Unbound as a fully recursive DNS resolver
# with security and privacy hardening. This script is designed to be called from the main
# setup_all.sh script.
# VERSION: 1.3
# DATE: 2025-09-21

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting Unbound DNS resolver setup..."

# 1. Install Unbound.
# The `preseed.cfg` does not include Unbound by default, so we install it here.
apt-get update
apt-get install -y unbound

# 2. Download the root hints file.
# This file is essential for Unbound to resolve top-level domains from the root servers.
echo "Downloading root hints file..."
wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root

# 3. Create the Unbound configuration file.
# This creates a minimal configuration that runs Unbound in fully recursive mode.
echo "Creating Unbound configuration file..."
cat > /etc/unbound/unbound.conf << EOF
server:
    # Use the local interface and a non-standard port to avoid conflicts with Pi-hole.
    interface: 127.0.0.1
    port: 5353

    # The access control list.
    # We only allow local connections, as Unbound will be used by Pi-hole.
    access-control: 127.0.0.1/32 allow

    # Force full recursion.
    do-not-query-address: 127.0.0.1
    do-not-query-address: ::1
    root-hints: "/var/lib/unbound/root.hints"

    # Set verbosity level to minimal.
    verbosity: 0

    # -------- DNSSEC AND HARDENING SETTINGS --------
    # Ensure Unbound operates in a secure mode.
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: yes

    # Prevents resolving subdomains of a non-existent domain.
    harden-below-nxdomain: yes

    # Protect against buffer overflows from malformed queries.
    harden-heap-buffers: yes
    harden-large-queries: yes

    # -------- PRIVACY SETTINGS --------
    # Prevents Unbound from revealing its identity or version.
    hide-identity: yes
    hide-version: yes

    # Implements QNAME minimisation to enhance privacy.
    qname-minimisation: yes

    # Do not log queries.
    log-queries: no

    # -------- PERFORMANCE SETTINGS --------
    # Set up cache sizes.
    msg-cache-size: 32m
    rrset-cache-size: 64m

    # Pre-emptively fetch expired cache entries.
    prefetch: yes

    # Prevent a single client from overwhelming the server with queries.
    # Adjust this value based on your needs.
    ip-ratelimit: 50
EOF

# 4. Enable and start the Unbound service.
# This ensures that Unbound starts automatically on boot.
echo "Enabling and starting Unbound service..."
systemctl enable unbound
systemctl start unbound

# 5. Test Unbound to ensure it is working correctly.
# We use 'dig' to query a well-known domain.
echo "Testing Unbound DNS resolver..."
dig @127.0.0.1 -p 5353 google.com > /dev/null

# The `if` statement checks the exit status of the previous command.
if [ $? -eq 0 ]; then
    echo "Unbound is working correctly."
else
    echo "ERROR: Unbound test failed. Check the logs for unbound."
    # The script will exit with an error code, which is good practice.
    exit 1
fi

echo "Unbound setup complete."
