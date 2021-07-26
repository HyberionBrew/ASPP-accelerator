----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/24/2021 10:19:44 AM
-- Design Name:
-- Module Name: dram_controller - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dram_controller is
 Port (
  clk : in std_logic;
  reset: in std_logic;
  init_calib_complete: in std_logic;
  app_en: out std_logic;
  app_wdf_end: out std_logic;
  app_wdf_wren: out std_logic;
  app_rd_data_valid : in std_logic;
  app_rdy : in std_logic;
  app_wdf_rdy : in std_logic;
  app_addr: out std_logic_vector(28 downto 0);
  app_cmd: out STD_LOGIC_VECTOR(2 DOWNTO 0);
  app_wdf_data: out STD_LOGIC_VECTOR(511 DOWNTO 0);
  app_wdf_mask : out STD_LOGIC_VECTOR(63 DOWNTO 0);
  app_rd_data : in STD_LOGIC_VECTOR(511 DOWNTO 0);
  dram_rdy_for_UART: out std_logic;
  fifo_empty : in std_logic;
  fifo_full: in std_logic
  );
end dram_controller;

architecture Behavioral of dram_controller is

signal cmd: std_logic_vector(2 downto 0);
signal cmd_en : std_logic;
signal cmd_addr, cmd_addr_nxt: std_logic_vector(28 downto 0);
constant NUM_WRITES : natural := 100;
constant BURST_SIZE: natural :=64;
constant MEM_DATA_SIZE : natural := 512;
type state_mem_t is (INIT, WRITE_DATA, READ_DATA, READY, END_TEST);
signal state,state_nxt: state_mem_t;
constant RD_INSTR :std_logic_vector(2 downto 0) := "001";
constant WR_INSTR :std_logic_vector(2 downto 0):= "000";
signal mem_addr, mem_addr_nxt : natural range 0 to (NUM_WRITES-1)*8;
signal app_rdy_reg: std_logic;
signal init_calib_complete_reg, init_calib_complete_reg_nxt : std_logic;
signal wr_counter_nxt, wr_counter,rd_counter_nxt,rd_counter : natural range 0 to 100;
begin

asy: process(all)
begin
  dram_rdy_for_UART <= init_calib_complete_reg;
  app_wdf_mask <= (others => '0');
  init_calib_complete_reg_nxt <= init_calib_complete;
end process;


calib_finished : process(clk,reset)
begin
  if reset = '1' then
    init_calib_complete_reg <= '0';
    state <= INIT;
    mem_addr <= 0;
    wr_counter <= 0;
    rd_counter <= 0;
  elsif rising_edge(clk) then
    init_calib_complete_reg <= init_calib_complete_reg_nxt;
    state <= state_nxt;
    mem_addr <= mem_addr_nxt;
    rd_counter <= rd_counter_nxt;
    wr_counter <= wr_counter_nxt;
  end if;
end process;

data : process(all)
begin
  app_cmd <= WR_INSTR;
  app_wdf_wren <= '0';
  app_en <= '0';
  app_wdf_data <= (others => '1');
  app_wdf_wren <= '0';
  app_wdf_end <= '0';
  app_addr <= (others => '0');
  mem_addr_nxt <= mem_addr;
  rd_counter_nxt <= 0;
  state_nxt <= state;
  wr_counter_nxt <= wr_counter;
  case(state) is
    when INIT =>

      if init_calib_complete_reg ='1' then

        if mem_addr = 0 then
            state_nxt <= WRITE_DATA;
            mem_addr_nxt <= 0;
        end if;
      end if;

    when WRITE_DATA =>
      app_cmd <= WR_INSTR;
      app_wdf_wren <= '1';
      app_en <= '1';
      for I in 0 to 63 loop
        app_wdf_data((I+1)*8-1 downto I*8) <= std_logic_vector((to_unsigned(wr_counter,8)));
      end loop;
      app_wdf_wren <= '1';
      app_wdf_end <= '1';
      app_addr <= (others => '0');
      if app_rdy = '1' and app_wdf_rdy = '1' then
        mem_addr_nxt <= mem_addr +1;
        wr_counter_nxt <= wr_counter +1;
        if wr_counter = 20-1 then
            state_nxt <= READY;
        end if;
      end if;
      
    when READY =>
        mem_addr_nxt <= 0;
        state_nxt <= READ_DATA;
    
    when READ_DATA =>
      app_cmd <= RD_INSTR;
      app_en <= '1';
      rd_counter_nxt <= rd_counter;
      if app_rdy = '1' then
        rd_counter_nxt <= rd_counter +1;
        mem_addr_nxt <= mem_addr +1;
        if rd_counter = 10-1 then
            state_nxt <= END_TEST;
        end if;
      end if;

    when others =>

  end case;
end process;







end Behavioral;
