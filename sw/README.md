# Software

- `refmodel/` — CPU golden model (truth for correctness)
- `host/` — Databento adapter + replay harness + benchmark runner
- `driver/` — optional UIO or small kernel module (Q1 scope)

Goal: deterministic replay → compare FPGA outputs vs golden → produce results under `results/`.

