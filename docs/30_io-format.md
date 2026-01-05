# I/O Format (Canonical Replay + Output Records)

This project uses Databento as the raw source, but the FPGA consumes a **canonical binary event format** so the hardware stays stable even if the data source changes.

All records are:
- **Fixed-width**
- **Little-endian**
- **Exactly 64 bytes** (power-of-two, DMA-friendly, cache-line friendly)
- Intended to live in DDR ring buffers and be moved in bursts via DMA

---

## Canonical event record (LOCKED SIZE / DRAFT FIELDS)
**Size:** 64 bytes  
**Endian:** little-endian  
**Alignment:** record size is 64B; ring base should be aligned to at least 4KB.

### Semantic fields (conceptual)
- `ts` (u64): timestamp in **nanoseconds since epoch** (see `docs/10_spec.md`)
- Top-of-book:
  - `bid_px`, `ask_px` (scaled integers; fixed-point scaling frozen in `docs/40_fixed-point.md`)
  - `bid_sz`, `ask_sz` (unsigned integer size)
- Trade (optional / may be zeroed):
  - `trade_px` (0 if none)
  - `trade_sz` (0 if none)
  - `trade_side` (0=unknown, 1=buy, 2=sell)
- `event_type` (0=quote, 1=trade, 2=both)
- `flags` reserved for adapter markings / future edge handling

### Binary layout (byte offsets)
Offset | Field | Type | Notes
---|---|---|---
0 | `ts` | u64 | ns since epoch
8 | `bid_px` | i32 | scaled by `PX_SCALE`
12 | `ask_px` | i32 | scaled by `PX_SCALE`
16 | `bid_sz` | u32 | size at best bid
20 | `ask_sz` | u32 | size at best ask
24 | `trade_px` | i32 | scaled by `PX_SCALE`, 0 if none
28 | `trade_sz` | u32 | 0 if none
32 | `trade_side` | u8 | 0/1/2
33 | `event_type` | u8 | 0/1/2
34 | `flags` | u16 | reserved (adapter-defined)
36 | `reserved0` | u32 | must be 0 in Q1
40 | `symbol_id` | u32 | Q1: set 0 (single-symbol); Phase 2+: use for multi-symbol
44 | `seq_no` | u32 | optional; Q1: set monotonic if convenient, else 0
48 | `reserved1` | u64 | must be 0 in Q1
56 | `reserved2` | u64 | must be 0 in Q1

**Notes**
- Q1 assumes **single symbol**. `symbol_id` is reserved for scaling later.
- `seq_no` is not required for correctness but is extremely useful for debugging (detect drops/corruption).

---

## Output bucket record (LOCKED SIZE / DRAFT FIELDS)
One output record **per bucket** (fixed cadence), including empty buckets (see `docs/10_spec.md`).

**Size:** 64 bytes  
**Endian:** little-endian

### Semantic fields
- `bucket_ts` (u64): canonical bucket timestamp (**bucket start**)
- `mid`, `spread`, `vwap` (i32): scaled by `PX_SCALE`
- `microprice` (i32): scaled by `PX_SCALE` with extra fractional bits (**`MP_FRAC_BITS`**, default 8)
- `ofi` (i32): signed OFI accumulator for the bucket
- `mid_ret` (i32): **difference return** over the bucket (see `docs/10_spec.md`)
- `flags` (u32): output flags (locked/crossed, uninitialized, vwap_carried, etc.)
- Optional debug fields: event count, last event timestamp

### Binary layout (byte offsets)
Offset | Field | Type | Notes
---|---|---|---
0 | `bucket_ts` | u64 | bucket start timestamp
8 | `mid` | i32 | `PX_SCALE`
12 | `spread` | i32 | `PX_SCALE`
16 | `microprice` | i32 | `PX_SCALE * 2^MP_FRAC_BITS`
20 | `vwap` | i32 | `PX_SCALE`
24 | `ofi` | i32 | signed
28 | `mid_ret` | i32 | signed, `PX_SCALE`
32 | `flags` | u32 | bitmask
36 | `bucket_event_count` | u32 | optional; 0 in empty buckets
40 | `last_event_ts` | u64 | optional; 0 if bucket had no events
48 | `reserved1` | u64 | 0
56 | `reserved2` | u64 | 0

### Output flags (recommended bit meanings)
Bit | Name | Meaning
---:|---|---
0 | `FLAG_UNINIT` | mid/spread not initialized yet
1 | `FLAG_EMPTY_BUCKET` | no events occurred inside bucket
2 | `FLAG_LOCKED_CROSSED` | bid >= ask occurred (spread clamped, microprice clamped)
3 | `FLAG_VWAP_CARRIED` | vwap carried forward because `sum_q == 0`
4 | `FLAG_OFI_VALID` | OFI valid (book initialized)

(Extend flags as needed; keep them stable once used in verification.)

---

## DDR Ring Buffer Contract (LOCKED STYLE)

The event ring and output ring live in DDR.

### Pointer style (LOCKED)
- Head/tail pointers are **record indices** in `[0, N)` (not byte offsets).
- Address = `base + (idx * 64)`.

### Full/empty rule (LOCKED)
- Ring is **full** when `next_head == tail`.
- Effective usable capacity is `N - 1` records.

### Roles
- **Event ring:** CPU produces (advances head), FPGA consumes (advances tail).
- **Output ring:** FPGA produces, CPU consumes.

---

## Databento adapter responsibility (host side)
- Parse Databento records (**MBP-1 / CMBP-1**)
- Normalize to canonical event record above
- Provide `ts` in **nanoseconds since epoch**
- Rescale prices into `PX_SCALE` (defined in `docs/40_fixed-point.md`)
- Define mapping rules for trade side and quote-only events
- Ensure canonical events are **non-decreasing in timestamp** (or drop + counter deterministically per spec)

