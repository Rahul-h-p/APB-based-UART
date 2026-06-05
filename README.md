# APB-based-UART

# APB_based_GPIO

A synthesizable 32-bit General Purpose Input/Output (GPIO) controller written in Verilog, designed to be interfaced over an APB (Advanced Peripheral Bus) style register interface. The design supports external clock sampling, auxiliary output muxing, per-bit interrupt generation, and tri-state IO pad control.

---

## Table of Contents

- [Features](#features)
- [Block Diagram](#block-diagram)
- [Register Map](#register-map)
- [File Structure](#file-structure)
- [Simulation Instructions](#simulation-instructions)
- [Tool Requirements](#tool-requirements)
- [Author](#author)

---

## Features

- 32-bit wide GPIO with individually controllable direction (OE)
- Interrupt generation with per-bit enable mask and trigger polarity
- External clock (ECLK) based input sampling — posedge or negedge selectable via NEC register
- Auxiliary output mux — allows peripheral signals to override GPIO output on a per-bit basis
- Tri-state IO pad interface with separate input capture and output drive
- Synchronous active-high reset
- All registers readable and writable via a simple address/data/write-enable bus

---

## Block Diagram

```
                        +-----------------------------+
                        |       gpio_register         |
                        |                             |
  gpio_addr  ---------> |   Register Write Decoder    |
  gpio_dat_i ---------> |                             |
  gpio_we    ---------> |  RGPIO_OUT   RGPIO_OE       |
  sys_clk    ---------> |  RGPIO_INTE  RGPIO_PTRIG    |
  sys_rst    ---------> |  RGPIO_AUX   RGPIO_CTRL     |
                        |  RGPIO_INTS  RGPIO_ECLK     |
                        |  RGPIO_NEC                  |
                        |                             |
  gpio_eclk  ---------> |  +--------+  +-----------+ |
  in_pad_i   ---------> |  |Posedge |  | Negedge   | | ----> gpio_dat_o
                        |  |Sampler |  | Sampler   | |
                        |  +---+----+  +-----+-----+ | ----> gpio_inta_o
                        |      |             |        |
                        |      +----+--------+        | ----> out_pad_o
                        |           |                 |
                        |      extc_in / in_muxed     | ----> oen_padoe_o
                        |           |                 |
                        |      RGPIO_IN (latched)     |
                        +-----------------------------+

                        +-----------------------------+
                        |       io_interface          |
                        |                             |
  out_pad_o  ---------> |  Tri-state pad driver  <--> | io_pad[31:0]
  oen_padoe_o --------> |  (per-bit controlled)       |
                        |                             |
  in_pad_i   <--------- |  Input capture              |
  gpio_eclk  <--------- |  External clock buffer      |
                        +-----------------------------+

                        +-----------------------------+
                        |       AUX_interface         |
                        |                             |
  aux_in     ---------> |  Registered auxiliary input | ----> aux_i
  sys_clk    ---------> |  (sync to sys_clk)          |
  sys_rst    ---------> |                             |
                        +-----------------------------+
```

---

## Register Map

Base address offset from the GPIO peripheral base. All registers are 32 bits wide.

| Offset | Register Name | Access | Description |
|--------|--------------|--------|-------------|
| 0x00 | RGPIO_IN | RO | Captured value of the input pads |
| 0x04 | RGPIO_OUT | RW | Output data driven to pads |
| 0x08 | RGPIO_OE | RW | Output enable — 1 = output, 0 = input (tri-state) |
| 0x0C | RGPIO_INTE | RW | Interrupt enable mask — 1 enables interrupt on that bit |
| 0x10 | RGPIO_PTRIG | RW | Interrupt trigger polarity — 0 = trigger on low, 1 = trigger on high |
| 0x14 | RGPIO_AUX | RW | Auxiliary mux select — 1 = aux_i drives output, 0 = RGPIO_OUT drives output |
| 0x18 | RGPIO_CTRL | RW | Control register — bit 0: INTE (global interrupt enable), bit 1: INTS (interrupt status summary) |
| 0x1C | RGPIO_INTS | RW | Interrupt status — set by hardware on edge detect, write to clear |
| 0x20 | RGPIO_ECLK | RW | External clock enable per bit — 1 = use gpio_eclk to sample that bit |
| 0x24 | RGPIO_NEC | RW | Negative edge clock select — 1 = sample on negedge of gpio_eclk, 0 = posedge |

### RGPIO_CTRL bit field

| Bit | Name | Description |
|-----|------|-------------|
| 0 | INTE | Global interrupt enable. Must be set for interrupts to propagate to gpio_inta_o |
| 1 | INTS | Interrupt status summary. Set by hardware when any RGPIO_INTS bit is active |

### Interrupt Logic

An interrupt is flagged on a bit when:
1. A change is detected on that input bit (`in_muxed ^ rgpio_in`)
2. The new value matches the programmed trigger polarity (`RGPIO_PTRIG`)
3. The bit's interrupt is enabled in `RGPIO_INTE`
4. The global `INTE` bit in `RGPIO_CTRL` is set

---
## Simulation Instructions

### Using Xilinx ISim (ISE 14.x)

1. Open ISE Project Navigator and create or open the project at `APB_based_GPIO/`.
2. Add all RTL files from `rtl/` and the desired testbench from `tb/` to the project.
3. Set the target testbench module as the top-level simulation source.
4. Right-click the testbench in the hierarchy and select **Simulate Behavioral Model**.
5. ISim will launch. Use the waveform viewer to inspect signals.

> **Note:** All files use Verilog-2001 syntax and are compatible with ISim. Do not use a `-sv` or SystemVerilog mode flag.

### Using Icarus Verilog (command line)

```bash
# Compile
iverilog -g2001 -o gpio_sim rtl/gpio_register.v tb/gpio_register_tb.v

# Run
vvp gpio_sim

# View waveforms (requires GTKWave)
gtkwave gpio_register_tb.vcd
```

### Expected Simulation Output (gpio_register_tb)

```
=== TC-01: Reset ===
  PASS | gpio_dat_o  after reset   ...
  PASS | gpio_inta_o after reset   ...
  ...
============================================
  Simulation complete
  PASSED : 30
  FAILED : 0
  *** ALL TESTS PASSED ***
```

---

## Tool Requirements

| Tool | Version | Purpose |
|------|---------|---------|
| Xilinx ISE | 14.7 | Synthesis + ISim simulation |
| Icarus Verilog | 11.0+ | Alternative open-source simulation |
| GTKWave | 3.3+ | Waveform viewing (optional) |

---

## Author

Developed as part of an APB-based GPIO peripheral design project.  
Target device family: Xilinx Spartan / Artix series.
