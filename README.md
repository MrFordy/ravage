# Ravage - Automated Pi-hole High Availability Setup (Primary)
An automated Debian installation system for deploying a highly-available Pi-hole DNS server with ad-blocking, DHCP, and recursive DNS resolution.

Overview
This repository contains scripts to build Ravage, the primary Pi-hole server with:

Pi-hole - Network-wide ad blocking
Unbound - Fully recursive DNS resolver (no third-party DNS)
Keepalived - High availability with automatic failover
Nebula-Sync - Configuration synchronization to replica servers

This approach was heavily influenced by WunderTech's Ultimate Pi-hole Setup (https://www.wundertech.net/ultimate-pi-hole-setup/) and a desire to make this as simple as reasonably practicable to restore.

See https://github.com/MrFordy/howlback for the secondary Pi-hole set up.