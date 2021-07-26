library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.core_pck.all;
use work.control_pck.all;
use std.textio.all;
use work.test_utils.all;


entity ctrl_tb is
end entity;

architecture arch of ctrl_tb is
  constant CLK_PERIOD : time := 20 ns;
  signal reset,clk             : std_logic;
  signal load_ifmaps       : std_logic;
  signal load_kernels      : std_logic;
  signal kernels_loaded    : std_logic;
  signal ifmaps_loaded     : std_logic;
  signal ifmap_DRAM_values : ifmap_DRAM_type;
  signal new_ifmaps        : std_logic_vector(2 downto 0);
  signal new_kernels: std_logic_vector(2 downto 0);
  signal get_psums         : std_logic;
  signal PEs_finished      : std_logic;
  signal psums_values_in   : psum_array;
  signal psums_to_array    : psum_array;
  signal kernel_values, kernel_values_out: kernel_values_array;
  signal iacts_values: iact_values_array;
begin

  cntrl_unit_i : entity work.cntrl_unit
  port map (
      clk             => clk,
    reset             => reset,
    load_ifmaps       => load_ifmaps,
    load_kernels      => load_kernels,
    kernels_loaded    => kernels_loaded,
    ifmaps_loaded     => ifmaps_loaded,
    ifmap_DRAM_values => ifmap_DRAM_values,
    kernel_values     => kernel_values,
    new_ifmaps        => new_ifmaps,
    new_kernels       => new_kernels,
    get_psums         => get_psums,
    PEs_finished      => PEs_finished,
    psum_values_in   => psums_values_in,
    kernel_values_out => kernel_values_out,
    iacts_values_out   => iacts_values,
    psums_to_array    => psums_to_array
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
  variable count:natural;
  begin
    reset <= '0';
--    new_ifmaps <= '0';
    wait for CLK_PERIOD;
    reset <= '1';
    PEs_finished <= '1';
    psums_values_in <= (others => (to_signed(1,ACC_DATA_WIDTH)));
    kernel_values <= (others => (to_signed(1,DATA_WIDTH)));
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

    ifmaps_loaded <= '1';
    wait for CLK_PERIOD*6;
    kernels_loaded <= '1';

    wait for CLK_PERIOD;
    wait;
  end process;

end architecture;
