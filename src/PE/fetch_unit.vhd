

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

USE ieee.numeric_std.ALL;
USE work.core_pck.ALL;

USE work.fetch_unit_pck.ALL;

-- The fetch unit is responsible for extracting the next valid index
-- (neither weight and ifmap equal to zero)
ENTITY fetch_unit IS
	GENERIC (
		COMPARISON_BITVEC_WIDTH : NATURAL := 18
	);
	PORT (
		reset, clk : IN STD_LOGIC;
		finished : OUT STD_LOGIC;
		new_kernels : IN STD_LOGIC;
		new_ifmaps : IN STD_LOGIC;
		kernel_bitvecs, ifmap_bitvecs : IN STD_LOGIC_VECTOR(FILTER_PER_PE - 1 DOWNTO 0);
		index : OUT NATURAL RANGE 0 TO FILTER_PER_PE - 1;
		valid : OUT STD_LOGIC
	);
END fetch_unit;

ARCHITECTURE arch OF fetch_unit IS
	SIGNAL state, state_nxt : state_type;
	SIGNAL kernel_bitvecs_reg, kernel_bitvecs_reg_storage, kernel_bitvecs_reg_storage_nxt, kernel_bitvecs_reg_nxt : STD_LOGIC_VECTOR(FILTER_PER_PE - 1 DOWNTO 0);
	SIGNAL ifmap_bitvecs_reg, ifmap_bitvecs_reg_nxt : STD_LOGIC_VECTOR(FILTER_PER_PE - 1 DOWNTO 0);
	CONSTANT MAX_COUNTER : NATURAL := FILTER_PER_PE/COMPARISON_BITVEC_WIDTH;
	SIGNAL index_reg, index_reg_nxt : NATURAL RANGE 0 TO FILTER_PER_PE + COMPARISON_BITVEC_WIDTH;

BEGIN

	sync : PROCESS (clk, reset)
	BEGIN
		IF reset = '0' THEN
			state <= LOADING_VALUES;
			ifmap_bitvecs_reg <= (OTHERS => '0');
			kernel_bitvecs_reg <= (OTHERS => '0');
			index_reg <= 0;
			kernel_bitvecs_reg_storage <= (OTHERS => '0');
		ELSIF rising_edge(clk) THEN
			state <= state_nxt;
			kernel_bitvecs_reg <= kernel_bitvecs_reg_nxt;
			ifmap_bitvecs_reg <= ifmap_bitvecs_reg_nxt;
			index_reg <= index_reg_nxt;
			kernel_bitvecs_reg_storage <= kernel_bitvecs_reg_storage_nxt;
		END IF;
	END PROCESS;

	-- see thesis for documentation
	state_process : PROCESS (ALL)
		VARIABLE comp_window : STD_LOGIC_VECTOR(COMPARISON_BITVEC_WIDTH - 1 DOWNTO 0);
		VARIABLE valid_var : STD_LOGIC;
		VARIABLE index_var : NATURAL RANGE 0 TO COMPARISON_BITVEC_WIDTH - 1;
		VARIABLE index_comp : NATURAL RANGE 0 TO FILTER_PER_PE + COMPARISON_BITVEC_WIDTH - 1;
	BEGIN
		valid_var := '0';
		state_nxt <= state;
		valid <= '0';
		finished <= '0';
		ifmap_bitvecs_reg_nxt <= ifmap_bitvecs_reg;
		kernel_bitvecs_reg_storage_nxt <= kernel_bitvecs_reg_storage;
		kernel_bitvecs_reg_nxt <= kernel_bitvecs_reg;
		index <= 0;
		index_reg_nxt <= 0;
		CASE(state) IS

			WHEN LOADING_VALUES =>
			kernel_bitvecs_reg_nxt <= kernel_bitvecs_reg_storage;
			IF new_kernels = '1' THEN
				kernel_bitvecs_reg_nxt <= kernel_bitvecs;
				kernel_bitvecs_reg_storage_nxt <= kernel_bitvecs;
			ELSIF new_ifmaps = '1' THEN
				ifmap_bitvecs_reg_nxt <= ifmap_bitvecs;
				state_nxt <= PROCESSING;
			END IF;
			finished <= '1';

			WHEN PROCESSING =>
			comp_window := kernel_bitvecs_reg((COMPARISON_BITVEC_WIDTH) - 1 DOWNTO 0) AND ifmap_bitvecs_reg((COMPARISON_BITVEC_WIDTH) - 1 DOWNTO 0);
			mask_last(comp_window, index_var, valid_var);
			index_comp := index_var + index_reg;
			kernel_bitvecs_reg_nxt <= STD_LOGIC_VECTOR(shift_right(unsigned(kernel_bitvecs_reg), index_var + 1));
			ifmap_bitvecs_reg_nxt <= STD_LOGIC_VECTOR(shift_right(unsigned(ifmap_bitvecs_reg), index_var + 1));
			IF index_comp < FILTER_PER_PE THEN
				valid <= valid_var;
			ELSE
				state_nxt <= LOADING_VALUES;
				valid <= '0';
				index_comp := 0;
				finished <= '1';
			END IF;
			index <= index_comp;
			index_reg_nxt <= index_comp + 1;
		END CASE;
	END PROCESS;

END ARCHITECTURE;