#!/system/bin/sh
# Performance Booster Miyabi Core - service.sh
# Copyright (C) 2026 Rama-X2
# Licensed under the GNU General Public License, Version 3.0
# Source: https://github.com/Rama-X2/performance-booster-miyabi-core
# Architecture: Advanced Dynamic Kernel & Scheduler Engine (Zero-Dumpsys Native IPC)

(
# Wait for Android OS boot completion
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 2
done

# Allow critical system daemons to settle
sleep 15

LOG_DIR="/data/adb/modules/performance-booster-miyabi-core"
LOG_FILE="$LOG_DIR/performance_miyabi.log"
mkdir -p "$LOG_DIR" 2>/dev/null

echo "========================================================" > "$LOG_FILE"
echo " Performance Booster Miyabi Core - Next-Gen Kernel Engine " >> "$LOG_FILE"
echo " Version: v1.0.0 | Author: Rama-X2                      " >> "$LOG_FILE"
echo " Initialization Timestamp: $(date)                     " >> "$LOG_FILE"
echo "========================================================" >> "$LOG_FILE"

log() {
  echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

write_val() {
  local val="$1"
  local target="$2"
  if [ -f "$target" ]; then
    chmod 644 "$target" 2>/dev/null
    echo "$val" > "$target" 2>/dev/null
  fi
}

# ==============================================================================
# PHASE 1: HARDWARE & TOPOLOGY DISCOVERY
# ==============================================================================

# 1. Total Physical RAM Detection (KB)
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
log "Detected Physical RAM: ${TOTAL_RAM_MB} MB"

# 2. CPU Architecture & Cluster Detection
CPU_PRESENT=$(cat /sys/devices/system/cpu/present 2>/dev/null)
CPU_ONLINE=$(cat /sys/devices/system/cpu/online 2>/dev/null)
TOTAL_CORES=$(grep -c ^processor /proc/cpuinfo)
log "CPU Cores: $TOTAL_CORES (Present: $CPU_PRESENT | Online: $CPU_ONLINE)"

# Discover Big & Prime CPU Core masks
BIG_CORES=""
LITTLE_CORES=""
PRIME_CORE=""

# Parse cluster policies
POLICIES=$(ls -d /sys/devices/system/cpu/cpufreq/policy* 2>/dev/null | sort -V)
POLICY_COUNT=$(echo "$POLICIES" | wc -w)
log "Detected cpufreq policies: $POLICY_COUNT policy domain(s)"

if [ "$POLICY_COUNT" -ge 3 ]; then
  # Tri-cluster (Little + Big + Prime, e.g. Snapdragon 8 Gen series, Dimensity 9000)
  LITTLE_POLICY=$(echo "$POLICIES" | sed -n '1p')
  BIG_POLICY=$(echo "$POLICIES" | sed -n '2p')
  PRIME_POLICY=$(echo "$POLICIES" | sed -n '3p')
  
  LITTLE_CORES=$(cat "$LITTLE_POLICY/affected_cpus" 2>/dev/null || cat "$LITTLE_POLICY/related_cpus" 2>/dev/null)
  BIG_CORES=$(cat "$BIG_POLICY/affected_cpus" 2>/dev/null || cat "$BIG_POLICY/related_cpus" 2>/dev/null)
  PRIME_CORE=$(cat "$PRIME_POLICY/affected_cpus" 2>/dev/null || cat "$PRIME_POLICY/related_cpus" 2>/dev/null)
elif [ "$POLICY_COUNT" -eq 2 ]; then
  # Dual-cluster (Little + Big, e.g. Snapdragon 600/700 series, Helio G series)
  LITTLE_POLICY=$(echo "$POLICIES" | sed -n '1p')
  BIG_POLICY=$(echo "$POLICIES" | sed -n '2p')
  
  LITTLE_CORES=$(cat "$LITTLE_POLICY/affected_cpus" 2>/dev/null || cat "$LITTLE_POLICY/related_cpus" 2>/dev/null)
  BIG_CORES=$(cat "$BIG_POLICY/affected_cpus" 2>/dev/null || cat "$BIG_POLICY/related_cpus" 2>/dev/null)
  PRIME_CORE="$BIG_CORES"
else
  # Single cluster fallback
  ALL_CORES=$(cat /sys/devices/system/cpu/online 2>/dev/null)
  LITTLE_CORES="$ALL_CORES"
  BIG_CORES="$ALL_CORES"
  PRIME_CORE="$ALL_CORES"
fi

log "Cluster Mapping -> Little: [$LITTLE_CORES] | Big: [$BIG_CORES] | Prime: [$PRIME_CORE]"

# Convert Big/Prime cores to hex taskset mask for thread affinity
TASKSET_BIG_MASK="ff"
if [ -n "$PRIME_CORE" ]; then
  # Build bitmask
  MASK=0
  for core in $BIG_CORES $PRIME_CORE; do
    MASK=$(( MASK | (1 << core) ))
  done
  TASKSET_BIG_MASK=$(printf "%x" $MASK)
fi
log "Calculated Big/Prime CPU Affinity Mask: 0x$TASKSET_BIG_MASK"

# ==============================================================================
# PHASE 2: RAM CAPACITY-AWARE VIRTUAL MEMORY TUNING
# ==============================================================================

log "Applying RAM Capacity-Aware VM Tuning..."

if [ "$TOTAL_RAM_MB" -le 4096 ]; then
  # Low/Entry RAM tier (<= 4GB): Balanced caching, prevents OOM kills
  write_val 70 /proc/sys/vm/vfs_cache_pressure
  write_val 50 /proc/sys/vm/watermark_scale_factor
  write_val 15 /proc/sys/vm/dirty_background_ratio
  write_val 25 /proc/sys/vm/dirty_ratio
  write_val 60 /proc/sys/vm/swappiness
elif [ "$TOTAL_RAM_MB" -le 8192 ]; then
  # Mid RAM tier (6GB - 8GB): Retain active file caches, smoother multitasking
  write_val 60 /proc/sys/vm/vfs_cache_pressure
  write_val 100 /proc/sys/vm/watermark_scale_factor
  write_val 10 /proc/sys/vm/dirty_background_ratio
  write_val 20 /proc/sys/vm/dirty_ratio
  write_val 40 /proc/sys/vm/swappiness
else
  # High/Flagship RAM tier (12GB+): Aggressive caching, near-zero reclaim
  write_val 50 /proc/sys/vm/vfs_cache_pressure
  write_val 150 /proc/sys/vm/watermark_scale_factor
  write_val 5 /proc/sys/vm/dirty_background_ratio
  write_val 15 /proc/sys/vm/dirty_ratio
  write_val 20 /proc/sys/vm/swappiness
fi

write_val 1500 /proc/sys/vm/stat_interval
write_val 0 /proc/sys/vm/compaction_proactiveness
write_val 0 /proc/sys/kernel/sched_schedstats
write_val 0 /sys/kernel/tracing/tracing_on
write_val 0 /sys/kernel/debug/tracing/tracing_on

# ==============================================================================
# PHASE 3: TOUCHSCREEN & VSYNC IRQ AFFINITY BALANCING
# ==============================================================================

log "Balancing Touchscreen and VSync Hardware Interrupts..."

# Route touch interrupts away from CPU0 to Core 1 or Core 2 to eliminate input lag
TOUCH_IRQS=$(grep -E 'goodix|fts_ts|focaltech|synaptics|sec_ts|novatek|touch|ts-irq' /proc/interrupts 2>/dev/null | awk -F':' '{print $1}' | tr -d ' ')

if [ -n "$TOUCH_IRQS" ]; then
  for irq in $TOUCH_IRQS; do
    if [ -f "/proc/irq/$irq/smp_affinity_list" ]; then
      # Pin touch IRQ to CPU 1 (or second core)
      echo "1" > "/proc/irq/$irq/smp_affinity_list" 2>/dev/null
      log "Touch IRQ ($irq) bound to CPU core 1"
    fi
  done
else
  log "No dedicated touch IRQ pattern found; using kernel default."
fi

# ==============================================================================
# PHASE 4: STORAGE I/O ACCELERATION
# ==============================================================================

log "Configuring Storage Layer Block Queues..."
for blk in /sys/block/sd* /sys/block/mmcblk* /sys/block/dm-* /sys/block/nvme*; do
  if [ -d "$blk/queue" ]; then
    write_val 512 "$blk/queue/read_ahead_kb"
    write_val 0 "$blk/queue/add_random"
    write_val 0 "$blk/queue/iostats"
    write_val 0 "$blk/queue/rotational"
    write_val 2 "$blk/queue/rq_affinity"
    write_val 0 "$blk/queue/nomerges"
  fi
done

# ==============================================================================
# PHASE 5: NETWORK STACK GAMING LOW LATENCY
# ==============================================================================

write_val 1 /proc/sys/net/ipv4/tcp_low_latency
write_val 3 /proc/sys/net/ipv4/tcp_fastopen
write_val 1 /proc/sys/net/ipv4/tcp_tw_reuse

# Storage maintenance
cmd power set-adaptive-power-saver-enabled false 2>/dev/null
fstrim -v /data 2>/dev/null >> "$LOG_FILE"

# ==============================================================================
# PHASE 6: DYNAMIC PROFILE CONTROLLERS
# ==============================================================================

apply_balanced_profile() {
  log "State Change -> BALANCED DAILY PROFILE (Cool & Energy Efficient)"
  
  # EAS / SchedTune balanced
  write_val 1 /dev/stune/top-app/schedtune.prefer_idle
  write_val 10 /dev/stune/top-app/schedtune.boost
  write_val 10 /dev/cpuctl/top-app/cpu.uclamp.min
  write_val 1 /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive
  
  # Little cores governor
  for pol in $LITTLE_POLICY; do
    if [ -d "$pol/schedutil" ]; then
      write_val 1000 "$pol/schedutil/up_rate_limit_us"
      write_val 10000 "$pol/schedutil/down_rate_limit_us"
    fi
  done
  
  # Big / Prime cores governor
  for pol in $BIG_POLICY $PRIME_POLICY; do
    if [ -d "$pol/schedutil" ]; then
      write_val 500 "$pol/schedutil/up_rate_limit_us"
      write_val 20000 "$pol/schedutil/down_rate_limit_us"
    fi
  done
  
  # GPU Balanced
  if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
    write_val 80 /sys/class/kgsl/kgsl-3d0/idle_timer
  fi
  
  echo "BALANCED (Daily Smooth)" > "$LOG_DIR/current_profile"
  rm -f "$LOG_DIR/active_game_pid" 2>/dev/null
}

apply_gaming_profile() {
  local target_pid="$1"
  local target_pkg="$2"
  log "Heavy Workload Detected: $target_pkg (PID: $target_pid) -> ACTIVATING EXTREME GAMING TURBO!"
  
  # Instant memory cache drop to maximize free heap
  sync
  echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
  
  # EAS / SchedTune Maximum Priority (Zero Stutter)
  write_val 1 /dev/stune/top-app/schedtune.prefer_idle
  write_val 40 /dev/stune/top-app/schedtune.boost
  write_val 40 /dev/cpuctl/top-app/cpu.uclamp.min
  write_val 1 /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive
  
  # Zero-Latency CPU Ramp-up across Big and Prime policies
  for pol in $BIG_POLICY $PRIME_POLICY $POLICIES; do
    if [ -d "$pol/schedutil" ]; then
      write_val 0 "$pol/schedutil/up_rate_limit_us"
      write_val 40000 "$pol/schedutil/down_rate_limit_us"
      write_val 500 "$pol/schedutil/rate_limit_us"
    fi
  done
  
  # GPU Full Throttle Flags
  if [ -d "/sys/module/ged/parameters" ]; then
    write_val 1 /sys/module/ged/parameters/ged_boost_enable
    write_val 1 /sys/module/ged/parameters/enable_gpu_boost
    write_val 1 /sys/module/ged/parameters/gx_boost_on
    write_val 1 /sys/module/ged/parameters/gx_game_mode
  fi
  
  if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
    write_val 120 /sys/class/kgsl/kgsl-3d0/idle_timer
    write_val 0 /sys/class/kgsl/kgsl-3d0/force_bus_on
    write_val 0 /sys/class/kgsl/kgsl-3d0/force_clk_on
    write_val 0 /sys/class/kgsl/kgsl-3d0/force_rail_on
  fi
  
  # --------------------------------------------------------------------------
  # THREAD RENICING & CPU CORE AFFINITY (THE FRAME RATE STABILIZER)
  # --------------------------------------------------------------------------
  if [ -d "/proc/$target_pid/task" ]; then
    # Elevate main process priority
    renice -n -20 -p "$target_pid" 2>/dev/null
    
    # Iterate through process threads to locate RenderThread and Main loop
    for tid in /proc/$target_pid/task/*; do
      TID=$(basename "$tid")
      TNAME=$(cat "$tid/comm" 2>/dev/null)
      
      case "$TNAME" in
        *Render*|*Unity*|*Main*|*GLThread*|*VkQueue*|*Surface*|*Worker*|*Game*)
          # Maximum Real-Time Nice Level
          renice -n -20 -p "$TID" 2>/dev/null
          
          # Bind rendering thread to Big/Prime cores if taskset is available
          if command -v taskset >/dev/null 2>&1; then
            taskset -p "$TASKSET_BIG_MASK" "$TID" 2>/dev/null
          fi
          ;;
      esac
    done
    log "RenderThreads prioritized (Nice: -20, Affinity: 0x$TASKSET_BIG_MASK)"
  fi
  
  echo "GAMING TURBO ($target_pkg)" > "$LOG_DIR/current_profile"
  echo "$target_pid" > "$LOG_DIR/active_game_pid"
}

# ==============================================================================
# PHASE 7: ZERO-OVERHEAD NATIVE LINUX CGROUP FOREGROUND DETECTOR
# ==============================================================================

# Determines foreground PID using pure Linux cgroup pseudo-files (NO Java dumpsys)
get_top_app_pid() {
  local pid=""
  if [ -f "/dev/cpuset/top-app/cgroup.procs" ]; then
    # Filter out system_server or zygote PIDs
    for p in $(cat /dev/cpuset/top-app/cgroup.procs 2>/dev/null); do
      if [ "$p" -gt 1000 ] 2>/dev/null; then
        cmd=$(cat "/proc/$p/cmdline" 2>/dev/null | tr '\0' ' ')
        case "$cmd" in
          *system_server*|*surfaceflinger*|*zygote*|*android.hardware*)
            continue
            ;;
          *)
            pid="$p"
            break
            ;;
        esac
      fi
    done
  elif [ -f "/dev/stune/top-app/cgroup.procs" ]; then
    pid=$(head -n 1 /dev/stune/top-app/cgroup.procs 2>/dev/null)
  fi
  echo "$pid"
}

is_heavy_gaming_workload() {
  local p="$1"
  [ -z "$p" ] || [ ! -d "/proc/$p" ] && return 1
  
  local cmdline
  cmdline=$(cat "/proc/$p/cmdline" 2>/dev/null | tr '\0' ' ' | awk '{print $1}')
  [ -z "$cmdline" ] && return 1
  
  # Exclude system launchers, keyboards, and common daily utilities immediately
  case "$cmdline" in
    *launcher*|*systemui*|*inputmethod*|*keyboard*|*whatsapp*|*telegram*|*instagram*|*tiktok*|*facebook*|*twitter*|*chrome*|*browser*|*youtube*|*spotify*|*settings*)
      return 1
      ;;
  esac
  
  # 1. Native RenderThread / Graphics Thread inspection
  if [ -d "/proc/$p/task" ]; then
    THREAD_NAMES=$(cat /proc/$p/task/*/comm 2>/dev/null)
    case "$THREAD_NAMES" in
      *RenderThread*|*UnityGfxDevice*|*GLThread*|*VkQueue*|*EGL*|*FMOD*|*CriWare*)
        return 0
        ;;
    esac
  fi
  
  # 2. Universal Signatures for Games, Ported Titles, and Emulators
  case "$cmdline" in
    *game*|*mobile.legends*|*dts.freefire*|*pubg*|*tencent.ig*|*miHoYo*|*hoyoverse*|*roblox*|*cod*|*activision*|*epicgames*|*riotgames*|*wildrift*|*ea.gp.*|*konami*|*gameloft*|*kurogame*|*carx*|*krafton*|*minecraft*|*mojang*|*supercell*|*clash*|*brawlstars*|*genshin*|*honkai*|*zenless*|*nikke*|*bluearchive*|*fgo*|*garena*|*unity*|*unreal*|*godot*|*emulator*|*ppsspp*|*yuzu*|*citra*|*aethersx2*|*dolphin*|*vita3k*|*skyline*|*netvios*|*winlator*|*mobox*|*box64*|*pojav*|*sudachi*|*strato*|*rpcs*|*retroarch*|*mupen*|*drastic*|*joiplay*|*renpy*|*fbe*|*fps*)
      return 0
      ;;
  esac
  
  return 1
}

# Apply default baseline
apply_balanced_profile
CURRENT_MODE="balanced"
LAST_CHECKED_PID=""

log "Autonomous Kernel Event Monitor Initialized (Zero-Dumpsys Loop)..."

# ==============================================================================
# PHASE 8: AUTONOMOUS REAL-TIME MONITORING LOOP
# ==============================================================================

while true; do
  sleep 2
  
  TOP_PID=$(get_top_app_pid)
  
  if [ -n "$TOP_PID" ] && [ "$TOP_PID" != "$LAST_CHECKED_PID" ]; then
    LAST_CHECKED_PID="$TOP_PID"
    
    if is_heavy_gaming_workload "$TOP_PID"; then
      PKG_NAME=$(cat "/proc/$TOP_PID/cmdline" 2>/dev/null | tr '\0' ' ' | awk '{print $1}')
      if [ "$CURRENT_MODE" != "gaming" ]; then
        apply_gaming_profile "$TOP_PID" "$PKG_NAME"
        CURRENT_MODE="gaming"
      fi
    else
      if [ "$CURRENT_MODE" != "balanced" ]; then
        apply_balanced_profile
        CURRENT_MODE="balanced"
      fi
    fi
  fi
done
) &
