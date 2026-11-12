#!/system/bin/sh
# Performance Booster Miyabi Core - customize.sh
# Copyright (C) 2026 Rama-X2
# Licensed under the GNU General Public License, Version 3.0
# Source: https://github.com/Rama-X2/performance-booster-miyabi-core

ui_print "=================================================="
ui_print "           ╔══════════════════════╗               "
ui_print "           ║           (≧◡≦)          ║              "
ui_print "           ║        Miyabi Core       ║              "
ui_print "           ╚══════════════════════╝               "
ui_print "                      ／l、                          "
ui_print "                    （ﾟ､ ｡ ７                        "
ui_print "                     l、  ~ヽ                        "
ui_print "                     じしf_, )ノ                     "
ui_print "   『 Performance Booster Miyabi Core v1.0.0 』   "
ui_print "=================================================="
ui_print " Created by : Rama-X2"
ui_print " GitHub     : https://github.com/Rama-X2"
ui_print "--------------------------------------------------"

# Device Detection
BRAND=$(getprop ro.product.brand)
[ -z "$BRAND" ] && BRAND=$(getprop ro.product.manufacturer)
MODEL=$(getprop ro.product.model)
DEVICE=$(getprop ro.product.device)
PLATFORM=$(getprop ro.board.platform)
[ -z "$PLATFORM" ] && PLATFORM=$(getprop ro.hardware)
ANDROID_VER=$(getprop ro.build.version.release)
API_LEVEL=$(getprop ro.build.version.sdk)
ABI=$(getprop ro.product.cpu.abi)
KERNEL_VER=$(uname -r)

ui_print " [i] Device Details:"
ui_print "     • Brand        : $BRAND"
ui_print "     • Model        : $MODEL ($DEVICE)"
ui_print "     • Platform/SOC : $PLATFORM"
ui_print "     • Android      : $ANDROID_VER (API $API_LEVEL)"
ui_print "     • Architecture : $ABI"
ui_print "     • Kernel       : $KERNEL_VER"
ui_print "--------------------------------------------------"

# Remove skip_mount if created by previous install
rm -f "$MODPATH/skip_mount"

# Detect and fix nested zip extraction
for dir in "$MODPATH"/*; do
  if [ -d "$dir" ] && [ -f "$dir/module.prop" ]; then
    ui_print " [*] Fixing nested zip structure..."
    mv "$dir"/* "$MODPATH/" 2>/dev/null
    rm -rf "$dir" 2>/dev/null
    break
  fi
done

# Clean carriage returns (dos2unix) on all executable scripts
ui_print " [*] Sanitizing line endings (dos2unix)..."
for file in "$MODPATH"/system/bin/miyabi-perf "$MODPATH"/service.sh "$MODPATH"/uninstall.sh "$MODPATH"/post-fs-data.sh; do
  if [ -f "$file" ]; then
    tr -d '\r' < "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
done

# Set permissions
ui_print " [*] Setting executable permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/system/bin/miyabi-perf" 0 0 0755 2>/dev/null || chmod 0755 "$MODPATH/system/bin/miyabi-perf"
set_perm "$MODPATH/service.sh" 0 0 0755 2>/dev/null || chmod 0755 "$MODPATH/service.sh"
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755 2>/dev/null || chmod 0755 "$MODPATH/post-fs-data.sh"
set_perm "$MODPATH/uninstall.sh" 0 0 0755 2>/dev/null || chmod 0755 "$MODPATH/uninstall.sh"

# Restore SELinux contexts
ui_print " [*] Restoring SELinux contexts..."
restorecon -R "$MODPATH/system/bin" 2>/dev/null
restorecon "$MODPATH/service.sh" 2>/dev/null
restorecon "$MODPATH/post-fs-data.sh" 2>/dev/null
restorecon "$MODPATH/uninstall.sh" 2>/dev/null

# KernelSU and APatch bin path fallback
if [ -d "/data/adb/ksu/bin" ]; then
  ui_print " [*] Integrating with KernelSU CLI environment..."
  cp -f "$MODPATH/system/bin/miyabi-perf" /data/adb/ksu/bin/miyabi-perf
  chmod 0755 /data/adb/ksu/bin/miyabi-perf 2>/dev/null
  restorecon /data/adb/ksu/bin/miyabi-perf 2>/dev/null
fi

if [ -d "/data/adb/apatch/bin" ]; then
  ui_print " [*] Integrating with APatch CLI environment..."
  cp -f "$MODPATH/system/bin/miyabi-perf" /data/adb/apatch/bin/miyabi-perf
  chmod 0755 /data/adb/apatch/bin/miyabi-perf 2>/dev/null
  restorecon /data/adb/apatch/bin/miyabi-perf 2>/dev/null
fi

ui_print " [✓] Installation Complete! 100% Stable & Crash-Free."
ui_print "==================『 REBOOT DEVICE 』=================="
ui_print " "
