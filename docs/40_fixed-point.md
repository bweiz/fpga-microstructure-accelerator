# Fixed-Point Policy (To be frozen early)

This doc will lock:
- scaling for price, size, returns
- Q formats / bit widths for intermediates
- rounding policy
- overflow/saturation behavior
- DSP usage vs LUT math

Rule: Every output field must document:
- input scaling
- intermediate widths
- output scaling
- overflow behavior

