library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.core_pck.all;
use work.control_pck.all;
use std.textio.all;
use work.test_utils.all;


entity state_calc_tb is
end entity;

architecture arch of state_calc_tb is
  constant CLK_PERIOD : time := 20 ns;
  signal clk,reset, finished: std_logic;
  signal new_ifmaps        : std_logic;
  signal need_kernels      : std_logic;
  signal ifmap_address     : ifmap_address_type;
  signal psum_address      : std_logic;
  signal psum_prev_address : std_logic;


begin

  state_calc_i : entity work.state_calc
  generic map(
    OFMS  => 2,
    PARALLEL_OFMS => 3
  )
  port map (
    clk   => clk,
    reset             => reset,
    new_ifmaps        => new_ifmaps,
    need_kernels      => need_kernels,
    ifmap_address     => ifmap_address,
    psum_address      => psum_address,
    psum_prev_address => psum_prev_address,
    finished          => finished
  );



--  PE_t : entity work.PE
--  port map(
--    reset => reset,
--    clk => clk,
--    index => index
--  );

  clock : process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;

  stim : process
  begin
    reset <= '0';
    new_ifmaps <= '0';
    wait for CLK_PERIOD;
    reset <= '1';
    wait for CLK_PERIOD *4;
    while true loop
      new_ifmaps <= '1';
      wait for CLK_PERIOD*2;
      new_ifmaps <= '0';
      wait for CLK_PERIOD*3;
    end loop;
    --bus_to_pe <= (others => '1');
    wait;
  end process;

end architecture;
