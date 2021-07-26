library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.core_pck.all;
use work.control_pck.all;

use std.textio.all;
use work.test_utils.all;


entity ifmap_ctrl_tb is
end entity;

architecture arch of ifmap_ctrl_tb is
  constant CLK_PERIOD : time := 20 ns;
  signal clk,reset: std_logic;



signal iacts_buffer_mode            : iacts_mode_type;
signal ifmap_DRAM_values          : ifmap_DRAM_type;
signal ifmap_position         : ifmap_position_type;
signal ifmap_out_buffer      : iacts_buffer_type;
signal ifmaps_prepared : std_logic;

begin

  iacts_buffer_i : entity work.iacts_buffer
  generic map (
    IFMAP_SIZE        => 512,
    IFMAPS_TO_PREPARE => 3,
    AWIDTH            => 12
  )
  port map (
    clk             => clk,
    reset           => reset,
    mode            => iacts_buffer_mode,
    values          => ifmap_DRAM_values,
    address         => ifmap_position,
    out_buffer      => ifmap_out_buffer,
    ifmaps_prepared => ifmaps_prepared
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
    ifmaps_loaded <= '0';
    wait for CLK_PERIOD;
    reset <= '1';
    wait for CLK_PERIOD*4;
    iacts_buffer_mode <= LOAD_IFMAP;
    count := 0;

    while true loop
      ifmap_DRAM_values.valid <= '1';
      for I in 0 to 18-1 loop

        ifmap_DRAM_values.data(DATA_WIDTH*(I+1)-1 downto DATA_WIDTH*I) <= std_logic_vector(to_unsigned(count,DATA_WIDTH));
        count := count +1;

      end loop; 
      wait for CLK_PERIOD;
      if count > 1024 then
        exit;
      end if;
    end loop;


    wait for CLK_PERIOD;
    ifmap_position <= (0,0,0);
    iacts_buffer_mode <= PREPARE_IFMAP;
    wait for CLK_PERIOD*18;
    iacts_buffer_mode <= CLEAN;
    wait for CLK_PERIOD;
    ifmap_position <= (1,0,0);
    iacts_buffer_mode <= PREPARE_IFMAP;
    wait;
  end process;

end architecture;
