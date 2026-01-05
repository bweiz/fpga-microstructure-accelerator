# Bring-up Smoke Test — Microstructure Accelerator (MMIO Control Plane)

This document defines the **minimum proof** that the accelerator is wired correctly:
- Platform Designer address map is correct
- Device Tree binds the device
- Driver maps MMIO registers correctly
- Userspace can configure + control the device
- FPGA counters change deterministically

This is **Milestone #1**. No DMA required.

---

## Prereqs
- DE10-Nano boots Linux and you have **serial console** access.
- FPGA image programmed that includes the accelerator MMIO slave regs.
- Device Tree includes a node for the accelerator with the correct `reg = <base size>`.

---

## Expected Artifacts
- Driver module loads cleanly (or built-in driver probes cleanly).
- A device appears (choose one depending on your interface):
  - **Char device**: `/dev/mstr0` (example)
  - **Sysfs**: `/sys/bus/platform/devices/.../`
  - **UIO** (prototype only): `/dev/uio0`

> This project aims for a real platform driver, but the smoke test works either way.

---

## Step 0 — Confirm kernel sees the device (DT → platform device)
1. Boot and log in over serial.
2. Confirm the platform device exists:

What you’re looking for:
- A platform device whose name matches your DT node (often based on `compatible`)
- A mapped MMIO region at your expected base address

Pass criteria:
- Platform device exists and reports the correct `reg` range.

---

## Step 1 — Load the driver and confirm probe()
1. Load the module (if module-based) or confirm it probed on boot.
2. Check kernel logs (serial output is fine).

What you’re looking for in the logs:
- `probe()` runs
- MMIO resource acquired
- regs mapped
- device interface created (char dev / sysfs / uio)

Pass criteria:
- No errors, no deferred probe loops, no resource conflicts.

---

## Step 2 — Read ID + VERSION (sanity check)
Read:
- `ID` register @ `0x00` should be ASCII `'MSTR'` (`0x4D535452`)
- `VERSION` @ `0x04` should match your build value

Pass criteria:
- `ID` matches exactly (this proves you’re reading the correct address space)
- `VERSION` is non-zero and stable across reads

Fail symptoms:
- `ID = 0xFFFFFFFF` or `0x00000000` usually means wrong mapping/span/bridge
- Random values suggest wrong base address or bus issues

---

## Step 3 — Reset behavior
1. Write `CTRL.RESET = 1`.
2. Confirm it self-clears (recommended behavior).
3. Confirm counters reset to 0.

Pass criteria:
- RESET bit returns to 0 automatically (or clears on explicit write per your spec)
- `EVENTS_IN`, `EVENTS_DROPPED_OOO`, `BUCKETS_OUT` read as 0 after reset

---

## Step 4 — START/STOP behavior (no DMA yet)
This test assumes the FPGA design increments a simple internal counter while RUNNING.

1. Write config regs:
- `BUCKET_NS` = default (1_000_000) or any valid value
- `VWAP_T_NS` = 0 (disabled for now)
- `MP_FRAC_BITS` = 8

2. Write `CTRL.START = 1`.
3. Wait ~1–2 seconds.
4. Read:
- `STATUS.RUNNING` (if implemented)
- `BUCKETS_OUT` (or a dedicated `HEARTBEAT_COUNTER` if you added one)

5. Write `CTRL.START = 0` (or `CTRL.STOP = 1`).
6. Read counters again after waiting.

Pass criteria:
- While running: the chosen “activity counter” increases monotonically
- After stop: the counter stops changing (or changes only in a defined way)

---

## Step 5 — Counter read stability
1. Read each counter register multiple times in a row.
2. Confirm read is side-effect free.

Pass criteria:
- Counters do not reset or jump backward due to reads
- Reads are consistent with expected motion (only increasing unless reset)

---

## Step 6 — Negative tests (quick but valuable)
### Wrong-span test (diagnostic)
If you intentionally reduce `SPAN` in DT below the required size, you should see:
- failures reading registers near the top of the map
- or probe errors if driver validates resource length

### Wrong-base test (diagnostic)
If base is wrong you typically see:
- `ID` mismatch immediately

Pass criteria:
- Your system fails loudly and obviously in the presence of wrong mapping
  (this prevents silent bad bring-up later)

---

## “Done Means…” (Milestone #1 complete)
You can power-cycle and reliably reproduce:
- driver probes cleanly
- `ID == 'MSTR'`
- `RESET` clears state/counters
- `START` causes deterministic counter activity
- `STOP` halts activity
- reads are stable and side-effect free

Once this is true, you are safe to move to **Milestone #2: Output DMA pattern writer**.

---

## Troubleshooting Cheatsheet
- **ID wrong** → wrong base address, wrong bridge, DT `reg` mismatch, or wrong Platform Designer mapping
- **Probe fails resource** → DT `reg` wrong size or overlaps another device
- **Counters never change** → START bit not wired, clock/reset gating issue, or RTL never sees the write
- **Counters change when STOP** → STOP not implemented or START not latched correctly
- **RESET doesn’t clear** → reset not wired to all sub-blocks or RESET not self-clearing as documented

