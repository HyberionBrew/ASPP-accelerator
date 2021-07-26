-- Initializing Block RAM from external data file
-- File: rams_init_file.vhd
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;

ENTITY rams_init_file IS
  GENERIC (
    FILENAME : STRING := "filename.data";
    ADDRW : NATURAL := 8;
    DATAW : NATURAL := 8;
    DEPTH : NATURAL := 255 * 3
  );
  PORT (
    clk : IN STD_LOGIC;
    addr : IN STD_LOGIC_VECTOR(ADDRW - 1 DOWNTO 0);
    dout : OUT STD_LOGIC_VECTOR(DATAW - 1 DOWNTO 0)
  );
END rams_init_file;

ARCHITECTURE syn OF rams_init_file IS
  TYPE RamType IS ARRAY (0 TO DEPTH - 1) OF bit_vector(DATAW - 1 DOWNTO 0);

  IMPURE FUNCTION InitRamFromFile(RamFileName : IN STRING) RETURN RamType IS
    FILE RamFile : text OPEN read_mode IS RamFileName;
    VARIABLE RamFileLine : line;
    VARIABLE RAM : RamType;
  BEGIN
    FOR I IN RamType'RANGE LOOP
      readline(RamFile, RamFileLine);
      read(RamFileLine, RAM(I));
    END LOOP;
    RETURN RAM;
  END FUNCTION;

  SIGNAL RAM : RamType := InitRamFromFile(FILENAME);
BEGIN
  PROCESS (clk)
  BEGIN
    IF clk'event AND clk = '1' THEN
      dout <= to_stdlogicvector(RAM(to_integer(unsigned(addr))));
    END IF;
  END PROCESS;
END syn;