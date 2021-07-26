library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.core_pck.all;
use work.control_pck.all;
USE work.top_types_pck.ALL;
use std.textio.all;
use work.test_utils.all;


entity top_tb is
  generic(
    PARALLEL_OFMS: natural:=PARALLEL_OFMS;
    MAX_OFMS: natural:=MAX_OFMS;
    FILTER_DEPTH:natural:=FILTER_DEPTH;
    FILTER_VALUES:natural:=FILTER_PER_PE;
    MAX_RATE:natural:= MAX_RATE
  );
end entity;

architecture arch of top_tb is
  constant CLK_PERIOD : time := 20 ns;
  signal reset,clk             : std_logic;
  signal ifmap_DRAM_values : ifmap_DRAM_type;
  signal kernel_values     : kernel_values_array;
  signal kernels_loaded    : std_logic;
  signal ifmaps_loaded, load_kernels, load_ifmaps  : std_logic;
  signal ifmap_zero_offset: std_logic_vector(DATA_WIDTH-1 downto 0);
  signal new_kernels_in : std_logic_vector(PARALLEL_OFMS-1 downto 0);
  signal ofms_out : ofms_out_type;
  type ofm_type is array(PARALLEL_OFMS-1 downto 0) of integer;
  type ofm_rep_type is array(MAX_OFMS-1 downto 0,32 downto 0, 32 downto 0) of integer;
  signal ofm_array: ofm_type;
  signal ofm_rep ,ofm_rep_final: ofm_rep_type;
  signal prev_ofms_valid: std_logic;
  signal from_uart : from_uart_type;
  signal to_uart       : to_uart_type;
  signal finished: std_logic;
  --constant PARALLEL_OFMS : natural := 3;
  --constant MAX_OFMS: natural := 3;
  signal prev_from_uart_valid : std_logic := '0';
  signal debug_ofm : natural;
  signal rx, tx: std_logic;
  constant UART_CLK_PERIOD: time := 7.68us;
      constant UART_CLK_PERIOD_2: time := 7.7us;
  signal UART_data_debug : std_logic_vector(7 downto 0);
  signal count_sig : natural;
begin

  top_i : entity work.top
  generic map(
  PARALLEL_OFMS => PARALLEL_OFMS,
  MAX_OFMS => MAX_OFMS,
  FILTER_DEPTH => FILTER_DEPTH,
  FILTER_VALUES => FILTER_VALUES,
  MAX_RATE => MAX_RATE
  )
  port map (
    reset             => reset,
    clk               => clk,
 --   ifmap_zero_offset => ifmap_zero_offset,
    --finished_ofms_to_storage => ofms_out,
    rx  => rx,
    tx => tx
    --to_uart => to_uart,
    --finished => finished
  );

