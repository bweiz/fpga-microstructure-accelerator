# Specification

## Input events (canonical fields)
Each event in the canonical replay stream contains:
- timestamp
- bid price, ask price
- bid size, ask size
- trade price, trade size (0 if quote-only event)
- trade side (buy/sell/unknown)
- event type (quote update vs trade)

## Output per time bucket
One output record per bucket:
- bucket timestamp (start or end; choose and keep consistent)
- mid
- spread
- microprice
- rolling VWAP (over a defined rolling window)
- OFI (L1 definition)
- mid return over bucket

## Bucket definition (locked for Q1)
Time-based buckets (recommended):
- bucket_id = floor((timestamp - t0) / bucket_ns)
- emit once per bucket in order

## Determinism requirements
- fixed-point formats are frozen early and documented
- rounding + overflow/saturation policy is explicit
- handling of corner cases is defined (zero sizes, locked/crossed markets, missing trades)

