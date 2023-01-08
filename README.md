# MachDyne_FPGAs_SBCs
Machdyne series of FPGA boards. Eis, Schoko, Keks, Bon Bon

# Setting up the environment.

**BELOW DIDN'T WORK**
1) First build the RISC-V cross compiler tool chain
  - We will us YosysHQ's environment to do that. Clone their repo: 
  - make YosysHQ
  - cd YosysHQ
  - git clone https://github.com/YosysHQ/picorv32.git
  - cd picorv32
  - make download-tools

**This seems to work**
https://mindchasers.com/dev/rv-getting-started

export PATH=/usr/local/bin:$PATH

TopRerenece/RISC-V Assembly Language Programming (Draft v0.17).pdf
The RISC-V Reader Oct2017.pdf

risc-v-asm-manual.pdf section 9.1:
3. Compile and generate dump for a program
(a) riscv64-unknown-elf-gcc -nostdlib -nostartfiles -T spike.lds example.S -o example.elf
(b) riscv64-unknown-elf-objdump -d example.elf & > example.dump

Spike simulator:
https://github.com/riscv-software-src/riscv-isa-sim


```
mkdir -p ~/projects/riscv
cd ~/projects/riscv
git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
INS_DIR=~/projects/riscv/install/rv32i
./configure --prefix=$INS_DIR --with -multilib -generator = "rv32i-ilp32--; rv32im -ilp32--"
make
```