LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

USE ieee.numeric_std.ALL;
USE work.core_pck.ALL;
USE work.control_pck.ALL;

USE work.ultra_ram_pck.ALL;
USE work.top_types_pck.ALL;

ENTITY iacts_buffer IS
  GENERIC (
    IFMAP_SIZE : NATURAL := 33;
    IFMAPS_TO_PREPARE : NATURAL := 3;
    AWIDTH : NATURAL := 18;
    DEPTH : NATURAL := 32
  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    mode : IN iacts_mode_type;
    values : IN ifmap_DRAM_type;
    address : IN ifmap_position_type;
    out_buffer : OUT iacts_buffer_type;
    ifmaps_prepared : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE arch OF iacts_buffer IS

  CONSTANT NUM_COL : NATURAL := 9; -- 72/9 = 8
  CONSTANT DWIDTH : NATURAL := 72 * 4;

  --counters for addressing the ultraram
  SIGNAL counter_a_nxt, counter_a, counter_b, counter_b_nxt : NATURAL;
  --output buffer of ifmaps
  SIGNAL out_buffer_nxt : iacts_buffer_type;
  -- the state of the preperations
  TYPE prepare_ifmap_state_type IS (PREP, WAIT_STATE, FIRST, LAST, FINISHED, STATIONARY);
  SIGNAL prepare_ifmap_state, prepare_ifmap_state_nxt : prepare_ifmap_state_type;
  -- URAM control signals
  SIGNAL rsta : STD_LOGIC;
  SIGNAL wea : STD_LOGIC_VECTOR(NUM_COL - 1 DOWNTO 0);
  SIGNAL regcea : STD_LOGIC;
  SIGNAL mem_ena : STD_LOGIC;
  SIGNAL dina : STD_LOGIC_VECTOR(DWIDTH - 1 DOWNTO 0);
  SIGNAL addra : STD_LOGIC_VECTOR(AWIDTH - 1 DOWNTO 0);
  SIGNAL douta : STD_LOGIC_VECTOR(DWIDTH - 1 DOWNTO 0);
  SIGNAL rstb : STD_LOGIC;
  SIGNAL web : STD_LOGIC_VECTOR(NUM_COL - 1 DOWNTO 0);
  SIGNAL regceb : STD_LOGIC;
  SIGNAL mem_enb : STD_LOGIC;
  SIGNAL dinb : STD_LOGIC_VECTOR(DWIDTH - 1 DOWNTO 0);
  SIGNAL addrb : STD_LOGIC_VECTOR(AWIDTH - 1 DOWNTO 0);
  SIGNAL doutb : STD_LOGIC_VECTOR(DWIDTH - 1 DOWNTO 0);

  SIGNAL debug : array_buffer;

  --forces wait until output from the URAM is valid
  SIGNAL wait_counter, wait_counter_nxt : NATURAL RANGE 0 TO 4;
  --write addresses for initializing the memory
  SIGNAL write_addr, write_addr_nxt : NATURAL;
  SIGNAL ifmap_counter, ifmap_counter_nxt : NATURAL RANGE 0 TO PE_COLUMNS - 1;
  CONSTANT ULTRA_RAM_DWIDTH : NATURAL := 72 * 4;
BEGIN

  ultra : xilinx_ultraram_true_dual_port_byte_write
  GENERIC MAP(
    AWIDTH => AWIDTH,
    DWIDTH => ULTRA_RAM_DWIDTH,
    NUM_COL => 9,
    NBPIPE => 3,
    DEPTH => DEPTH
  )
  PORT MAP(
    clk => clk,
    rsta => rsta,
    wea => wea,
    regcea => regcea,
    mem_ena => mem_ena,
    dina => dina,
    addra => addra,
    douta => douta,

    rstb => rstb,
    web => web,
    regceb => regceb,
    mem_enb => mem_enb,
    dinb => dinb,
    addrb => addrb,
    doutb => doutb
  );

  sync : PROCESS (clk, reset)
  BEGIN
    IF reset = '0' THEN
      prepare_ifmap_state <= PREP;
      wait_counter <= 0;
      out_buffer <= (OTHERS => (OTHERS => (OTHERS => '0')));
      write_addr <= 0;
      ifmap_counter <= 0;
      counter_a <= 0;
      counter_b <= 1;
    ELSIF rising_edge(clk) THEN
      out_buffer <= out_buffer_nxt;
      prepare_ifmap_state <= prepare_ifmap_state_nxt;
      write_addr <= write_addr_nxt;
      wait_counter <= wait_counter_nxt;
      ifmap_counter <= ifmap_counter_nxt;
      counter_a <= counter_a_nxt;
      counter_b <= counter_b_nxt;
    END IF;
  END PROCESS;
  --prepares and control the ifmaps
  in_out : PROCESS (ALL)
    VARIABLE start_address : NATURAL;
  BEGIN
    rsta <= '0';
    rstb <= '0';
    IF reset = '0' THEN
      rsta <= '1';
      rstb <= '1';
    END IF;

    mem_ena <= '1';
    mem_enb <= '1';
    wea <= (OTHERS => '0');
    web <= (OTHERS => '0');
    regcea <= '0';
    dina <= (OTHERS => '0');
    dinb <= (OTHERS => '0');
    addra <= (OTHERS => '0');
    addrb <= (OTHERS => '0');
    regceb <= '0';
    ifmaps_prepared <= '0';
    out_buffer_nxt <= out_buffer;
    wait_counter_nxt <= 0;
    counter_a_nxt <= counter_a;
    counter_b_nxt <= counter_b;
    ifmap_counter_nxt <= ifmap_counter;
    --FOR I IN 0 TO 8 LOOP
    --  debug <= to_buffer(douta);
    --END LOOP;
    write_addr_nxt <= write_addr;
    prepare_ifmap_state_nxt <= prepare_ifmap_state;

    CASE(mode) IS
      WHEN ENABLE_MEM =>
      WHEN LOAD_IFMAP =>

      addra <= STD_LOGIC_VECTOR(to_unsigned(write_addr, AWIDTH));
      addrb <= STD_LOGIC_VECTOR(to_unsigned(write_addr + 1, AWIDTH));
      dina <= values.data(ULTRA_RAM_DWIDTH - 1 DOWNTO 0);
      dinb <= values.data(ULTRA_RAM_DWIDTH * 2 - 1 DOWNTO ULTRA_RAM_DWIDTH);
      IF values.valid = '1' THEN
        wea <= (OTHERS => '1');
        web <= (OTHERS => '1');
        write_addr_nxt <= write_addr + 2;
      END IF;

      --prepares the ifmaps
      WHEN PREPARE_IFMAP =>
      regcea <= '1';
      regceb <= '1';
      start_address := address.x * PE_COLUMNS * 2 + address.y * IFMAP_SIZE * 2 + address.depth_pos * IFMAP_SIZE * IFMAP_SIZE * 2;--address.x*3*2 + address.y*11*3*2 + address.depth_pos*11*3*33*2;

      addra <= STD_LOGIC_VECTOR(to_unsigned(start_address + counter_a, AWIDTH));
      addrb <= STD_LOGIC_VECTOR(to_unsigned(start_address + counter_a + 1, AWIDTH));
      counter_a_nxt <= counter_a + 2;

      CASE(prepare_ifmap_state) IS

        WHEN PREP =>
        prepare_ifmap_state_nxt <= WAIT_STATE;

        WHEN WAIT_STATE =>
        wait_counter_nxt <= wait_counter + 1;
        prepare_ifmap_state_nxt <= WAIT_STATE;
        IF wait_counter = 3 THEN
          prepare_ifmap_state_nxt <= STATIONARY;
        END IF;

        WHEN STATIONARY =>
        --loops and waits until IFMAPS_TO_PREPARE ifmaps have been prepared
        FOR I IN 0 TO 36 - 1 LOOP
          out_buffer_nxt(ifmap_counter, I) <= to_buffer(douta)(I);
          IF I + 36 < 64 THEN
            out_buffer_nxt(ifmap_counter, I + 36) <= to_buffer(doutb)(I);
          END IF;
        END LOOP;

        IF ifmap_counter = IFMAPS_TO_PREPARE - 1 THEN
          ifmap_counter_nxt <= 0;
          prepare_ifmap_state_nxt <= FINISHED;
        ELSE
          ifmap_counter_nxt <= ifmap_counter + 1;
        END IF;
        WHEN FINISHED =>
        ifmaps_prepared <= '1';
        counter_a_nxt <= 0;
        counter_b_nxt <= 1;
        ifmap_counter_nxt <= 0;

        WHEN OTHERS =>

      END CASE;
      WHEN CLEAN =>
      out_buffer_nxt <= (OTHERS => (OTHERS => (OTHERS => '0')));
      prepare_ifmap_state_nxt <= PREP;
      counter_a_nxt <= 0;
      ifmap_counter_nxt <= 0;
    END CASE;
  END PROCESS;

END ARCHITECTURE;