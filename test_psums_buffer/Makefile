VCOM_ARGS=-2008 -work work
VSIM_ARGS=-msgmode both

VHDL_FILES = \
	../src/core_pck.vhd\
	../src/pe_pck.vhd\
	../src/control/control_pck.vhd\
	../src/control/ultra_ram_pck.vhd\
	../src/control/ultra_ram.vhd\
	../src/control/psums_buffer.vhd
TB_FILES = \
  ./tb/test_utils.vhd\
  ./tb/psum_buffer_tb.vhd

TIME_RESOLUTION = 1ps

TB = psums_buffer_tb
SIM_TIME = 10000 ns
WAVE = ./wave.do

compile:
	rm -f log
	vlib work | tee log
	for i in $(VHDL_FILES); do \
		vcom $(VCOM_ARGS) $$i | tee -a log;\
	done;
	for i in $(TB_FILES); do \
		vcom $(VCOM_ARGS) $$i | tee -a log;\
	done;
	@echo "--------------------------------------------------------------"
	@echo "--              Error and Warning Summary                   --"
	@echo "--------------------------------------------------------------"
	@cat log | grep 'Warning\|Error'

compile_post:
	vlib work | tee log
	vcom $(VCOM_ARGS) $(POST_SDO) | tee -a log;

list_sources:
	@for i in $(VHDL_FILES); do \
		echo $$i;\
	done;

sim:
	vsim -do "vsim $(TB) -t $(TIME_RESOLUTION) $(VSIM_ARGS); do $(WAVE); run $(SIM_TIME)"

sim_quit:
	vsim -c -do "vsim $(TB) -t $(TIME_RESOLUTION) $(VSIM_ARGS); run $(SIM_TIME); q" > /dev/null
	grep "failed" ./testdata/output.txt || true

clean:
	rm -f transcript
	rm -f vsim.wlf
	rm -f log
	rm -fr work

.PHONY: s
s: sim

.PHONY: sq
sq: sim_quit
