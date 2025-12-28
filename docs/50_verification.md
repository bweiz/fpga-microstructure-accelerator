# Verification Plan

## Golden reference model
CPU implementation is the source of truth.
It must match FPGA fixed-point behavior (rounding/overflow).

## Deterministic vectors
Store small vectors in `data/vectors/` with expected outputs.

Include corner cases:
- zero sizes
- locked/crossed markets (policy defined)
- bursts
- long runs to test rolling windows

## Stages
1) unit tests (golden model)
2) RTL sim vs golden
3) hardware replay vs golden
4) stress tests + drop counter validation

