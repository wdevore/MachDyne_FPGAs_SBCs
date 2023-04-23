TOP = Top
TOP_FILE = ${TOP}.sv
COMMON = ../../../../common

SUB_MODULES_FILES = \
	${COMMON}/DeMux2.sv \
	${COMMON}/Mux4.sv \
	${COMMON}/Mux2.sv \
	${COMMON}/UART_Defines.sv \
	${COMMON}/UART_Enums.sv \
	${COMMON}/CDCSynchron.sv \
	${COMMON}/UARTRx.sv \
	${COMMON}/UARTTx.sv \
	../components/uart/UART_Enums.sv \
	../components/uart/UART_Component.sv \
	SynEnums.sv \
	../components/femtorv32_intermissum.v \
	pll.v \
	SoC.sv

MODULES_FILES = ${SUB_MODULES_FILES} ${TOP_FILE}

BUILD_BIN = /media/RAMDisk

ICESTORM_TOOLCHAIN = /usr/local

# Verilator is used for it linting prior to synth
SIMULATION_TOOLCHAIN = /usr/local/bin/verilator

# -blif ${BUILD_BIN}/chip.blif
# -noflatten
YOSYS_COMMAND = "synth_ecp5 -json ${BUILD_BIN}/hardware.json -top Top"

PINS_CONSTRAINTS = ../../schoko_v1.lpf

.PHONY: all

all: build route pack tigard

compile: build route

lint:
	@echo "############### Linting via Verilator ##################"
	${SIMULATION_TOOLCHAIN} --lint-only -Wall ${MODULES_FILES} \
	--top-module ${TOP}

build: ${MODULES_FILES} ${PINS_CONSTRAINTS}
	@echo "##### Building..."
	${ICESTORM_TOOLCHAIN}/bin/yosys -p ${YOSYS_COMMAND} \
	-l ${BUILD_BIN}/yo.log \
	-q \
	-defer \
	-DPRELOAD_MEMORY \
	${MODULES_FILES}

# 	-v
route: ${BUILD_BIN}/hardware.json
	@echo "##### Routing..."
	${ICESTORM_TOOLCHAIN}/bin/nextpnr-ecp5 \
	-l ${BUILD_BIN}/next.log \
	-q \
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

packsvf: ${BUILD_BIN}/hardware_out.config
	@echo "##### SVF Packing..."
	${ICESTORM_TOOLCHAIN}/bin/ecppack \
	-v \
	${BUILD_BIN}/hardware_out.config \
	--svf ${BUILD_BIN}/hardware.svf

# Use "-v" to get verbose messages
tigard: ${BUILD_BIN}/hardware_out.config
	@echo "##### Uploading..."
	openFPGALoader -c tigard ${BUILD_BIN}/hardware.bit

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