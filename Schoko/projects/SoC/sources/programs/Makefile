RISCV_TOOLCHAIN := /opt/riscv/bin/
GAS := riscv64-unknown-linux-gnu-as
LD  := riscv64-unknown-linux-gnu-ld
DUMP := riscv64-unknown-linux-gnu-objdump

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
	-m elf32lriscv_ilp32 \
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

.PHONY: out2verlog
out2verlog: $(BUILD_BIN)/$(BINARY_MODULE)
	riscv64-unknown-linux-gnu-objcopy \
	-O verilog \
	--verilog-data-width 4 \
	$(BUILD_BIN)/$(BINARY_MODULE) $(BUILD_BIN)/filename.hex

# @([0-9a-zA-Z]+) ([0-9a-zA-Z]+)