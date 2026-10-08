# netnow

A tiny XFCE panel script that shows how much data you've uploaded and downloaded on the **current Wi-Fi network**.

![Screenshot](screenshot.png)

## How it works

1. Detects the current SSID (`iwgetid`, falls back to `nmcli`) and the active interface (`ip route`).
2. Reads the RX/TX byte counters from `/proc/net/dev`.
3. Saves a baseline per network in `~/.cache/netnow/` the first time it runs on that network.
4. On each run, prints usage since that baseline (↑ upload in orange, ↓ download in red) in MB.
5. Detects a reboot (via `btime` in `/proc/stat`) and clears all baselines, since the kernel counters reset too.

## Requirements

- Linux with XFCE and the **Generic Monitor (GenMon)** panel plugin
- `ip`, `awk`, and either `iwgetid` or `nmcli`

## Install

```bash
chmod +x ~/.netnow.sh
```

Then add a **Generic Monitor** item to the XFCE panel and set:

- **Command:** `/home/<you>/.netnow.sh`
- **Period:** `5` seconds (or whatever you prefer)
- Uncheck **Label**

## Reset a network's counter

```bash
rm ~/.cache/netnow/"<SSID>"
```

Or reset everything:

```bash
rm -rf ~/.cache/netnow
```

## Notes

- Usage is counted from the first run on each SSID (within the current boot), not from the start of the month.
- If there's no default route (no connection), the script prints nothing.
- Wired connections work too; the interface name is used instead of the SSID.
