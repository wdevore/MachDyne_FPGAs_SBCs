TOP_FILE = Top.sv

SUB_MODULES_FILES =

MODULES_FILES = ${SUB_MODULES_FILES} ${TOP_FILE}

BUILD_BIN = /media/RAMDisk

ICESTORM_TOOLCHAIN = /usr/local

YOSYS_COMMAND = "synth_ecp5 -blif ${BUILD_BIN}/chip.blif -json ${BUILD_BIN}/hardware.json -top Top"

PINS_CONSTRAINTS = ../schoko_v1.lpf

.PHONY: all

all: build route pack upload

compile: build route pack

build: ${MODULES_FILES} ${PINS_CONSTRAINTS}
	@echo "##### Building..."
	${ICESTORM_TOOLCHAIN}/bin/yosys -p ${YOSYS_COMMAND} \
	-l ${BUILD_BIN}/yo.log \
	-q \
	-defer \
	${MODULES_FILES}

route: ${BUILD_BIN}/hardware.json
	@echo "##### Routing..."
	${ICESTORM_TOOLCHAIN}/bin/nextpnr-ecp5 \
	-q \
	-l ${BUILD_BIN}/next.log \
	--45k \
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

# Currently doesn't work via Tigard.
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
