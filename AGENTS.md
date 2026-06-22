# Repository Notes

## TODO: XDMA Kernel Support Matrix

Keep the XDMA driver compile-compatible with these target Ubuntu kernels:

- `5.4.0-216-generic`
- `6.8.0-90-generic` - bscdrambender-supported kernel
- `6.17.0-35-generic` - current development host kernel

Validation should remain compile-only unless explicitly doing hardware bring-up:
do not load the module, touch `/dev/xdma*`, or run hardware tests during routine
compatibility checks.
