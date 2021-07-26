----------------------------------------------------------------------------------
-- Company:
-- Engineer: Fabian Kresse
--
-- Create Date: 03/17/2021 12:21:08 PM
-- Design Name:
-- Module Name: project_top - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.core_pck.ALL;

ENTITY project_top IS
  PORT (
    clk_in1_p : IN STD_LOGIC;
    clk_in1_n : IN STD_LOGIC;
    rx : IN STD_LOGIC;
    tx : OUT STD_LOGIC
  );
END project_top;

ARCHITECTURE Behavioral OF project_top IS
  COMPONENT clk_wiz_0
    PORT (
      clk_out1 : OUT STD_LOGIC;
      reset : IN STD_LOGIC;
      locked : OUT STD_LOGIC;
      clk_in1_p : IN STD_LOGIC;
      clk_in1_n : IN STD_LOGIC
    );
  END COMPONENT;
  SIGNAL clk, clk_out, reset, locked : STD_LOGIC;
  CONSTANT reset_top : STD_LOGIC := '1';
BEGIN

  CLOCK_100MHZ : clk_wiz_0
  PORT MAP(
    clk_out1 => clk_out,
    reset => NOT(reset_top),
    locked => locked,
    clk_in1_p => clk_in1_p,
    clk_in1_n => clk_in1_n
  );

  pro_top_i : ENTITY work.top
    GENERIC MAP(
      PARALLEL_OFMS => PARALLEL_OFMS,
      MAX_OFMS => MAX_OFMS,
      FILTER_DEPTH => FILTER_DEPTH,
      FILTER_VALUES => FILTER_PER_PE,
      MAX_RATE => MAX_RATE,
      PE_COLUMNS => PE_COLUMNS,
      OFM_REQUANT => OFM_REQUANT
    )
    PORT MAP(
      reset => reset_top AND locked,
      clk => clk_out,
      rx => rx,
      tx => tx
    );
END Behavioral;