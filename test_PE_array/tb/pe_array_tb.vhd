library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.core_pck.all;
use work.pe_pack.all;

use std.textio.all;
use work.test_utils.all;


entity pe_array_tb is
end entity;

architecture arch of pe_array_tb is
  constant CLK_PERIOD : time := 20 ns;
  signal clk,reset: std_logic;
  signal new_kernels_to_array, new_ifmaps_to_array: std_logic_vector(PE_ROWS-1 downto 0);
  signal bus_pe_array: std_logic_vector(BUSSIZE-1 downto 0);
  signal get_psums, finished_out : std_logic;
  signal new_psum: std_logic_vector(0 downto 0);
begin

  pe_array_i : entity work.pe_array
port map (
  reset                => reset,
  clk                  => clk,
  bus_pe_array         => bus_pe_array,
  new_kernels_to_array => new_kernels_to_array,
  new_ifmaps_to_array  => new_ifmaps_to_array,
  get_psums            => get_psums,
  new_psum             => new_psum,
  finished_out         => finished_out
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
  file infile : text open read_mode is "./data/bitvecs_pe_test.txt";
  variable inline, outline : line;
  variable int:integer;
  variable in_vec : string(1 to 64);
  variable space : string(1 to 1);
  begin
    reset <= '0';

    wait for CLK_PERIOD;
    reset <= '1';
    --bus_to_pe <= (others => '1');
    new_psum <= "1";
    bus_pe_array <= (others => '0');
    wait for CLK_PERIOD;
    new_psum <= "0";
    bus_pe_array <= (others => '1');
    readline(infile,inline);
    for I in 0 to 63 loop
      read(inline, int);
      bus_pe_array(DATA_WIDTH*(I+1)+63 downto DATA_WIDTH*I+64) <= std_logic_vector(to_signed(int,DATA_WIDTH));
    end loop;
    read(inline, space);
    read(inline, in_vec);
    bus_pe_array(63 downto 0) <= to_std_logic_vector(in_vec);
    --initialized the new kernels
    --write the same kernels to all PEs
    new_kernels_to_array <= "100";
    wait for CLK_PERIOD;
    new_kernels_to_array <= "001";
    wait for CLK_PERIOD;
    new_kernels_to_array <= "010";
    wait for CLK_PERIOD;
    new_kernels_to_array <= "000";

    new_ifmaps_to_array <= "100";
    readline(infile,inline);
    for I in 0 to 63 loop
      read(inline, int);
      bus_pe_array((DATA_WIDTH)*(I+1)+63 downto DATA_WIDTH*I+64) <= std_logic_vector(to_unsigned(int,DATA_WIDTH));
    end loop;
    read(inline, space);
    read(inline, in_vec);
    bus_pe_array(63 downto 0) <= to_std_logic_vector(in_vec);
    read(inline, int);
    bus_pe_array(bus_pe_array'high downto bus_pe_array'high-DATA_WIDTH+1) <= std_logic_vector(to_unsigned(int,DATA_WIDTH));

    wait for CLK_PERIOD;
    new_ifmaps_to_array <= "000";
    bus_pe_array <= (others => 'Z');
    wait for CLK_PERIOD * 60;
    bus_pe_array <= (others => '0');
    new_psum <= "1";
    wait for CLK_PERIOD;
    bus_pe_array <= (others => 'Z');
    new_psum <= "0";
    wait for CLK_PERIOD *4;
    get_psums <= '1';
    wait for CLK_PERIOD;
    get_psums <= '0';

    wait;
  end process;

end architecture;
