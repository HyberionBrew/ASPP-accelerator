-- The PE
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.core_pck.ALL;
USE work.pe_pack.ALL;

ENTITY pe IS
	PORT (
		reset, clk : IN STD_LOGIC;
		new_kernels : IN STD_LOGIC;
		new_ifmaps : IN STD_LOGIC;
		new_psum : IN STD_LOGIC;
		psum_in : IN signed(ACC_DATA_WIDTH - 1 DOWNTO 0);
		bus_to_pe : IN STD_LOGIC_VECTOR(BUSSIZE - 1 DOWNTO 0);
		psum : OUT signed(ACC_DATA_WIDTH - 1 DOWNTO 0);
		mult_counter : OUT unsigned(EXEC_COUNTER_WIDTH - 1 DOWNTO 0);
		ifmap_zero_offset : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
		finished_ifmaps : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF pe IS

	SIGNAL valid_from_fetch, valid_from_mult, finished_from_mult, finished_from_fetch, finished : STD_LOGIC;
	SIGNAL index : NATURAL RANGE 0 TO FILTER_PER_PE - 1;
	SIGNAL result : signed(DATA_WIDTH_RESULT - 1 DOWNTO 0);
	ALIAS bitvecs : STD_LOGIC_VECTOR(FILTER_PER_PE - 1 DOWNTO 0) IS bus_to_pe(FILTER_PER_PE - 1 DOWNTO 0);
	ALIAS data : STD_LOGIC_VECTOR(FILTER_PER_PE * DATA_WIDTH - 1 DOWNTO 0) IS bus_to_pe(FILTER_PER_PE * DATA_WIDTH - 1 + FILTER_PER_PE DOWNTO FILTER_PER_PE);

BEGIN
	f_as : PROCESS (ALL)
	BEGIN
		finished_ifmaps <= finished_from_fetch;
	END PROCESS;

	fetch_unit_i : ENTITY work.fetch_unit
		GENERIC MAP(
			COMPARISON_BITVEC_WIDTH => COMPARISON_BITVEC_WIDTH
		)
		PORT MAP(
			reset => reset,
			clk => clk,
			finished => finished_from_fetch,
			new_kernels => new_kernels,
			new_ifmaps => new_ifmaps,
			kernel_bitvecs => bitvecs,
			ifmap_bitvecs => bitvecs,
			index => index,
			valid => valid_from_fetch
		);

	mult_unit_i : ENTITY work.mult_unit
		GENERIC MAP(
			DATA_WIDTH_RESULT => DATA_WIDTH_RESULT
		)
		PORT MAP(
			clk => clk,
			reset => reset,
			finished_in => finished_from_fetch,
			finished_out => finished_from_mult,
			new_kernels => new_kernels,
			new_ifmaps => new_ifmaps,
			data => data,
			ifmap_zero_offset => ifmap_zero_offset,
			index => index,
			valid => valid_from_fetch,
			valid_out => valid_from_mult,
			result_out => result
		);

	accum_unit_i : ENTITY work.accum_unit
		GENERIC MAP(
			ACC_DATA_WIDTH => ACC_DATA_WIDTH,
			DATA_WIDTH_RESULT => DATA_WIDTH_RESULT
		)
		PORT MAP(
			reset => reset,
			clk => clk,
			new_psum => new_psum,
			new_ifmap => new_ifmaps,
			finished_in => finished_from_mult,
			finished_out => finished,
			psum_in => psum_in,
			psum_out => psum,
			result => result,
			valid => valid_from_mult
		);

	mult_cp : PROCESS (clk, reset)
	BEGIN
		IF reset = '0' THEN
			mult_counter <= (OTHERS => '0');
		ELSIF rising_edge(clk) THEN
			mult_counter <= mult_counter;
			IF valid_from_mult = '1' THEN
				mult_counter <= mult_counter + 1;
			END IF;
		END IF;
	END PROCESS;
END ARCHITECTURE;