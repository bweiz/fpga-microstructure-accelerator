# Architecture

## Top-level blocks
1. Userspace replay source (Databento → canonical events)
2. Stream interface (Avalon-ST into FPGA)
3. FPGA feature pipeline (streaming, pipelined, fixed-point)
4. Output buffer (FIFO/BRAM) + control/status (Avalon-MM)
5. Userspace collector (reads outputs, compares to golden, logs metrics)

## Interfaces (Q1 intent)
- Avalon-ST: input event stream
- Avalon-MM: control/status + output record readout

## Buffering/backpressure
Define:
- input FIFO depth, drop policy, drop counters
- output FIFO depth and host drain strategy

## Measurement hooks (required)
- counters: events_in, events_dropped, buckets_out
- timestamp/latency measurement mechanism (FPGA cycle counter or host timestamping)

