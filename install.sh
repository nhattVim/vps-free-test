#!/bin/bash
set -e

# -- Cấu hình
WINDOWS_ISO_PATH="$HOME/Downloads/Win10_21H2_English_x64.iso" # <-- chỉnh lại nếu cần
COMPOSE_FILE="windows10.yml"
CONTAINER_NAME="windows"
RAM_SIZE="4G"
CPU_CORES="2"
DISK_SIZE="30G"
DISK2_SIZE="10G"

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
newgrp kvm

echo "4. Kiểm tra file ISO Windows tồn tại..."
if [ ! -f "$WINDOWS_ISO_PATH" ]; then
  echo "Lỗi: Không tìm thấy file ISO Windows tại $WINDOWS_ISO_PATH"
  echo "Vui lòng tải ISO Windows 10 bản chính thức về đường dẫn này."
  exit 1
fi

echo "5. Tạo file docker-compose $COMPOSE_FILE"
cat > $COMPOSE_FILE <<EOF
version: '3.8'

services:
  windows:
    image: dockurr/windows
    container_name: $CONTAINER_NAME
    environment:
      VERSION: "10"
      USERNAME: "MASTER"
      PASSWORD: "admin@123"
      RAM_SIZE: "$RAM_SIZE"
      CPU_CORES: "$CPU_CORES"
      DISK_SIZE: "$DISK_SIZE"
      DISK2_SIZE: "$DISK2_SIZE"
      ISO_URL: ""  # bỏ vì dùng ISO mount thủ công
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    volumes:
      - $WINDOWS_ISO_PATH:/ISO/Win10.iso:ro
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
      - "3389:3389/udp"
    stop_grace_period: 2m
EOF

echo "6. Khởi động container Windows..."
sudo docker-compose -f $COMPOSE_FILE up -d

echo "Hoàn tất! Bạn có thể kết nối Windows container qua cổng 3389 (RDP)."
