# Null 2

Archived resources for the **Null 2** DIY handheld game console, originally designed and sold on Tindie by [ampersand](https://github.com/DesignedbyAmpersand). The original website (null2.co.uk) is offline.

The Null 2 runs RetroPie on a Raspberry Pi Zero W or Zero 2 W, with a 3.2" ILI9341 SPI display, PCM5102A audio DAC, and a custom PCB.

---

## Getting started

See **[setup/README.md](setup/README.md)** for instructions on flashing and configuring your Null 2.

The setup script applies all Null 2 hardware config to a freshly flashed stock RetroPie image - flash the official download, SSH in, clone this repo, and run the script. The original pre-built Null 2 images are still available on OneDrive; see `setup/README.md` for links.

---

## Repository contents

| Folder | Contents |
|---|---|
| [`setup/`](setup/) | Setup script and instructions |
| [`boot/`](boot/) | `/boot/config.txt` and `retrogame.cfg` applied by the setup script |
| [`scripts/`](scripts/) | `systembuttons.py` - volume and safe shutdown hotkeys |
| [`theme/`](theme/) | Null2 EmulationStation theme |
| [`hardware/pcb/`](hardware/pcb/) | PCB Gerber files (v1.5) for manufacturing |
| [`hardware/laser-acrylic/`](hardware/laser-acrylic/) | Acrylic case laser cut files (3mm + 5mm) |
| [`hardware/laser-wood/`](hardware/laser-wood/) | Wooden case laser cut files |
| [`docs/`](docs/) | Build guide, user guide, wiring reference, and archived website pages |

---

## Hardware

- **Display:** 3.2" ILI9341 SPI, 240x320 (rotated to 320x240)
- **Audio:** PCM5102A I2S DAC + PAM8403 amplifier
- **Charging:** TP4056 module, 5V/2A max, no fast chargers
- **Input:** DS Lite rubber membranes + Adafruit retrogame GPIO daemon

Full parts list: [`docs/Null 2 Parts List.txt`](docs/Null%202%20Parts%20List.txt)
