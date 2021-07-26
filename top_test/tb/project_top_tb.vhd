----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2021 08:42:26 AM
-- Design Name: 
-- Module Name: project_top_tb - Behavioral
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

entity project_top_tb is
end project_top_tb;

architecture Behavioral of project_top_tb is

signal rx,tx, clk_in1_p, clk_in1_n : std_logic;
constant CLK_PERIOD :time := 3.3333ns;
begin
  clock : process
  begin
    clk_in1_p <= '0';
    clk_in1_n <= '1';
    wait for CLK_PERIOD/2;
    clk_in1_p <= '1';
    clk_in1_n <= '0';
    wait for CLK_PERIOD/2;
  end process;

top_i : entity work.project_top
port map(
    clk_in1_p => clk_in1_p,
    clk_in1_n => clk_in1_n,
    rx => rx,
    tx => tx
);

end Behavioral;
