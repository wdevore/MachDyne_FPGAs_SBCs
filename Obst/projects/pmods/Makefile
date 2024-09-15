TOP_FILE = Top.sv

SUB_MODULES_FILES =

MODULES_FILES = ${SUB_MODULES_FILES} ${TOP_FILE}

BUILD_BIN = /media/RAMDisk

ICESTORM_TOOLCHAIN = /usr/local

YOSYS_COMMAND = "synth_ecp5 -blif ${BUILD_BIN}/chip.blif -json ${BUILD_BIN}/hardware.json -top Top"

PINS_CONSTRAINTS = ../../resources/obst_v0.lpf

.PHONY: all

all: build route pack tigard

compile: build route pack

build: ${MODULES_FILES} ${PINS_CONSTRAINTS}
	@echo "##### Building..."
	${ICESTORM_TOOLCHAIN}/bin/yosys -p ${YOSYS_COMMAND} \
	-l ${BUILD_BIN}/yo.log \
	-q \
	-defer \
	${MODULES_FILES}

# Note:
# openFPGALoader's "boards.yml" seems to list the 12F's package on the Konfekt as "6BG256C"
# however, nextpnr expects "CABGA256". This is an error but I don't want to deal with it just yet.
# So for now the package is set CABGA256.
route: ${BUILD_BIN}/hardware.json
	@echo "##### Routing..."
	${ICESTORM_TOOLCHAIN}/bin/nextpnr-ecp5 \
	-q \
	-l ${BUILD_BIN}/next.log \
	--12k \
	--package CABGA256 \
	--lpf ${PINS_CONSTRAINTS} \
	--json ${BUILD_BIN}/hardware.json \
	--textcfg ${BUILD_BIN}/hardware_out.config

pack: ${BUILD_BIN}/hardware_out.config
	@echo "##### Packing..."
	${ICESTORM_TOOLCHAIN}/bin/ecppack \
	--compress \
	-v \
	--freq 2.4 \
	${BUILD_BIN}/hardware_out.config \
	--bit ${BUILD_BIN}/hardware.bit

packsvf: ${BUILD_BIN}/hardware_out.config
	@echo "##### SVF Packing..."
	${ICESTORM_TOOLCHAIN}/bin/ecppack \
	-v \
	${BUILD_BIN}/hardware_out.config \
	--svf ${BUILD_BIN}/hardware.svf

# Use "-v" to get verbose messages
# --vid 0x0403 --pid 0x6010
tigard: ${BUILD_BIN}/hardware_out.config
	@echo "##### Uploading..."
	openFPGALoader -v -c tigard ${BUILD_BIN}/hardware.bit

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