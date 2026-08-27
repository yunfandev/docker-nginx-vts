#!/usr/bin/env bash
# Per-boot Docker daemon for the Cloud Agent VM (the environment "start" command).
#
# The VM is itself a container with an overlay rootfs and no systemd, and the
# daemon is configured (see .cursor/install.sh) to use the fuse-overlayfs storage
# driver with iptables disabled. This script runs dockerd in the FOREGROUND so the
# platform keeps it attached for the lifetime of the agent session; a backgrounded
# daemon would be reaped once the start command returned.
set -euo pipefail

# Safety net: if a daemon is already reachable, don't launch a second one. Stay
# attached so this start slot keeps running.
if sudo docker info >/dev/null 2>&1; then
  echo "dockerd already running; staying attached."
  exec tail -f /dev/null
fi

# Remove a stale pid file left by a previous (now dead) daemon.
sudo rm -f /var/run/docker.pid

echo "Starting dockerd in the foreground..."
exec sudo dockerd
