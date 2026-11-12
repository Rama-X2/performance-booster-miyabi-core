#!/system/bin/sh
# Performance Booster Miyabi Core - service.sh
# Copyright (C) 2026 Rama-X2
# Licensed under the GNU General Public License, Version 3.0
# Source: https://github.com/Rama-X2/performance-booster-miyabi-core

(
# Wait for Android OS to finish booting
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 3
done

# Wait for system services to stabilize
sleep 20

LOG_DIR="/data/adb/modules/performance-booster-miyabi-core"
LOG_FILE="$LOG_DIR/performance_miyabi.log"
mkdir -p "$LOG_DIR" 2>/dev/null

echo "==================================================" > "$LOG_FILE"
echo "  Performance Booster Miyabi Core Engine v1.0.0   " >> "$LOG_FILE"
echo "  Date: $(date)" >> "$LOG_FILE"
echo "==================================================" >> "$LOG_FILE"

log_info() {
  echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

write_safe() {
  local val="$1"
  local path="$2"
  if [ -f "$path" ]; then
    chmod 644 "$path" 2>/dev/null
    echo "$val" > "$path" 2>/dev/null
    log_info "Tuned: $path -> $val"
  fi
}

log_info "Initializing Dynamic Engine..."

# 1. Virtual Memory (VM) Optimization
log_info "Applying Virtual Memory (VM) Optimizations..."
write_safe 65 /proc/sys/vm/vfs_cache_pressure
write_safe 10 /proc/sys/vm/dirty_background_ratio
write_safe 20 /proc/sys/vm/dirty_ratio
write_safe 10 /proc/sys/vm/stat_interval
write_safe 0 /proc/sys/vm/compaction_proactiveness

# 2. Kernel Tracing & Overhead Reduction
log_info "Reducing kernel logging & tracing overhead..."
write_safe 0 /proc/sys/kernel/sched_schedstats
write_safe 0 /sys/kernel/tracing/tracing_on
write_safe 0 /sys/kernel/debug/tracing/tracing_on

# 3. CPU SchedTune & EAS uclamp Boost (Foreground responsiveness)
log_info "Optimizing CPU SchedTune & EAS uclamp for top-app..."
write_safe 1 /dev/stune/top-app/schedtune.prefer_idle
write_safe 10 /dev/stune/top-app/schedtune.boost
write_safe 10 /dev/cpuctl/top-app/cpu.uclamp.min
write_safe 1 /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive

# 4. CPU Governor Tuning (Schedutil / Interactive)
log_info "Scanning and tuning CPU frequency governors..."
for gov in /sys/devices/system/cpu/cpufreq/policy*/schedutil /sys/devices/system/cpu/cpu*/cpufreq/schedutil; do
  if [ -d "$gov" ]; then
    write_safe 500 "$gov/up_rate_limit_us"
    write_safe 20000 "$gov/down_rate_limit_us"
    write_safe 1000 "$gov/rate_limit_us"
  fi
done

# 5. Storage / Block I/O Tuning
log_info "Optimizing block device I/O read-ahead and queues..."
for block in /sys/block/sd* /sys/block/mmcblk* /sys/block/dm-* /sys/block/nvme*; do
  if [ -d "$block/queue" ]; then
    write_safe 512 "$block/queue/read_ahead_kb"
    write_safe 0 "$block/queue/add_random"
    write_safe 0 "$block/queue/iostats"
    write_safe 0 "$block/queue/rotational"
    write_safe 2 "$block/queue/rq_affinity"
  fi
done

# 6. Dynamic Chipset Acceleration (MediaTek / Qualcomm)
if [ -d "/sys/module/ged/parameters" ]; then
  log_info "MediaTek GPU/GED Engine detected! Applying GPU boost..."
  write_safe 1 /sys/module/ged/parameters/ged_boost_enable
  write_safe 1 /sys/module/ged/parameters/enable_gpu_boost
  write_safe 1 /sys/module/ged/parameters/gx_boost_on
  write_safe 1 /sys/module/ged/parameters/gx_game_mode
fi

if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
  log_info "Qualcomm Adreno GPU detected! Applying KGSL idle optimization..."
  write_safe 80 /sys/class/kgsl/kgsl-3d0/idle_timer
  write_safe 0 /sys/class/kgsl/kgsl-3d0/force_bus_on
  write_safe 0 /sys/class/kgsl/kgsl-3d0/force_clk_on
  write_safe 0 /sys/class/kgsl/kgsl-3d0/force_rail_on
fi

# 7. Network / TCP Gaming Low Latency
log_info "Applying TCP network low-latency parameters..."
write_safe 1 /proc/sys/net/ipv4/tcp_low_latency
write_safe 3 /proc/sys/net/ipv4/tcp_fastopen
write_safe 1 /proc/sys/net/ipv4/tcp_tw_reuse

# 8. Android Framework & Storage Trim
log_info "Executing background maintenance & storage trim..."
cmd power set-adaptive-power-saver-enabled false 2>/dev/null
fstrim -v /data 2>/dev/null >> "$LOG_FILE"
fstrim -v /cache 2>/dev/null >> "$LOG_FILE"

log_info "Performance Booster Miyabi Core active and running smoothly."
echo "==================================================" >> "$LOG_FILE"
) &
