cat > scripts/mstr_smoke.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------------------------
# mstr_smoke.sh — DE10-Nano / Cyclone V FPGA Microstructure Accelerator
#
# Usage:
#   sudo ./scripts/mstr_smoke.sh
#   sudo ./scripts/mstr_smoke.sh 0xff37f400
#
# Requires:
#   devmem (often from busybox: busybox devmem)
# --------------------------------------------------------------------

BASE_ADDR="${1:-0xff37f400}"

# Register offsets (bytes) from docs
OFF_ID=0x00
OFF_VERSION=0x04
OFF_CTRL=0x08
OFF_STATUS=0x0C
OFF_BUCKET_NS=0x10

# Counters / telemetry (4B/4C)
OFF_BUCKETS_OUT=0x4C        # word 19
OFF_CYCLES_RUNNING=0x50     # word 20 (requires span >= 0x60)
OFF_LAST_BUCKET_CYCLES=0x54 # word 21
OFF_SOFT_RESET_COUNT=0x58   # word 22

# CTRL bits
CTRL_START=0x1
CTRL_STOP=0x2
CTRL_RESET=0x4

# Default test params
BUCKET_NS_DEFAULT=1000000    # 1 ms
SLEEP_RUN_S=0.2              # run duration in seconds
SLEEP_STOP_S=0.1             # stop duration in seconds

# Choose devmem command (devmem or busybox devmem)
if command -v devmem >/dev/null 2>&1; then
  DEVMEM="devmem"
elif command -v busybox >/dev/null 2>&1 && busybox devmem >/dev/null 2>&1; then
  DEVMEM="busybox devmem"
else
  echo "ERROR: devmem not found. Install devmem or busybox with devmem."
  exit 1
fi

# 32-bit read/write helpers
read32() {
  local addr="$1"
  # devmem <addr> 32
  $DEVMEM "$addr" 32
}

write32() {
  local addr="$1"
  local val="$2"
  # devmem <addr> 32 <value>
  $DEVMEM "$addr" 32 "$val" >/dev/null
}

# Add offset to base (both are hex like 0xff37f400)
addr_add() {
  local base="$1"
  local off="$2"
  python3 - <<PY
base=int("$base",16)
off=int("$off",16)
print(hex(base+off))
PY
}

reg_read() {
  local off="$1"
  local a
  a="$(addr_add "$BASE_ADDR" "$off")"
  read32 "$a"
}

reg_write() {
  local off="$1"
  local val="$2"
  local a
  a="$(addr_add "$BASE_ADDR" "$off")"
  write32 "$a" "$val"
}

banner() {
  echo "------------------------------------------------------------"
  echo "$1"
  echo "------------------------------------------------------------"
}

hex32() {
  # Print as 0xXXXXXXXX
  python3 - <<PY
v=int("$1",0) & 0xffffffff
print("0x%08X" % v)
PY
}

read_print() {
  local name="$1"
  local off="$2"
  local v
  v="$(reg_read "$off")"
  printf "%-20s @ +%-6s = %s\n" "$name" "$off" "$(hex32 "$v")"
}

main() {
  banner "MSTR SMOKE TEST (BASE=${BASE_ADDR})"

  banner "1) Read ID / VERSION"
  read_print "ID"      "$OFF_ID"
  read_print "VERSION" "$OFF_VERSION"

  banner "2) Configure BUCKET_NS = ${BUCKET_NS_DEFAULT} (1ms)"
  reg_write "$OFF_BUCKET_NS" "$BUCKET_NS_DEFAULT"
  read_print "BUCKET_NS" "$OFF_BUCKET_NS"

  banner "3) Soft RESET pulse (CTRL bit2) — clear counters"
  reg_write "$OFF_CTRL" "$CTRL_RESET"
  # Read counters after reset
  read_print "BUCKETS_OUT"       "$OFF_BUCKETS_OUT"
  read_print "CYCLES_RUNNING"    "$OFF_CYCLES_RUNNING"
  read_print "LAST_BUCKET_CYCLES" "$OFF_LAST_BUCKET_CYCLES"
  read_print "SOFT_RESET_COUNT"  "$OFF_SOFT_RESET_COUNT"

  banner "4) START (CTRL bit0), run for ${SLEEP_RUN_S}s"
  reg_write "$OFF_CTRL" "$CTRL_START"
  sleep "$SLEEP_RUN_S"

  banner "5) Read STATUS + counters while running"
  read_print "STATUS"            "$OFF_STATUS"
  read_print "BUCKETS_OUT"       "$OFF_BUCKETS_OUT"
  read_print "CYCLES_RUNNING"    "$OFF_CYCLES_RUNNING"
  read_print "LAST_BUCKET_CYCLES" "$OFF_LAST_BUCKET_CYCLES"
  read_print "SOFT_RESET_COUNT"  "$OFF_SOFT_RESET_COUNT"

  banner "6) STOP (CTRL bit1), wait ${SLEEP_STOP_S}s, verify counters stop"
  reg_write "$OFF_CTRL" "$CTRL_STOP"
  sleep "$SLEEP_STOP_S"

  banner "7) Read STATUS + counters after stop (should hold steady)"
  read_print "STATUS"            "$OFF_STATUS"
  read_print "BUCKETS_OUT"       "$OFF_BUCKETS_OUT"
  read_print "CYCLES_RUNNING"    "$OFF_CYCLES_RUNNING"
  read_print "LAST_BUCKET_CYCLES" "$OFF_LAST_BUCKET_CYCLES"
  read_print "SOFT_RESET_COUNT"  "$OFF_SOFT_RESET_COUNT"

  banner "8) Soft RESET again — counters should clear; reset count should increment"
  reg_write "$OFF_CTRL" "$CTRL_RESET"
  read_print "STATUS"            "$OFF_STATUS"
  read_print "BUCKETS_OUT"       "$OFF_BUCKETS_OUT"
  read_print "CYCLES_RUNNING"    "$OFF_CYCLES_RUNNING"
  read_print "LAST_BUCKET_CYCLES" "$OFF_LAST_BUCKET_CYCLES"
  read_print "SOFT_RESET_COUNT"  "$OFF_SOFT_RESET_COUNT"

  banner "DONE"
  echo "Expected sanity (50MHz, 1ms buckets):"
  echo " - LAST_BUCKET_CYCLES ~= 50000"
  echo " - BUCKETS_OUT after 0.2s ~= 200"
  echo " - CYCLES_RUNNING after 0.2s ~= 10,000,000"
}
main
EOF

chmod +x scripts/mstr_smoke.sh

echo "Created: scripts/mstr_smoke.sh"
echo "Run it on the DE10 with: sudo ./scripts/mstr_smoke.sh"

