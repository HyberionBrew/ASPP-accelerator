library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.core_pck.all;
use work.pe_pack.all;

use std.textio.all;
use work.test_utils.all;


entity PE_tb is
end entity;

architecture arch of PE_tb is
  constant CLK_PERIOD : time := 20 ns;
  signal clk,reset, finished, new_kernels, new_ifmaps, valid_out: std_logic;
  signal result : signed(18-1 downto 0);
  signal bus_to_pe: std_logic_vector(BUSSIZE-1 downto 0);
  signal new_psum : std_logic;
  signal psum_in: signed(ACC_DATA_WIDTH-1 downto 0);
begin

  pe_i : entity work.pe
  port map (
  reset       => reset,
  clk         => clk,
  finished    => finished,
  new_kernels => new_kernels,
  new_ifmaps  => new_ifmaps,
  new_psum    => new_psum,
  psum_in     => psum_in,
  bus_to_pe   => bus_to_pe,
  result      => result,
  valid_out   => valid_out
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
    new_psum <= '1';
    psum_in <= (others => '0');
    wait for CLK_PERIOD;
    new_psum <= '0';
    reset <= '1';
    bus_to_pe <= (others => '1');
    new_kernels <= '1';
    readline(infile,inline);
    for I in 0 to 63 loop
      read(inline, int);
      bus_to_pe(DATA_WIDTH*(I+1)+63 downto DATA_WIDTH*I+64) <= std_logic_vector(to_signed(int,DATA_WIDTH));
    end loop;
    read(inline, space);
    read(inline, in_vec);
    bus_to_pe(63 downto 0) <= to_std_logic_vector(in_vec);


    wait for CLK_PERIOD;
    new_kernels <= '0';

    new_ifmaps <= '1';
    readline(infile,inline);
    for I in 0 to 63 loop
      read(inline, int);
      bus_to_pe((DATA_WIDTH)*(I+1)+63 downto DATA_WIDTH*I+64) <= std_logic_vector(to_unsigned(int,DATA_WIDTH));
    end loop;
    read(inline, space);
    read(inline, in_vec);
    bus_to_pe(63 downto 0) <= to_std_logic_vector(in_vec);
    read(inline, int);
    bus_to_pe(bus_to_pe'high downto bus_to_pe'high-DATA_WIDTH+1) <= std_logic_vector(to_unsigned(int,DATA_WIDTH));

    wait for CLK_PERIOD;
    new_ifmaps <= '0';
    bus_to_pe <= (others => '0');
    wait for CLK_PERIOD * 60;
    --bus_to_pe <= (others => '1');
    new_psum <= '1';
    psum_in <= (others => '0');
    wait for CLK_PERIOD;
    new_psum <= '0';
    wait;
  end process;

end architecture;
