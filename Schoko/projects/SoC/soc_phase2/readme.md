# Description
*Phase 2* integrates GNU Gas assembler for writing a basic Monitor. This does not include a bootloader, just a barebones monitor.

# Dev setup 
Open 4 Terminals laid out in quadrants.
- The upper left runs: ```minicom -b 115200 -o -D /dev/ttyUSB2```
- The bottome left runs: ```make``` from */media/iposthuman/Nihongo/Hardware/MachDyne_FPGAs_SBCs/Schoko/projects/SoC/soc_phase2*
- The upper right runs the simple Go program to send a byte: ```go run . 0x34``` from */media/iposthuman/Nihongo/Hardware/MachDyne_FPGAs_SBCs/Schoko/go_clients/basic*

### Using custom assembler
- The lower right runs the assembler: ```go run . /media/iposthuman/Nihongo/Hardware/MachDyne_FPGAs_SBCs/Schoko/projects/SoC/sources/config.json``` from */media/iposthuman/Nihongo/Hardware/RISC-V/RISC-V-Assemblers/basic*

### Using Gas
- The lower right runs the assembler: ```make``` from */media/iposthuman/Nihongo/Hardware/MachDyne_FPGAs_SBCs/Schoko/projects/SoC/sources/gas/monitor*

# Gas assembler
When compiling don't attempt to use ```j$(nproc)``` as it can cause headers to fail to be found.

```./configure --prefix=/opt/riscv --enable-multilib```

