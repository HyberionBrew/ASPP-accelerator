library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;

use work.control_pck.all;

entity ofm_tb is
end entity;

architecture arch of ofm_tb is
  constant CLK_PERIOD : time := 20 ns;
  signal clk           : std_logic;
  signal reset         : std_logic;
  signal enable        : std_logic;
  constant MAX_OFMS: natural := 6;
  constant PARALLEL_OFMS : natural := 3;
  signal ofm           : natural range 0 to 1-1;
  signal rate          : natural range 1 to 1;
  signal ofms_in       : ofms_out_type;
  signal from_uart : from_uart_type;
  signal to_uart       : to_uart_type;

begin

  ofms_unit_i : entity work.ofms_unit
  generic map (
    PARALLEL_OFMS => PARALLEL_OFMS,
    MAX_OFMS      => MAX_OFMS,
    MAX_RATE      => 1
  )
  port map (
  clk       => clk,
  reset     => reset,
  ofms_in   => ofms_in,
  from_uart => from_uart,
  to_uart   => to_uart
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
  file infile : text open read_mode is "data/result_from_acc.data";
  Variable inline          : line;
  Variable v_data_write : integer;
  constant space: string(1 to 1):= " ";
  variable int : integer;
  variable data_count,count : natural;
  begin
    reset <= '0';
    count := 0;
    wait for CLK_PERIOD;
    reset <= '1';
    wait for CLK_PERIOD * 6;
    data_count := 0;
      ofms_in.valid <= '1';
      for x in 0 to 33-1 loop
        readline(infile,inline);
      for y in 0 to 33-1 loop
        if data_count = 5 then
          wait for CLK_PERIOD;
          data_count := 0;
        else
          data_count := data_count +1;
        end if;
        read(inline, int);
        ofms_in.data(24*(data_count+1)-1 downto 24*data_count) <= std_logic_vector(to_signed(int,24));
      end loop;
    end loop;
    wait for CLK_PERIOD;
    ofms_in.valid <= '0';
    from_uart.want_data <= '1';
    from_uart.ready <= '1';
    wait;
  end process;

end architecture;
