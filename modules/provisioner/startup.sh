#!/bin/bash
set -e

echo "Starting Docker installation..."

sudo apt-get update
sudo apt-get install -y ca-certificates curl

if ! command -v docker &> /dev/null; then
  echo "Docker not found, installing..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker $(whoami)
  echo "Docker installed successfully"
else
  echo "Docker already installed: $(docker --version)"
fi

# Verify Docker installation
if ! command -v docker &> /dev/null; then
  echo "Error: Docker installation failed - docker command not found"
  exit 1
fi

echo "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker is running
if ! sudo systemctl is-active --quiet docker; then
  echo "Error: Docker service failed to start"
  exit 1
fi

echo "Docker service is running"
sudo apt-get autoremove -y

echo "Docker installation completed successfully"
