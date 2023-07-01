RISCV_TOOLCHAIN := /opt/riscv/bin/
# "linux-gnu" or "elf"
BUILD_TYPE := elf
GAS := riscv64-unknown-$(BUILD_TYPE)-as
LD  := riscv64-unknown-$(BUILD_TYPE)-ld
DUMP := riscv64-unknown-$(BUILD_TYPE)-objdump
COPY := riscv64-unknown-$(BUILD_TYPE)-objcopy

# Emulations:
# "elf32lriscv_ilp32" or "elf32lriscv"
EMULATION := elf32lriscv

BINARY_MODULE := program
FIRMWARE := app
HEX_FIRMWARE := $(FIRMWARE).hex

MODULES_FILES = \
	add.s

BUILD_BIN = /media/RAMDisk

.PHONY: all
all: assemble link dump out2hex

assemble: $(MODULES_FILES)
	@echo "############### Assembling ##################"
	@$(RISCV_TOOLCHAIN)$(GAS) \
	-march=rv32im \
	-mabi=ilp32 \
	-mlittle-endian \
	-mno-relax \
	-mno-arch-attr \
	-fno-pic \
	-o $(BUILD_BIN)/$(BINARY_MODULE).o $(MODULES_FILES)

# -T linker_script.ld
# 	-nostdlib \

link: $(BUILD_BIN)/$(BINARY_MODULE).o
	@echo "############### Linking... ##################"
	@$(RISCV_TOOLCHAIN)$(LD) \
	-m $(EMULATION) \
	-o $(BUILD_BIN)/$(BINARY_MODULE) \
	-O 0 \
	-Map $(BINARY_MODULE).map \
	-T $(BINARY_MODULE).ld \
	$(BUILD_BIN)/$(BINARY_MODULE).o

# You can also dump the .o file such that it isn't relocated 
# by the linker.
#	--visualize-jumps \
#	--disassemble-zeroes \
# 	--disassembler-options=no-aliases \
#	--section=keybuffer \
# 	-t \
#   --full-contents \

.PHONY: dump
dump: $(BUILD_BIN)/${BINARY_MODULE}
	@echo "############### Dumping... ##################"
	@$(RISCV_TOOLCHAIN)$(DUMP) \
	-d \
	-h \
	-w \
	--insn-width=4 \
	--section=.text \
	--section=.data \
	--section=.rodata \
	--section=keybuffer \
	--section=stack \
	$(BUILD_BIN)/$(BINARY_MODULE) \
	>$(BUILD_BIN)/$(FIRMWARE).out

.PHONY: out2hex
out2hex: $(BUILD_BIN)/$(FIRMWARE).out
	@echo "############### Generating hex firmware... ##################"
	@cd ../gas/out2hex; \
	go run . $(BUILD_BIN)/$(FIRMWARE).out ../../../binaries/$(FIRMWARE).hex

.PHONY: clean
clean:
	@rm	$(BUILD_BIN)/*.o \
		$(BUILD_BIN)/*.out \
		$(BUILD_BIN)/$(BINARY_MODULE)

# Note:
# The "verilog-data-width" parameter can implicitly switch the address
# outputs from byte-address form to word-address form depending on the
# value passed, for example, a "1" generates byte-address form and the data
# is in big-endian format. However, a value of "4" generates word-address
# form and the data is in little-endian format.
# For example: a "1" generates:
# @00001000
# 13 05 A0 00 93 05 50 00 B3 02 B5 00 73 00 10 00
#
# and a "4" generates:
# @00000400
# 00A00513 00500593 00B502B3 00100073

.PHONY: out2verlog
out2verlog: $(BUILD_BIN)/$(BINARY_MODULE)
	@$(RISCV_TOOLCHAIN)$(COPY) \
	-O verilog \
	--verilog-data-width 4 \
	$(BUILD_BIN)/$(BINARY_MODULE) $(BUILD_BIN)/filename.hex

