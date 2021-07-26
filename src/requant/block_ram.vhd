-- Ram Inference Example using Records (Simple Dual port)
-- File:rams_sdp_record.vhd
-- taken from xilinx language example designs

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY rams_sdp_record IS GENERIC (
  A_WID : INTEGER := 17;
  D_WID : INTEGER := 36;
  DEPTH : INTEGER := 33 * 33
);
PORT (
  clk : IN STD_LOGIC;
  we : IN STD_LOGIC;
  ena : IN STD_LOGIC;
  raddr : IN STD_LOGIC_VECTOR(A_WID - 1 DOWNTO 0);
  waddr : IN STD_LOGIC_VECTOR(A_WID - 1 DOWNTO 0);
  din : IN STD_LOGIC_VECTOR(D_WID - 1 DOWNTO 0);
  dout : OUT STD_LOGIC_VECTOR(D_WID - 1 DOWNTO 0)
);
END rams_sdp_record;

ARCHITECTURE arch OF rams_sdp_record IS
  TYPE mem_t IS ARRAY(INTEGER RANGE <>) OF STD_LOGIC_VECTOR(D_WID - 1 DOWNTO 0);
  SIGNAL mem : mem_t(DEPTH - 1 DOWNTO 0) := (OTHERS => (OTHERS => '0'));
BEGIN
  PROCESS (clk)
  BEGIN
    IF (clk'event AND clk = '1') THEN
      IF (ena = '1') THEN
        IF (we = '1') THEN
          mem(to_integer(unsigned(waddr))) <= din;
        END IF;
      END IF;
    END IF;
  END PROCESS;

  PROCESS (clk)
  BEGIN
    IF (clk'event AND clk = '1') THEN
      IF (ena = '1') THEN
        dout <= mem(to_integer(unsigned(raddr)));
      END IF;
    END IF;
  END PROCESS;

END arch;