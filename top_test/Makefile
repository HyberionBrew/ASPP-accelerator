VCOM_ARGS=-2008 -work work
VSIM_ARGS=-msgmode both

VHDL_FILES = \
	../src/core_pck.vhd\
	../src/control/control_pck.vhd\
	../src/pe_pck.vhd\
	../src/control/state_calc.vhd\
	../src/control/ultra_ram.vhd\
	../src/control/ultra_ram_pck.vhd\
	../src/control/iacts_buffer.vhd\
	../src/control/psums_buffer.vhd\
	../src/control/ctrl.vhd\
	../src/PE/fetch_unit_pck.vhd\
	../src/PE/fetch_unit.vhd\
	../src/PE/mult.vhd\
	../src/PE/accum.vhd\
	../src/PE/pe.vhd\
	../src/pe_array_pck.vhd\
	../src/pe_array.vhd\
	../src/bitvec_unit.vhd\
	../src/ofm/block_ram_pkg.vhd\
    ../src/ofm/block_ram.vhd\
    ../src/ofm/init_file_bram.vhd\
    ../src/ofm/ofm_unit.vhd\
	../src/top.vhd\

TB_FILES = \
  ./tb/test_utils.vhd\
  ./tb/top_tb.vhd

TIME_RESOLUTION = 10ps

TB = top_tb
SIM_TIME = 6 ms
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
	set generics "-gPARALLEL_OFMS=3 -gMAX_OFMS=3 -gFILTER_DEPTH=1"
	vsim -do "vsim $(TB) -f arg_file.txt -t $(TIME_RESOLUTION) $(VSIM_ARGS); do $(WAVE); run $(SIM_TIME)"

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
