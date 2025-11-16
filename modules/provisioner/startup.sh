#!/bin/bash
set -e

sudo apt-get update
sudo apt-get install -y ca-certificates curl

if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker $(whoami)
fi

sudo systemctl start docker
sudo systemctl enable docker

sudo apt-get autoremove -y
