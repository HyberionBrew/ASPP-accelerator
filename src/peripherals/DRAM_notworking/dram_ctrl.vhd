LIBRARY ieee;
USE ieee.std_logic_1164.ALL; 

USE ieee.numeric_std.ALL;
USE IEEE.math_real.ALL;


Library UNISIM;
use UNISIM.vcomponents.all;

ENTITY dram_ctrl IS
	PORT (
		c0_sys_clk_p : IN STD_LOGIC;
  	    c0_sys_clk_n : IN STD_LOGIC;
		c0_ddr4_adr : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
        c0_ddr4_ba : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        c0_ddr4_cke : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        c0_ddr4_cs_n : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        c0_ddr4_dm_dbi_n : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        c0_ddr4_dq : INOUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        c0_ddr4_dqs_c : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        c0_ddr4_dqs_t : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        c0_ddr4_odt : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        c0_ddr4_bg : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        c0_ddr4_reset_n : OUT STD_LOGIC;
        c0_ddr4_act_n : OUT STD_LOGIC;
        c0_ddr4_ck_c : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        c0_ddr4_ck_t : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        tx : OUT STD_LOGIC;
        rx: in STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF dram_ctrl IS

signal c0_init_calib_complete : STD_LOGIC;
--signal dbg_clk : STD_LOGIC;
signal dbg_bus : STD_LOGIC_VECTOR(511 DOWNTO 0);
signal clk_ui_ddr4 : STD_LOGIC;
signal clk_sync_rst_ui_ddr4 : STD_LOGIC;
signal c0_ddr4_app_en : STD_LOGIC;
signal c0_ddr4_app_hi_pri : STD_LOGIC;
signal c0_ddr4_app_wdf_end : STD_LOGIC;
signal c0_ddr4_app_wdf_wren : STD_LOGIC;
signal c0_ddr4_app_rd_data_end : STD_LOGIC;
signal c0_ddr4_app_rd_data_valid : STD_LOGIC;
signal c0_ddr4_app_rdy : STD_LOGIC;
signal c0_ddr4_app_wdf_rdy : STD_LOGIC;
signal c0_ddr4_app_addr : STD_LOGIC_VECTOR(28 DOWNTO 0);
signal c0_ddr4_app_cmd : STD_LOGIC_VECTOR(2 DOWNTO 0);
signal c0_ddr4_app_wdf_data : STD_LOGIC_VECTOR(511 DOWNTO 0);
signal c0_ddr4_app_wdf_mask : STD_LOGIC_VECTOR(63 DOWNTO 0);
signal c0_ddr4_app_rd_data,data_fifo,data_in_fifo, data_in_fifo_nxt : STD_LOGIC_VECTOR(511 DOWNTO 0);
signal sys_rst,fifo_empty : STD_LOGIC;
signal clk_fabric: std_logic;
signal fifo_full, rd_en: std_logic;
signal reset: std_logic;
signal rd_data_valid_nxt, rd_data_valid : std_logic;
signal clk_count: natural range 0 to 101;
signal locked: std_logic;
signal clk_wiz,clk_wiz2,clk_ddr4: std_logic;
signal fifo_empty_dram, fifo_full_dram, fifo_empty_fabric, fifo_full_fabric: std_logic_vector(1 downto 0);

COMPONENT ddr4_0
  PORT (
    c0_init_calib_complete : OUT STD_LOGIC;
    dbg_clk : OUT STD_LOGIC;
    c0_sys_clk_p : IN STD_LOGIC;
    c0_sys_clk_n : IN STD_LOGIC;
    dbg_bus : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
    c0_ddr4_adr : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    c0_ddr4_ba : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_cke : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    c0_ddr4_cs_n : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    c0_ddr4_dm_dbi_n : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    c0_ddr4_dq : INOUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    c0_ddr4_dqs_c : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    c0_ddr4_dqs_t : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    c0_ddr4_odt : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    c0_ddr4_bg : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_reset_n : OUT STD_LOGIC;
    c0_ddr4_act_n : OUT STD_LOGIC;
    c0_ddr4_ck_c : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    c0_ddr4_ck_t : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    c0_ddr4_ui_clk : OUT STD_LOGIC;
    c0_ddr4_ui_clk_sync_rst : OUT STD_LOGIC;
    c0_ddr4_app_en : IN STD_LOGIC;
    c0_ddr4_app_hi_pri : IN STD_LOGIC;
    c0_ddr4_app_wdf_end : IN STD_LOGIC;
    c0_ddr4_app_wdf_wren : IN STD_LOGIC;
    c0_ddr4_app_rd_data_end : OUT STD_LOGIC;
    c0_ddr4_app_rd_data_valid : OUT STD_LOGIC;
    c0_ddr4_app_rdy : OUT STD_LOGIC;
    c0_ddr4_app_wdf_rdy : OUT STD_LOGIC;
    c0_ddr4_app_addr : IN STD_LOGIC_VECTOR(28 DOWNTO 0);
    c0_ddr4_app_cmd : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    c0_ddr4_app_wdf_data : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    c0_ddr4_app_wdf_mask : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    c0_ddr4_app_rd_data : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
    addn_ui_clkout1 : OUT STD_LOGIC;
    sys_rst : IN STD_LOGIC
  );
END COMPONENT;

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

COMPONENT fifo_generator_0
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
  END COMPONENT;


-- COMP_TAG_END ------ End COMPONENT Declaration ------------
-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.


-- COMP_TAG_END ------ End COMPONENT Declaration ------------
-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.
------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG


begin


ddr4 : ddr4_0
  PORT MAP (
    c0_init_calib_complete => c0_init_calib_complete,
    dbg_clk => open,
    c0_sys_clk_p => c0_sys_clk_p,
    c0_sys_clk_n => c0_sys_clk_n,
    dbg_bus => open,
    c0_ddr4_adr => c0_ddr4_adr,
    c0_ddr4_ba => c0_ddr4_ba,
    c0_ddr4_cke => c0_ddr4_cke,
    c0_ddr4_cs_n => c0_ddr4_cs_n,
    c0_ddr4_dm_dbi_n => c0_ddr4_dm_dbi_n,
    c0_ddr4_dq => c0_ddr4_dq,
    c0_ddr4_dqs_c => c0_ddr4_dqs_c,
    c0_ddr4_dqs_t => c0_ddr4_dqs_t,
    c0_ddr4_odt => c0_ddr4_odt,
    c0_ddr4_bg => c0_ddr4_bg,
    c0_ddr4_reset_n => c0_ddr4_reset_n,
    c0_ddr4_act_n => c0_ddr4_act_n,
    c0_ddr4_ck_c => c0_ddr4_ck_c,
    c0_ddr4_ck_t => c0_ddr4_ck_t,
    c0_ddr4_ui_clk => clk_ui_ddr4,
    c0_ddr4_ui_clk_sync_rst => clk_sync_rst_ui_ddr4,
    c0_ddr4_app_en => c0_ddr4_app_en,
    c0_ddr4_app_hi_pri => '0',
    c0_ddr4_app_wdf_end => c0_ddr4_app_wdf_end,
    c0_ddr4_app_wdf_wren => c0_ddr4_app_wdf_wren,
    c0_ddr4_app_rd_data_end => open,
    c0_ddr4_app_rd_data_valid => c0_ddr4_app_rd_data_valid,
    c0_ddr4_app_rdy => c0_ddr4_app_rdy,
    c0_ddr4_app_wdf_rdy => c0_ddr4_app_wdf_rdy,
    c0_ddr4_app_addr => c0_ddr4_app_addr,
    c0_ddr4_app_cmd => c0_ddr4_app_cmd,
    c0_ddr4_app_wdf_data => c0_ddr4_app_wdf_data,
    c0_ddr4_app_wdf_mask => c0_ddr4_app_wdf_mask,
    c0_ddr4_app_rd_data => c0_ddr4_app_rd_data,
    addn_ui_clkout1 => clk_fabric,
    sys_rst => '0'
  );

fifo : fifo_generator_0
  PORT MAP (
    rst => not(c0_init_calib_complete),
    wr_clk => clk_ui_ddr4,
    rd_clk => clk_fabric,
    din => data_in_fifo,
    wr_en => rd_data_valid,
    rd_en => rd_en,
    dout => data_fifo,
    full => fifo_full,
    empty => fifo_empty
  );

 sync: process(clk_ui_ddr4,clk_sync_rst_ui_ddr4)
 begin
     if clk_sync_rst_ui_ddr4 = '1' then
        data_in_fifo <= (others => '0');
        rd_data_valid <= '0';
     elsif rising_edge(clk_ui_ddr4) then
         data_in_fifo <= data_in_fifo_nxt;
         rd_data_valid <= rd_data_valid_nxt;
     end if;
 end process;

  debug: process(all)
  begin
  data_in_fifo_nxt <= c0_ddr4_app_rd_data;
  rd_data_valid_nxt <= c0_ddr4_app_rd_data_valid;
   -- if c0_ddr4_app_rd_data_valid = '1' then
        
    --    data_in_fifo(8-1 downto 0) <= 0x"AA";
  -- end if;
  end process;
  
  
  sync_fifo_fabric: process(clk_fabric, clk_sync_rst_ui_ddr4)
   begin
   if clk_sync_rst_ui_ddr4 = '1' then 
        fifo_empty_fabric <= (others => '1'); 
        fifo_full_fabric <= (others => '1'); 
    elsif rising_edge(clk_fabric) then
        fifo_empty_fabric(1) <= fifo_empty;
        fifo_empty_fabric(0) <= fifo_empty_fabric(1);
        fifo_full_fabric(1) <= fifo_full;
        fifo_full_fabric(0) <= fifo_full_fabric(1);
    end if;
   end process;

    sync_fifo_dram: process(clk_fabric, clk_sync_rst_ui_ddr4)
   begin
   if clk_sync_rst_ui_ddr4 = '1' then 
        fifo_empty_dram <= (others => '1'); 
        fifo_full_dram <= (others => '1'); 
    elsif rising_edge(clk_fabric) then
        fifo_empty_dram(1) <= fifo_empty;
        fifo_empty_dram(0) <= fifo_empty_dram(1);
        fifo_full_dram(1) <= fifo_full;
        fifo_full_dram(0) <= fifo_full_dram(1);
    end if;
   end process;
  
  
  
ddr4_cmd_i : entity work.dram_controller
port map (
  clk                 => clk_ui_ddr4,
  reset               => clk_sync_rst_ui_ddr4,
  init_calib_complete => c0_init_calib_complete,
  app_en              => c0_ddr4_app_en,
  app_wdf_end         => c0_ddr4_app_wdf_end,
  app_wdf_wren        => c0_ddr4_app_wdf_wren,
  app_rd_data_valid   => c0_ddr4_app_rd_data_valid,
  app_rdy             => c0_ddr4_app_rdy,
  app_wdf_rdy         => c0_ddr4_app_wdf_rdy,
  app_addr            => c0_ddr4_app_addr,
  app_cmd             => c0_ddr4_app_cmd,
  app_wdf_data        => c0_ddr4_app_wdf_data,
  app_wdf_mask        => c0_ddr4_app_wdf_mask,
  app_rd_data         => c0_ddr4_app_rd_data,
  dram_rdy_for_uart   => open,
  fifo_empty => fifo_empty,
  fifo_full => fifo_full
);

uart_ctrl: entity work.uart_ctrl
port map(
    clk => clk_fabric,
    reset => not(clk_sync_rst_ui_ddr4),
    rd_fifo => rd_en,
    data_fifo => data_fifo,
    fifo_full => fifo_full_fabric(0),
    fifo_empty => fifo_empty_fabric(0),
    tx => tx,
    rx => rx
);



end architecture;
