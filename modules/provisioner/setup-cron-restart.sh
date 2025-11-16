#!/bin/bash
set -e

container_name="amnezia-wg-easy"
cron_schedule="${1:-0 3 * * *}"
cron_command="docker restart ${container_name} >/dev/null 2>&1"
cron_job="${cron_schedule} ${cron_command}"

if ! command -v docker &> /dev/null; then
  echo "Error: Docker is not installed"
  exit 1
fi

if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
  echo "Warning: Container ${container_name} does not exist yet"
  exit 0
fi

if crontab -l 2>/dev/null | grep -q "${cron_command}"; then
  echo "Cron job for ${container_name} restart already exists"
  exit 0
fi

(crontab -l 2>/dev/null; echo "${cron_job}") | crontab -
echo "Cron job added: ${cron_job}"

