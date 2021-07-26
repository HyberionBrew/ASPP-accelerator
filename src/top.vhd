LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

USE work.core_pck.ALL;
USE work.top_types_pck.ALL;

ENTITY top IS
	GENERIC (
		PARALLEL_OFMS : NATURAL := 4; --variable
		MAX_OFMS : NATURAL := 4; --variable
		FILTER_DEPTH : NATURAL := 1; --32; --variable
		FILTER_VALUES : NATURAL := 64; --fixed cannot be easily extended/changed
		MAX_RATE : NATURAL := 1; --either 1,2,3 not yet extended beyond 1
		PE_COLUMNS : NATURAL := 3; --fixed could be extended to 9
		OFM_REQUANT : NATURAL := 62
	);
	PORT (
		reset, clk : IN STD_LOGIC;
		rx : IN STD_LOGIC;
		tx : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF top IS
	--UART and OFMS_UNIT COMMUNICATION
	SIGNAL from_uart : from_uart_type;
	SIGNAL to_uart : to_uart_type;
	SIGNAL to_uart_from_ofm, to_uart_from_counters : to_uart_type;
	--ctrl to PEs
	SIGNAL ctrl_to_PEs : ctrl_to_PEs_type;
	--from bitvec generated
	SIGNAL bus_to_array, bus_values : STD_LOGIC_VECTOR(BUSSIZE - 1 DOWNTO 0);
	SIGNAL new_kernels_to_ctrl : STD_LOGIC_VECTOR(PARALLEL_OFMS - 1 DOWNTO 0);
	--PEs to ctrl
	SIGNAL PEs_finished : STD_LOGIC;
	SIGNAL psums_from_array : psum_array;
	SIGNAL array_finished_ifmaps : STD_LOGIC;
	CONSTANT ifmap_zero_offset : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(IFMAP_ZERO_CONSTANT, DATA_WIDTH));
	--used to calculate/output utilization
	SIGNAL mult_counter : mult_counter_array;
	SIGNAL finished_ofms_to_storage : ofms_out_type;
	SIGNAL exc_counter : unsigned(EXEC_COUNTER_WIDTH - 1 DOWNTO 0);
	SIGNAL uart_exec_data_counter, uart_exec_data_counter_nxt : NATURAL RANGE 0 TO PARALLEL_OFMS * PE_COLUMNS * 4 + 4 + 10;
	SIGNAL uart_exec_data, uart_exec_data_nxt : STD_LOGIC_VECTOR(8 - 1 DOWNTO 0);
	SIGNAL finished_counters : STD_LOGIC;
	SIGNAL slice_cp, slice_cp_nxt : NATURAL RANGE 0 TO 4 - 1;
	SIGNAL ofm_cp, ofm_cp_nxt : NATURAL RANGE 0 TO PARALLEL_OFMS - 1;
	SIGNAL column_cp, column_cp_nxt : NATURAL RANGE 0 TO PE_COLUMNS - 1;
	SIGNAL in_unit_to_ctrl : in_unit_to_ctrl_type;
	SIGNAL ctrl_to_in : ctrl_to_in_type;
	--everything finished
	SIGNAL finished : STD_LOGIC;
