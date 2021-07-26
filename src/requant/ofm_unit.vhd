LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

USE ieee.numeric_std.ALL;
USE IEEE.math_real.ALL;
USE work.core_pck.ALL;
USE work.control_pck.ALL;
USE work.top_types_pck.ALL;
ENTITY ofms_unit IS
  GENERIC (
    PARALLEL_OFMS : NATURAL := 3;
    MAX_OFMS : NATURAL := 255;
    MAX_RATE : NATURAL := 3;
    PE_COLUMNS : NATURAL := 3;
    OFM_REQUANT : NATURAL := 62
  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    ofms_in : IN ofms_out_type;
    from_uart : IN from_uart_type;
    to_uart : OUT to_uart_type --to modify
  );
END ENTITY;
-- this architecture is not well implemented (it is correct however) and propably should be split into multiple entities
-- Roughly the entity takes in the finished ofms, subsequently it puts them into the requant pipeline
-- the results of the requant pipeline are saved in BRAM until all ofms have been saved.
-- Once all have been saved they are communicated to the uart unit and written out by it.
ARCHITECTURE arch OF ofms_unit IS

  CONSTANT D_WID : NATURAL := PARALLEL_OFMS * PE_COLUMNS * DATA_WIDTH;

  --first stage compute real values
  --second stage write the result to the BRAMs
  SIGNAL dout_scale : STD_LOGIC_VECTOR(32 - 1 DOWNTO 0);

  -- basic values
  CONSTANT ofm_quant : NATURAL := OFM_REQUANT;
  CONSTANT OFM_SIZE_IFMAP : NATURAL := IFMAP_SIZE * (IFMAP_SIZE/PE_COLUMNS);
  CONSTANT MAX_ADDR_DATA : NATURAL := (MAX_OFMs/PARALLEL_OFMS) * MAX_RATE * OFM_SIZE_IFMAP; --3
  CONSTANT MAX_ADDR_ITER : NATURAL := PARALLEL_OFMS * MAX_RATE * OFM_SIZE_IFMAP;
  CONSTANT VAlUES_WIDTH : NATURAL := PARALLEL_OFMS * PE_COLUMNS;
  CONSTANT A_WID : NATURAL := INTEGER(ceil(log2(real(MAX_ADDR_DATA))));
  CONSTANT PARALLEL_DATA : NATURAL := PARALLEL_OFMS * PE_COLUMNS;
  -- ofm memory control
  SIGNAL we : STD_LOGIC;
  SIGNAL ena : STD_LOGIC;
  SIGNAL raddr : STD_LOGIC_VECTOR(A_WID - 1 DOWNTO 0);
  SIGNAL waddr : STD_LOGIC_VECTOR(A_WID - 1 DOWNTO 0);
  SIGNAL din : STD_LOGIC_VECTOR(PARALLEL_OFMS * PE_COLUMNS * DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL dout : STD_LOGIC_VECTOR(PARALLEL_OFMS * PE_COLUMNS * DATA_WIDTH - 1 DOWNTO 0);
  -- the Bram address of the ofms
  SIGNAL addr_ofm : NATURAL RANGE 0 TO MAX_OFMS - 1;

  -- provides the address to write to when new ofms are written
  SIGNAL write_counter, write_counter_nxt : NATURAL RANGE 0 TO OFM_SIZE_IFMAP - 1;
  -- when writing out only 8 bits can be written to the UART this is realized with these signals
  SIGNAL uart_buffer, uart_buffer_nxt : STD_LOGIC_VECTOR(VAlUES_WIDTH * DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL data_counter, data_counter_nxt : NATURAL RANGE 0 TO PARALLEL_DATA - 1;
  TYPE uart_state_type IS (IDLE, LOAD_DATA, STATIONARY, FINISHED);
  -- represents the uart state as communicated from the UART
  SIGNAL uart_state, uart_state_nxt : uart_state_type;
  -- counter for keeping track when writing out over uart 
  -- (seperated from write_counter because it could be extended to overlap (saving some cycles), not implemented)
  SIGNAL read_counter, read_counter_nxt : NATURAL RANGE 0 TO MAX_ADDR_DATA;
  TYPE set_scale_state_type IS (IDLE, SET_SCALE, SET_OFFSET, WAIT_STATE);
  SIGNAL set_scale_state, set_scale_state_nxt : set_scale_state_type;
  SIGNAL addr_scale_counter, addr_scale_counter_nxt : NATURAL RANGE 0 TO PARALLEL_OFMS + 7;

  -- keeps track of where to write the ofms that come from the requant stage
  SIGNAL iter_offs, iter_offs_nxt : NATURAL RANGE 0 TO MAX_OFMS - 1;
  TYPE debug_buffer_type IS ARRAY(0 TO PARALLEL_OFMS - 1, 0 TO PE_COLUMNS - 1) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

  SIGNAL raddr_int : NATURAL RANGE 0 TO MAX_ADDR_DATA - 1;
  CONSTANT OFFSET_DELAY : NATURAL := 3;
  SIGNAL out_result_valid_nxt, out_result_valid : STD_LOGIC;

  SIGNAL offset_counter, offset_counter_nxt : NATURAL RANGE 0 TO OFFSET_DELAY;
  SIGNAL mult_data_nxt, mult_data : STD_LOGIC_VECTOR(PARALLEL_OFMS * PE_COLUMNS * ACC_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL mult_data_valid_nxt, mult_data_valid : STD_LOGIC;
  SIGNAL wait_counter, wait_counter_nxt : NATURAL RANGE 0 TO 100;

  -- debug signals
  TYPE debug_type IS ARRAY(0 TO PARALLEL_OFMS - 1, 0 TO PE_COLUMNS - 1)OF unsigned(DATA_WIDTH - 1 DOWNTO 0);
  TYPE debug_type_2 IS ARRAY(0 TO PARALLEL_OFMS - 1, 0 TO PE_COLUMNS - 1)OF signed(ACC_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL debug : debug_type;
  SIGNAL debug_2 : debug_type_2;
  SIGNAL debug_uart_buffer : debug_buffer_type;

  -- used for the requantization
  -- requant pipeline signals
  TYPE result_mult_type IS ARRAY(0 TO PARALLEL_OFMS - 1, 0 TO PE_COLUMNS - 1) OF signed(ACC_DATA_WIDTH + 32 - 1 DOWNTO 0);
  TYPE result_type IS ARRAY(0 TO PARALLEL_OFMS - 1, 0 TO PE_COLUMNS - 1) OF signed(DATA_WIDTH - 1 + 1 DOWNTO 0);
  SIGNAL result_mult_nxt, result_mult, out_result_reg, out_result_reg_nxt : result_mult_type;
  SIGNAL result, result_nxt : result_type;
  SIGNAL result_valid, result_valid_nxt : STD_LOGIC;
  SIGNAL result_mult_valid, result_mult_valid_nxt : STD_LOGIC;

  -- control when to advance the 'scales' (requant) i.e. the values that are used to requantize the 24 ACC-WIDTH BITS to 8bits
  SIGNAL counter, counter_nxt : NATURAL RANGE 0 TO MAX_ADDR_ITER - 1;
  -- the 'shift' value for requantization
  SIGNAL dout_shift : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
  TYPE scale_type IS ARRAY(0 TO PARALLEL_OFMS - 1) OF signed(32 - 1 DOWNTO 0);
  TYPE shift_type IS ARRAY(0 TO PARALLEL_OFMS - 1) OF NATURAL RANGE 0 TO 255 - 1;
  SIGNAL scale_nxt, scale : scale_type;
  SIGNAL shift, shift_nxt : shift_type;
  SIGNAL scale_buffer, scale_buffer_nxt : scale_type;
  SIGNAL shift_buffer, shift_buffer_nxt : shift_type;

  -- it is important that we round away from zero see thesis
  FUNCTION round_away_from_zero(vec : signed(ACC_DATA_WIDTH + 32 - 1 DOWNTO 0);
    n : NATURAL RANGE 0 TO 255 - 1) RETURN signed IS
    VARIABLE result : signed(9 - 1 DOWNTO 0) := (OTHERS => '0');
    VARIABLE neg : STD_LOGIC; --tells if negative

  BEGIN
    IF n < 2 THEN
      RETURN to_signed(0, DATA_WIDTH + 1);
    END IF;
    result := shift_right(vec, n)(9 - 1 DOWNTO 0);
    neg := STD_LOGIC(vec(vec'length - 1));
    IF neg = '1' THEN
      IF vec(n - 1) = '1' THEN
        RETURN result + 1;
      ELSE --first place is '1'
        RETURN result;
      END IF;
    ELSE -- positve
      IF vec(n - 1) = '0' THEN
        RETURN result;
      ELSE --first place is a '1'
        RETURN result + 1;
      END IF;
    END IF;
    RETURN result;
  END FUNCTION;
BEGIN

  sync : PROCESS (clk, reset)
  BEGIN
    IF rising_edge(clk) THEN
      IF reset = '0' THEN
        shift <= (OTHERS => 0);
        scale <= (OTHERS => (OTHERS => '0'));
        counter <= 0;
        result_mult <= (OTHERS => (OTHERS => to_signed(0, result_mult(0, 0)'length)));
        result <= (OTHERS => (OTHERS => to_signed(0, DATA_WIDTH + 1)));
        result_valid <= '0';
        result_mult_valid <= '0';
        read_counter <= 0;
        data_counter <= 0;
        uart_state <= IDLE;
        uart_buffer <= (OTHERS => '0');
        write_counter <= 0;
        addr_scale_counter <= 0;
        set_scale_state <= SET_SCALE;
        scale_buffer <= (OTHERS => (OTHERS => '0'));
        shift_buffer <= (OTHERS => 0);
        iter_offs <= 0;
        offset_counter <= 0;
        out_result_valid <= '0';
        out_result_reg <= (OTHERS => (OTHERS => to_signed(0, result_mult(0, 0)'length)));
        mult_data <= (OTHERS => '0');
        mult_data_valid <= '0';
        wait_counter <= 0;
      ELSE
        set_scale_state <= set_scale_state_nxt;
        iter_offs <= iter_offs_nxt;
        addr_scale_counter <= addr_scale_counter_nxt;
        scale_buffer <= scale_buffer_nxt;
        shift <= shift_nxt;
        scale <= scale_nxt;
        counter <= counter_nxt;
        result_mult <= result_mult_nxt;
        result <= result_nxt;
        result_valid <= result_valid_nxt;
        result_mult_valid <= result_mult_valid_nxt;
        read_counter <= read_counter_nxt;
        uart_state <= uart_state_nxt;
        data_counter <= data_counter_nxt;
        uart_buffer <= uart_buffer_nxt;
        write_counter <= write_counter_nxt;
        shift_buffer <= shift_buffer_nxt;
        offset_counter <= offset_counter_nxt;
        out_result_valid <= out_result_valid_nxt;
        out_result_reg <= out_result_reg_nxt;
        mult_data <= mult_data_nxt;
        mult_data_valid <= mult_data_valid_nxt;
        wait_counter <= wait_counter_nxt;
      END IF;
    END IF;

  END PROCESS;

  --requants
  requant_pipeline : PROCESS (ALL)
    VARIABLE out_var : unsigned(DATA_WIDTH - 1 DOWNTO 0);
  BEGIN
    we <= '0';
    waddr <= (OTHERS => '0');
    ena <= '0';
    result_valid_nxt <= '0';
    din <= (OTHERS => '0');
    write_counter_nxt <= write_counter;
    result_mult_valid_nxt <= '0';
    result_nxt <= result;
    result_mult_nxt <= result_mult;
    out_result_valid_nxt <= '0';
    mult_data_nxt <= ofms_in.data;
    mult_data_valid_nxt <= ofms_in.valid;
    
    IF mult_data_valid = '1' THEN
      FOR ofm IN 0 TO PARALLEL_OFMS - 1 LOOP
        FOR I IN 0 TO PE_COLUMNS - 1 LOOP
          result_mult_nxt(ofm, I) <= signed(mult_data(ACC_DATA_WIDTH * (I + 1 + ofm * PE_COLUMNS) - 1 DOWNTO ACC_DATA_WIDTH * (I + ofm * PE_COLUMNS))) * scale(ofm);
          debug_2(ofm,I) <= signed(mult_data(ACC_DATA_WIDTH*(I+1+ofm*PE_COLUMNS)-1 downto ACC_DATA_WIDTH*(I+ofm*PE_COLUMNS)));
        END LOOP;
      END LOOP;
      result_mult_valid_nxt <= '1';
    END IF;

    -- this is added for better DSP inference (extra register stage -> power savings)
    -- this doesn't work if compiled with to relaxed constraints (see Xilinx Forums) 
    out_result_reg_nxt <= result_mult;
    IF result_mult_valid = '1' THEN
      out_result_valid_nxt <= '1';
    END IF;

    IF out_result_valid = '1' THEN
      result_valid_nxt <= '1';
      FOR ofm IN 0 TO PARALLEL_OFMS - 1 LOOP
        FOR I IN 0 TO PE_COLUMNS - 1 LOOP
          result_nxt(ofm, I) <= round_away_from_zero(out_result_reg(ofm, I), shift(ofm));
          --  debug(I) <= shift_right(result_mult(I),shift);
        END LOOP;
      END LOOP;
    END IF;
    waddr <= (OTHERS => '0');

    IF result_valid = '1' THEN
      we <= '1';
      ena <= '1';
      IF write_counter = OFM_SIZE_IFMAP - 1 THEN
        write_counter_nxt <= 0;
      ELSE
        write_counter_nxt <= write_counter + 1;
      END IF;
      waddr <= STD_LOGIC_VECTOR(to_unsigned(write_counter + iter_offs * OFM_SIZE_IFMAP, waddr'length));
      FOR ofm IN 0 TO PARALLEL_OFMS - 1 LOOP
        FOR I IN 0 TO PE_COLUMNS - 1 LOOP

          out_var := to_unsigned(to_integer(result(ofm, I)) + ofm_quant, DATA_WIDTH);
          din(DATA_WIDTH * (I + 1 + ofm * PE_COLUMNS) - 1 DOWNTO DATA_WIDTH * (I + ofm * PE_COLUMNS)) <= STD_LOGIC_VECTOR(out_var);
          --out_var := to_unsigned(to_integer(result(I)+ofm_quant),DATA_WIDTH);
          debug(ofm,I) <= out_var;
        END LOOP;
      END LOOP;
    END IF;
    CASE(uart_state) IS

      WHEN IDLE =>
      WHEN OTHERS =>
      ena <= '1';
    END CASE;
  END PROCESS;

  --prepares the needed shift and scale values
  addr : PROCESS (ALL)
  BEGIN
    counter_nxt <= counter;
    IF ofms_in.valid = '1' THEN
      counter_nxt <= counter + 1;
    END IF;
    IF counter = OFM_SIZE_IFMAP - 1 THEN
      counter_nxt <= 0;
    END IF;
    set_scale_state_nxt <= set_scale_state;
    addr_scale_counter_nxt <= 0;
    addr_ofm <= 0;
    scale_nxt <= scale;
    shift_nxt <= shift;
    iter_offs_nxt <= iter_offs;
    offset_counter_nxt <= 0;
    shift_nxt <= shift;
    scale_buffer_nxt <= scale_buffer;
    shift_buffer_nxt <= shift_buffer;
    wait_counter_nxt <= 0;
    CASE(set_scale_state) IS

      WHEN IDLE =>
      IF counter = OFM_SIZE_IFMAP - 1 THEN
        set_scale_state_nxt <= WAIT_STATE;
      END IF;
      WHEN WAIT_STATE =>
      IF wait_counter = 100 THEN
        set_scale_state_nxt <= SET_OFFSET;
      ELSE
        wait_counter_nxt <= wait_counter + 1;
      END IF;

      WHEN SET_OFFSET =>
      IF offset_counter = OFFSET_DELAY - 1 THEN
        set_scale_state_nxt <= SET_SCALE;
        IF (iter_offs + 1) * PARALLEL_OFMS = MAX_OFMS THEN
          iter_offs_nxt <= 0;
        ELSE
          iter_offs_nxt <= iter_offs + 1;
        END IF;
      ELSE
        offset_counter_nxt <= offset_counter + 1;
      END IF;

      WHEN SET_SCALE =>
      IF addr_scale_counter = PARALLEL_OFMS + 4 THEN
        set_scale_state_nxt <= IDLE;
        scale_nxt <= scale_buffer;
        shift_nxt <= shift_buffer;
      ELSE
        addr_scale_counter_nxt <= addr_scale_counter + 1;
      END IF;
      IF addr_scale_counter > 0 AND addr_scale_counter < PARALLEL_OFMS + 1 THEN
        scale_buffer_nxt(addr_scale_counter - 1) <= signed(dout_scale);
        shift_buffer_nxt(addr_scale_counter - 1) <= to_integer(unsigned(dout_shift));
      END IF;
      IF addr_scale_counter < PARALLEL_OFMS THEN
        addr_ofm <= addr_scale_counter + iter_offs * PARALLEL_OFMS;
      END IF;
    END CASE;
  END PROCESS;

  -- process for communicating with the UART unit
  write_out_over_UART : PROCESS (ALL)
    VARIABLE uart_buffer_var : STD_LOGIC_VECTOR(VAlUES_WIDTH * DATA_WIDTH - 1 DOWNTO 0);
  BEGIN
    read_counter_nxt <= 0;
    to_uart.valid <= '0';
    to_uart.data <= (OTHERS => '0');
    uart_state_nxt <= uart_state;
    data_counter_nxt <= data_counter;
    uart_buffer_nxt <= uart_buffer;
    IF read_counter < MAX_ADDR_DATA THEN
      raddr_int <= read_counter;
    ELSE
      raddr_int <= 0;
    END IF;

    CASE(uart_state) IS

      WHEN IDLE =>
      to_uart.valid <= '0';
      IF from_uart.want_data_ofm = '1' THEN
        uart_state_nxt <= LOAD_DATA;

      ELSE
        uart_state_nxt <= IDLE;
      END IF;

      WHEN LOAD_DATA =>
      read_counter_nxt <= read_counter;
      uart_buffer_var := dout;
      data_counter_nxt <= 0;
      IF from_uart.ready = '1' THEN
        IF 0 = PARALLEL_DATA - 1 THEN
          data_counter_nxt <= 0;
        ELSE
          data_counter_nxt <= 1;
        END IF;
        to_uart.data <= uart_buffer_var(DATA_WIDTH - 1 DOWNTO 0);

        to_uart.valid <= '1';

        uart_buffer_nxt <= uart_buffer_var;
        FOR ofm IN 0 TO PARALLEL_OFMS - 1 LOOP
          FOR I IN 0 TO PE_COLUMNS - 1 LOOP
            debug_uart_buffer(ofm, I) <= uart_buffer_var(DATA_WIDTH * (I + ofm * PE_COLUMNS + 1) - 1 DOWNTO DATA_WIDTH * (I + ofm * PE_COLUMNS));
          END LOOP;
        END LOOP;
        IF 0 = PARALLEL_DATA - 1 THEN
          uart_state_nxt <= LOAD_DATA;
        ELSE
          uart_state_nxt <= STATIONARY;
        END IF;

        IF read_counter = MAX_ADDR_DATA THEN
          read_counter_nxt <= 0;
          uart_state_nxt <= FINISHED;
        ELSE
          read_counter_nxt <= read_counter + 1;
        END IF;
      END IF;
      WHEN FINISHED =>
      to_uart.valid <= '0';

      WHEN STATIONARY =>
      read_counter_nxt <= read_counter;
      IF from_uart.ready = '1' THEN
        to_uart.data <= uart_buffer(DATA_WIDTH * (data_counter + 1) - 1 DOWNTO DATA_WIDTH * data_counter);
        to_uart.valid <= '1';
        IF data_counter = PARALLEL_DATA - 1 THEN
          uart_state_nxt <= LOAD_DATA;
        ELSE
          data_counter_nxt <= data_counter + 1;
        END IF;
      END IF;
    END CASE;

  END PROCESS;

  --scale memory
  scales_mem : ENTITY work.rams_init_file
    GENERIC MAP(
      FILENAME => "scales.data",
      ADDRW => 10, --255*3
      DATAW => 32,
      DEPTH => MAX_OFMS * MAX_RATE
    )
    PORT MAP(
      clk => clk,
      addr => STD_LOGIC_VECTOR(to_unsigned(addr_ofm, 10)),
      dout => dout_scale
    );

  shift_mem : ENTITY work.rams_init_file
    GENERIC MAP(
      FILENAME => "shift.data",
      ADDRW => 10, --255*3
      DATAW => DATA_WIDTH,
      DEPTH => MAX_OFMS * MAX_RATE
    )
    PORT MAP(
      clk => clk,
      addr => STD_LOGIC_VECTOR(to_unsigned(addr_ofm, 10)),
      dout => dout_shift
    );
  --ofm memory
  rams_sdp_record_i : ENTITY work.rams_sdp_record
    GENERIC MAP(
      A_WID => A_WID,
      D_WID => PARALLEL_OFMS * PE_COLUMNS * DATA_WIDTH,
      DEPTH => MAX_ADDR_DATA
    )
    PORT MAP(
      clk => clk,
      we => we,
      ena => ena,
      raddr => STD_LOGIC_VECTOR(to_unsigned(raddr_int, A_WID)),
      waddr => waddr,
      din => din,
      dout => dout
    );
END ARCHITECTURE;