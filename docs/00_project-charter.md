# Project Charter — Q1 2026 FPGA Microstructure Accelerator

## Objective
Build a **streaming FPGA accelerator** that computes rolling market microstructure features with deterministic latency.

## Data source (Q1)
Databento **L1** (top-of-book + trades) via MBP-1 or consolidated CMBP-1, normalized into a canonical replay format.

## Scope (Q1)
- Platform: DE10-Nano (Cyclone V)
- Input: L1 quotes + trades (single symbol for Q1)
- Output cadence: 1–10 ms fixed time buckets
- Required features:
  - mid price
  - spread
  - microprice
  - rolling VWAP (trade-based)
  - OFI (L1 definition)
  - mid returns

Optional (only if time permits):
- short-horizon trend strength
- volatility regime
- liquidity regime (avg spread + top-of-book depth)

## Success criteria
- deterministic replay -> FPGA outputs match CPU golden model
- throughput + latency measured (min/median/p99)
- utilization + timing closure recorded and explained
- HW/SW boundary is explicit and justified

## Out of scope (Q1)
- Yocto/minimal OS image
- full depth order book (L2+)
- multi-symbol scaling
- live trading / exchange connectivity

