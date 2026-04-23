# Null 2 Setup

Flash RetroPie onto an SD card and configure it for the Null 2 hardware.

## What you need

- A built Null 2 (see [docs/](../docs/) for build guide)
- A micro SD card (8GB+)
- A computer with [Raspberry Pi Imager](https://www.raspberrypi.com/software/) installed

---

## Step 1: Flash RetroPie

Download the correct base image for your Pi:

| Pi model | Image |
|---|---|
| **Pi Zero W** (original) | [RetroPie for Pi Zero/Zero W](https://retropie.org.uk/download/) - select "Raspberry Pi 0/1" |
| **Pi Zero 2 W** | [RetroPie for Pi Zero 2 W](https://retropie.org.uk/download/) - select "Raspberry Pi Zero 2 W" |

This script is for a fresh RetroPie install - it applies Null 2 hardware config on top of a stock image. It does not modify a pre-existing Null 2 image.

The original Null 2 pre-built images are still available on OneDrive (links in [`docs/Website PDFs/Null 2 Pi Zero 1 Image.pdf`](../docs/Website%20PDFs/Null%202%20Pi%20Zero%201%20Image.pdf) and [`docs/Website PDFs/Null 2 Pi Zero 2 Image.pdf`](../docs/Website%20PDFs/Null%202%20Pi%20Zero%202%20Image.pdf)). Pi Zero 2 image is RetroPie 4.7.19, Pi Zero 1 is 4.1. Current release is 4.8.

Open Raspberry Pi Imager, select your image, and before writing press **Ctrl+Shift+X** to open advanced options:
- Set your **WiFi credentials** (SSID + password)
- Enable **SSH**
- Optionally set hostname (e.g. `null2`)

Write the image to your SD card.

---

## Step 2: First boot

Insert the SD card into the Null 2 (slot is on the left side). Flip the power switch.

The screen will be **white for a few minutes** while the filesystem expands - this is normal. Wait for the RetroPie splash screen.

Find the Pi's IP address from your router, or use `null2.local` if you set a hostname.

---

## Step 3: SSH in and run setup

```bash
ssh pi@null2.local
# default password: raspberry
```

Change the default password, then clone this repo and run the setup script:

```bash
git clone https://github.com/arebokert/Null2.git
cd Null2
bash setup/install.sh
```

The script will:
- Detect your Pi model
- Install build dependencies
- Build and install **fbcp-ili9341** (SPI display driver, takes ~10 min on Pi Zero W)
- Apply `/boot/config.txt`
- Build and install **retrogame** (GPIO button daemon)
- Install the Null2 EmulationStation theme
- Install **systembuttons.py** (volume + shutdown hotkeys)

Progress is logged to `/home/pi/null2-setup.log`.

---

## Step 4: Reboot

```bash
sudo reboot
```

---

## Adding ROMs

Transfer ROMs via SFTP to `/home/pi/RetroPie/roms/<system>/` while the Pi is on your WiFi.

See the [RetroPie ROM transfer guide](https://retropie.org.uk/docs/Transferring-Roms/) for details (SFTP section).

---

## Controls

Full button layout in [`docs/Website PDFs/Null 2 User Guide.pdf`](../docs/Website%20PDFs/Null%202%20User%20Guide.pdf). Quick reference:

| Combo | Action |
|---|---|
| System + B | Safe shutdown |
| System + L | Volume down |
| System + R | Volume up |
| Select + Start | Exit game |
| Select + X | Open RetroArch menu |
| Select + L / R | Load / save state |

Always use System + B to shut down. Wait for the activity LED to stop flashing before flipping the power switch.

---

## Charging

- **5V/2A max** - fast chargers (e.g. Google Pixel) will damage the TP4056 module.
- RED LED = charging, BLUE LED = charged.
- Don't charge while the device is on.
- Headphones don't mute the speakers - use the mute switch.
