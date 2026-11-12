# Performance Booster Miyabi Core

<div align="center">

```text
           ╔══════════════════════╗               
           ║           (≧◡≦)          ║              
           ║        Miyabi Core       ║              
           ╚══════════════════════╝               
                      ／l、                          
                    （ﾟ､ ｡ ７                        
                     l、  ~ヽ                        
                     じしf_, )ノ                     
```

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Universal](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-orange.svg)](#)
[![Stability](https://img.shields.io/badge/Stability-100%25%20Crash--Free-brightgreen.svg)](#)
[![Version](https://img.shields.io/badge/Version-v1.0.0-purple.svg)](#)

**Ultimate Kernel & System Responsiveness Optimizer (Miyabi Core Engine)**  
*Developed by Rama-X2 (@Rama-X2)*

</div>

---

## 🌟 Overview

**Performance Booster Miyabi Core** is a next-generation Android performance optimization module designed with strict safety, zero application crashes, and seamless compatibility across **Magisk**, **KernelSU**, and **APatch**.

Unlike primitive performance modules that break critical system services (such as disabling GMS components, forcing incompatible hardware composer configs, or setting aggressive memory killers), **Performance Booster Miyabi Core** tunes the Linux kernel dynamically at runtime using native schedulers, modern Virtual Memory parameters, and intelligent chipset detection.

---

## 🚀 Key Features

- **🐾 100% Safe & Crash-Free Architecture**
  - **No broken GMS hacks**: Zero package manager tampering, ensuring Google Play Services, banking apps, games, and messengers run without Force Close.
  - **No hardware composer override**: Native SurfaceFlinger and display pipelines remain intact.
  - **Safe LMKD parameters**: Preserves Android's memory killer threshold so apps are not randomly terminated upon opening.

- **⚡ Kernel & EAS SchedTune Engine**
  - Optimizes `top-app` cgroup scheduling for immediate foreground thread response.
  - Schedutil governor tuning: sets ultra-responsive `up_rate_limit_us` (500μs) and smoother frequency ramp-down (`20000μs`).
  - Android 11+ `uclamp` latency-sensitive priority for foreground touch interactions.

- **🧠 Smart Virtual Memory (VM) Tuning**
  - Balanced `vfs_cache_pressure` (65) to maintain filesystem cache and prevent stutter during app switching.
  - Smooth dirty ratios (`dirty_ratio: 20`, `dirty_background_ratio: 10`) preventing disk write bottlenecks.
  - Disables kernel statistics (`sched_schedstats`, `ftrace`) to free up CPU cycles.

- **💾 Block Storage I/O Acceleration**
  - Dynamically scans storage devices (`UFS`, `eMMC`, `NVMe`) and sets optimal 512 KB read-ahead.
  - Disables entropy contribution and rotational overhead on flash storage.

- **🎮 Dynamic Chipset Accelerators**
  - **Qualcomm Snapdragon**: Optimizes Adreno KGSL idle timers to prevent rapid downclocking during gameplay.
  - **MediaTek (Dimensity / Helio)**: Activates GED GPU Boost and dynamic game mode flags safely.

- **📱 Interactive CLI Dashboard (`miyabi-perf`)**
  - Built-in root command-line tool accessible directly via Termux or ADB shell (`su -c miyabi-perf`).

---

## 🛠️ Interactive CLI (`miyabi-perf`)

You can control and inspect the performance engine anytime via terminal:

```bash
su
miyabi-perf
```

### Commands:
| Command | Description |
|---|---|
| `miyabi-perf status` | Displays live engine state, active CPU governor, VM cache pressure, and I/O status. |
| `miyabi-perf boost` | Executes on-demand cache drop, storage trim, and turbo SchedTune burst. |
| `miyabi-perf balance` | Re-applies balanced gaming & daily performance profile. |
| `miyabi-perf powersave` | Switches to daily battery-friendly profile. |
| `miyabi-perf log` | Views recent runtime optimization logs. |

---

## 📥 Installation

1. Download the flashable `.zip` from [Releases](https://github.com/Rama-X2/performance-booster-miyabi-core/releases).
2. Open **Magisk**, **KernelSU**, or **APatch** app.
3. Tap **Modules** -> **Install from storage**.
4. Select `Performance-Booster-Miyabi-Core-v1.0.0.zip`.
5. Enjoy the Miyabi Core Cat installation screen!
6. Reboot your device.

---

## 📋 Compatibility

- **Root Solutions**: Magisk v20.4+, KernelSU, KernelSU-Next, APatch.
- **Android Versions**: Android 9.0 (Pie) up to Android 15+.
- **Chipsets**: Qualcomm Snapdragon, MediaTek (Dimensity / Helio), Samsung Exynos, Google Tensor, Unisoc.

---

## 📄 License & Credits

- **Author**: [Rama-X2](https://github.com/Rama-X2)
- **Part of the Miyabi Core Project**:
  - [charger-protector-miyabi-core](https://github.com/Rama-X2/charger-protector-miyabi-core)
  - [gms-breaker-miyabi-core](https://github.com/Rama-X2/gms-breaker-miyabi-core)
  - [thermal-breaker-miyabi-core](https://github.com/Rama-X2/thermal-breaker-miyabi-core)
- **License**: [GNU General Public License v3.0](LICENSE)