BEGIN

	-- The following processes are responsible for the UART control and outputing multiplication counters
	-- (for benchmarking the utilization)
	uart_c_sync : PROCESS (reset, clk)
	BEGIN
		IF reset = '0' THEN
			uart_exec_data_counter <= 0;
			uart_exec_data <= (OTHERS => '0');
			slice_cp <= 0;
			ofm_cp <= 0;
			column_cp <= 0;
		ELSIF rising_edge(clk) THEN
			uart_exec_data_counter <= uart_exec_data_counter_nxt;
			uart_exec_data <= uart_exec_data_nxt;
			column_cp <= column_cp_nxt;
			slice_cp <= slice_cp_nxt;
			ofm_cp <= ofm_cp_nxt;
		END IF;

	END PROCESS;

	uart_counter_gen : PROCESS (ALL)
	BEGIN
		to_uart_from_counters.valid <= '0';
		to_uart_from_counters.data <= uart_exec_data;
		uart_exec_data_counter_nxt <= uart_exec_data_counter;
		IF from_uart.want_data_counters = '1' THEN
			IF from_uart.ready = '1' THEN
				to_uart_from_counters.valid <= '1';
				to_uart_from_counters.data <= uart_exec_data;
				uart_exec_data_counter_nxt <= uart_exec_data_counter + 1;
			END IF;
		END IF;
	END PROCESS;

	uart_exec_data_prov : PROCESS (ALL)
	BEGIN
		finished_counters <= '0';
		uart_exec_data_nxt <= X"0A";
		ofm_cp_nxt <= ofm_cp;
		slice_cp_nxt <= slice_cp;
		column_cp_nxt <= column_cp;
		IF uart_exec_data_counter < 4 THEN
			uart_exec_data_nxt <= STD_LOGIC_VECTOR(exc_counter(DATA_WIDTH * (4 - (uart_exec_data_counter)) - 1 DOWNTO DATA_WIDTH * (3 - (uart_exec_data_counter))));
		ELSIF uart_exec_data_counter < PARALLEL_OFMS * PE_COLUMNS * 4 + 4 THEN
			IF from_uart.ready = '1' THEN
				IF slice_cp = 4 - 1 THEN
					slice_cp_nxt <= 0;
					IF column_cp = PE_COLUMNS - 1 THEN
						column_cp_nxt <= 0;
						IF ofm_cp = PARALLEL_OFMS - 1 THEN
							ofm_cp_nxt <= 0;
						ELSE
							ofm_cp_nxt <= ofm_cp + 1;
						END IF;
					ELSE
						column_cp_nxt <= column_cp + 1;
					END IF;
				ELSE
					slice_cp_nxt <= slice_cp + 1;
				END IF;
			END IF;
			uart_exec_data_nxt <= STD_LOGIC_VECTOR(mult_counter(column_cp, ofm_cp)(DATA_WIDTH * (4 - (slice_cp)) - 1 DOWNTO DATA_WIDTH * (3 - (slice_cp))));
		ELSIF uart_exec_data_counter = PARALLEL_OFMS * PE_COLUMNS * 4 + 4 THEN
			uart_exec_data_nxt <= X"0A";
		ELSE
			finished_counters <= '1';
		END IF;
	END PROCESS;
	uart_arb : PROCESS (ALL)
	BEGIN
		IF from_uart.want_data_ofm = '1' THEN
			to_uart <= to_uart_from_ofm;
		ELSE
			to_uart <= to_uart_from_counters;
		END IF;
	END PROCESS;

	-- The output feature map unit stores the completed psums and requantizes them
	requant_unit : ENTITY work.ofms_unit
		GENERIC MAP(
			PARALLEL_OFMS => PARALLEL_OFMS,
			MAX_OFMS => MAX_OFMS,
			MAX_RATE => MAX_RATE,
			PE_COLUMNS => PE_COLUMNS,
			OFM_REQUANT => OFM_REQUANT
		)
		PORT MAP(
			clk => clk,
			reset => reset,
			ofms_in => finished_ofms_to_storage,
			from_uart => from_uart,
			to_uart => to_uart_from_ofm
		);

	-- The uart_unit is the master in the comm with the ofm_unit
	-- it tells the ofm_unit once data should be prepared and when to send
	-- new data
	uart_i : ENTITY work.uart_unit
		PORT MAP(
			clk => clk,
			reset => reset,
			from_uart => from_uart,
			to_uart => to_uart,
			rx => rx,
			tx => tx,
			finished => finished, --just used for asserting from_uart.want_data <= '1'
			finished_counters => finished_counters
		);

	-- stores ifmaps and kernels at startup
	in_unit_i : ENTITY work.in_unit
		GENERIC MAP(
			PARALLEL_OFMS => PARALLEL_OFMS,
			MAX_OFMS => MAX_OFMS,
			MAX_RATE => MAX_RATE,
			PE_COLUMNS => PE_COLUMNS,
			FILTER_DEPTH => FILTER_DEPTH
		)
		PORT MAP(
			clk => clk,
			reset => reset,
			in_unit_to_ctrl => in_unit_to_ctrl,
			ctrl_to_in => ctrl_to_in
		);

	--responsible for the control flow
	cntrl_unit_i : ENTITY work.cntrl_unit
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
			ctrl_to_in => ctrl_to_in,
			in_unit_to_ctrl => in_unit_to_ctrl,
			ctr_to_PEs => ctrl_to_PEs,
			PEs_finished => array_finished_ifmaps,
			psum_values_in => psums_from_array,
			ofms_out => finished_ofms_to_storage,
			finished => finished,
			exc_counter => exc_counter
		);
	--creates the zero/non-zero bitvectors
	bitvec_i : ENTITY work.bitvec
		GENERIC MAP(
			PARALLEL_OFMS => PARALLEL_OFMS,
			FILTER_VALUES => FILTER_VALUES,
			PE_COLUMNS => PE_COLUMNS
		)
		PORT MAP(
			clk => clk,
			reset => reset,
			kernels_to_bitvec => ctrl_to_PEs.kernel_values,
			iacts_to_bitvec => ctrl_to_PEs.ifmap_values,
			new_ifmaps => ctrl_to_PEs.new_ifmaps,
			new_kernels => ctrl_to_PEs.new_kernels,
			bus_values => bus_values,
			ifmap_zero_offset => ifmap_zero_offset
		);

	-- The PE array
	pe_array_i : ENTITY work.pe_array
		GENERIC MAP(
			PARALLEL_OFMS => PARALLEL_OFMS,
			FILTER_DEPTH => FILTER_DEPTH,
			PE_COLUMNS => PE_COLUMNS -- fixed, could be extended
		)
		PORT MAP(
			reset => reset,
			clk => clk,
			bus_pe_array => bus_to_array,
			new_kernels_to_array => ctrl_to_PEs.new_kernels,
			new_ifmaps_to_array => ctrl_to_PEs.new_ifmaps,
			psums_to_control => psums_from_array,
			psums_from_control => ctrl_to_PEs.new_psum_values,
			get_psums => ctrl_to_PEs.get_psums,
			new_psum => ctrl_to_PEs.new_psums,
			ifmap_zero_offset => ifmap_zero_offset,
			finished_ifmaps_out => array_finished_ifmaps,
			mult_counter => mult_counter
		);
	bus_arb : PROCESS (ALL)
	BEGIN

		IF OR_REDUCE(ctrl_to_PEs.new_ifmaps) = '1' OR OR_REDUCE(ctrl_to_PEs.new_kernels) = '1' THEN
			bus_to_array <= bus_values;
		ELSE
			bus_to_array <= (OTHERS => '-');
		END IF;

	END PROCESS;
END ARCHITECTURE;