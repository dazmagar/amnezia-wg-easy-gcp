#!/bin/bash
set -e

curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $(whoami)

sudo systemctl start docker
sudo systemctl enable docker

sudo apt-get install -y mc ca-certificates curl

sudo apt-get autoremove -y
