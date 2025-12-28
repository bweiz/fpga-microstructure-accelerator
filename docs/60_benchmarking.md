# Benchmarking & Reporting

Measure:
- events/sec sustained
- end-to-end latency (min/median/p99)
- bucket jitter (if any)
- fmax achieved and timing slack
- ALMs/LUTs, DSPs, BRAM

Store artifacts under:
- `results/latency/`
- `results/utilization/`
- `results/plots/`

Comparison:
- CPU-only replay (same vectors) vs FPGA replay