--  PE_t : entity work.PE
--  port map(
--    reset => reset,
--    clk => clk,
--    index => index
--  );

  write_finished: process
  begin
    from_uart <= ('0','0','0');
    if finished = '1' then
      from_uart <= ('1','1','0');
      wait for CLK_PERIOD *30;
      from_uart <= ('0','1','0');
      wait;
    end if;
    wait for CLK_PERIOD;
  end process;


  ofm_final : process
  variable ofm :natural := 0;
  begin

    if to_uart.valid = '1' then
        --for y in 0 to 32 loop
        while MAX_OFMS-1 > ofm loop
        for y in 0 to 32 loop
        for x in 0 to 10 loop
          for I in 0 to PARALLEL_OFMS-1 loop
            for J in 0 to PE_COLUMNS-1 loop
              ofm_rep_final(ofm+I,y,x*PE_COLUMNS+J) <= to_integer(signed(to_uart.data));
              wait for CLK_PERIOD;
            end loop;
          end loop;
        end loop;
      end loop;
      ofm := ofm + PARALLEL_OFMS;
      debug_ofm <= ofm;
    end loop;

    wait;
    else
      wait for CLK_PERIOD;
    end if;
  end process;

  write_out_ofm_final: process
  file outfile : text open write_mode is "ofm_final.data";
  Variable row          : line;
  Variable v_data_write : integer;
  constant space: string(1 to 1):= " ";
  begin
    prev_from_uart_valid <= to_uart.valid;
    if to_uart.valid = '0' and prev_from_uart_valid = '1' then
      for ofm in 0 to MAX_OFMS-1 loop
        for y in 0 to 32 loop
          for x in 0 to 32 loop
              --for I in 0 to 3 loop
          v_data_write := ofm_rep_final(ofm,y,x);
        write(row, v_data_write);
        write(row,space);
      --end loop;
      end loop;
      writeline(outfile ,row);
    end loop;
    write(row,space);
    writeline(outfile ,row);
  end loop;
  end if;
  wait for CLK_PERIOD;
  end process;

  ofm : process
  begin
    for I in 0 to PARALLEL_OFMS-1 loop
      ofm_array(I) <= to_integer(signed(ofms_out.data(ACC_DATA_WIDTH*(I+1)-1 downto ACC_DATA_WIDTH*I)));
    end loop;
    if ofms_out.valid = '1' then
      for y in 0 to 32 loop
      for x in 0 to 10 loop
        for ofm in 0 to PARALLEL_OFMS-1 loop
        for I in 0 to 2 loop --only takes the first 2
        ofm_rep(ofm,y,x*3+I) <= to_integer(signed(ofms_out.data(ACC_DATA_WIDTH*(I+1)+(ofm*72)-1 downto ACC_DATA_WIDTH*I+ofm*72)));
      end loop;
      end loop;
      wait for CLK_PERIOD;
    end loop;
  end loop;
    end if;
    wait for CLK_PERIOD;
  end process;

  write_out_ofm: process
  file outfile : text open write_mode is "ofm.data";
  Variable row          : line;
  Variable v_data_write : integer;
  constant space: string(1 to 1):= " ";
  begin
    prev_ofms_valid <= ofms_out.valid;
    if ofms_out.valid = '0' and prev_ofms_valid = '1' then
      for ofm in 0 to PARALLEL_OFMS-1 loop
      for y in 0 to 32 loop
        for x in 0 to 32 loop
          v_data_write := ofm_rep(ofm,y,x);

        write(row, v_data_write);
                write(row,space);
      end loop;
      writeline(outfile ,row);
    end loop;
    write(row,space);
    writeline(outfile ,row);
  end loop;
    end if;
    wait for CLK_PERIOD;
  end process;

  clock : process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;

  ifmap_loader : process
  file infile : text open read_mode is "ifmaps_input.data";
  variable inline, outline : line;
  variable int:integer;
  constant ifmaps_to_load: natural := 33*33*4*FILTER_DEPTH+10;--since it loads twice below (the +10, 2 should suffic)
  variable ifmap_count: natural := 0;
  begin
    while load_ifmaps = '0' loop
      wait for CLK_PERIOD;
    end loop;
    for J in 0 to ifmaps_to_load-1 loop
      ifmap_DRAM_values.valid <= '0';
      if load_ifmaps = '1' then
          if ifmap_count mod 4 = 0 then
            readline(infile,inline);
          end if;
          for I in 0 to 18-1 loop --load two for one iter
            read(inline, int);
            ifmap_DRAM_values.data(DATA_WIDTH*(I+1)-1 downto DATA_WIDTH *I) <= std_logic_vector(to_unsigned(int,DATA_WIDTH));
            ifmap_DRAM_values.valid <= '1';
          end loop;
          ifmap_count := ifmap_count +1;
        end if;
      wait for CLK_PERIOD;
    end loop;
    ifmaps_loaded <= '1';
    wait;
  end process;

  kernel_loader:process
  file infile : text open read_mode is "weights.data";
  variable inline, outline : line;
  variable int:integer;
  --constant ifmaps_to_load: natural := 33*8;--*33*8;
  variable kernel_count: natural := 0;
  begin

    wait for CLK_PERIOD;
    while true loop
      new_kernels_in <= (others => '0');
      kernels_loaded <= '0';
      if load_kernels = '1' then
        if kernel_count = PARALLEL_OFMS then
          kernels_loaded <= '1';
          kernel_count := 0;
          wait for CLK_PERIOD*100;
        else
          readline(infile,inline);
          for I in 0 to 63 loop
            read(inline, int);
            kernel_values(I) <= to_signed(int,DATA_WIDTH);
            new_kernels_in(kernel_count) <= '1';
          end loop;
          kernel_count := kernel_count +1;
        end if;
      end if;
    wait for CLK_PERIOD;
    end loop;

  end process;


  stim : process
  variable count:natural;
  begin
    reset <= '0';
    ifmap_zero_offset <= std_logic_vector(to_unsigned(43,DATA_WIDTH));
--    new_ifmaps <= '0';
    wait for CLK_PERIOD;
    reset <= '1';
    --kernel_values <= (others => (to_signed(1,DATA_WIDTH)));
    wait;
  end process;

  decode_UART : process
  variable count: natural := 0;
  begin
      UART_data_debug <= (others => '-');
      if tx = '0' then
          wait for UART_CLK_PERIOD_2;
          while not(count = 8) loop
              UART_data_debug(count) <= tx;
              count := count +1;
              wait for UART_CLK_PERIOD;
              count_sig <= count;
          end loop;
      end if;
      count := 0;
      wait for UART_CLK_PERIOD;
  end process;


end architecture;
