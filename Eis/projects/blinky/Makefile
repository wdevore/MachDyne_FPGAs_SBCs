TOP_FILE = Top.sv

SUB_MODULES_FILES =

MODULES_FILES = ${SUB_MODULES_FILES} ${TOP_FILE}

BUILD_BIN = /media/RAMDisk

ICESTORM_TOOLCHAIN = /usr/local

YOSYS_COMMAND = "synth_ice40 -blif ${BUILD_BIN}/chip.blif -json ${BUILD_BIN}/hardware.json -top Top"

PINS_CONSTRAINTS = ../eis.pcf

.PHONY: all

all: build route upload

compile: build route

build: ${MODULES_FILES} ${PINS_CONSTRAINTS}
	@echo "##### Building..."
	${ICESTORM_TOOLCHAIN}/bin/yosys -p ${YOSYS_COMMAND} \
	-l ${BUILD_BIN}/yo.log \
	-q \
	-defer \
	${MODULES_FILES}

route: ${BUILD_BIN}/hardware.json
	@echo "##### Routing..."
	${ICESTORM_TOOLCHAIN}/bin/nextpnr-ice40 \
	--hx8k \
	-q \
	--package bg121 \
	--pcf ${PINS_CONSTRAINTS} \
	-l ${BUILD_BIN}/next.log \
	--json ${BUILD_BIN}/hardware.json \
	--asc ${BUILD_BIN}/hardware.asc

explain: ${BUILD_BIN}/hardware.asc
	icebox_explain ${BUILD_BIN}/hardware.asc > ${BUILD_BIN}/hardware.ex

time: ${BUILD_BIN}/hardware.bin
	icetime -tmd hx8k ${BUILD_BIN}/hardware.asc
	
upload: ${BUILD_BIN}/hardware.asc
	@echo "##### Packing..."
	${ICESTORM_TOOLCHAIN}/bin/icepack ${BUILD_BIN}/hardware.asc ${BUILD_BIN}/hardware.bin
	@echo "##### Uploading..."
	ldprog -i -s ${BUILD_BIN}/hardware.bin
