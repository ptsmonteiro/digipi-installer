# digipi-installer

Install [DigiPi](https://github.com/craigerl/digipi) on **non-Raspberry Pi hardware**, by applying its config files and services onto a stock **Debian trixie** system instead of requiring the official Raspberry Pi SD card image.

## What this is

[DigiPi](https://digipi.org/) by Craig Lamparter (KM6LYW) is a ham radio "operating system" that bundles tools like Direwolf, OpenWebRX, Winlink, and APRS into a single SD card image, built specifically for Raspberry Pi hardware running a **32-bit (armhf/arm32) OS**. The official image's binaries and packages target arm32 only — they don't run as-is on arm64 or amd64 systems.

The [craigerl/digipi](https://github.com/craigerl/digipi) GitHub repo publishes the underlying config files and original/modified code (for GPL compliance and education), but it is explicitly **not** a recipe for building a bootable image, and the tooling assumes a Raspberry Pi running arm32.

**digipi-installer** takes the config files, services, and source code from `craigerl/digipi` and applies/rebuilds them on **Debian trixie, arm64**, so DigiPi's functionality can run on 64-bit hardware the official image was never built for: arm64 boards that aren't a Pi, virtual machines, and eventually amd64 systems. Because the original components are arm32 binaries, this generally means compiling from source rather than reusing prebuilt packages — see [Architecture note](#architecture-note) below.

This project does not interact with or substitute for the official Patreon-distributed image in any way — it's a separate, from-scratch install path aimed at portability.

## Motivation

My primary use case is running DigiPi inside a **UTM virtual machine on an Apple Silicon (M1) MacBook**, which is arm64 and has no Raspberry Pi hardware to speak of. The official image's arm32 binaries and Pi-specific assumptions (boot firmware, `config.txt`, GPIO, codec boards) don't apply there, so this project re-implements the setup — rebuilding components for arm64 where needed — as a portable installer that runs on any Debian trixie target.

## Target platforms

| Platform | Status |
|---|---|
| Debian trixie, arm64 (e.g. UTM VM on Apple Silicon, other arm64 boards/VMs — not just Raspberry Pi) | 🎯 Primary target |
| Debian trixie, amd64 | 🧭 Planned |

The initial focus is arm64 since that's the primary development and test target (UTM on M1). amd64 support is intended as a later milestone, once the arm64 install path is solid. Pi-specific hardware integrations (GPIO, `config.txt`, codec boards, etc.) are out of scope — the goal is the software/services side of DigiPi running on generic 64-bit hardware or a VM.

## Architecture note

The official DigiPi image ships **arm32 (armhf)** binaries — there's no arm64 build of DigiPi's packaged components. That means this project can't just copy files from the original image and drop them onto Debian trixie arm64; instead, for each component it needs to either:

- **Compile from source** for arm64 (preferred where the upstream source is available, e.g. Direwolf, codec2, ax25-tools), or
- **Find/package an arm64-native equivalent**, or
- Run via **multiarch/armhf compatibility** (`qemu-user-static` + `dpkg --add-architecture armhf`) as a fallback for anything that resists a clean rebuild.


## How it works

1. Start from a clean Debian trixie install (arm64).
2. Run the installer script(s) in this repo.
3. The scripts install build dependencies, fetch/compile the relevant DigiPi components from source for arm64 (falling back to armhf multiarch where a clean rebuild isn't practical), drop the configs from `craigerl/digipi` into place, and enable the corresponding systemd services.

> **Status:** early development. Expect incomplete coverage of the full DigiPi feature set while this is being built out, especially for components that turn out to be harder to port from arm32.

## Usage

```bash
git clone https://github.com/<your-username>/digipi-installer.git
cd digipi-installer
sudo ./install.sh
```

*(Installer script(s) and exact usage will be filled in as the project develops.)*

## Why not just use the official image?

The official image is great if you're running real Raspberry Pi hardware — this project isn't a replacement for it there. It exists for cases the image doesn't cover, such as:

- Running DigiPi inside a VM (e.g. UTM on Apple Silicon) with no Pi hardware involved
- Running on arm64 boards/systems that aren't a Raspberry Pi
- Eventually, running on amd64 systems
- Layering DigiPi's services onto a Debian trixie install you already manage

## Relationship to upstream

This project is **not affiliated with** Craig Lamparter or the official DigiPi project. It consumes the publicly available files from `craigerl/digipi` and applies them in a different way (installer onto stock Debian) rather than via the official SD card image. All credit for the original tooling, configs, and integration work goes to the upstream DigiPi project.

## Status / Roadmap

- [ ] arm64 / Debian trixie install script, tested in UTM on Apple Silicon
- [ ] Document supported DigiPi features per stage
- [ ] amd64 / Debian trixie support
- [ ] CI testing on real or emulated hardware

## Contributing

Issues and PRs welcome, especially around testing on different hardware and tracking upstream `craigerl/digipi` changes.

