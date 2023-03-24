# Description
A port of Femto-intermissum from Verilog to SystemVerilog and Modulerized.

# Links
- https://github.com/Ravenslofty/yosys-cookbook/blob/master/ecp5.md

# Tasks
- **done** Pull fresh versions of Yosys, Nextpnr and ecp5 tools.
- Synth Femto and drive 8 LEDs on PMOD
- Connect UART and send to Minicom a boot message

# Description
A port of Femto-intermissum from Verilog to SystemVerilog and Modulerized.

# Links
- https://github.com/Ravenslofty/yosys-cookbook/blob/master/ecp5.md

# Tasks
- **done** Pull fresh versions of Yosys, Nextpnr and ecp5 tools.
- Create hex files using assembler
- Synth Femto and drive 8 LEDs on PMOD
- Connect UART and send to Minicom a boot message



# PLL
An example of a 10MHz clock for the CPU
```
$ ecppll -i 48 --reset -o 10 -f pll.v

Pll parameters:
Refclk divisor: 14
Feedback divisor: 3
clkout0 divisor: 53
clkout0 frequency: 10.2857 MHz
VCO frequency: 545.143
```

The configuration for 640x480 VGA:
```
$ ecppll -i 48 --reset -o 25.175 --highres -f pll.v

Pll parameters:
Refclk divisor: 13
Feedback divisor: 3
clkout0 divisor: 50
clkout0 frequency: 25.1748 MHz
clkout1 divisor: 22
clkout1 frequency: 25.1748 MHz
clkout1 phase shift: 0 degrees
VCO frequency: 553.846
```

# Hex files
We need to create basic binaries (aka hex files) for testing femto functionality.

# Assembler
Clone the basic assembler from the [RISC-V-Assemblers](https://github.com/wdevore/RISC-V-Assemblers) github repo:

## Usage
- First create and/or modify *\<filename\>.json* file to adjust the input and output.
- Run assembler: ```$ go run . *<filename>.json*```
- Then copy the *.hex* file to your *binaries* folder, for example:
  - */path-to-parent/Schoko/projects/femto/simulation/binaries*


Create an **.s** file, for example,
```asm
RVector: @
    @: Main            // Reset vector
Main: @
    lw x1, 0x28(x0)     // Load x1 with the contents of: 0x28 BA = 0x0A WA
    andi x2, x1, 0x05
    ebreak              // Stop
```

## Online assembler
[RISC-V Online Assembler](https://riscvasm.lucasteske.dev/#)

# SoC
```
//  --------------
//  |            |  0x00000000
//  |            |  
//  |            |  RAM
//  |            | 
//  |            |  0x003FFFFF
//  --------------
//  |            |  0x00400000   LEDs
//  |            |  
//  |            |  IO
//  |            | 
//  |            |  ...
//  --------------
// 00000000_01000000_00000000_00000000 = 0x00400000
```