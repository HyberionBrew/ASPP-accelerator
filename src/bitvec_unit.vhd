LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;
USE work.core_pck.ALL;
USE work.control_pck.ALL;
USE work.top_types_pck.ALL;
USE work.pe_array_pck.ALL;

ENTITY bitvec IS
  GENERIC (
    PARALLEL_OFMS : NATURAL := 4;
    FILTER_VALUES : NATURAL := 64;
    PE_COLUMNS : NATURAL := 3
  );
  PORT (
    clk, reset : IN STD_LOGIC;
    kernels_to_bitvec : IN kernel_values_array;
    iacts_to_bitvec : IN iact_values_array;
    new_ifmaps : IN STD_LOGIC_VECTOR(PE_COLUMNS - 1 DOWNTO 0);
    new_kernels : IN STD_LOGIC_VECTOR(PARALLEL_OFMS - 1 DOWNTO 0);
    bus_values : OUT STD_LOGIC_VECTOR(BUSSIZE - 1 DOWNTO 0);
    ifmap_zero_offset : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
  );
END ENTITY;

--returns the bus values and encodes zeros in the bitvev arrays
ARCHITECTURE arch OF bitvec IS
  SIGNAL zero_point : NATURAL RANGE 0 TO 255 - 1;
BEGIN
  fow : PROCESS (ALL)
  BEGIN
    bus_values <= (OTHERS => '0');
  
    IF OR_REDUCE (new_ifmaps) = '1' THEN
      FOR I IN 0 TO 63 LOOP
        IF to_integer(unsigned(iacts_to_bitvec(I))) = zero_point THEN
          bus_values(I) <= '0';
        ELSE
          bus_values(I) <= '1';
        END IF;
        bus_values(DATA_WIDTH * (I + 1) + 63 DOWNTO DATA_WIDTH * I + 64) <= STD_LOGIC_VECTOR(iacts_to_bitvec(I));
      END LOOP;
    ELSIF OR_REDUCE(new_kernels) = '1' THEN
      FOR I IN 0 TO 63 LOOP
        IF to_integer(signed(kernels_to_bitvec(I))) = 0 THEN
          bus_values(I) <= '0';
        ELSE
          bus_values(I) <= '1';
        END IF;
        bus_values(DATA_WIDTH * (I + 1) + 63 DOWNTO DATA_WIDTH * I + 64) <= STD_LOGIC_VECTOR(kernels_to_bitvec(I));
      END LOOP;
    END IF;
  END PROCESS;
  
  zero_offs_sync : PROCESS (clk, reset)
  BEGIN
    IF reset = '0' THEN
      zero_point <= 0;
    ELSIF rising_edge(clk) THEN
      zero_point <= to_integer(unsigned(ifmap_zero_offset));
    END IF;
  END PROCESS;

END ARCHITECTURE;
