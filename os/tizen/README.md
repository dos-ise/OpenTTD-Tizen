# OpenTTD for Samsung Smart TV (Tizen)

OpenTTD compiled to WebAssembly and packaged as a Tizen widget (`.wgt`) for Samsung Smart TVs.

---

## Build

Requirements:
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- The full OpenTTD repo cloned to your machine

Run the build script from `os/tizen/`:

```
build.bat
```

This will:
1. Build a Docker image containing Tizen Studio 6.1 and Emscripten 3.1.57
2. Compile OpenTTD to WebAssembly
3. Package and sign it as a Tizen widget
4. Extract `OpenTTD.wgt` into the `os/tizen/` folder

The first build takes a while (downloading toolchains, compiling). Subsequent builds use Docker's cache and are much faster.

---

## Installation

The easiest way to install the generated `.wgt` file on your Samsung TV is by using:

**Samsung Jellyfin Installer**
https://github.com/Jellyfin2Samsung/Samsung-Jellyfin-Installer

Although designed for Jellyfin, the installer supports any Tizen widget and provides a streamlined installation workflow.

**Steps:**
1. Download and launch the Samsung Jellyfin Installer
2. Enable Developer Mode on your TV and connect it to the installer
3. Select the generated `OpenTTD.wgt` file
4. Install it onto the TV
5. Launch OpenTTD from the TV's app menu
