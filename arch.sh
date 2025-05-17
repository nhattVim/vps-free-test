#!/bin/bash
set -e

ARCH_ISO_PATH="$HOME/Downloads/archlinux-x86_64.iso"
COMPOSE_FILE="archlinux.yml"
CONTAINER_NAME="archlinux"
RAM_SIZE="2G"
CPU_CORES="2"
DISK_SIZE="20G"
DISK2_SIZE="5G"
ISO_DOWNLOAD_URL="https://mirror.rackspace.com/archlinux/iso/latest/archlinux-x86_64.iso"

mkdir -p "$(dirname "$ARCH_ISO_PATH")"

echo "1. Kiểm tra và cài Docker..."
if ! command -v docker &>/dev/null; then
  echo "Docker chưa cài, tiến hành cài..."
  sudo apt update
  sudo apt install -y docker.io
  sudo systemctl enable --now docker
else
  echo "Docker đã cài."
fi

echo "2. Kiểm tra docker-compose..."
if ! command -v docker-compose &>/dev/null; then
  echo "docker-compose chưa có, cài bản standalone..."
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
else
  echo "docker-compose đã có."
fi

echo "3. Tạo nhóm kvm nếu chưa có và fix quyền /dev/kvm"
if ! getent group kvm >/dev/null; then
  sudo groupadd kvm
  echo "Nhóm kvm đã được tạo."
fi
sudo chgrp kvm /dev/kvm
sudo chmod 660 /dev/kvm
sudo usermod -aG kvm $USER || true

echo "4. Kiểm tra file ISO Arch Linux tồn tại..."
if [ ! -f "$ARCH_ISO_PATH" ]; then
  echo "Không tìm thấy file ISO Arch Linux tại $ARCH_ISO_PATH"
  echo "Bắt đầu tải bản ISO Arch Linux mới nhất từ mirror chính thức..."
  wget --continue --show-progress -O "$ARCH_ISO_PATH" "$ISO_DOWNLOAD_URL"
  echo "Đã tải xong ISO Arch Linux."
fi

echo "5. Tạo file docker-compose $COMPOSE_FILE"
cat > $COMPOSE_FILE <<EOF
services:
  archlinux:
    image: archlinux
    container_name: $CONTAINER_NAME
    environment:
      RAM_SIZE: "$RAM_SIZE"
      CPU_CORES: "$CPU_CORES"
      DISK_SIZE: "$DISK_SIZE"
      DISK2_SIZE: "$DISK2_SIZE"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    volumes:
      - $ARCH_ISO_PATH:/ISO/archlinux-x86_64.iso:ro
    ports:
      - "2223:22/tcp"
    stop_grace_period: 2m
EOF


echo "6. Khởi động container Arch Linux..."
sudo docker-compose -f $COMPOSE_FILE up -d

echo "Hoàn tất! Bạn có thể kết nối Arch Linux container qua cổng 2223 (SSH)."
