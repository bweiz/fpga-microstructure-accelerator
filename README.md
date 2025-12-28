# Q1 2026 FPGA Project — Finance / Microstructure Accelerator

A **streaming FPGA accelerator** (DE10-Nano / Cyclone V) that ingests a high-rate stream of **top-of-book (L1) quotes + trades** and emits **rolling market microstructure features** on a fixed cadence (1–10 ms buckets).

**Data source (Q1):** Databento **L1** (MBP-1 or consolidated CMBP-1), normalized into a canonical binary event format for FPGA replay.

> This is an engineering performance project (latency/throughput/determinism), not trading advice.

---

## What this project is (and isn’t)

**Is:**
- Streaming computation (event-by-event)
- Microstructure features: mid, spread, microprice, VWAP, OFI, returns
- Deterministic replay + verification vs CPU golden model
- Benchmark-driven design and documentation

**Is not:**
- Daily indicators / long-horizon TA
- Batch analytics
- Full depth order book (L2+) in Q1 (future extension)

---

## Repo map

- `docs/` — source of truth: spec, IO formats, fixed-point, verification, benchmarking
- `rtl/` — streaming RTL pipeline + interfaces
- `hw/` — Quartus / Platform Designer integration for DE10-Nano
- `sw/` — CPU golden model + replay/benchmark host app + driver/UIO
- `data/` — deterministic vectors + small sample streams (no large datasets in git)
- `scripts/` — build/run/plot helpers
- `results/` — benchmark artifacts (latency histograms, resource tables, plots)

Start here: **`docs/README.md`**

---

## Success criteria (Q1)

1. Replay drives FPGA deterministically; outputs match CPU golden model.
2. Throughput + latency are measured (min/median/p99) and defensible.
3. Resource utilization + timing closure results are captured and explained.
4. HW/SW boundary is explicit: what runs where, and why.

If it cannot be **shown or measured**, it does not count.

---

## License
MIT — see `LICENSE`.

