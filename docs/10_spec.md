# Specification

## Input events (canonical fields)
Each event in the canonical replay stream contains:
- timestamp `ts` (u64, **nanoseconds since epoch**)
- bid price, ask price
- bid size, ask size
- trade price, trade size (0 if quote-only event)
- trade side (buy/sell/unknown)
- event type (quote update vs trade vs both)

## Output per time bucket
One output record per bucket (fixed cadence):
- `bucket_ts` (**bucket start timestamp**, locked)
- `mid`
- `spread`
- `microprice`
- rolling VWAP (over a defined rolling window)
- OFI (L1 definition)
- `mid_ret` (bucket return — locked definition below)

Binary layouts and scaling live in `docs/30_io-format.md` and `docs/40_fixed-point.md`.

---

## Bucket definition (LOCKED)

### Timestamp
- `ts` is an unsigned 64-bit integer timestamp in **nanoseconds since epoch**.
- The adapter (Databento → canonical events) is responsible for providing `ts` in ns.

### Bucket width
- `BUCKET_NS` is a compile-time or runtime configuration value (default: `1_000_000` for 1 ms).
- Valid Q1 range: 1–10 ms.

### Bucket ID
For each event with timestamp `ts`:
- `bucket_id = ts / BUCKET_NS` (integer division)
- `bucket_ts = bucket_id * BUCKET_NS` (**bucket start time**)

### Bucket end time (for windowed stats)
- `bucket_end_ts = bucket_ts + BUCKET_NS`

### Emission policy (fixed cadence)
The system must emit **one output record per bucket**. Buckets with no events are still emitted.

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
- `mid`, `spread`, `microprice`: **carry forward** last known values
- `vwap`: carry forward last known rolling VWAP value (trade window unchanged)
- `ofi_bucket`: `0`
- `mid_ret_bucket`: `0`

### Out-of-order timestamps (determinism)
The canonical event stream must be **non-decreasing in `ts`**.
- If `ts` decreases vs the previous event, the event is **dropped** and a counter increments:
  - `events_dropped_out_of_order += 1`

---

## Mid-price return over bucket (LOCKED, simple + deterministic)
This project uses a **difference return** (not log, not percent) for Q1:

- Let `mid_end(bucket)` be the final mid observed inside the bucket.  
  - If the bucket had no events: `mid_end(bucket) = mid_end(prev_bucket)` (carry-forward).

Then:
- `mid_ret_bucket = mid_end(bucket) - mid_end(prev_bucket)`

(You can add percent/log returns later as additional fields if desired.)

---

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

Then:
- `ofi_event = ofi_bid + ofi_ask`
- `ofi_bucket = Σ ofi_event` over events in the bucket

### Trade events
- Trades do not directly modify OFI.
- If an event contains both a trade and quote update, OFI is computed from quote delta as normal.

### Initialization
- Until both sides have been initialized, set `ofi_event = 0`.
- After initialization, update the stored previous snapshot after each processed event.

### Edge rules (LOCKED)
- If `qb` or `qa` is zero, computations still proceed deterministically.
- Locked/crossed market handling:
  - If `b >= a`, set `spread = 0` and clamp `microprice = mid` for that output record.
  - OFI still follows the delta rules above.

---

## VWAP — Time Window (LOCKED)

We compute rolling VWAP over the last `VWAP_T_MS` milliseconds, based on **trade timestamps**.

### Parameters
- `VWAP_T_MS`: configurable window length in ms (Q1 recommended: 100–2000 ms)
- `VWAP_T_NS = VWAP_T_MS * 1_000_000`
- Window evaluated at **bucket end time**:
  - `bucket_end_ts = bucket_ts + BUCKET_NS`

### Trade eligibility
A trade with timestamp `ts_trade` is included if:
- `bucket_end_ts - VWAP_T_NS <= ts_trade < bucket_end_ts`

### Definition
- `vwap = (Σ(p_i * q_i)) / (Σ q_i)` over eligible trades

### Streaming maintenance (implementation requirement)
Maintain a timestamped trade FIFO and rolling sums:
- `sum_pq = Σ(p_i * q_i)`
- `sum_q  = Σ q_i`

On each incoming trade:
1. enqueue `(ts_trade, p, q)`
2. `sum_pq += p*q`, `sum_q += q`
3. evict while `ts_old < bucket_end_ts - VWAP_T_NS`:
   - dequeue `(ts_old, p_old, q_old)`
   - `sum_pq -= p_old*q_old`, `sum_q -= q_old`

Strict lower-bound rule:
- evict `ts_old < (bucket_end_ts - VWAP_T_NS)`
- keep `ts_old == (bucket_end_ts - VWAP_T_NS)`

### When VWAP is undefined
If `sum_q == 0`:
- output `vwap = last_valid_vwap` (carry-forward)
- until first valid vwap exists: initialize `vwap = mid` (once mid initialized), else `0`

### Ordering constraints
- Event timestamps must be non-decreasing.
- Trade timestamps must be non-decreasing; otherwise drop + counter:
  - `trades_dropped_out_of_order += 1`

---

## Microprice — Output Format (LOCKED)

microprice = (ask * bid_size + bid * ask_size) / (bid_size + ask_size)

### Output precision
Microprice is output as fixed-point with additional fractional bits:
- base price scale `PX_SCALE` (defined in `docs/40_fixed-point.md`)
- plus `MP_FRAC_BITS` (default 8; frozen by end of Week 2)

Conceptually:
- `microprice_out = round_nearest_ties_to_even(microprice * 2^MP_FRAC_BITS)`

### Edge cases
- If `bid_size + ask_size == 0`, set `microprice = mid` (if initialized), else `0`.
- If locked/crossed (`bid >= ask`):
  - `spread = 0`
  - `microprice = mid`

---

## Determinism requirements
- fixed-point formats frozen early and documented
- rounding + overflow/saturation policy explicit (in `docs/40_fixed-point.md`)
- corner cases explicitly defined (zero sizes, locked/crossed, missing trades)
- out-of-order timestamps dropped + counted

