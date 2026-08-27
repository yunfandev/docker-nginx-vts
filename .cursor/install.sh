#!/usr/bin/env bash
# Prepare the Cloud Agent VM to build and run the nginx-vts Docker image.
#
# This installs the Docker engine (missing from the base image), configures the
# daemon for the nested-container VM, starts it, and builds the repository image
# so it is cached in the environment snapshot. It is safe to run repeatedly.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker engine and dependencies..."
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo apt-get update -qq
  # --force-confold keeps existing conffiles (e.g. /etc/fuse.conf) so the
  # non-interactive install does not stall on a dpkg prompt.
  sudo apt-get install -y -o Dpkg::Options::=--force-confold \
    ca-certificates curl gnupg fuse-overlayfs iptables uidmap

  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -o Dpkg::Options::=--force-confold \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin
fi

# The VM rootfs is overlay and has no working netfilter, so use fuse-overlayfs
# and disable iptables. Builds and runs use host networking (see README notes).
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json >/dev/null <<'JSON'
{
  "storage-driver": "fuse-overlayfs",
  "iptables": false,
  "ip6tables": false
}
JSON

# Let the ubuntu user talk to the daemon socket without sudo.
sudo groupadd -f docker
sudo usermod -aG docker ubuntu

# Start the daemon so we can build the image now.
bash "${SCRIPT_DIR}/start-docker.sh"

# Build the repository image so it is validated and cached in the snapshot.
# --network host is required because the daemon runs without bridge NAT.
echo "Building nginx-vts image..."
sudo docker build --network host -t nginx-vts "${REPO_ROOT}"

echo "Install complete. 'docker build -t nginx-vts .' and 'docker run ... nginx-vts' are ready."
