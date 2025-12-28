# I/O Format (Canonical Replay + Output Records)

This project uses Databento as the raw source, but the FPGA consumes a **canonical binary event format** so the hardware stays stable even if the data source changes.

## Canonical event record (draft)
Fixed-width, little-endian. Finalize once fixed-point scaling is chosen.

Suggested layout (16-byte aligned):
- u64 ts            (timestamp in ns or us; lock later)
- i32 bid_px
- i32 ask_px
- u32 bid_sz
- u32 ask_sz
- i32 trade_px      (0 if none)
- u32 trade_sz      (0 if none)
- u8  trade_side    (0=unknown, 1=buy, 2=sell)
- u8  event_type    (0=quote, 1=trade, 2=both)
- u16 flags/reserved

## Output record (draft)
- u64 bucket_ts
- i32 mid
- i32 spread
- i32 microprice
- i32 vwap
- i32 ofi
- i32 mid_ret
- u32 flags

## Databento adapter responsibility (host side)
- parse Databento records (MBP-1 / CMBP-1)
- normalize to canonical event record
- rescale prices to chosen fixed-point
- define mapping rules for "trade side" and quote-only events

