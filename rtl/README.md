# RTL

RTL for the streaming feature pipeline.

Design principles:
- backpressure-safe (valid/ready)
- pipelined
- deterministic latency once configured
- fixed-point math documented in `docs/40_fixed-point.md`

