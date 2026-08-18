# Use Multiple Boards and Channels

Each open board handle owns one `(PCI BDF, XDMA channel)` endpoint. A second
process cannot open the same endpoint while it is in use. Different channels
on the same FPGA and endpoints on different FPGAs may be used independently
when the bitstream provides separate controllers.

Do not persist `xdmaN` as a physical-card identifier. Record the complete PCI
BDF and channel with experiment results. If a card is moved to another slot,
discover its BDF again before running an experiment. See
[Identify an FPGA endpoint](identify-an-endpoint.md) for the discovery
procedure.
