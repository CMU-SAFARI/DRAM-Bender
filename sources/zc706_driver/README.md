### Testing and Verifying the ZC706 PCIe Driver

1. Define ILA_CORES flag in `/projects/ZC706/verilog/pcie_top.v` and synthesize / implement the project (see line 60)
2. Compile the ZC706 PCIe Driver with `$ make all`
3. Insert ZC706 Driver with `$ insmod dma_softmc`
4. Compile the driver test with `$ g++ test/*.c -o test/test`
5. Setup ILA cores to trigger when `softmc_c2h_tvalid` or `softmc_h2c_tvalid` is asserted
6. Run the driver test with `./test/test` and verify data transfers using ILA core waveforms

### Using ZC706 PCIe Driver Instead of XDMA

1. Replace the default *BoardInterface* to `BoardInterface::IFACE::XDMA` in `/sources/api/platform.cpp` (line 69)
2. Include the DRAM-Bender platform to applications and execute as before (e.g., `/sources/apps/Smalltest`)