- [Manual 2.40](https://sourceware.org/binutils/docs/as/)
- [Debian install](https://www.drtuber.com/video/4381194/beautiful-blonde-showing-her-big-boobs-on-cam#) see section 3.1 "Cross compilation/Pre-built toolchains"
- [ASM manual risc-v](https://github.com/riscv-non-isa/riscv-asm-manual/blob/master/riscv-asm.md) More details on params and meanings (**important**)
- [John's Basement - Youtube](https://www.youtube.com/watch?v=ODn7vnWOptM) where he covers compiling via gcc on a *.S* file.
- [Western digital 1-12](https://www.youtube.com/playlist?list=PL6noQ0vZDAdh_aGvqKvxd0brXImHXMuLY)
- [Low Level Learning](https://www.youtube.com/watch?v=n8g_XKSSqRo) Is an excellent article for compiling to a SiFive micro board but it also has excellent assembler **linker script** setup.
- [Chibi Akumas video](https://www.youtube.com/watch?v=bEUMLh2lasE&t=307s) Excellent dude teaches Retro and modern stuff. This video is on RISC-V
- [Fastbit](https://www.youtube.com/watch?v=B7oKdUvRhQQ) Video on linker scripts. Very informative.
- [QuantSpack](https://www.youtube.com/watch?v=-thR3Jy-Gew) another vid on linker script. There are several vids.
- [Russ Ross](https://www.youtube.com/watch?v=5g8M85r8Au8) vid on setting up cross assembly with good info on assembling and linking.
- [Build run](https://inst.eecs.berkeley.edu/~cs250/fa10/handouts/tut3-riscv.pdf) covers params and dumps
- [Helloworld](https://smist08.wordpress.com/2019/09/07/risc-v-assembly-language-hello-world/) Simply hello world you can run in [rars](https://github.com/TheThirdOne/rars). Run the *.jar* as ```java -jar rars1_6.jar``` from the *Downloads* folder. You will need to install a JRE: ```sudo apt install default-jre```.
  - [More Rars](http://ecen323wiki.groups.et.byu.net/labs/lab-04/)
- [RISC-V options](https://gcc.gnu.org/onlinedocs/gcc/RISC-V-Options.html) parameters
- [RISC-V options 2](https://sourceware.org/binutils/docs/as/RISC_002dV_002dOptions.html) Example: *-fpic*
- [RISC-V options 3](https://gcc.gnu.org/onlinedocs/gcc/gcc-command-options/machine-dependent-options/risc-v-options.html) From GNU org
- [ASM example.s](http://ix.io/2dyN/gas)
- [LearnRISC-V HiFive-RevB](https://www.youtube.com/watch?v=Xshh5iPholc) I have the original RevA. Shows setting up a linker script for the board.
- [](https://www.dynamsoft.com/codepool/riscv-barcode-sdk-qemu-emulator-ubuntu.html) Talks about installing pre-builts and QEMU

## Options
```
Target RISC-V options:
   [-fpic|-fPIC|-fno-pic]
   [-march=ISA]
   [-mabi=ABI]
   [-mlittle-endian|-mbig-endian]
```

Inspecting the top of the *femtorv32_intermissum.v* file we find what options we need to use with Gas:
```verilog
// Firmware generation flags for this processor
`define NRV_ARCH     "rv32im"
`define NRV_ABI      "ilp32"
```
And knowning that we are following the newer endian format of "little"
```
   [-march=rv32im]
   [-mabi=ilp32]
   [-mlittle-endian]
```

## Building
```
riscv64-linux-gnu-as -march=rv64imac -o HelloWorld.o HelloWorld.s
riscv64-linux-gnu-ld -o HelloWorld HelloWorld.o
```

### Makefiles
- [Makefile Tutorial](https://makefiletutorial.com/)

## Dumping
```
riscv64-linux-gnu-objdump -d HelloWorld
```

Produces:
```s
HelloWorld:     file format elf64-littleriscv

Disassembly of section .text:

00000000000100b0 <_start>:
   100b0: 00100513           li a0,1
   100b4: 00001597           auipc a1,0x1
   100b8: 02058593           addi a1,a1,32 # 110d4 <__DATA_BEGIN__>
   100bc: 00d00613           li a2,13
   100c0: 04000893           li a7,64
   100c4: 00000073           ecall
   100c8: 00000513           li a0,0
   100cc: 05d00893           li a7,93
   100d0: 00000073           ecall
```


# Linker and scripts
- [Every thing you wanted to know about linker scripts](https://mcyoung.xyz/2021/06/01/linker-script/) Very good and clear descriptions.
- [GNU ld](https://sourceware.org/binutils/docs/ld/index.html) Contains section on the linker scripts.
- [Objdump](https://unix.stackexchange.com/questions/421556/)get-hex-only-output-from-objdump
- [Use Verilog file IO](http://www.chris.spear.net/pli/fileio.htm)
- [elfview](https://github.com/mattfischer/elfview/tree/master/src)
- [elf2hex](https://github.com/sifive/elf2hex)
- [convert elf 2 hex](https://community.st.com/s/question/0D50X0000AlflsxSQA/) how-to-convert-hex-file-to-elf-file
- ```arm-none-eabi-objcopy -O ihex -R .eeprom filename.elf filename.hex```
- [RISC-V from scratch Part 1](https://twilco.github.io/riscv-from-scratch/2019/03/10/riscv-from-scratch-1.html) Part 1 and 2 use qemu to emulate a HiFive board.
- [RISC-V from scratch Part 2](https://twilco.github.io/riscv-from-scratch/2019/04/27/riscv-from-scratch-2.html) This part covers linker scripts
- [Section name](https://sourceware.org/binutils/docs/as/Section.html)
- [Ld Man page](https://manpages.debian.org/testing/binutils-riscv64-linux-gnu/riscv64-linux-gnu-ld.1.en.html)

riscv64-linux-gnu-ld: supported targets: elf64-littleriscv **elf32-littleriscv** elf32-bigriscv elf64-bigriscv elf64-little elf64-big elf32-little elf32-big srec symbolsrec verilog tekhex binary ihex plugin

Note: when calling *as* directly you will need to explicitly specify the emulation via: ```-m elf32lriscv_ilp32```

Below are the emulations supported for *multilib*:

riscv64-linux-gnu-ld: supported emulations: elf64lriscv elf64lriscv_lp64f elf64lriscv_lp64 elf32lriscv elf32lriscv_ilp32f **elf32lriscv_ilp32** elf64briscv elf64briscv_lp64f elf64briscv_lp64 elf32briscv elf32briscv_ilp32f elf32briscv_ilp32

# Emulators and Simulators
- [TinyEMU emulator](https://bellard.org/tinyemu/) Javascript

# GNU poke
It is a binary editor.
- http://www.jemarch.net/poke
- GDB Dashboard

# Terminals
```screen /dev/ttyUSB1 115200```  "Ctrl-a \" to exit

**NOTE**: minicom allows a Go program to open a connection but **screen** does not.
```minicom -b 115200 -o -D /dev/ttyUSB2``` "Ctrl-a Crtl-z x"

- Make sure you turn off *flow control*: ```Ctrl-A Z O "serial port setup" F```
- Also change "Backspace key sends" to **DEL**: ```Ctrl-A T B B```

## Screen
- C-a C              (clear)           Clear the screen.
- C-a \              (quit)            Kill all windows and terminate screen.

# Misc Links
- [Makefile tutorial](https://makefiletutorial.com/) Pretty good

# RISC-V Assembler and Runtime Simulator
- [RISC-V Assembler and Runtime Simulator](https://github.com/TheThirdOne/rars/wiki/Environment-Calls)
- [ChibiAkumas](https://www.youtube.com/watch?v=bEUMLh2lasE&list=PLp_QNRIYljFqBuOYDFluT66Y7biUH1Dnc&index=2) Shows usage of Rars.