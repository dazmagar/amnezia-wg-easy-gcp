container_name="amnezia-wg-easy"
container_id=$(sudo docker ps -a -q --filter "name=${container_name}")
if [ -n "$container_id" ]; then
  echo "Stopping and removing existing container: $container_name"
  sudo docker stop $container_name
  sudo docker rm $container_name
fi

sudo docker run -d \
  --name=amnezia-wg-easy \
  -e LANG=en \
  -e WG_HOST=$1 \
  -e PASSWORD_HASH=$2 \
  -e PORT=51821 \
  -e WG_PORT=51820 \
  -v ~/.amnezia-wg-easy:/etc/wireguard \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.ip_forward=1" \
  --device=/dev/net/tun:/dev/net/tun \
  --restart unless-stopped \
  amnezia-wg-easy
