#!/bin/bash
set -e

container_name="amnezia-wg-easy"
LOG_FILE="/tmp/amnezia-container-deploy.log"

echo "Starting container deployment for ${container_name}..." >&2
echo "Starting container deployment for ${container_name}..." > "${LOG_FILE}"

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "ERROR: Missing required arguments. Usage: $0 <WG_HOST> <PASSWORD_HASH>" >&2
  echo "ERROR: Missing required arguments. Usage: $0 <WG_HOST> <PASSWORD_HASH>" >> "${LOG_FILE}"
  exit 1
fi

echo "WG_HOST: $1" >&2
echo "WG_HOST: $1" >> "${LOG_FILE}"
echo "PASSWORD_HASH: [provided]" >&2

# Verify Docker image exists
echo "Checking if Docker image 'amnezia-wg-easy' exists..." >&2
echo "Checking if Docker image 'amnezia-wg-easy' exists..." >> "${LOG_FILE}"
if ! sudo docker images -q amnezia-wg-easy | grep -q .; then
  echo "ERROR: Docker image 'amnezia-wg-easy' not found. Please build the image first." >&2
  echo "ERROR: Docker image 'amnezia-wg-easy' not found. Please build the image first." >> "${LOG_FILE}"
  echo "Available images:" >&2
  sudo docker images >&2
  sudo docker images >> "${LOG_FILE}"
  exit 1
fi

IMAGE_INFO=$(sudo docker images amnezia-wg-easy --format '{{.Repository}}:{{.Tag}}')
echo "Docker image found: ${IMAGE_INFO}" >&2
echo "Docker image found: ${IMAGE_INFO}" >> "${LOG_FILE}"

# Get home directory path (use whoami to get current user)
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~${CURRENT_USER})
WG_CONFIG_DIR="${HOME_DIR}/.amnezia-wg-easy"

echo "WireGuard config directory: ${WG_CONFIG_DIR}" >&2
echo "WireGuard config directory: ${WG_CONFIG_DIR}" >> "${LOG_FILE}"

# Ensure config directory exists
if [ ! -d "${WG_CONFIG_DIR}" ]; then
  echo "Creating WireGuard config directory: ${WG_CONFIG_DIR}" >&2
  echo "Creating WireGuard config directory: ${WG_CONFIG_DIR}" >> "${LOG_FILE}"
  sudo mkdir -p "${WG_CONFIG_DIR}"
  sudo chown root:root "${WG_CONFIG_DIR}"
fi

# Stop and remove existing container if it exists
container_id=$(sudo docker ps -a -q --filter "name=${container_name}")
if [ -n "$container_id" ]; then
  echo "Stopping and removing existing container: ${container_name} (ID: ${container_id})" >&2
  echo "Stopping and removing existing container: ${container_name} (ID: ${container_id})" >> "${LOG_FILE}"
  sudo docker stop ${container_name} || true
  sudo docker rm ${container_name} || true
fi

echo "Starting Docker container..." >&2
echo "Starting Docker container..." >> "${LOG_FILE}"
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
  echo "ERROR: Failed to start Docker container" >&2
  echo "ERROR: Failed to start Docker container" >> "${LOG_FILE}"
  echo "Container logs:" >&2
  echo "Container logs:" >> "${LOG_FILE}"
  sudo docker logs ${container_name} 2>&1 | tee -a "${LOG_FILE}" || true
  echo "Full deployment log: ${LOG_FILE}" >&2
  exit 1
fi

echo "Container started successfully" >&2
echo "Container started successfully" >> "${LOG_FILE}"
echo "Container status:" >&2
echo "Container status:" >> "${LOG_FILE}"
sudo docker ps --filter "name=${container_name}" >&2
sudo docker ps --filter "name=${container_name}" >> "${LOG_FILE}"
echo "Full deployment log saved to: ${LOG_FILE}" >&2
