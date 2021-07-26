LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

USE ieee.numeric_std.ALL;
USE work.core_pck.ALL;
USE work.control_pck.ALL;
USE work.ultra_ram_pck.ALL;
USE work.top_types_pck.ALL;

ENTITY psums_buffer IS
	GENERIC (
		ACC_WIDTH : NATURAL := 24;
		MAX_OFMS : NATURAL := 3;
		PARALLEL_OFMS : NATURAL := 4;
		PE_COLUMNS : NATURAL := 3;
		A_WIDTH : NATURAL := 9;
		DWIDTH : NATURAL := 24 * 3 * 4;
		DEPTH : NATURAL := 33 * 11
	);

	PORT (
		clk : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		mode : IN mode_psums_type;
		address : IN point;
		address_prev : IN point;
		psums_ready : OUT STD_LOGIC;
		psum_values_in : IN psum_array;
		first_pass : IN STD_LOGIC;
		out_buffer : OUT psum_array;
		ofms_out : OUT ofms_out_type;
		finished_writing_ofm : OUT STD_LOGIC
	);

END ENTITY;

ARCHITECTURE arch OF psums_buffer IS

	--TYPE mode_psums_type IS (WRITE_PSUMS, PREPARE_PSUMS, CLEAN);
	
	--BRAM control 
	SIGNAL we : STD_LOGIC;
	SIGNAL ena : STD_LOGIC;
	SIGNAL raddr : STD_LOGIC_VECTOR(A_WIDTH - 1 DOWNTO 0);
	SIGNAL waddr : STD_LOGIC_VECTOR(A_WIDTH - 1 DOWNTO 0);
	SIGNAL din : STD_LOGIC_VECTOR(DWIDTH - 1 DOWNTO 0);
	SIGNAL dout : STD_LOGIC_VECTOR(DWIDTH - 1 DOWNTO 0);

	TYPE prepare_psums_state_type IS (WAIT_STATE, STATIONARY, FINISHED);
	SIGNAL prepare_psums_state, prepare_psums_state_nxt : prepare_psums_state_type;
	SIGNAL out_buffer_nxt : psum_array;
	SIGNAL psums_reg_in_nxt, psums_reg_in : psum_array;
	SIGNAL write_out_counter, write_out_counter_nxt : NATURAL;
	--used for waiting until the output is valid (i.e. as dictated by in address)
	CONSTANT MEM_DELAY : NATURAL := 2;
	SIGNAL wait_counter, wait_counter_nxt : NATURAL RANGE 0 TO MEM_DELAY;
	SIGNAL valid_ofm_nxt, valid_ofm : STD_LOGIC;

