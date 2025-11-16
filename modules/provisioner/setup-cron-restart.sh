#!/bin/bash
set -e

container_name="amnezia-wg-easy"
cron_schedule="${1:-0 3 * * *}"
cron_command="sudo docker restart ${container_name} >/dev/null 2>&1"
cron_job="${cron_schedule} ${cron_command}"

if ! sudo docker --version &> /dev/null; then
  echo "Warning: Docker is not installed, skipping cron setup"
  exit 0
fi

# Wait for container to be running (with timeout)
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
  if sudo docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
    echo "Container ${container_name} is running"
    break
  fi
  attempt=$((attempt + 1))
  if [ $attempt -eq $max_attempts ]; then
    echo "Warning: Container ${container_name} is not running after ${max_attempts} attempts, skipping cron setup"
    exit 0
  fi
  echo "Waiting for container ${container_name} to start... (attempt $attempt/$max_attempts)"
  sleep 2
done

# Check if cron job already exists (check for container name in cron)
if crontab -l 2>/dev/null | grep -q "${container_name}"; then
  echo "Cron job for ${container_name} restart already exists"
  crontab -l | grep "${container_name}"
  exit 0
fi

# Add cron job
(crontab -l 2>/dev/null; echo "${cron_job}") | crontab -
if [ $? -eq 0 ]; then
  echo "Cron job added successfully: ${cron_job}"
  echo "Current crontab:"
  crontab -l
else
  echo "ERROR: Failed to add cron job"
  exit 1
fi

