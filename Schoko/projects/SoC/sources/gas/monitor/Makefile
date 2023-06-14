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
all: assemble link dump out2hex

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

# -T linker_script.ld
# 	-nostdlib \

link: $(BINARY_MODULE).o
	@echo "############### Linking... ##################"
	@$(RISCV_TOOLCHAIN)$(LD) \
	-m elf32lriscv_ilp32 \
	-o ${BINARY_MODULE} \
	-O 0 \
	-Map monitor.map \
	-T ${BINARY_MODULE}.ld \
	${BINARY_MODULE}.o

# You can also dump the .o file such that it isn't relocated 
# by the linker.
#	--visualize-jumps \
#	--disassemble-zeroes \
# 	--disassembler-options=no-aliases \
#	--section=keybuffer \
# 	-t \
#   --full-contents \

.PHONY: dump
dump: ${BINARY_MODULE}
	@echo "############### Dumping... ##################"
	@$(RISCV_TOOLCHAIN)$(DUMP) \
	-d \
	-h \
	-w \
	--insn-width=4 \
	--section=.text \
	--section=.data \
	--section=.rodata \
	--section=stack \
	${BINARY_MODULE} \
	>firmware.out

.PHONY: out2hex
out2hex: firmware.out
	@echo "############### Generating hex firmware... ##################"
	@cd ../out2hex; \
	go run . ../monitor/firmware.out ../../../binaries/firmware.hex

.PHONY: clean
clean:
	rm	*.o \
		*.out \
		${BINARY_MODULE}

learn:
	@echo $(MAKE_VERSION)