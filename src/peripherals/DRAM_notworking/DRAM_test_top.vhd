----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2021 11:08:09 AM
-- Design Name: 
-- Module Name: tb - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb is
end tb;

architecture Behavioral of tb is
signal c0_sys_clk_p     : STD_LOGIC;
signal c0_sys_clk_n     : STD_LOGIC;
signal c0_ddr4_adr      : STD_LOGIC_VECTOR(16 DOWNTO 0);
signal c0_ddr4_ba       : STD_LOGIC_VECTOR(1 DOWNTO 0);
signal c0_ddr4_cke      : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal c0_ddr4_cs_n     : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal c0_ddr4_dm_dbi_n : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal c0_ddr4_dq       : STD_LOGIC_VECTOR(63 DOWNTO 0);
signal c0_ddr4_dqs_c    : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal c0_ddr4_dqs_t    : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal c0_ddr4_odt      : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal c0_ddr4_bg       : STD_LOGIC_VECTOR(1 DOWNTO 0);
signal c0_ddr4_reset_n ,rx, tx : STD_LOGIC;
signal c0_ddr4_act_n    : STD_LOGIC;
signal c0_ddr4_ck_c     : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal c0_ddr4_ck_t     : STD_LOGIC_VECTOR(0 DOWNTO 0);

begin

dram_ctrl_i : entity work.dram_ctrl
port map (
  c0_sys_clk_p     => c0_sys_clk_p,
  c0_sys_clk_n     => c0_sys_clk_n,
  c0_ddr4_adr      => c0_ddr4_adr,
  c0_ddr4_ba       => c0_ddr4_ba,
  c0_ddr4_cke      => c0_ddr4_cke,
  c0_ddr4_cs_n     => c0_ddr4_cs_n,
  c0_ddr4_dm_dbi_n => c0_ddr4_dm_dbi_n,
  c0_ddr4_dq       => c0_ddr4_dq,
  c0_ddr4_dqs_c    => c0_ddr4_dqs_c,
  c0_ddr4_dqs_t    => c0_ddr4_dqs_t,
  c0_ddr4_odt      => c0_ddr4_odt,
  c0_ddr4_bg       => c0_ddr4_bg,
  c0_ddr4_reset_n  => c0_ddr4_reset_n,
  c0_ddr4_act_n    => c0_ddr4_act_n,
  c0_ddr4_ck_c     => c0_ddr4_ck_c,
  c0_ddr4_ck_t     => c0_ddr4_ck_t,
  rx => rx,
  tx => tx
);

clk: process
begin

c0_sys_clk_n <= '0';
c0_sys_clk_p <= '1';
wait for 3330 ps/2;
c0_sys_clk_n <= '1';
c0_sys_clk_p  <= '0';
wait for 3330 ps/2;
end process;

end Behavioral;
