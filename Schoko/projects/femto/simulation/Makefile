# Top module is the HDL component being tested.
TOP = Top

# A cpp test-bench driver
TEST_BENCH = \
	test_bench.cpp

TEMPLATE_HEADER = ../module.h

# VERILATOR_PUBLICS = 
# The vcd data for viewing
GTKWAVE_SETTINGS = waveform

# HDL modules
MODULES_FILES =  \
	SimEnums.sv \
	femtorv32_intermissum.v \
	SoC.sv \
	Top.sv
	
# output build directory
BUILD_DIR = /media/RAMDisk

# Verilator is the simulator
SIMULATION_TOOLCHAIN = /usr/local/bin/verilator

# Typically you would use "lint", "compile"+"run"+"view", or just "go"
# The other target/phonies are for reference and perhaps of some limited functionality.
.PHONY: all

lint:
	@echo "############### Linting via Verilator ##################"
	${SIMULATION_TOOLCHAIN} --lint-only -Wall ${MODULES_FILES} \
	--top-module ${TOP}

compile:
	@echo "################## Compiling ##################"
	cp ${TEST_BENCH} ${BUILD_DIR}
	cp ${TEMPLATE_HEADER} ${BUILD_DIR}
	${SIMULATION_TOOLCHAIN} --Mdir ${BUILD_DIR} \
	--trace -cc \
	--top-module ${TOP} \
	--exe --build ${TEST_BENCH} ${MODULES_FILES} \
	-DPRELOAD_MEMORY \
	-DSHOW_MEMORY

run:
	@echo "################## Simulating ##################"
	${BUILD_DIR}/V${TOP}

view:
	@echo "################## Viewing ##################"
	gtkwave ${BUILD_DIR}/waveform.vcd \
	${GTKWAVE_SETTINGS}.gtkw \
	--rcvar 'splash_disable on' \
	--rcvar 'fontname_signals Monospace 14' \
	--rcvar 'fontname_waves Monospace 14' \
	--rcvar 'color_back 222222' \
	--rcvar 'color_trans 999999' \
	--rcvar 'color_time 00ddff' \
	--rcvar 'enable_horiz_grid off' \
	--rcvar 'highlight_wavewindow on' \
	--rcvar 'show_base_symbols on' \
	--rcvar 'fill_waveform on' \
	--rcvar 'disable_mouseover off'
	

go: compile run view
	@echo "################## Simulated via Verilator ##################"

clean:
	rm ${BUILD_DIR}/*