BEGIN

	sync : PROCESS (clk, reset)
	BEGIN
		IF reset = '0' THEN
			wait_counter <= 0;
			prepare_psums_state <= WAIT_STATE;
			out_buffer <= (OTHERS => (OTHERS => (OTHERS => '0')));
			wait_counter <= 0;
			psums_reg_in <= (OTHERS => (OTHERS => (OTHERS => '0')));
			write_out_counter <= 0;
			valid_ofm <= '0';
		ELSIF rising_edge(clk) THEN
			wait_counter <= wait_counter_nxt;
			prepare_psums_state <= prepare_psums_state_nxt;
			out_buffer <= out_buffer_nxt;
			wait_counter <= wait_counter_nxt;
			psums_reg_in <= psums_reg_in_nxt;
			write_out_counter <= write_out_counter_nxt;
			valid_ofm <= valid_ofm_nxt;
		END IF;
	END PROCESS;

	rams_sdp_record_i : ENTITY work.rams_sdp_record
		GENERIC MAP(
			A_WID => A_WIDTH,
			D_WID => DWIDTH,
			DEPTH => DEPTH
		)
		PORT MAP(
			clk => clk,
			we => we,
			ena => ena,
			raddr => raddr,
			waddr => waddr,
			din => din,
			dout => dout
		);

	state : PROCESS (ALL)
	BEGIN
		ena <= '1';
		we <= '0';

		din <= (OTHERS => '0');
		out_buffer_nxt <= out_buffer;
		prepare_psums_state_nxt <= prepare_psums_state;
		wait_counter_nxt <= 0;
		psums_reg_in_nxt <= psums_reg_in;
		psums_ready <= '0';
		finished_writing_ofm <= '0';
		ofms_out.valid <= valid_ofm;
		ofms_out.data <= (OTHERS => '0');
		write_out_counter_nxt <= 0;
		raddr <= (OTHERS => '0');
		valid_ofm_nxt <= '0';
		waddr <= (OTHERS => '0');

		CASE(mode) IS

			WHEN FETCH_PSUMS =>
			psums_reg_in_nxt <= psum_values_in;

			WHEN WRITE_OUT_PSUMS =>

			raddr <= STD_LOGIC_VECTOR(to_unsigned(write_out_counter, raddr'length));
			write_out_counter_nxt <= write_out_counter + 1;
			valid_ofm_nxt <= '1';
			IF write_out_counter > 0 THEN
				ofms_out.data <= dout;
				valid_ofm_nxt <= '1';
			ELSE
				ofms_out.valid <= '0';
			END IF;
			IF write_out_counter > DEPTH - 1 THEN
				raddr <= STD_LOGIC_VECTOR(to_unsigned(0, raddr'length));
				valid_ofm_nxt <= '0';
			END IF;
			IF write_out_counter = DEPTH + MEM_DELAY + 1 THEN
				write_out_counter_nxt <= 0;
				finished_writing_ofm <= '1';
			END IF;

			WHEN PREPARE_PSUMS =>

			raddr <= STD_LOGIC_VECTOR(to_unsigned(address.y * IFMAP_SIZE/PE_COLUMNS + address.x, raddr'length));
			waddr <= STD_LOGIC_VECTOR(to_unsigned(address_prev.y * IFMAP_SIZE/PE_COLUMNS + address_prev.x, waddr'length));

			-- write the psum reg that has first been fetched back to memory
			FOR ofm IN 0 TO PARALLEL_OFMS - 1 LOOP
				we <= '1';
				FOR I IN 0 TO PE_COLUMNS - 1 LOOP
					din(((ofm * PE_COLUMNS + I) + 1) * ACC_DATA_WIDTH - 1 DOWNTO (ofm * PE_COLUMNS + I) * ACC_DATA_WIDTH) <= STD_LOGIC_VECTOR(signed(psums_reg_in(ofm, I)));
				END LOOP;
			END LOOP;

			CASE (prepare_psums_state) IS
				WHEN WAIT_STATE =>

					IF wait_counter = MEM_DELAY THEN
						prepare_psums_state_nxt <= STATIONARY;
						wait_counter_nxt <= 0;
					ELSE
						wait_counter_nxt <= wait_counter + 1;
					END IF;

				WHEN STATIONARY =>
					IF first_pass = '1' THEN
						out_buffer_nxt <= (OTHERS => (OTHERS => (OTHERS => '0')));
					ELSE
						FOR ofm IN 0 TO PARALLEL_OFMS - 1 LOOP
							FOR x IN 0 TO PE_COLUMNS - 1 LOOP
								out_buffer_nxt(ofm, x) <= signed(dout(((ofm * PE_COLUMNS + x) + 1) * ACC_DATA_WIDTH - 1 DOWNTO (ofm * PE_COLUMNS + x) * ACC_DATA_WIDTH));
							END LOOP;
						END LOOP;
					END IF;
					prepare_psums_state_nxt <= FINISHED;
				WHEN FINISHED =>
					psums_ready <= '1';
					wait_counter_nxt <= 0;
			END CASE;

			WHEN WRITE_BACK =>

			WHEN CLEAN =>
			write_out_counter_nxt <= 0;
			prepare_psums_state_nxt <= WAIT_STATE;
			wait_counter_nxt <= 0;
		END CASE;
	END PROCESS;

END ARCHITECTURE;