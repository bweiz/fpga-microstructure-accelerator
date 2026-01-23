# Register Map — Microstructure Accelerator (MMIO)

This document is the **contract** for the accelerator’s MMIO (control plane).
It will later evolve to include DMA orchestration for the data plane (DDR rings).

---

## MMIO Interface
- **Bus:** Avalon-MM slave (HPS lightweight bridge)
- **Endianness:** little-endian
- **Register width:** 32-bit
- **Addressing:** byte offsets (register *N* at offset `4*N`)
- **Access:** `readl/writel` semantics on the CPU side

---

## Register Base / Span

### Base address
**Base address:** `0x0017F400` *(placeholder from coursework; actual base subject to change)*

### Span
**Span (LOCKED):** `0x60` bytes 


---

## Register Map (byte offsets)

### 0) Identification (recommended)
Offset | Name | R/W | Reset | Description
---:|---|:---:|---:|---
0x00 | `ID` | R | 0x4D535452 | ASCII `'MSTR'` (microstructure accel ID)
0x04 | `VERSION` | R | 0x0001_0000 | Major.Minor packed (example)

### 1) Control / Configuration
Offset | Name | R/W | Reset | Description
---:|---|:---:|---:|---
0x08 | `CTRL` | R/W | 0x0000_0000 | bit0 START, bit1 STOP, bit2 RESET (see below)
0x0C | `STATUS` | R | 0x0000_0000 | bit0 RUNNING, bit1 ERROR, bit2 INIT_DONE (optional)
0x10 | `BUCKET_NS` | R/W | 1_000_000 | Bucket width in ns (default 1 ms)
0x14 | `VWAP_T_NS` | R/W | 0 | VWAP window in ns (0 = disabled until set)
0x18 | `MP_FRAC_BITS` | R/W | 8 | Microprice fractional bits (default 8)

**CTRL bit definitions**
- bit0 `START`: write 1 to start; write 0 to stop (or use STOP)
- bit1 `STOP`: optional explicit stop (implementation-defined; can alias START=0)
- bit2 `RESET`: resets internal pipeline state/counters (*self-clearing**)

> Recommended behavior: `RESET` clears counters and internal state, then self-clears to 0.

---

## 2) DDR Ring Configuration (record indices)

Rings are in DDR and addressed by **record index** (not byte offset).  
Record size is assumed **64 bytes** (see `docs/30_io-format.md`).

### Event ring (CPU -> FPGA)
Offset | Name | R/W | Reset | Description
---:|---|:---:|---:|---
0x1C | `EV_BASE_LO` | R/W | 0 | Event ring base address [31:0]
0x20 | `EV_BASE_HI` | R/W | 0 | Event ring base address [63:32] (0 on 32-bit systems)
0x24 | `EV_NRECS` | R/W | 0 | Number of 64B records in ring (N)
0x28 | `EV_HEAD` | R/W | 0 | Producer head index (CPU writes)
0x2C | `EV_TAIL` | R | 0 | Consumer tail index (FPGA updates)

### Output ring (FPGA -> CPU)
Offset | Name | R/W | Reset | Description
---:|---|:---:|---:|---
0x30 | `OUT_BASE_LO` | R/W | 0 | Output ring base address [31:0]
0x34 | `OUT_BASE_HI` | R/W | 0 | Output ring base address [63:32]
0x38 | `OUT_NRECS` | R/W | 0 | Number of 64B records in ring (N)
0x3C | `OUT_HEAD` | R | 0 | Producer head index (FPGA updates)
0x40 | `OUT_TAIL` | R/W | 0 | Consumer tail index (CPU writes)

**Ring full rule (LOCKED)**
- Ring is full when `next_head == tail` (usable capacity = `N - 1`)

---

## 3) Counters / Telemetry
Offset | Name | R/W | Reset | Description
---:|---|:---:|---:|---
0x44 | `EVENTS_IN` | R | 0 | Number of events consumed from event ring
0x48 | `EVENTS_DROPPED_OOO` | R | 0 | Dropped events due to out-of-order `ts`
0x4C | `BUCKETS_OUT` | R | 0 | Number of bucket records produced
0x50 | CYCLES_RUNNING_LO | R | 0 | Increments every FPGA clock while RUNNING=1
0x54 | LAST_BUCKET_CYCLES | R | 0 | Captured cycles-per-bucket at last bucket boundary
0x58 | SOFT_RESET_COUNT | R | 0 | Increments on each CTRL.RESET (soft reset pulse); clears on hard rst

> Optional extensions:
> - `IN_FIFO_HIWATER`, `OUT_FIFO_HIWATER`, `RING_OVERRUNS`, `STALL_CYCLES`, etc.

---

## Notes / Conventions
- All multiword addresses are little-endian (`*_LO` at lower offset, then `*_HI`).
- Reads of counters are side-effect free.
- Any “write-1-to-clear” counters must be explicitly documented.

