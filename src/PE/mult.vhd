LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.core_pck.ALL;
ENTITY mult_unit IS
	GENERIC (
		DATA_WIDTH_RESULT : NATURAL := 18
	);
	PORT (
		clk : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		finished_in : IN STD_LOGIC;
		finished_out : OUT STD_LOGIC;
		new_kernels : IN STD_LOGIC;
		new_ifmaps : IN STD_LOGIC;
		data : IN STD_LOGIC_VECTOR(DATA_WIDTH * FILTER_PER_PE - 1 DOWNTO 0);
		ifmap_zero_offset : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
		index : IN NATURAL RANGE 0 TO FILTER_PER_PE - 1;
		valid : IN STD_LOGIC;
		valid_out : OUT STD_LOGIC;
		result_out : OUT signed(DATA_WIDTH_RESULT - 1 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE arch OF mult_unit IS
	TYPE kernel_reg_type IS ARRAY (0 TO FILTER_PER_PE - 1) OF signed(DATA_WIDTH - 1 DOWNTO 0);
	TYPE ifmap_reg_type IS ARRAY (0 TO FILTER_PER_PE - 1) OF unsigned(DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL kernel_value_reg, kernel_value_reg_nxt : kernel_reg_type;
	SIGNAL ifmap_value_reg, ifmap_value_reg_nxt : ifmap_reg_type;
	SIGNAL ifmap_reg_signed, ifmap_reg_signed_nxt : signed(DATA_WIDTH - 1 + 1 DOWNTO 0);
	SIGNAL ifmap_zero_reg_nxt, ifmap_zero_reg : unsigned(DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL valid_mult, valid_mult_nxt, valid_result, valid_result_nxt, finished_result, finished_result_nxt, finished_prep_nxt, finished_prep : STD_LOGIC;
	SIGNAL result, result_nxt : signed(DATA_WIDTH_RESULT - 1 DOWNTO 0);
	SIGNAL weight_reg_signed_nxt, weight_reg_signed : signed(DATA_WIDTH - 1 + 1 DOWNTO 0);
BEGIN
	sync : PROCESS (clk, reset)
	BEGIN
		IF reset = '0' THEN
			kernel_value_reg <= (OTHERS => (OTHERS => '0'));
			ifmap_value_reg <= (OTHERS => (OTHERS => '0'));
			ifmap_reg_signed <= (OTHERS => '0');
			ifmap_zero_reg <= (OTHERS => '0');
			valid_mult <= '0';
			valid_result <= '0';
			weight_reg_signed <= (OTHERS => '0');
			result <= (OTHERS => '0');
			finished_prep <= '0';
			finished_result <= '0';

		ELSIF rising_edge(clk) THEN
			kernel_value_reg <= kernel_value_reg_nxt;
			ifmap_value_reg <= ifmap_value_reg_nxt;
			ifmap_reg_signed <= ifmap_reg_signed_nxt;
			ifmap_zero_reg <= ifmap_zero_reg_nxt;
			valid_mult <= valid_mult_nxt;
			valid_result <= valid_result_nxt;
			weight_reg_signed <= weight_reg_signed_nxt;
			result <= result_nxt;
			finished_prep <= finished_prep_nxt;
			finished_result <= finished_result_nxt;
		END IF;
	END PROCESS;

	-- fetches and stores
	new_data : PROCESS (ALL)
	BEGIN
		kernel_value_reg_nxt <= kernel_value_reg;
		ifmap_value_reg_nxt <= ifmap_value_reg;
		ifmap_zero_reg_nxt <= unsigned(ifmap_zero_offset);

		IF new_kernels = '1' THEN
			FOR I IN 0 TO FILTER_PER_PE - 1 LOOP
				kernel_value_reg_nxt(I) <= signed(data(DATA_WIDTH * (I + 1) - 1 DOWNTO DATA_WIDTH * I));
			END LOOP;
		ELSIF new_ifmaps = '1' THEN
			FOR I IN 0 TO FILTER_PER_PE - 1 LOOP
				ifmap_value_reg_nxt(I) <= unsigned(data(DATA_WIDTH * (I + 1) - 1 DOWNTO DATA_WIDTH * I));
			END LOOP;
		END IF;
	END PROCESS;

	--multiplication pipeline
	mult : PROCESS (ALL)
	BEGIN
		valid_out <= '0';
		valid_mult_nxt <= valid;
		result_nxt <= (OTHERS => '0');
		ifmap_reg_signed_nxt <= (OTHERS => '0');
		weight_reg_signed_nxt <= (OTHERS => '0');
		valid_result_nxt <= '0';
		finished_prep_nxt <= finished_in;
		finished_result_nxt <= finished_prep;
		finished_out <= finished_result;
		IF valid = '1' THEN
			ifmap_reg_signed_nxt <= to_signed(to_integer(ifmap_value_reg(index)) - to_integer(ifmap_zero_reg), ifmap_reg_signed'length);
			weight_reg_signed_nxt <= resize(kernel_value_reg(index), weight_reg_signed'length);
		END IF;
		IF valid_mult = '1' THEN
			result_nxt <= ifmap_reg_signed * weight_reg_signed;
			valid_result_nxt <= valid_mult;
		END IF;
		valid_out <= valid_result;
		result_out <= result;
	END PROCESS;

END ARCHITECTURE;