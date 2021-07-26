library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.core_pck.all;
use work.control_pck.all;

use std.textio.all;
use work.test_utils.all;


entity psums_buffer_tb is
end entity;

architecture arch of psums_buffer_tb is
  constant CLK_PERIOD : time := 20 ns;
  signal clk             : std_logic;
  signal reset           : std_logic;
  signal mode            : mode_psums_type;
  signal address         : psum_address_type;
  signal address_prev    : psum_address_type;
  signal psums_ready     : std_logic;
  signal psum_values_in  : psum_array;
  signal psum_values_out : psum_array;
  signal first_pass      : std_logic;
  signal out_buffer      : psums_buffer_type;

begin

  psums_buffer_i : entity work.psums_buffer
  generic map (
    ACC_WIDTH => 24,
    OFMS      => 3,
    AWIDTH    => 12
  )
  port map (
    clk             => clk,
    reset           => reset,
    mode            => mode,
    address         => address,
    address_prev    => address_prev,
    psums_ready     => psums_ready,
    psum_values_in  => psum_values_in,
    psum_values_out => psum_values_out,
    first_pass      => first_pass,
    out_buffer      => out_buffer
  );



  clock : process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;

  stim : process
  --file infile : text open read_mode is "./data/bitvecs_pe_test.txt";
  variable inline, outline : line;
  variable int:integer;
  variable in_vec : string(1 to 64);
  variable space : string(1 to 1);
  variable Ic,count: natural;

  begin
    Ic := 0;
    reset <= '0';
    mode <= CLEAN;
    first_pass <= '1';
    wait for CLK_PERIOD;
    reset <= '1';
    wait for CLK_PERIOD;
    mode <= FETCH_PSUMS;
    psum_values_in <= (others => to_signed(1,ACC_DATA_WIDTH));
    wait for CLK_PERIOD;
    address <= (0,0,0);
    address_prev <= (0,0,0);

    mode <= PREPARE_PSUMS;
    wait for CLK_PERIOD *20;
    mode <= CLEAN;
    wait for CLK_PERIOD;
    mode <= FETCH_PSUMS;
    wait for CLK_PERIOD;
    address <= (0,0,0);
    mode <= PREPARE_PSUMS;
    address_prev <= (10,0,0);
    first_pass <= '0';
    wait for CLK_PERIOD *20;
--    address <= (1,0,0);
    wait;
  end process;

end architecture;
