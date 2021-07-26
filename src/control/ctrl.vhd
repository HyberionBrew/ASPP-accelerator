LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

USE work.core_pck.ALL;
USE work.control_pck.ALL;
USE work.top_types_pck.ALL;

USE IEEE.math_real.ALL;

ENTITY cntrl_unit IS
	GENERIC (
		PARALLEL_OFMS : NATURAL := 3;
		MAX_OFMS : NATURAL := 255;
		FILTER_DEPTH : NATURAL := 32;
		FILTER_VALUES : NATURAL := 64;
		MAX_RATE : NATURAL := 3
	);
	PORT (
		clk, reset : IN STD_LOGIC;
		--one to DRAM/kernel unit
		ctrl_to_in : OUT ctrl_to_in_type;
		in_unit_to_ctrl : IN in_unit_to_ctrl_type;
		--load_ifmaps : OUT STD_LOGIC;
		--load_kernels : OUT STD_LOGIC;
		--from DRAM
		
		--kernels_loaded : IN STD_LOGIC;
		--ifmaps_loaded : IN STD_LOGIC;
		--ifmap_values_from_dram : IN ifmap_DRAM_type;
		--kernel_values_from_dram : IN kernel_values_array;
		--control to PEs
		--new_kernels_valid : IN STD_LOGIC_VECTOR(PARALLEL_OFMS - 1 DOWNTO 0);
		ctr_to_PEs : OUT ctrl_to_PEs_type;
		--control from PEs
		PEs_finished : IN STD_LOGIC;
		--values from PE array
		psum_values_in : IN psum_array;
		ofms_out : OUT ofms_out_type;
		--values to PE arry		
		exc_counter : OUT unsigned(EXEC_COUNTER_WIDTH - 1 DOWNTO 0);
		finished : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF cntrl_unit IS

	--control state
	TYPE state_type IS (LOADING_IFMAPS, WAITING, WRITE_IFMAP, WRITE_KERNEL, CLEAN, WRITE_PSUMS_OUT, FINISHED_STATE);
	SIGNAL state, state_nxt : state_type;

	--control for input activation buffer
	SIGNAL iacts_buffer_mode : iacts_mode_type;
	SIGNAL ifmap_out_buffer : iacts_buffer_type;
	--ifmap out buffer valid if high
	SIGNAL ifmaps_prepared : STD_LOGIC;
	--counts the number of ifmaps writen
	SIGNAL write_ifmap_counter, write_ifmap_counter_nxt : NATURAL RANGE 0 TO PE_COLUMNS - 1;

	--signals the the in unit should provide a kernel next
	SIGNAL need_kernel_nxt, need_kernel : STD_LOGIC;
	SIGNAL need_new_kernel : STD_LOGIC;
	--the current position in the ifmap/kernel
	SIGNAL ifmap_position, ifmap_position_prev : ifmap_position_type;
	SIGNAL write_kernel_counter, write_kernel_counter_nxt : NATURAL RANGE 0 TO PARALLEL_OFMS;
	--controls the psum buffer/its outputs
	TYPE psums_state_type IS (REQUEST_PSUMS, FETCH, PROCESS_PSUMS, IDLE);
	SIGNAL psum_state_nxt, psum_state : psums_state_type;
	SIGNAL psum_mode : mode_psums_type;
	SIGNAL psums_position : point;
	SIGNAL psums_position_prev : point;
	SIGNAL psums_writen, psums_writen_nxt : STD_LOGIC;
	-- high on buffer out valid
	SIGNAL psums_ready : STD_LOGIC;
	SIGNAL psum_values_out : psum_array;
	--singals that psums buffer should only provide 0s
	SIGNAL first_pass : STD_LOGIC;

	SIGNAL write_out_ofms, finished_writing_ofm : STD_LOGIC;
	SIGNAL finished_all : STD_LOGIC;

BEGIN

	sync : PROCESS (clk, reset)
	BEGIN
		IF reset = '0' THEN
			state <= LOADING_IFMAPS;
			need_kernel <= '1';
			write_ifmap_counter <= 0;
			psum_state <= REQUEST_PSUMS;
			write_kernel_counter <= 0;
			psums_writen <= '0';
		ELSIF rising_edge(clk) THEN
			state <= state_nxt;
			need_kernel <= need_kernel_nxt;
			write_ifmap_counter <= write_ifmap_counter_nxt;
			psum_state <= psum_state_nxt;
			write_kernel_counter <= write_kernel_counter_nxt;
			psums_writen <= psums_writen_nxt;
		END IF;
	END PROCESS;

	-- only needed for utilization measurement
	exec_count : PROCESS (ALL)
	BEGIN
		IF reset = '0' THEN
			exc_counter <= (OTHERS => '0');
		ELSIF rising_edge(clk) THEN
			exc_counter <= exc_counter;
			IF finished_all = '0' THEN
				IF NOT(state = LOADING_IFMAPS) THEN
					exc_counter <= exc_counter + 1;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	--computes the state
	state_pro : PROCESS (ALL)
	BEGIN
		state_nxt <= state;
		need_kernel_nxt <= need_kernel;
		ctrl_to_in.load_kernels <= '0';
		write_ifmap_counter_nxt <= write_ifmap_counter;
		write_kernel_counter_nxt <= write_kernel_counter;
		ctrl_to_in.load_ifmaps <= '0';
		finished <= '0';
		CASE(state) IS

			WHEN LOADING_IFMAPS =>
			ctrl_to_in.load_ifmaps <= '1';
			IF in_unit_to_ctrl.ifmaps_loaded = '1' THEN
				state_nxt <= WAITING;
			END IF;

			--PROCESSING
			WHEN WAITING =>
			--ready for new values?
			IF PEs_finished = '1' THEN
				IF need_kernel = '1' AND psums_writen = '1' THEN
					state_nxt <= WRITE_KERNEL;
				ELSE
					IF ifmaps_prepared = '1' AND psums_writen = '1' THEN
						state_nxt <= WRITE_IFMAP;
					END IF;
				END IF;
				IF write_out_ofms = '1' AND finished_writing_ofm = '0' AND psums_writen = '1' THEN
					state_nxt <= WRITE_PSUMS_OUT;
				END IF;
			END IF;

			--PROCESSING
			WHEN WRITE_KERNEL =>
			ctrl_to_in.load_kernels <= '1';
			IF in_unit_to_ctrl.kernels_loaded = '1' AND write_kernel_counter >= PARALLEL_OFMS - 1 THEN
				IF ifmaps_prepared = '1' THEN
					state_nxt <= WRITE_IFMAP;
					write_kernel_counter_nxt <= write_kernel_counter;
				ELSE
					write_kernel_counter_nxt <= write_kernel_counter;
					ctrl_to_in.load_kernels <= '0';
				END IF;
			ELSE
				IF write_kernel_counter >= PARALLEL_OFMS - 1 THEN
					write_kernel_counter_nxt <= 0;
				ELSE
					write_kernel_counter_nxt <= write_kernel_counter + 1;
				END IF;
			END IF;

			--PROCESSING
			WHEN WRITE_PSUMS_OUT =>
			IF finished_writing_ofm = '1' THEN
				IF finished_all = '0' THEN
					IF ifmaps_prepared = '1' THEN
						state_nxt <= WRITE_IFMAP;
					END IF;
				ELSE
					state_nxt <= FINISHED_STATE;
				END IF;
			END IF;

			--PROCESSING
			WHEN WRITE_IFMAP =>
			write_kernel_counter_nxt <= 0;
			IF write_ifmap_counter = PE_COLUMNS - 1 THEN
				write_ifmap_counter_nxt <= 0;
				state_nxt <= CLEAN;
			ELSE
				write_ifmap_counter_nxt <= write_ifmap_counter + 1;
			END IF;
			
			--PROCESSING
			WHEN CLEAN =>
			need_kernel_nxt <= need_new_kernel;
			state_nxt <= WAITING;

			WHEN FINISHED_STATE =>
			state_nxt <= FINISHED_STATE;
			finished <= '1';

		END CASE;

	END PROCESS;

	--takes care of writing to the bitvec unit
	write_to_pe_array : PROCESS (ALL)
	BEGIN
		ctr_to_PEs.ifmap_values <= (OTHERS => (OTHERS => '-'));
		ctr_to_PEs.kernel_values <= (OTHERS => (OTHERS => '-'));
		ctr_to_PEs.new_kernels <= (OTHERS => '0');

		CASE(state) IS

			WHEN WAITING =>

			WHEN WRITE_IFMAP =>
			FOR I IN 0 TO FILTER_PER_PE - 1 LOOP
				ctr_to_PEs.ifmap_values(I) <= ifmap_out_buffer(write_ifmap_counter, I);
			END LOOP;
			WHEN WRITE_KERNEL =>
			ctr_to_PEs.kernel_values <= in_unit_to_ctrl.kernel_values;
			ctr_to_PEs.new_kernels <= in_unit_to_ctrl.new_kernels;
			WHEN OTHERS =>

		END CASE;

	END PROCESS;

	--this process controls the ifmap loading with the iacts_buffer
	ifmaps_process : PROCESS (state, write_ifmap_counter) --all doesnt work here due to vivado bug
	BEGIN
		iacts_buffer_mode <= PREPARE_IFMAP;
		ctr_to_PEs.new_ifmaps <= (OTHERS => '0');
		CASE(state) IS
			WHEN LOADING_IFMAPS =>
			iacts_buffer_mode <= LOAD_IFMAP;
			WHEN WAITING =>
			iacts_buffer_mode <= PREPARE_IFMAP;
			WHEN WRITE_KERNEL =>
			iacts_buffer_mode <= PREPARE_IFMAP;
			WHEN WRITE_IFMAP =>
			ctr_to_PEs.new_ifmaps(write_ifmap_counter) <= '1';
			WHEN CLEAN =>
			iacts_buffer_mode <= CLEAN;
			WHEN OTHERS =>
		END CASE;
	END PROCESS;

	--this process controls the psums buffer
	psums_ctrl : PROCESS (ALL)
	BEGIN
		psum_mode <= CLEAN;
		psum_state_nxt <= psum_state;
		psums_writen_nxt <= psums_writen;
		ctr_to_PEs.new_psums <= '0';
		ctr_to_PEs.get_psums <= '0';
		ctr_to_PEs.new_psum_values <= (OTHERS => (OTHERS => (OTHERS => '-')));
		CASE(state) IS
			WHEN WRITE_PSUMS_OUT =>
			psum_mode <= WRITE_OUT_PSUMS;
			WHEN WAITING =>
			CASE (psum_state) IS
				WHEN REQUEST_PSUMS =>
					ctr_to_PEs.get_psums <= '1';
					psum_state_nxt <= FETCH;
					psum_mode <= FETCH_PSUMS;
				WHEN FETCH =>
					psum_state_nxt <= PROCESS_PSUMS;
					psum_mode <= FETCH_PSUMS;
				WHEN PROCESS_PSUMS =>
					psum_mode <= PREPARE_PSUMS;
					psum_state_nxt <= PROCESS_PSUMS;
					IF psums_ready = '1' THEN
						ctr_to_PEs.new_psum_values <= psum_values_out;
						psums_writen_nxt <= '1';
						ctr_to_PEs.new_psums <= '1';
						psum_state_nxt <= IDLE;
					END IF;
				WHEN OTHERS =>

			END CASE;
			WHEN OTHERS =>
			psum_state_nxt <= REQUEST_PSUMS;
			psums_writen_nxt <= '0';
		END CASE;
	END PROCESS;

	--unit calculates the needed ifmap/psum positions
	position_unit : ENTITY work.state_calc
		GENERIC MAP(
			PARALLEL_OFMS => PARALLEL_OFMS,
			MAX_OFMS => MAX_OFMS,
			FILTER_DEPTH => FILTER_DEPTH,
			FILTER_VALUES => FILTER_VALUES,
			MAX_RATE => MAX_RATE
		)
		PORT MAP(
			clk => clk,
			reset => reset,
			new_ifmaps => OR_REDUCE(ctr_to_PEs.new_ifmaps), --new_ifmap event signals advance for state
			need_kernel => need_new_kernel, --goes high if new kernel should be provided
			first_pass => first_pass, --high on first pass tells psums_buffer to output 0s
			write_out_ofms_out => write_out_ofms, --high starts writing out to storage
			ifmap_position => ifmap_position, --the next ifmap_position
			psums_position => psums_position,
			psums_position_prev => psums_position_prev,
			finished => finished_all
		);

	iacts_buffer_i : ENTITY work.iacts_buffer
		GENERIC MAP(
			IFMAP_SIZE => IFMAP_SIZE,
			IFMAPS_TO_PREPARE => PE_COLUMNS,
			AWIDTH => AWIDTH_IACTS_BUFFER,
			DEPTH => DEPTH_IACTS_BUFFER
		)
		PORT MAP(
			clk => clk,
			reset => reset,
			mode => iacts_buffer_mode,
			values => in_unit_to_ctrl.ifmap_values,
			address => ifmap_position,
			out_buffer => ifmap_out_buffer,
			ifmaps_prepared => ifmaps_prepared
		);

	psums_buffer_i : ENTITY work.psums_buffer
		GENERIC MAP(
			ACC_WIDTH => ACC_DATA_WIDTH,
			MAX_OFMS => MAX_OFMS,
			PE_COLUMNS => PE_COLUMNS,
			PARALLEL_OFMS => PARALLEL_OFMS,
			A_WIDTH => AWIDTH_PSUM_BUFFER,
			DWIDTH => DWIDTH_PSUM_BUFFER,
			DEPTH => DEPTH_PSUM_BUFFER
		)
		PORT MAP(
			clk => clk,
			reset => reset,
			mode => psum_mode,
			address => psums_position,
			address_prev => psums_position_prev,
			psums_ready => psums_ready,
			psum_values_in => psum_values_in,
			first_pass => first_pass,
			out_buffer => psum_values_out,
			ofms_out => ofms_out,
			finished_writing_ofm => finished_writing_ofm
		);
END ARCHITECTURE;