# Description
A port of Femto-intermissum from Verilog to SystemVerilog and Modulerized.

# Links
- https://github.com/Ravenslofty/yosys-cookbook/blob/master/ecp5.md
- https://projectf.io/posts/fpga-graphics/
- http://tinyvga.com/vga-timing/640x480@73Hz
- https://zipcpu.com/blog/2017/06/02/generating-timing.html 
- https://www.youtube.com/watch?v=5xY3-Er72VU uses the upduino 3.0
- https://imuguruza.github.io/blog/vga
- https://www.youtube.com/watch?v=ZNunxg7o8l0  Great scott
- https://www.fpga4fun.com/PongGame.html  pong
- https://ktln2.org/2018/01/23/implementing-vga-in-verilog/
- https://vanhunteradams.com/DE1/VGA_Driver/Driver.html
- https://www.instructables.com/Video-Interfacing-With-FPGA-Using-VGA/
- https://www.instructables.com/Design-of-a-Simple-VGA-Controller-in-VHDL/
- https://blog.waynejohnson.net/doku.php/generating_vga_with_an_fpga
- https://nandland.com/project-9-vga-introduction-driving-test-patterns-to-vga-monitor/ 
 


# Description
A port of Femto-intermissum from Verilog to SystemVerilog and Modulerized.

# Links
- https://github.com/Ravenslofty/yosys-cookbook/blob/master/ecp5.md

# Tasks
- **done** Pull fresh versions of Yosys, Nextpnr and ecp5 tools.
- **done** Synth Femto and drive 8 LEDs on PMOD
- **done** Simplify UART component
- **done** Create hex files using assembler
- Connect UART and send to Client a boot message
  - Write assembly
  - start Minicom on ttyACM0

# Minicom client (aka trasnmitter)
Turn off "flow control" [Ctrl-a x o]

Tigard's UART port is on the first listed USB port. Note: if you have already plugged in some other UART device prior then the Tigard's port will be higher, for example, **ttyUSB1**.
```$ minicom -b 115200 -o -D /dev/ttyUSB2```
Or
```$ minicom -b 115200 -o -D /dev/ttyACM0```

# Screen
```screen /dev/ttyUSB1 115200```  "Ctrl-a \" to exit

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
- Clone the basic assembler from the [RISC-V-Assemblers](https://github.com/wdevore/RISC-V-Assemblers) github repo.

## Usage
- Navigate to the *basic* folder.
- Modify or Copy the **basic.json** file to match you requirements by adjusting the input and output.
  - For Schoko I created a *config.json* in the *sources* folder.
- Run assembler: ```$ go run . */path/to-schoko/Hardware/MachDyne_FPGAs_SBCs/Schoko/projects/SoC/sources/config.json*```


Create an **.s** file, for example,
```asm
RVector: @
    @: Main            // Reset vector
Main: @
    lw x1, 0x28(x0)     // Load x1 with the contents of: 0x28 BA = 0x0A WA
    andi x2, x1, 0x05
    ebreak              // Stop
```

## Assembly references and tools
- [RISC-V Online Assembler](https://riscvasm.lucasteske.dev/#)
- [TopRerenece/RISC-V Assembly Language Programming (Draft v0.18).pdf](https://github.com/johnwinans/rvalp)
- The RISC-V Reader Oct2017.pdf
- RISC-v Assembly language Programmer Manual Part 1 Shakti 2020.pdf
- https://github.com/riscv-collab/riscv-gnu-toolchain  installs and stuff
- https://en.wikipedia.org/wiki/GNU_Assembler
- https://dmytrish.net/lib/riscv/linux/hello-gas.html
- https://sourceware.org/binutils/docs/ld/  linker manual

**as** is the GNU Assembler. It's found in binutils but if you do:

sudo apt-get install build-essential

You will get gas along with gcc (which default uses gas for assembling on the back end).

For a 'tutorial' about using gas, you probably want to read [Programming From the Ground Up](http://download.savannah.gnu.org/releases/pgubook/), which uses it.


### Online assembler/disassembler
- [Assembler](https://riscvasm.lucasteske.dev/#)
- [Disassembler](https://luplab.gitlab.io/rvcodecjs/#q=00110123&abi=false&isa=AUTO)


# SoC

---
# Tasks
| Done | Description|
|:---:| ---|
| &#9745; | Pull fresh versions of Yosys, Nextpnr and ecp5 tools. |
| &#9745; | Phase 1: Synth Femto and drive 8 LEDs on PMOD |
| &#9745; | Write Go client to interface to SoC UART port |
| &#9744; | Phase 2: Connect UART and send to Client a boot message |

# Go Client
There are several ways to approach the client.

- Build a basic turn based io (the simplest)
- C++ ncurses with [Serialib](https://github.com/imabot2/serialib)
- or [Termui](https://github.com/gizak/termui) (Go)
