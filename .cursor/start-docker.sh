#!/usr/bin/env bash
# Idempotently start the Docker daemon inside the Cloud Agent VM.
#
# The VM is itself a container with an overlay rootfs and no netfilter/systemd,
# so dockerd is configured (see .cursor/install.sh) to use the fuse-overlayfs
# storage driver with iptables disabled, and is launched here as a background
# process rather than via systemd.
set -euo pipefail

if sudo docker info >/dev/null 2>&1; then
  echo "dockerd already running"
  exit 0
fi

# Remove a stale pid file left behind by a previous (now dead) daemon.
sudo rm -f /var/run/docker.pid

sudo bash -c 'nohup dockerd >/var/log/dockerd.log 2>&1 &'

for _ in $(seq 1 60); do
  if sudo docker info >/dev/null 2>&1; then
    echo "dockerd is ready"
    exit 0
  fi
  sleep 1
done

echo "dockerd failed to become ready; last log lines:" >&2
sudo tail -n 50 /var/log/dockerd.log >&2 || true
exit 1
