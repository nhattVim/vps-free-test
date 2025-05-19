#!/bin/bash
set -e

COMPOSE_FILE="windows10.yml"
CONTAINER_NAME="windows"
RAM_SIZE="8G"
CPU_CORES="4"
DISK_SIZE="60G"
DISK2_SIZE="10G"

echo "1. Cập nhật hệ thống..."
sudo apt update
sudo apt upgrade -y

echo "2. Kiểm tra và cài Docker..."
if ! command -v docker &>/dev/null; then
  echo "Docker chưa cài, tiến hành cài..."
  sudo apt install -y docker.io
  sudo systemctl enable --now docker
else
  echo "✅ Docker đã cài."
fi

echo "3. Kiểm tra docker-compose..."
if ! command -v docker-compose &>/dev/null; then
  echo "docker-compose chưa có, cài bản standalone..."
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
else
  echo "✅ docker-compose đã có."
fi

echo "4. Tạo nhóm kvm nếu chưa có và fix quyền /dev/kvm"
if ! getent group kvm >/dev/null; then
  sudo groupadd kvm
  echo "Nhóm kvm đã được tạo."
fi
sudo chgrp kvm /dev/kvm
sudo chmod 660 /dev/kvm
sudo usermod -aG kvm $USER || true

echo "5. Tạo file docker-compose $COMPOSE_FILE"
cat > $COMPOSE_FILE <<EOF
services:
  windows:
    image: dockurr/windows
    container_name: $CONTAINER_NAME
    environment:
      VERSION: "11"
      USERNAME: "MASTER"
      PASSWORD: "admin@123"
      RAM_SIZE: "$RAM_SIZE"
      CPU_CORES: "$CPU_CORES"
      DISK_SIZE: "$DISK_SIZE"
      DISK2_SIZE: "$DISK2_SIZE"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
      - "3389:3389/udp"
    stop_grace_period: 2m
EOF

echo "6. Khởi động container Windows..."
sudo docker-compose -f $COMPOSE_FILE up

echo ""
echo "✅ Hoàn tất! Bạn có thể kết nối Windows container qua cổng 3389 (Remote Desktop)."
echo "  - IP: localhost"
echo "  - Cổng: 3389"
echo "  - Username: MASTER"
echo "  - Password: admin@123"
