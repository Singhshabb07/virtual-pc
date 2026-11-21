#!/usr/bin/env bash
# ==============================================================================
# Codevern Cloud PC - Ubuntu 22.04 LTS Bootstrap Script
# Provisions NVIDIA drivers, XFCE desktop, Sunshine streamer, and Dev Suite
# ==============================================================================

set -euo pipefail

IDLE_TIMEOUT_MINUTES="${1:-15}"
LOG_FILE="/var/log/codevern-cloudpc-bootstrap.log"

exec > >(tee -a "${LOG_FILE}") 2>&1
echo "=== Starting Codevern Cloud PC Linux Provisioning ==="

export DEBIAN_FRONTEND=noninteractive

# 1. Format and Mount Persistent Data Disk (400 GB)
echo "[1/6] Setting up Persistent Data Storage..."
DATA_DISK=$(lsblk -dpno NAME,TYPE | grep disk | grep -v 'xvda\|nvme0n1' | head -n 1 | awk '{print $1}') || true
if [ -n "${DATA_DISK}" ] && ! blkid "${DATA_DISK}"; then
    echo "Formatting ${DATA_DISK} as ext4..."
    mkfs.ext4 -F "${DATA_DISK}"
    mkdir -p /mnt/data
    UUID=$(blkid -s UUID -o value "${DATA_DISK}")
    echo "UUID=${UUID} /mnt/data ext4 defaults,nofail 0 2" >> /etc/fstab
    mount /mnt/data
    mkdir -p /mnt/data/workspace
    chown -R ubuntu:ubuntu /mnt/data
    echo "Persistent data volume mounted at /mnt/data"
fi

# 2. System Update & Dependencies
echo "[2/6] Updating system packages..."
apt-get update -y
apt-get install -y \
    software-properties-common \
    curl \
    wget \
    git \
    build-essential \
    xorg \
    xfce4 \
    xfce4-goodies \
    xserver-xorg-video-dummy \
    pulseaudio \
    pavucontrol \
    xprintidle \
    jq

# 3. NVIDIA Driver Installation for AWS G4dn (Tesla T4)
echo "[3/6] Installing NVIDIA GPU Drivers & CUDA NVENC..."
apt-get install -y linux-headers-$(uname -r)
add-apt-repository -y ppa:graphics-drivers/ppa
apt-get update -y
apt-get install -y nvidia-driver-535 nvidia-utils-535

# 4. Sunshine Low-Latency Streaming Host
echo "[4/6] Installing Sunshine Streaming Host..."
SUNSHINE_URL=$(curl -s https://api.github.com/repos/LizardByte/Sunshine/releases/latest | jq -r '.assets[] | select(.name | endswith("ubuntu-22.04-amd64.deb")) | .browser_download_url')
wget -O /tmp/sunshine.deb "${SUNSHINE_URL}"
apt-get install -y /tmp/sunshine.deb || apt-get install -f -y

# Configure Sunshine systemd service
systemctl enable --now sunshine || true

# 5. Developer & Productivity Suite
echo "[5/6] Installing Development & Productivity Tools..."
# VS Code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /packages.microsoft.gpg
install -D -o root -g root -m 644 /packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
rm -f /packages.microsoft.gpg

# Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

apt-get update -y
apt-get install -y \
    code \
    nodejs \
    python3 \
    python3-pip \
    python3-venv \
    openjdk-17-jdk \
    chromium-browser \
    libreoffice

# 6. Idle Auto-Shutdown Service
echo "[6/6] Configuring Idle Auto-Shutdown Daemon..."
cat << 'EOF' > /usr/local/bin/idle-shutdown.sh
#!/usr/bin/env bash
TIMEOUT_MINUTES=15
IDLE_THRESHOLD_MS=$((TIMEOUT_MINUTES * 60 * 1000))

while true; do
    sleep 60
    # Check X11 idle time
    IDLE_MS=$(DISPLAY=:0 su ubuntu -c "xprintidle" 2>/dev/null || echo 0)
    
    # Check GPU utilization
    GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo 0)
    
    if [ "${IDLE_MS}" -ge "${IDLE_THRESHOLD_MS}" ] && [ "${GPU_UTIL}" -lt 15 ]; then
        echo "[$(date)] Idle timeout reached (${IDLE_MS} ms, GPU ${GPU_UTIL}%). Shutting down EC2 instance..."
        shutdown -h now
        break
    fi
done
EOF

chmod +x /usr/local/bin/idle-shutdown.sh

cat << 'EOF' > /etc/systemd/system/codevern-idle-shutdown.service
[Unit]
Description=Codevern Cloud PC Inactivity Shutdown Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/idle-shutdown.sh
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now codevern-idle-shutdown.service

echo "=== Linux Cloud PC Provisioning Complete ==="
