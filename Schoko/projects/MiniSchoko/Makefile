FAMILY = ecp5
DEVICE = 45k
PACKAGE = CABGA256
LPF = schoko_v1.lpf

TOP_FILE = soc.sv

SUB_MODULES_FILES = \
	pll_ecp5.v \
	sdram.v \
	uart.v \
	picorv32/picorv32.v

MODULES_FILES = ${SUB_MODULES_FILES} ${TOP_FILE}

BUILD_BIN = /media/RAMDisk

ICESTORM_TOOLCHAIN = /usr/local

# -blif ${BUILD_BIN}/chip.blif
# -noflatten
YOSYS_COMMAND = "synth_ecp5 -json ${BUILD_BIN}/soc.json -top sysctl"

PINS_CONSTRAINTS = schoko_v1.lpf

.PHONY: all

all: build route pack tigard

compile: build route

build: ${MODULES_FILES} ${PINS_CONSTRAINTS}
	@echo "##### Building..."
	${ICESTORM_TOOLCHAIN}/bin/yosys -p ${YOSYS_COMMAND} \
	-l ${BUILD_BIN}/yo.log \
	-q \
	-defer \
	${MODULES_FILES}

# 	-v
route: ${BUILD_BIN}/soc.json
	@echo "##### Routing..."
	${ICESTORM_TOOLCHAIN}/bin/nextpnr-ecp5 \
	-l ${BUILD_BIN}/next.log \
	-q \
	--$(DEVICE) \
	--package $(PACKAGE) \
	--lpf ${PINS_CONSTRAINTS} \
	--json ${BUILD_BIN}/soc.json \
	--textcfg ${BUILD_BIN}/soc.config

pack: ${BUILD_BIN}/soc.config
	@echo "##### Packing..."
	${ICESTORM_TOOLCHAIN}/bin/ecppack \
	--compress \
	-v \
	--freq 2.4 \
	${BUILD_BIN}/soc.config \
	--bit ${BUILD_BIN}/soc.bin

# Use "-v" to get verbose messages
tigard: ${BUILD_BIN}/hardware_out.config
	@echo "##### Uploading..."
	openFPGALoader -c tigard ${BUILD_BIN}/soc.bin

packsvf: ${BUILD_BIN}/soc.config
	@echo "##### SVF Packing..."
	${ICESTORM_TOOLCHAIN}/bin/ecppack \
	-v \
	${BUILD_BIN}/soc_final.config

# The "-a 0" is important. You don't want to wipe-out the bootloader.
# "-a 0" is the user-image.
# You will need a udev rule to avoid "sudo"
# ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="16d0", ATTRS{idProduct}=="116d", MODE="0666", GROUP="plugdev" ENV{ID_MM_DEVICE_IGNORE}="1"
dfu: ${BUILD_BIN}/hardware_out.config
	@echo "##### DFU Uploading..."
	dfu-util -R -a 0 -D ${BUILD_BIN}/hardware.bit

# make openocd 2> /media/RAMDisk/ocd.log
#	-d 3
# -quiet
openocd: ${BUILD_BIN}/hardware.svf
	openocd \
	-f ../tigard-jtag.cfg \
	-f ../lfe5u-45f.cfg \
	-d3 \
	-c "init; scan_chain; jtag cget ecp5.tap -idcode; svf -tap ecp5.tap -progress ${BUILD_BIN}/hardware.svf; exit"