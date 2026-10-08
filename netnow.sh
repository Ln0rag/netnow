#!/bin/bash

# ── Get current network ──────────────────────────────────────────
SSID=$(iwgetid -r 2>/dev/null)

if [ -z "$SSID" ]; then
    SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null |
           grep "^yes:" |
           cut -d: -f2)
fi

# ── Get active interface ─────────────────────────────────────────
IFACE=$(ip route show default 2>/dev/null |
        awk '/default/{print $5; exit}')

if [ -z "$IFACE" ]; then
    exit 1
fi

# ── Read current counters from /proc/net/dev ─────────────────────
read RX TX < <(
    awk -v iface="$IFACE:" '$0 ~ iface {print $2, $10}' /proc/net/dev
)

if [ -z "$RX" ] || [ -z "$TX" ]; then
    echo "Could not read counters for $IFACE"
    exit 1
fi

# ── Storage directory ────────────────────────────────────────────
CACHE_DIR="$HOME/.cache/netnow"
mkdir -p "$CACHE_DIR"

# ── Detect reboot and clear cache if needed ──────────────────────
BOOT_TIME=$(awk '/^btime/{print $2}' /proc/stat)
BOOT_FILE="$CACHE_DIR/.boot"

if [ -f "$BOOT_FILE" ]; then
    read SAVED_BOOT < "$BOOT_FILE"

    if [ "$BOOT_TIME" != "$SAVED_BOOT" ]; then
        # Reboot detected — wipe all saved counters
        rm -f "$CACHE_DIR"/* 2>/dev/null
        echo "$BOOT_TIME" > "$BOOT_FILE"
    fi
else
    echo "$BOOT_TIME" > "$BOOT_FILE"
fi

# ── Storage file per SSID (fallback to interface name) ──────────
KEY="${SSID:-$IFACE}"
FILE="$CACHE_DIR/$(echo "$KEY" | tr '/' '_')"

# ── Save or read baseline ────────────────────────────────────────
if [ -f "$FILE" ]; then
    read OLD_RX OLD_TX < "$FILE"
else
    OLD_RX=$RX
    OLD_TX=$TX
    echo "$RX $TX" > "$FILE"
fi

# ── Calculate difference ─────────────────────────────────────────
DIFF_RX=$((RX - OLD_RX))
DIFF_TX=$((TX - OLD_TX))

# ── Convert to MB ────────────────────────────────────────────────
UPLOAD=$(awk -v tx="$DIFF_TX" 'BEGIN {
    printf "%.1f", tx/1048576
}')

DOWNLOAD=$(awk -v rx="$DIFF_RX" 'BEGIN {
    printf "%.1f", rx/1048576
}')

# ── XFCE GenMon output ───────────────────────────────────────────
# ↑ Upload  = light orange
# ↓ Download = red

printf '<txt><span foreground="#F5A623">↑ %s MB</span><span foreground="#FF3333">↓ %s MB</span></txt>' \
    "$UPLOAD" "$DOWNLOAD"
