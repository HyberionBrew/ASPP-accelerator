LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;
USE work.core_pck.ALL;
USE work.top_types_pck.ALL;
USE work.pe_array_pck.ALL;

ENTITY pe_array IS
	GENERIC (
		PARALLEL_OFMS : NATURAL := 3;
		FILTER_DEPTH : NATURAL := 32;
		PE_COLUMNS : NATURAL := 3
	);
	PORT (
		reset, clk : IN STD_LOGIC;
		bus_pe_array : IN STD_LOGIC_VECTOR(BUSSIZE - 1 DOWNTO 0);
		new_kernels_to_array : IN STD_LOGIC_VECTOR(PARALLEL_OFMS - 1 DOWNTO 0);
		new_ifmaps_to_array : IN STD_LOGIC_VECTOR(PE_COLUMNS - 1 DOWNTO 0);
		psums_to_control : OUT psum_array;
		psums_from_control : IN psum_array;
		get_psums : IN STD_LOGIC;
		new_psum : IN STD_LOGIC;
		ifmap_zero_offset : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
		finished_ifmaps_out : OUT STD_LOGIC;
		mult_counter : OUT mult_counter_array
	);
END ENTITY;

ARCHITECTURE arch OF pe_array IS

	SIGNAL finished_ifmaps, new_kernels, new_ifmaps : std_logic_array;
	TYPE psums_array IS ARRAY(0 TO PE_COLUMNS - 1, 0 TO PARALLEL_OFMS - 1) OF signed(ACC_DATA_WIDTH - 1 DOWNTO 0);

	SIGNAL psum : psums_array;
	SIGNAL psums_bus : STD_LOGIC_VECTOR(BUSSIZE - 1 DOWNTO 0);
	SIGNAL bus_to_pe : STD_LOGIC_VECTOR(BUSSIZE - 1 DOWNTO 0);
	SIGNAL psum_in : psums_array;

BEGIN
	-- 9 = PE_COLUMNS could be added somewhat easily, other values are more problematic
	--ASSERT PE_COLUMNS = 3 or PE_COLUMNS = 2 or PE_COLUMNS = 1 REPORT "Only 1, 2 or 3 PE_COLUMNS are supported!";
	--ASSERT IFMAP_SIZE mod PE_COLUMNS = 0 REPORT "IFMAP SIZE MUST BE DIVISIBLE by PE_COLUMNS!";
	PEs_rows : FOR row IN 0 TO PARALLEL_OFMS - 1 GENERATE
		PEs_columns : FOR col IN 0 TO PE_COLUMNS - 1 GENERATE
			pe_i : ENTITY work.pe
				PORT MAP(
					reset => reset,
					clk => clk,
					new_kernels => new_kernels(col, row),
					new_ifmaps => new_ifmaps(col, row),
					new_psum => new_psum,
					psum_in => psum_in(col, row),
					bus_to_pe => bus_to_pe,
					psum => psum(col, row),
					mult_counter => mult_counter(col, row),
					ifmap_zero_offset => ifmap_zero_offset,
					finished_ifmaps => finished_ifmaps(col, row)
				);
		END GENERATE;
	END GENERATE;

	-- output all PEs finished
	out_p : PROCESS (ALL)
	BEGIN
		finished_ifmaps_out <= AND_REDUCE_COL_ROWS(finished_ifmaps);
	END PROCESS;

	-- Selects the appropiate PEs for receiving new values
	bus_driver : PROCESS (ALL)
	BEGIN
		new_kernels <= (OTHERS => (OTHERS => '0'));
		new_ifmaps <= (OTHERS => (OTHERS => '0'));
		bus_to_pe <= bus_pe_array WHEN OR_REDUCE(new_ifmaps_to_array) = '1' OR OR_REDUCE(new_kernels_to_array) = '1' OR new_psum = '1' ELSE
			(OTHERS => '-');

		FOR row IN 0 TO PARALLEL_OFMS - 1 LOOP
			IF new_kernels_to_array(row) = '1' THEN
				FOR col IN 0 TO PE_COLUMNS - 1 LOOP
					new_kernels(col, row) <= '1';
				END LOOP;
			END IF;
		END LOOP;

		FOR col IN 0 TO PE_COLUMNS - 1 LOOP
			IF new_ifmaps_to_array(col) = '1' THEN
				FOR row IN 0 TO PARALLEL_OFMS - 1 LOOP
					new_ifmaps(col, row) <= '1';
				END LOOP;
			END IF;
		END LOOP;
	END PROCESS;

	-- sends the psums to the right PEs
	psum_input : PROCESS (ALL)
	BEGIN
		psum_in <= (OTHERS => (OTHERS => (OTHERS => '0')));
		FOR row IN 0 TO PARALLEL_OFMS - 1 LOOP
			FOR col IN 0 TO PE_COLUMNS - 1 LOOP
				psum_in(col, row) <= psums_from_control(row, col);
			END LOOP;
		END LOOP;
	END PROCESS;

	--writes the psums back to the psums stage
	psums_back : PROCESS (ALL)
	BEGIN
		psums_bus <= (OTHERS => '0');
		FOR row IN 0 TO PARALLEL_OFMS - 1 LOOP
			FOR col IN 0 TO PE_COLUMNS - 1 LOOP
				psums_to_control(row, col) <= psum(col, row);
			END LOOP;
		END LOOP;
	END PROCESS;
END ARCHITECTURE;