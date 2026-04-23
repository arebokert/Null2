#!/bin/bash
# Null 2 Setup Script
# Configures a fresh RetroPie install for the Null 2 DIY handheld.
# Run as the 'pi' user (not root) after SSHing into the Pi.
#
# Usage: bash setup/install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LOG="/home/pi/null2-setup.log"

exec > >(tee -a "$LOG") 2>&1

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[null2]${NC} $1"; }
warn()    { echo -e "${YELLOW}[null2]${NC} $1"; }
error()   { echo -e "${RED}[null2]${NC} $1" >&2; exit 1; }
skip()    { echo -e "${YELLOW}[null2]${NC} Skipping: $1 (already installed)"; }

# ── Preflight checks ──────────────────────────────────────────────────────────

check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root. Run as 'pi' — the script uses sudo internally."
    fi
}

check_pi() {
    if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        error "This script must be run on a Raspberry Pi."
    fi
}

check_arch() {
    local arch
    arch=$(uname -m)
    if [[ "$arch" == "aarch64" ]]; then
        error "fbcp-ili9341 requires a 32-bit OS. You are running 64-bit ($arch). Flash a 32-bit RetroPie image and try again."
    fi
}

detect_model() {
    local model
    model=$(cat /proc/device-tree/model 2>/dev/null || echo "unknown")
    if echo "$model" | grep -q "Zero 2"; then
        PI_MODEL="zero2"
        SPI_DIVISOR=6   # 400MHz core / 6 ≈ 66MHz SPI
        info "Detected: Raspberry Pi Zero 2 W (SPI divisor: $SPI_DIVISOR)"
    else
        PI_MODEL="zero"
        SPI_DIVISOR=4   # 250MHz core / 4 ≈ 62MHz SPI
        info "Detected: Raspberry Pi Zero W (SPI divisor: $SPI_DIVISOR)"
    fi
}

# ── Helpers ───────────────────────────────────────────────────────────────────

add_to_rc_local() {
    local line="$1"
    if ! grep -qF "$line" /etc/rc.local; then
        sudo sed -i "s|^exit 0|${line}\nexit 0|" /etc/rc.local
        info "Added to /etc/rc.local: $line"
    fi
}

# ── Install steps ─────────────────────────────────────────────────────────────

install_deps() {
    info "Installing build dependencies..."
    sudo apt-get update -qq
    sudo apt-get install -y cmake git build-essential python3-pip
    sudo pip3 install --quiet keyboard
}

install_fbcp() {
    if [[ -f /usr/local/bin/fbcp-ili9341 ]]; then
        skip "fbcp-ili9341"
        return
    fi

    info "Building fbcp-ili9341 display driver (this takes ~10 min on Pi Zero W)..."
    rm -rf /tmp/fbcp-ili9341
    git clone --depth=1 https://github.com/juj/fbcp-ili9341.git /tmp/fbcp-ili9341
    mkdir /tmp/fbcp-ili9341/build
    pushd /tmp/fbcp-ili9341/build > /dev/null
    cmake \
        -DILI9341=ON \
        -DGPIO_TFT_DATA_CONTROL=24 \
        -DGPIO_TFT_RESET_PIN=25 \
        -DGPIO_TFT_BACKLIGHT=18 \
        -DSPI_BUS_CLOCK_DIVISOR="$SPI_DIVISOR" \
        -DSTATISTICS=0 \
        -DUSE_DMA_TRANSFERS=ON \
        .. > /dev/null
    make -j"$(nproc)"
    sudo cp fbcp-ili9341 /usr/local/bin/fbcp-ili9341
    popd > /dev/null
    rm -rf /tmp/fbcp-ili9341
    info "fbcp-ili9341 installed to /usr/local/bin/fbcp-ili9341"

    sudo tee /etc/systemd/system/fbcp-ili9341.service > /dev/null <<'EOF'
[Unit]
Description=fbcp-ili9341 SPI Display Driver
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/fbcp-ili9341
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable fbcp-ili9341
    info "fbcp-ili9341 systemd service enabled"
}

apply_boot_config() {
    info "Applying /boot/config.txt..."
    if [[ -f /boot/config.txt ]]; then
        sudo cp /boot/config.txt /boot/config.txt.backup
        info "Previous config backed up to /boot/config.txt.backup"
    fi
    sudo cp "$REPO_DIR/boot/config.txt" /boot/config.txt

    info "Copying retrogame.cfg to /boot/..."
    sudo cp "$REPO_DIR/boot/retrogame.cfg" /boot/retrogame.cfg
}

install_retrogame() {
    if [[ -f /usr/local/bin/retrogame ]]; then
        skip "retrogame"
        return
    fi

    info "Building retrogame button daemon..."
    rm -rf /tmp/adafruit-retrogame
    git clone --depth=1 https://github.com/adafruit/Adafruit-Retrogame.git /tmp/adafruit-retrogame
    pushd /tmp/adafruit-retrogame > /dev/null
    make retrogame
    sudo cp retrogame /usr/local/bin/retrogame
    popd > /dev/null
    rm -rf /tmp/adafruit-retrogame

    sudo tee /etc/udev/rules.d/10-retrogame.rules > /dev/null <<'EOF'
SUBSYSTEM=="input", ATTRS{name}=="retrogame", ENV{ID_INPUT_KEYBOARD}="1"
EOF
    sudo udevadm control --reload-rules

    add_to_rc_local "/usr/local/bin/retrogame &"
    info "retrogame installed"
}

install_theme() {
    local theme_dir="/etc/emulationstation/themes/Null2"
    if [[ -d "$theme_dir" ]]; then
        skip "Null2 EmulationStation theme"
        return
    fi

    info "Installing Null2 EmulationStation theme..."
    sudo mkdir -p "$theme_dir"
    sudo cp -r "$REPO_DIR/theme/." "$theme_dir/"
    info "Theme installed to $theme_dir"
}

install_systembuttons() {
    if [[ -f /home/pi/Scripts/systembuttons.py ]]; then
        skip "systembuttons.py"
        return
    fi

    info "Installing systembuttons.py (volume + shutdown hotkeys)..."
    mkdir -p /home/pi/Scripts
    cp "$REPO_DIR/scripts/systembuttons.py" /home/pi/Scripts/systembuttons.py

    add_to_rc_local "sudo python3 /home/pi/Scripts/systembuttons.py &"
    info "systembuttons.py installed"
}

finish() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    info "Setup complete! Summary:"
    echo "  fbcp-ili9341  → /usr/local/bin/fbcp-ili9341 (systemd service)"
    echo "  retrogame     → /usr/local/bin/retrogame (rc.local)"
    echo "  config.txt    → /boot/config.txt"
    echo "  retrogame.cfg → /boot/retrogame.cfg"
    echo "  theme         → /etc/emulationstation/themes/Null2/"
    echo "  sysbuttons    → /home/pi/Scripts/systembuttons.py (rc.local)"
    echo "  log           → $LOG"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    warn "Reboot to apply all changes: sudo reboot"
    warn "On first boot, the screen will be white for a few minutes while"
    warn "the filesystem expands. This is normal — wait for the splash screen."
    echo ""
    warn "Safe shutdown: hold System button + press B."
    warn "Wait for the activity LED to stop flashing before flipping power off."
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    echo ""
    info "Null 2 Setup Script"
    info "Log: $LOG"
    echo ""

    check_root
    check_pi
    check_arch
    detect_model

    install_deps
    install_fbcp
    apply_boot_config
    install_retrogame
    install_theme
    install_systembuttons
    finish
}

main "$@"
