# AirSim + ArduPilot SITL + QGroundControl (Pixi)

![AirSim-ArduPilotSITL](additional-readme/image.png)

Complete isolated simulation environment for **AirSim** with **ArduPilot SITL** and **QGroundControl** using **pixi** for dependency management.

## 🎯 Overview

This repository provides a **fully isolated** simulation environment for AirSim with ArduPilot SITL without polluting your system with manual apt installs. All dependencies are managed through pixi (conda-based), ensuring reproducibility and clean builds.

### What's Included

1. **AirSim** - Unreal Engine-based simulator (AirSimNH environment)
2. **ArduPilot SITL** - Software-in-the-loop flight controller (ArduCopter)
3. **QGroundControl** - Ground control station for mission planning

All components downloaded and configured in `.airsim_ardupilot/` directory.

## 📋 Prerequisites

- **Ubuntu 22.04** (tested)
- **pixi** installed ([Installation Guide](https://prefix.dev/docs/pixi/overview))
- **Git**

## 🚀 Quick Start

### 1. Install Dependencies

Initialize the Pixi environment with all required build tools and Python packages:

```bash
pixi install
```

This will create an isolated `simulation` environment with:

- Build toolchain (gcc, g++, make, pkg-config, ccache)
- Development tools (git, wget, unzip, zip, rsync)
- Python packages (empy, pexpect, dronecan, pymavlink, MAVProxy, etc.)

### 2. Activate Pixi Environment

Enter the pixi environment:

```bash
pixi shell
```

All subsequent commands should be run within this shell.

### 3. Download and Build Components

#### Download AirSim Environment

```bash
./scripts/download-airsim.sh
```

This will:

- Download AirSimNH environment (v1.8.1) from Microsoft AirSim releases
- Extract to `.airsim_ardupilot/airsim/AirSimNH/`
- Copy configuration from `config/airsim/settings.json`
- Create symlink at `~/Documents/AirSim/settings.json`

#### Download QGroundControl

```bash
./scripts/download-qground.sh
```

This will:

- Download latest QGroundControl AppImage
- Save to `.airsim_ardupilot/qgroundcontrol/`
- Make executable automatically

#### Build ArduPilot SITL

Compile ArduCopter for SITL:

```bash
./scripts/build-ardupilot-sitl.sh
```

This will:

- Clone ArduPilot repository (if not present)
- Update all submodules
- Configure and build ArduCopter binary for SITL
- Output binary at `.airsim_ardupilot/ardupilot/build/sitl/bin/arducopter`

Build options:

- `--clean` - Remove previous build artifacts
- `--force-clone` - Delete and re-clone ArduPilot repository

### 4. Verify Installation

Check that all components are ready:

```bash
./scripts/check-simulation.sh
```

This validates:

- ✅ AirSim environment and launcher
- ✅ QGroundControl AppImage
- ✅ ArduPilot SITL binary
- ✅ Pixi environment status

## 🔧 Configuration

### AirSim Settings

Configuration file: `config/airsim/settings.json`

Key settings:

- **Vehicle Type**: ArduCopter
- **Origin**: Lat -7.2823507, Lon 112.7923504, Alt 20m
- **Ports**: UDP 9003, Control 9002
- **Camera**: 1280x720, 90° FOV, pitch -90°
- **Sensors**: Barometer, IMU, GPS, Magnetometer enabled
- **ViewMode**: FlyWithMe (default)

### ArduPilot Parameters

Configuration file: `config/ardupilot/airsim.parm`

Optimized parameters for AirSim SITL:

- `SCHED_LOOP_RATE=180` - Reduced scheduler rate for stability
- `WPNAV_SPEED=140` - Limited waypoint speed (5 km/h)
- `ANGLE_MAX=1500` - Restricted attitude authority
- `WPNAV_ACCEL=50` - Smooth waypoint acceleration
- `SIM_SPEEDUP=20` - Simulation speedup factor
- GPS and failsafe thresholds relaxed for testing

## 🚁 Running the Simulation

### Simple Run (Recommended)

Start all components together:

```bash
./scripts/run-simulation.sh
```

Options:

- `--no-display` - Run AirSim in headless mode (NoDisplay)
- `--help` - Show usage information

This will:

1. Update ViewMode in settings.json based on display flag
2. Start QGroundControl (background)
3. Start AirSim environment (background)
4. Start ArduPilot SITL with parameter file (foreground)

Press `Ctrl+C` to stop all components gracefully.

### Manual Component Startup

If you prefer to start components individually:

```bash
# Terminal 1: QGroundControl
.airsim_ardupilot/qgroundcontrol/QGroundControl-x86_64.AppImage

# Terminal 2: AirSim
.airsim_ardupilot/airsim/AirSimNH/LinuxNoEditor/AirSimNH.sh

# Terminal 3: ArduPilot SITL (in pixi shell)
cd .airsim_ardupilot/ardupilot
python3 Tools/autotest/sim_vehicle.py -v ArduCopter --model airsim-copter \
  --console --map --out=127.0.0.1:14550 --out=127.0.0.1:14551 \
  --add-param-file=../../config/ardupilot/airsim.parm
```

## ⚙️ Environment Variables

- `AIRSIM_HOME` - Base directory for all components (default: `./.airsim_ardupilot`)
- `AIRSIM_ENV_RELEASE` - AirSim release tag (default: `v1.8.1`)
- `ARDUPILOT_REPO_URL` - ArduPilot repository URL
- `QGC_URL` - QGroundControl download URL

## 📁 Directory Structure

```text
airsim-qgroundcontrol-ardupilot-sitl-pixi/
├── pixi.toml                        # Pixi environment configuration
├── pixi.lock                        # Locked dependencies
├── README.md                        # This file
├── config/                          # Configuration files
│   ├── airsim/
│   │   └── settings.json            # AirSim settings template
│   └── ardupilot/
│       └── airsim.parm              # ArduPilot parameters
├── scripts/                         # Build and utility scripts
│   ├── download-airsim.sh           # Download AirSim environment
│   ├── download-qground.sh          # Download QGroundControl
│   ├── build-ardupilot-sitl.sh      # Build ArduPilot SITL
│   ├── check-simulation.sh          # Verify installation
│   └── run-simulation.sh            # Run all components
└── .airsim_ardupilot/               # Workspace (created by scripts)
    ├── airsim/
    │   ├── AirSimNH/                # Unreal Engine environment
    │   └── settings.json            # Active AirSim configuration
    ├── qgroundcontrol/
    │   └── QGroundControl-x86_64.AppImage
    └── ardupilot/
        ├── build/sitl/bin/arducopter
        └── Tools/autotest/sim_vehicle.py
```

## 🔧 Pixi Environment Details

The `simulation` environment defined in `pixi.toml` provides:

### From Pixi (conda environment)

- Python 3.11-3.12
- Build toolchain (gcc, g++, make, pkg-config, ccache)
- Development tools (git, wget, unzip, zip, rsync)

### PyPI Packages

- empy 3.3.4 (template engine for ArduPilot waf)
- pexpect (process automation)
- dronecan (DroneCAN/UAVCAN support)
- future (Python 2/3 compatibility)
- pymavlink (MAVLink protocol library)
- MAVProxy (MAVLink proxy and command shell)
- pyserial (serial communication)
- packaging, monotonic (utility libraries)

## 🆘 Troubleshooting

### Build Errors

If ArduPilot build fails:

```bash
./scripts/build-ardupilot-sitl.sh --clean
```

### Missing Dependencies

Ensure you're in the Pixi environment:

```bash
pixi shell
```

### Settings Not Applied

Re-run the download script to reset settings:

```bash
rm -rf .airsim_ardupilot/airsim/settings.json
./scripts/download-airsim.sh
```

## 📝 Notes

- **Isolation**: All components installed in `.airsim_ardupilot/` directory
- **No System Pollution**: No manual `apt install` required
- **Reproducible**: pixi.lock ensures identical dependency versions
- **Auto Configuration**: ArduPilot parameters automatically loaded on startup
- **MAVLink**: QGroundControl connects on port 14550, telemetry on 14551

## 📚 References

- [AirSim GitHub](https://github.com/microsoft/AirSim)
- [ArduPilot Documentation](https://ardupilot.org/)
- [QGroundControl User Guide](https://docs.qgroundcontrol.com/)
- [Pixi Documentation](https://prefix.dev/docs/pixi/overview)
- [MAVLink Protocol](https://mavlink.io/en/)

## 📄 License

Follow respective licenses of:

- ArduPilot: GPLv3
- AirSim: MIT License
- QGroundControl: Apache 2.0 / GPLv3
- This build system: Use freely

---

Built with ❤️ using Pixi for clean, reproducible simulation environments
