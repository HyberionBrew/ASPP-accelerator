----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2021 10:34:53 AM
-- Design Name: 
-- Module Name: uart_dramtest - Behavioral
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

entity uart_ctrl is
 Port ( clk,reset, fifo_full, fifo_empty, rx: in std_logic;
        tx,rd_fifo: out std_logic;
        data_fifo: in std_logic_vector(511 downto 0)
        );
end uart_ctrl;

architecture Behavioral of uart_ctrl is


  signal awvalid, awready,wvalid,wready : std_logic;
  signal wdata : STD_LOGIC_VECTOR(31 DOWNTO 0);
  signal wstrb,awaddr: STD_LOGIC_VECTOR(3 DOWNTO 0);
  type state_t is (IDLE, INIT,WAIT_ACK,SET_WRITE,WRITE_UART,CHECK_FIFO_FULL,CHECK_FIFO_FULL_2, GET_DATA,DEBUG);
  signal state, state_nxt: state_t;
  signal bvalid: std_logic;
  signal count,count_nxt: natural;
  signal bresp: std_logic_vector(1 downto 0);
  signal arvalid, arready: std_logic;
  signal araddr: std_logic_vector(3 downto 0);
  signal rdata: std_logic_vector(32-1 downto 0);
  signal wrdata_reg, wrdata_reg_nxt : std_logic_vector(7 downto 0);
  
  
COMPONENT axi_uartlite_0
  PORT (
    s_axi_aclk : IN STD_LOGIC;
    s_axi_aresetn : IN STD_LOGIC;
    interrupt : OUT STD_LOGIC;
    s_axi_awaddr : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi_awvalid : IN STD_LOGIC;
    s_axi_awready : OUT STD_LOGIC;
    s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi_wvalid : IN STD_LOGIC;
    s_axi_wready : OUT STD_LOGIC;
    s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_bvalid : OUT STD_LOGIC;
    s_axi_bready : IN STD_LOGIC;
    s_axi_araddr : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi_arvalid : IN STD_LOGIC;
    s_axi_arready : OUT STD_LOGIC;
    s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_rvalid : OUT STD_LOGIC;
    s_axi_rready : IN STD_LOGIC;
    rx : IN STD_LOGIC;
    tx : OUT STD_LOGIC
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG

begin



  sync: process(clk,reset)
  variable var: natural := 1;
  begin
    if reset = '0' then
      --awvalid <= '0';
      state <= IDLE;
      count <= 0;
      wrdata_reg <= (others => '0');
    elsif rising_edge(clk) then
      state <= state_nxt;
      count <= count_nxt;
      wrdata_reg <= wrdata_reg_nxt;
      --if awready = '1' then
       -- if and wready = '1' then
        --  wdata <= (others => '1');
        --end if;
      --end if;
    end if;
  end process;



  state_p: process(all)
  variable debug_count : natural := 0;
  begin
    rd_fifo <= '0';
    awvalid <= '0';
    awaddr <= "0000";
    wstrb <= "0000";
    state_nxt <= state;
    wvalid <= '0';
    wdata <= (others => '0');
      count_nxt <= count;
      arvalid <= '0';
    wrdata_reg_nxt <= wrdata_reg;
    araddr <= "0000";
    case (state) is
      when IDLE=>
        count_nxt <= count +1;
        if count = 100 then
        state_nxt <= INIT;
        count_nxt <= 0;
        end if;
        
      when INIT =>
        awaddr <= "1100";
        awvalid <= '1';
        wstrb <= "0010";
        wdata(8-1 downto 0) <= X"13";
        wvalid <= '1';
        if wready = '1' then
          state_nxt <= WAIT_ACK;
        end if;

      when WAIT_ACK =>
        awvalid <= '0';
        wstrb <= "0010";
        wdata(8-1 downto 0) <= X"13";
        wvalid <= '0';
        if bvalid = '1' then
          state_nxt <= GET_DATA;
         -- state_nxt <= DEBUG;
        end if;

   --   when DEBUG =>
    --    from_uart.ready <= '1';
    --    state_nxt <= DEBUG;
    --    if debug_count = 10000 then
    --        from_uart.ready <= '0';
    --    else
    --        debug_count := debug_count +1;
   --    end if;

      when GET_DATA =>
        if fifo_empty = '0' then
          state_nxt <= SET_WRITE;
          rd_fifo <= '1';
        end if;

      when SET_WRITE =>
        awaddr <= "0100";
        awvalid <= '1';
        wdata(8-1 downto 0) <= data_fifo(8-1 downto 0);

        wvalid <= '1';
      --  state_nxt <= WRITE_UART;
        wstrb <= "0000";
        if wready = '1' then
          count_nxt <= count +1;
          state_nxt <= WRITE_UART;
        end if;
      when WRITE_UART =>
        awvalid <= '0';
        wvalid <= '0';
        if bresp = "00" then
          state_nxt <= CHECK_FIFO_FULL;
        end if;

      when CHECK_FIFO_FULL =>
        araddr <= "1000";
        arvalid <= '1';
        if arready = '1' then
          state_nxt <= CHECK_FIFO_FULL_2;
        end if;

      when CHECK_FIFO_FULL_2 =>
        if rdata(3) = '0' then
          state_nxt <= GET_DATA;
        else
          state_nxt <= CHECK_FIFO_FULL;
        end if;
        --if wready = '1' then
        --  wdata <= (others => '1');
      --    wvalid <= '1';
      --  end if;

        when others =>
    end case;
  end process;
  
  

  
    uartlite_i : axi_uartlite_0
      PORT MAP (
        s_axi_aclk => clk,
        s_axi_aresetn => reset,
        interrupt => open,
        s_axi_awaddr => awaddr,
        s_axi_awvalid => awvalid,
        s_axi_awready => awready,
        s_axi_wdata => wdata,
        s_axi_wstrb => wstrb,
        s_axi_wvalid => wvalid,
        s_axi_wready => wready,
        s_axi_bresp => bresp,
        s_axi_bvalid => bvalid,
        s_axi_bready => '1',
        s_axi_araddr => araddr,
        s_axi_arvalid => arvalid,
        s_axi_arready => arready,
        s_axi_rdata => rdata,
        s_axi_rresp => open,
        s_axi_rvalid => open,
        s_axi_rready => '1',
        rx => rx,
        tx => tx
      );


end Behavioral;
