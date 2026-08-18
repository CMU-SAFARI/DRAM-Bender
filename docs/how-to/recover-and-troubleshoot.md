# Recover and Troubleshoot

## Recovering after an interrupted application

Open the intended endpoint and call `full_reset()` before submitting another
program. This resets FPGA logic, cancels and drains old readback, and clears the
software queue.

The API also performs `full_reset()` on its own before raising when
`receive_into()` times out, when it surfaces an asynchronous readback error, or
when Ctrl+C interrupts a receive or synchronization wait on the main Python
thread.

## No `/dev/xdma*` nodes appear

- Confirm that the FPGA is programmed and visible in `lspci -D`.
- Confirm that `drambender_xdma` is loaded.
- Inspect the kernel log for probe or PCIe errors.
- Confirm that the bitstream exposes paired H2C and C2H streaming channels.

## Opening the endpoint reports `Device or resource busy`

Another process owns that BDF/channel endpoint. Close the existing board
handle or terminate the process cleanly. Use context managers in notebooks and
scripts so ownership is released promptly.

## The example receives the wrong amount of data

Check the selected target, rank/channel coordinates, program read count, and
buffer size. A U200 bitstream must also match the installed DIMM organization
and slot.

## Device nodes are not accessible as a normal user

Verify membership in the `drambender` group and start a new login session after
running `xdma/install_access.sh`. See
[Install the XDMA driver](install-the-xdma-driver.md).
