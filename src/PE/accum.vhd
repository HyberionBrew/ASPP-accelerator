LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.core_pck.ALL;

ENTITY accum_unit IS
	GENERIC (
		ACC_DATA_WIDTH : NATURAL := 24;
		DATA_WIDTH_RESULT : NATURAL := 18
	);
	PORT (

		reset, clk : IN STD_LOGIC;
		new_psum : IN STD_LOGIC;
		new_ifmap : IN STD_LOGIC;
		finished_in : IN STD_LOGIC;
		finished_out : OUT STD_LOGIC;
		psum_in : IN signed(ACC_DATA_WIDTH - 1 DOWNTO 0);
		psum_out : OUT signed(ACC_DATA_WIDTH - 1 DOWNTO 0);
		result : IN signed(DATA_WIDTH_RESULT - 1 DOWNTO 0);
		valid : IN STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF accum_unit IS
	SIGNAL finished_reg, finished, finished_nxt : STD_LOGIC;
	TYPE psum_array IS ARRAY (0 TO 1) OF signed(ACC_DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL psum, psum_nxt : psum_array;
	SIGNAL swap, swap_nxt : STD_LOGIC_VECTOR(0 DOWNTO 0);
BEGIN
	sync : PROCESS (clk, reset)
	BEGIN
		IF reset = '0' THEN
			psum <= (OTHERS => (OTHERS => '0'));
			swap <= "0";
			finished <= '0';
		ELSIF rising_edge(clk) THEN
			psum <= psum_nxt;
			finished_reg <= finished;
			swap <= swap_nxt;
			finished <= finished_nxt;
		END IF;
	END PROCESS;
	
	-- is double buffered and while accumulating one psum the other one is read and swapped out
	state : PROCESS (ALL)
		VARIABLE swap_int, not_swap_int : NATURAL;
	BEGIN
		swap_int := to_integer(unsigned(swap));
		not_swap_int := to_integer(unsigned(NOT(swap)));
		psum_nxt <= psum;
		swap_nxt <= swap;
		IF new_psum = '1' THEN
			psum_nxt(not_swap_int) <= psum_in;
		END IF;

		IF new_ifmap = '1' THEN
			swap_nxt <= NOT(swap);
		END IF;
		IF valid = '1' THEN
			psum_nxt(swap_int) <= psum(swap_int) + resize(result, ACC_DATA_WIDTH);
		END IF;
		finished_nxt <= finished_in;
		finished_out <= finished;
		psum_out <= psum(not_swap_int);

	END PROCESS;

END ARCHITECTURE;