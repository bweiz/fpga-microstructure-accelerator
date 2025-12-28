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

## Bucket definition (LOCKED)

This project uses **time-based buckets** aligned to the event timestamp (epoch time).

### Timestamp
- `ts` is an **unsigned 64-bit integer** timestamp in **nanoseconds since epoch**.
- The adapter (Databento → canonical events) is responsible for providing `ts` in ns.

### Bucket width
- `BUCKET_NS` is a compile-time or runtime configuration value (default: `1_000_000` for 1 ms).
- Valid Q1 range: 1–10 ms.

### Bucket ID
For each event with timestamp `ts`:
- `bucket_id = ts / BUCKET_NS` (integer division)
- `bucket_ts = bucket_id * BUCKET_NS` (this is the bucket’s canonical timestamp)

### Emission policy (fixed cadence)
The system must emit **one output record per bucket** (fixed cadence). Buckets with no events are still emitted.

Event-driven implementation rule:
- Maintain `current_bucket_id`.
- For an incoming event with `bucket_id_new`:
  - While `current_bucket_id < bucket_id_new`:
    - **Finalize and emit** the current bucket record.
    - Advance `current_bucket_id += 1`.
    - Emit “empty bucket” records if needed (see below).
  - Then process the event inside `current_bucket_id == bucket_id_new`.

### Empty bucket behavior
If a bucket contains **no events**:
- `mid`, `spread`, `microprice`: **carry forward** the last known values
- `vwap`: carry forward the last known rolling VWAP value (trade window unchanged)
- `ofi_bucket`: `0`
- `mid_ret_bucket`: `0` (since `mid_end == mid_prev_end`)

### Out-of-order timestamps (determinism)
The canonical event stream must be **non-decreasing in `ts`**.
- If `ts` decreases vs the previous event, the event is **dropped** and a counter increments:
  - `events_dropped_out_of_order += 1`

## Order Flow Imbalance (OFI) — L1 (LOCKED)

We compute OFI from **top-of-book quote deltas** using the following rule per event.

Let the previous top-of-book be:
- `b_prev` (best bid price), `qb_prev` (best bid size)
- `a_prev` (best ask price), `qa_prev` (best ask size)

And the current top-of-book be:
- `b` (best bid), `qb` (best bid size)
- `a` (best ask), `qa` (best ask size)

Define the **bid contribution**:
- If `b > b_prev`: `ofi_bid = +qb`
- Else if `b < b_prev`: `ofi_bid = -qb_prev`
- Else (`b == b_prev`): `ofi_bid = +(qb - qb_prev)`

Define the **ask contribution**:
- If `a < a_prev`: `ofi_ask = -qa`
- Else if `a > a_prev`: `ofi_ask = +qa_prev`
- Else (`a == a_prev`): `ofi_ask = +(qa_prev - qa)`

Then the per-event OFI increment is:
- `ofi_event = ofi_bid + ofi_ask`

The per-bucket OFI is the sum over all events in the bucket:
- `ofi_bucket = Σ ofi_event` over events where `bucket_id(event) == bucket_id(bucket)`

### Interpretation
- Positive OFI ≈ net **buy pressure**
  - bid improves or bid size increases at same bid
  - ask worsens (moves up) or ask size decreases at same ask
- Negative OFI ≈ net **sell pressure**

### Trade events
- **Trades do not directly modify OFI**.
- If an event contains both a trade and a quote update, OFI is computed from the quote delta as normal.

### Initialization
OFI requires a valid previous book snapshot.
- Until both sides have been initialized (`b_prev,a_prev,qb_prev,qa_prev` valid), set `ofi_event = 0`.
- After initialization, update the stored previous snapshot after each processed event.

### Edge rules
- If `qb` or `qa` is zero, computations are still valid (OFI contributions may be 0).
- Locked/crossed market handling:
  - If `b >= a`, set `spread = 0` and clamp `microprice = mid` for that output record.
  - OFI still follows the delta rules above (deterministic).

## Determinism requirements
- fixed-point formats are frozen early and documented
- rounding + overflow/saturation policy is explicit
- handling of corner cases is defined (zero sizes, locked/crossed markets, missing trades)

