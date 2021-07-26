-- Taken form Xilinx language example designs
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

PACKAGE block_ram_pkg IS

	COMPONENT block_ram IS
		GENERIC (
			ADDR_WIDTH : NATURAL; -- bitwidth of address
			DATA_WIDTH : NATURAL -- bitwidth of data
		);
		PORT (
			clk : IN STD_LOGIC;
			addr_a : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0); -- port a address
			addr_b : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0); -- port b address
			din_a : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- port a write data
			din_b : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- port b write data
			en_a : IN STD_LOGIC; -- port a enable
			en_b : IN STD_LOGIC; -- port b enable
			we_a : IN STD_LOGIC; -- port a write-enable
			we_b : IN STD_LOGIC; -- port b write-enable
			dout_a : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- port a read data
			dout_b : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) -- port b read data
		);
	END COMPONENT block_ram;

END block_ram_pkg;