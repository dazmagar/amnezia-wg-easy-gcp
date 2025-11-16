#!/bin/bash
set -e

container_name="amnezia-wg-easy"

echo "Starting container deployment for ${container_name}..."

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "ERROR: Missing required arguments. Usage: $0 <WG_HOST> <PASSWORD_HASH>"
  exit 1
fi

echo "WG_HOST: $1"
echo "PASSWORD_HASH: [hidden]"

# Verify Docker image exists
echo "Checking if Docker image 'amnezia-wg-easy' exists..."
if ! sudo docker images -q amnezia-wg-easy | grep -q .; then
  echo "ERROR: Docker image 'amnezia-wg-easy' not found. Please build the image first."
  echo "Available images:"
  sudo docker images
  exit 1
fi

echo "Docker image found: $(sudo docker images amnezia-wg-easy --format '{{.Repository}}:{{.Tag}}')"

# Get home directory path (use whoami to get current user)
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~${CURRENT_USER})
WG_CONFIG_DIR="${HOME_DIR}/.amnezia-wg-easy"

echo "WireGuard config directory: ${WG_CONFIG_DIR}"

# Ensure config directory exists
if [ ! -d "${WG_CONFIG_DIR}" ]; then
  echo "Creating WireGuard config directory: ${WG_CONFIG_DIR}"
  sudo mkdir -p "${WG_CONFIG_DIR}"
  sudo chown root:root "${WG_CONFIG_DIR}"
fi

# Stop and remove existing container if it exists
container_id=$(sudo docker ps -a -q --filter "name=${container_name}")
if [ -n "$container_id" ]; then
  echo "Stopping and removing existing container: ${container_name} (ID: ${container_id})"
  sudo docker stop ${container_name} || true
  sudo docker rm ${container_name} || true
fi

echo "Starting Docker container..."
if ! sudo docker run -d \
  --name=${container_name} \
  -e LANG=en \
  -e WG_HOST="$1" \
  -e PASSWORD_HASH="$2" \
  -e PORT=51821 \
  -e WG_PORT=51820 \
  -v "${WG_CONFIG_DIR}:/etc/wireguard" \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.ip_forward=1" \
  --device=/dev/net/tun:/dev/net/tun \
  --restart unless-stopped \
  amnezia-wg-easy; then
  echo "ERROR: Failed to start Docker container"
  echo "Container logs:"
  sudo docker logs ${container_name} 2>&1 || true
  exit 1
fi

echo "Container started successfully"
echo "Container status:"
sudo docker ps --filter "name=${container_name}"
