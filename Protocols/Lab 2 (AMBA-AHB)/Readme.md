# AMBA-AHB Bus System

RTL implementation of an AMBA AHB (Advanced High-performance Bus) system with a
single master, arbiter, address decoder, read-data multiplexer, and four
slave peripherals.

## Directory structure

```
AHB/
├── doc/            Design documentation, specifications, notes
├── Screenshots/     Simulation waveforms / test result screenshots
└── src/             RTL source files (Verilog/SystemVerilog)
```

## Architecture

- **Master** – issues address/control (HADDR, HTRANS, HWRITE, HSIZE, HBURST)
  and write data (HWDATA)
- **Arbiter** – grants bus ownership among requesting masters
- **Address decoder** – decodes HADDR and asserts the matching HSELx
- **4 Slaves** – respond with HRDATA, HRESP, HREADY
- **Read-data mux** – selects the active slave's HRDATA/HRESP/HREADY back to
  the master

