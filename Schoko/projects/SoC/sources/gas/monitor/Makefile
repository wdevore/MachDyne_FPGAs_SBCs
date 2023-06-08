RISCV_TOOLCHAIN := /opt/riscv/bin/
GAS := riscv64-unknown-linux-gnu-as
LD  := riscv64-unknown-linux-gnu-ld
DUMP := riscv64-unknown-linux-gnu-objdump

BINARY_MODULE := monitor
FIRMWARE := firmware
HEX_FIRMWARE := $(FIRMWARE).hex

SUB_MODULES_FILES = \
	monitor.s

BUILD_BIN = /media/RAMDisk

.PHONY: all
all: assemble link dump

assemble:
	@echo "############### Assembling ##################"
	@$(RISCV_TOOLCHAIN)$(GAS) \
	-march=rv32im \
	-mabi=ilp32 \
	-mlittle-endian \
	-mno-relax \
	-mno-arch-attr \
	-fno-pic \
	-o $(BINARY_MODULE).o $(SUB_MODULES_FILES)

link: $(BINARY_MODULE).o
	@echo "############### Linking... ##################"
	@$(RISCV_TOOLCHAIN)$(LD) \
	-m elf32lriscv_ilp32 \
	-o ${BINARY_MODULE} \
	-O 0 \
	${BINARY_MODULE}.o

# You can also dump the .o file such that it isn't relocated 
# by the linker.
# --section=.text

.PHONY: dump
dump: ${BINARY_MODULE}
	@echo "############### Dumping... ##################"
	@$(RISCV_TOOLCHAIN)$(DUMP) \
	-d \
	-h \
	-s \
	--disassemble-zeroes \
	--section=.text \
	--section=.data \
	--section=.rodata \
	--section=.bss \
	--section=.stack \
	${BINARY_MODULE} \
	>firmware.out

.PHONY: elf2hex
elf2hex: firmware.out

clean:
	rm	*.o \
		*.out \
		${BINARY_MODULE}

learn:
	@echo $(MAKE_VERSION)