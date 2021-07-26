LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.core_pck.ALL;
USE work.control_pck.ALL;
USE work.top_types_pck.ALL;

-- The uart writes out to the PC
ENTITY uart_unit IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    from_uart : OUT from_uart_type;
    to_uart : IN to_uart_type;
    rx : IN STD_LOGIC;
    tx : OUT STD_LOGIC;
    finished : IN STD_LOGIC;
    finished_counters : IN STD_LOGIC
  );
END ENTITY;

ARCHITECTURE arch OF uart_unit IS

  COMPONENT axi_uartlite_0
    PORT (
      s_axi_aclk : IN STD_LOGIC;
      s_axi_aresetn : IN STD_LOGIC;
      interrupt : OUT STD_LOGIC;
      s_axi_awaddr : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      s_axi_awvalid : IN STD_LOGIC; --address valid
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

  SIGNAL awvalid, awready, wvalid, wready : STD_LOGIC;
  SIGNAL wdata : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL wstrb, awaddr : STD_LOGIC_VECTOR(3 DOWNTO 0);
  TYPE state_t IS (IDLE, INIT, WAIT_ACK, SET_WRITE, WRITE_UART, CHECK_FIFO_FULL, CHECK_FIFO_FULL_2, GET_DATA, DEBUG);
  SIGNAL state, state_nxt : state_t;
  SIGNAL bvalid : STD_LOGIC;
  SIGNAL count, count_nxt : NATURAL;
  SIGNAL bresp : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL arvalid, arready : STD_LOGIC;
  SIGNAL araddr : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL rdata : STD_LOGIC_VECTOR(32 - 1 DOWNTO 0);
  SIGNAL wrdata_reg, wrdata_reg_nxt : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN

  sync : PROCESS (clk, reset)
    VARIABLE var : NATURAL := 1;
  BEGIN
    IF reset = '0' THEN
      state <= IDLE;
      count <= 0;
      wrdata_reg <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      state <= state_nxt;
      count <= count_nxt;
      wrdata_reg <= wrdata_reg_nxt;
    END IF;
  END PROCESS;

  state_p : PROCESS (ALL)
    VARIABLE debug_count : NATURAL := 0;
  BEGIN
    awvalid <= '0';
    awaddr <= "0000";
    wstrb <= "0000";
    state_nxt <= state;
    wvalid <= '0';
    wdata <= (OTHERS => '0');
    count_nxt <= count;
    arvalid <= '0';
    wrdata_reg_nxt <= wrdata_reg;
    from_uart.ready <= '0';
    araddr <= "0000";
    CASE (state) IS
      WHEN IDLE =>
        state_nxt <= INIT;
      WHEN INIT =>
        awaddr <= "1100";
        awvalid <= '1';
        wstrb <= "0010";
        wdata(8 - 1 DOWNTO 0) <= X"13";
        wvalid <= '1';
        IF wready = '1' THEN
          state_nxt <= WAIT_ACK;
        END IF;

      WHEN WAIT_ACK =>
        awvalid <= '0';
        wstrb <= "0010";
        wdata(8 - 1 DOWNTO 0) <= X"13";
        wvalid <= '0';
        IF bvalid = '1' THEN
          state_nxt <= GET_DATA;
          -- state_nxt <= DEBUG;
        END IF;

        --   when DEBUG =>
        --    from_uart.ready <= '1';
        --    state_nxt <= DEBUG;
        --    if debug_count = 10000 then
        --        from_uart.ready <= '0';
        --    else
        --        debug_count := debug_count +1;
        --    end if;

      WHEN GET_DATA =>
        from_uart.ready <= '1';
        IF to_uart.valid = '1' THEN
          state_nxt <= SET_WRITE;
          wrdata_reg_nxt <= to_uart.data;
        END IF;

      WHEN SET_WRITE =>
        awaddr <= "0100";
        awvalid <= '1';
        wdata(8 - 1 DOWNTO 0) <= wrdata_reg_nxt;

        wvalid <= '1';
        wstrb <= "0000";
        IF wready = '1' THEN
          count_nxt <= count + 1;
          state_nxt <= WRITE_UART;
        END IF;

      WHEN WRITE_UART =>
        awvalid <= '0';
        wvalid <= '0';
        IF bresp = "00" THEN
          state_nxt <= CHECK_FIFO_FULL;
        END IF;

      WHEN CHECK_FIFO_FULL =>
        araddr <= "1000";
        arvalid <= '1';
        IF arready = '1' THEN
          state_nxt <= CHECK_FIFO_FULL_2;
        END IF;

      WHEN CHECK_FIFO_FULL_2 =>
        IF rdata(3) = '0' THEN
          state_nxt <= GET_DATA;
        ELSE
          state_nxt <= CHECK_FIFO_FULL;
        END IF;
      WHEN OTHERS =>
    END CASE;
  END PROCESS;
  out_p : PROCESS (ALL)
  BEGIN
    from_uart.want_data_ofm <= '0';
    from_uart.want_data_counters <= '0';
    IF finished = '1' THEN
      IF finished_counters = '1' THEN

        from_uart.want_data_ofm <= '1';
      ELSE
        from_uart.want_data_counters <= '1';
      END IF;
    END IF;
  END PROCESS;
  uartlite_i : axi_uartlite_0
  PORT MAP(
    s_axi_aclk => clk,
    s_axi_aresetn => reset,
    interrupt => OPEN,
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
    s_axi_rresp => OPEN,
    s_axi_rvalid => OPEN,
    s_axi_rready => '1',
    rx => rx,
    tx => tx
  );

END ARCHITECTURE;