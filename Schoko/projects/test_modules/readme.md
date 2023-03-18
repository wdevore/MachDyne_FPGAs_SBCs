# Description
A port of Femto-intermissum from Verilog to SystemVerilog and Modulerized.

# Links
- https://github.com/Ravenslofty/yosys-cookbook/blob/master/ecp5.md

# Tasks
- **done** Pull fresh versions of Yosys, Nextpnr and ecp5 tools.
- Synth Femto and drive 8 LEDs on PMOD
- Connect UART and send to Minicom a boot message



# PLL

```
ecppll -i 48 --reset -o 10 -f pll.v

Pll parameters:
Refclk divisor: 14
Feedback divisor: 3
clkout0 divisor: 53
clkout0 frequency: 10.2857 MHz
VCO frequency: 545.143
```
