RISCV_TOOLCHAIN := /opt/riscv/bin/
# "linux-gnu" or "elf"
BUILD_TYPE := linux-gnu
GAS := riscv64-unknown-$(BUILD_TYPE)-as
LD  := riscv64-unknown-$(BUILD_TYPE)-ld
DUMP := riscv64-unknown-$(BUILD_TYPE)-objdump
COPY := riscv64-unknown-$(BUILD_TYPE)-objcopy

# Emulations:
# "elf32lriscv_ilp32" or "elf32lriscv"
EMULATION := elf32lriscv

BINARY_MODULE := monitor
FIRMWARE := firmware
HEX_FIRMWARE := $(FIRMWARE).hex

BUILD_BIN = /media/RAMDisk

MODULES_FILES = \
	utils.s \
	uart.s \
	isrs.s \
	prints.s \
	dumps.s \
	process_A_command.s \
	process_E_command.s \
	process_R_command.s \
	process_W_command.s \
	process_U_command.s \
	process_X_command.s \
	monitor.s

# The order these are listed have a direct impact on
# how the linker assembles them. The monitor NEEDS to
# be listed first such that it is at address 0x00000000.
OBJECT_FILES = \
	monitor.o \
	uart.o \
	isrs.o \
	prints.o \
	utils.o \
	dumps.o \
	process_A_command.o \
	process_E_command.o \
	process_R_command.o \
	process_W_command.o \
	process_U_command.o \
	process_X_command.o

# Append BUILD_BIN to every object file because they are
# located in ram disk.
LINK_FILES = $(foreach fl,$(OBJECT_FILES),$(BUILD_BIN)/$(fl))

GAS_PARMS = \
	-march=rv32im \
	-mabi=ilp32 \
	-mlittle-endian \
	-mno-relax \
	-mno-arch-attr \
	-fno-pic

# .PHONY: all
all: assemble link dump out2hex

# %.o : %.s
# 	@echo "Assembling $@"
# 	$(RISCV_TOOLCHAIN)$(GAS) $(GAS_PARMS) $(BUILD_BIN)/$< -o $(BUILD_BIN)/$@ $<
assemble: $(OBJECT_FILES)

%.o: %.s
	@echo "Assembling $@"
	@$(RISCV_TOOLCHAIN)$(GAS) $(GAS_PARMS) -o $(BUILD_BIN)/$@ $<

link:
	@echo "############### Linking... ##################"
	@$(RISCV_TOOLCHAIN)$(LD) \
	-m $(EMULATION) \
	-O 0 \
	-Map $(BINARY_MODULE).map \
	-T $(BINARY_MODULE).ld \
	-o $(BUILD_BIN)/$(BINARY_MODULE) \
	$(LINK_FILES)

# link:
# 	@echo "############### Linking... ##################"
# 	@$(RISCV_TOOLCHAIN)$(LD) \
# 	-m $(EMULATION) \
# 	-O 0 \
# 	-Map $(BINARY_MODULE).map \
# 	-T $(BINARY_MODULE).ld \
# 	-o $(BUILD_BIN)/$(BINARY_MODULE) \
# 	$(BUILD_BIN)/monitor.o \
# 	$(BUILD_BIN)/uart.o \
# 	$(BUILD_BIN)/isrs.o

# -T linker_script.ld
# 	-nostdlib \

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
	--section=m_code \
	$(BUILD_BIN)/$(BINARY_MODULE) \
	>$(BUILD_BIN)/$(FIRMWARE).out

.PHONY: out2hex
out2hex: $(BUILD_BIN)/$(FIRMWARE).out
	@echo "############### Generating hex firmware... ##################"
	@cd ../out2hex; \
	go run . $(BUILD_BIN)/$(FIRMWARE).out $(BUILD_BIN)/$(FIRMWARE).hex

.PHONY: clean
clean:
	@rm	$(BUILD_BIN)/*.o \
		$(BUILD_BIN)/*.out \
		$(BUILD_BIN)/$(BINARY_MODULE)

.PHONY: out2verlog
out2verlog: $(BUILD_BIN)/$(BINARY_MODULE)
	@echo "############### Generating hex firmware via objcopy... ##################"
	@$(RISCV_TOOLCHAIN)$(COPY) \
	-O verilog \
	--verilog-data-width 4 \
	$(BUILD_BIN)/$(BINARY_MODULE) $(BUILD_BIN)/firmware.hex
