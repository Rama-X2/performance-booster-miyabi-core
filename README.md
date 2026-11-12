# 🌸 Performance Booster Miyabi Core

<div align="center">

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-orange.svg)](#)
[![Status](https://img.shields.io/badge/Status-Stable-brightgreen.svg)](#)
[![Version](https://img.shields.io/badge/Version-v1.0.0-purple.svg)](#)

**Advanced Autonomous Kernel & Scheduler Optimization Engine for Android**  
Author: Rama-X2 ([@Rama-X2](https://github.com/Rama-X2))

</div>

---

## Overview

Performance Booster Miyabi Core is an advanced, fully autonomous kernel and scheduler optimization engine engineered for rooted Android environments. It transitions away from conventional static script modifications by introducing real-time CPU cluster topology discovery, dynamic thread-level priority boosting, touchscreen hardware interrupt balancing, and zero-overhead native Linux cgroup tracking.

Everything operates autonomously at the Linux kernel level with zero manual whitelisting, zero background Java overhead, and zero risk to critical framework services.

---

## Technical Architecture

### 1. Zero-Overhead Native Linux Cgroup Detection (No Java IPC)
Unlike typical performance scripts that poll `dumpsys window` or `dumpsys activity` (which trigger heavy Android Java Binder transactions every few seconds), this engine interfaces directly with Linux pseudo-filesystems:
- Inspects `/dev/cpuset/top-app/cgroup.procs` and `/proc/$PID/cmdline` to identify foreground workloads in microseconds.
- Examines active task descriptors in `/proc/$PID/task/*/comm` to detect rendering threads (`RenderThread`, `UnityGfxDevice`, `GLThread`, `VkQueue`, `EGL`) natively.
- Background monitoring consumes less than 0.001% CPU, eliminating the micro-stutter and battery drain associated with shell-based Java polling.

### 2. Thread-Level Renicing and CPU Core Affinity Pinning
When a heavy 3D game or graphics workload is active:
- **RenderThread Elevation**: Inspects all sub-threads of the active workload and elevates graphic rendering threads to `renice -20` (highest Linux real-time priority).
- **Core Affinity Binding (`taskset`)**: Automatically binds rendering threads to Big and Prime CPU cores (Cortex-A7x, Cortex-X series) to eliminate frame-time spikes and maintain consistent 60/90/120 FPS frame pacing.

### 3. Touchscreen & VSync Hardware IRQ Balancing
On stock Android kernels, touchscreen interrupt lines (`goodix`, `focaltech`, `synaptics`, `novatek`, `sec_ts`) often default to CPU 0 alongside heavy operating system interrupts:
- The engine scans `/proc/interrupts` during boot to locate active touchscreen hardware controllers.
- Routes touch interrupts to dedicated CPU cores via `/proc/irq/$IRQ/smp_affinity_list`, reducing touch input latency and eliminating touch drops during heavy CPU loads.

### 4. RAM Capacity-Aware Virtual Memory (VM) Scaling
The engine inspects physical memory capacity (`/proc/meminfo`) and automatically configures adaptive parameters:
- **Entry Tier (<= 4 GB RAM)**: Configures `watermark_scale_factor=50`, `vfs_cache_pressure=70`, and balanced swappiness to prevent aggressive low-memory killing.
- **Mid Tier (6 GB - 8 GB RAM)**: Configures `watermark_scale_factor=100`, `vfs_cache_pressure=60`, and `swappiness=40` for fluid application switching.
- **Flagship Tier (12 GB+ RAM)**: Sets `watermark_scale_factor=150`, `vfs_cache_pressure=50`, and `swappiness=20`, retaining maximal filesystem and page caches in RAM.

### 5. Multi-Cluster Governor Synchronization
- **Tri-Cluster Aware**: Detects Little, Big, and Prime CPU policy domains dynamically.
- **Instant Frequency Ramp**: In gaming mode, sets `up_rate_limit_us=0` on Big and Prime cores for immediate frequency scaling on demand.
- **Sustained Load Latching**: Increases `down_rate_limit_us=40000` to prevent rapid CPU downclocking in intensive multiplayer scenes.

---

## Stability and Safety Design

- **Zero GMS Package Disabling**: Does not modify or disable Google Play Services. Push notifications, banking applications, and SafetyNet/Play Integrity remain fully operational.
- **No Hardware Composer Override**: Completely avoids modifying `/vendor/etc/init/android.hardware.graphics.composer*.rc`. Native SurfaceFlinger hardware composer operations remain untouched.
- **Safe LMKD Thresholds**: Does not inject aggressive Low Memory Killer kill limits, preventing applications from terminating upon opening.
- **Non-Destructive**: All adjustments occur strictly in volatile sysfs/procfs interfaces at runtime.

---

## Interactive CLI Dashboard (`miyabi-perf`)

An interactive command-line interface is available via any root terminal (Termux or ADB shell):

```bash
su
miyabi-perf [command]
```

### Available Commands

| Command | Action |
|---|---|
| `miyabi-perf status` | Displays full hardware topology, RAM tier, active process PID, thread count, and engine state. |
| `miyabi-perf monitor` | Launches a live terminal monitor refreshing every 2 seconds (similar to `htop`). |
| `miyabi-perf boost` | Manually forces immediate Turbo Burst, cache drop, and storage trim. |
| `miyabi-perf balance` | Restores default balanced daily profile. |
| `miyabi-perf powersave` | Manually forces energy-saving daily profile. |
| `miyabi-perf log` | Views complete boot initialization and dynamic event logs. |

---

## Installation

1. Download the latest `Performance-Booster-Miyabi-Core-v1.0.0.zip` from [Releases](https://github.com/Rama-X2/performance-booster-miyabi-core/releases).
2. Open your root manager: **Magisk**, **KernelSU**, or **APatch**.
3. Navigate to **Modules** -> **Install from storage**.
4. Select the `.zip` file and confirm installation.
5. Reboot the device.

---

## Compatibility

- **Root Environment**: Magisk v20.4+, KernelSU, KernelSU-Next, APatch.
- **Android Versions**: Android 9.0 up to Android 15+.
- **Architectures**: arm64-v8a, armeabi-v7a, x86_64.
- **Chipsets**: Qualcomm Snapdragon, MediaTek (Dimensity / Helio), Samsung Exynos, Google Tensor, Unisoc.

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**.  
See the [LICENSE](LICENSE) file for details.
