LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

USE ieee.numeric_std.ALL;
USE work.core_pck.ALL;
USE work.control_pck.ALL;
USE work.top_types_pck.ALL;
USE IEEE.math_real.ALL;

ENTITY in_unit IS
	GENERIC (
		PARALLEL_OFMS : NATURAL := 3;
		MAX_OFMS : NATURAL := 255;
		MAX_RATE : NATURAL := 3;
		PE_COLUMNS : NATURAL := 3;
		FILTER_DEPTH : NATURAL := 1
	);
	PORT (
		clk : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		in_unit_to_ctrl : OUT in_unit_to_ctrl_type;
		ctrl_to_in: IN ctrl_to_in_type
	);
END ENTITY;

ARCHITECTURE arch OF in_unit IS
	CONSTANT DEPTH_IFMAP : NATURAL := INTEGER((real(FILTER_DEPTH * IFMAP_SIZE * IFMAP_SIZE * 72 * 8/(288 * 2))));
	CONSTANT ADDRW_IFMAP : NATURAL := INTEGER(ceil(log2(real(FILTER_DEPTH * IFMAP_SIZE * IFMAP_SIZE * 72 * 8/(288 * 2)))));
	CONSTANT DEPTH_KERNEL : NATURAL := MAX_OFMS * FILTER_DEPTH * 9;
	CONSTANT ADDRW_KERNEL : NATURAL := INTEGER(ceil(log2(real(DEPTH_KERNEL))));
	--the state of the ifmap buffer
	TYPE state_buffer_t IS (IDLE, STATIONARY, OUTS, FINISHED);
	SIGNAL state_ifmap, state_ifmap_nxt : state_buffer_t;
	--the state of the kernel buffer
	SIGNAL state_kernel, state_kernel_nxt : state_buffer_t;
	--current read addr of ifmap/kernel
	SIGNAL addr_ifmap, addr_ifmap_nxt : NATURAL RANGE 0 TO DEPTH_IFMAP - 1;
	SIGNAL addr_kernel, addr_kernel_nxt : NATURAL RANGE 0 TO DEPTH_KERNEL - 1;

	SIGNAL kernel_ofm_counter, kernel_ofm_counter_nxt : NATURAL RANGE 0 TO PARALLEL_OFMS - 1 + 1;
	-- ifmap and kernel values
	SIGNAL ifmap : STD_LOGIC_VECTOR(72 * 8 - 1 DOWNTO 0);
	SIGNAL kernel : STD_LOGIC_VECTOR(512 - 1 DOWNTO 0);
	-- before providing new kernel values wait at least 100 cycles (could also be implemented by simply detecting edge)
	-- 100 is ecessive it need only be ~2, however after kernel update it takes at least >1000 cycles until new ones are needed 
	SIGNAL wait_counter, wait_counter_nxt : NATURAL RANGE 0 TO 100;
	TYPE deb_t IS ARRAY(0 TO 36 - 1) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL debug_ifmap : deb_t;
BEGIN

	debug : PROCESS (ALL)
	BEGIN
		FOR I IN 0 TO 36 - 1 LOOP
			debug_ifmap(I) <= ifmap(DATA_WIDTH * (36 - I) - 1 DOWNTO DATA_WIDTH * (36 - 1 - I));
		END LOOP;

	END PROCESS;
	sync : PROCESS (clk, reset)
	BEGIN
		IF reset = '0' THEN
			state_ifmap <= IDLE;
			state_kernel <= IDLE;
			addr_ifmap <= 0;
			addr_kernel <= 0;
			wait_counter <= 0;
			kernel_ofm_counter <= 0;
		ELSIF rising_edge(clk) THEN
			state_ifmap <= state_ifmap_nxt;
			state_kernel <= state_kernel_nxt;
			addr_ifmap <= addr_ifmap_nxt;
			addr_kernel <= addr_kernel_nxt;
			kernel_ofm_counter <= kernel_ofm_counter_nxt;
			wait_counter <= wait_counter_nxt;
		END IF;

	END PROCESS;

	ifmap_out : PROCESS (ALL)
	BEGIN
		addr_ifmap_nxt <= 0;
		in_unit_to_ctrl.ifmap_values.valid <= '0';
		in_unit_to_ctrl.ifmap_values.data <= (OTHERS => '0');
		state_ifmap_nxt <= state_ifmap;
		in_unit_to_ctrl.ifmaps_loaded <= '0';
		CASE(state_ifmap) IS

			WHEN IDLE =>
			IF ctrl_to_in.load_ifmaps = '1' THEN
				state_ifmap_nxt <= STATIONARY;
				addr_ifmap_nxt <= 1;
			END IF;

			WHEN STATIONARY =>
			state_ifmap_nxt <= STATIONARY;
			FOR I IN 0 TO 72 - 1 LOOP
				in_unit_to_ctrl.ifmap_values.data((I + 1) * DATA_WIDTH - 1 DOWNTO DATA_WIDTH * I) <= ifmap((72 - I) * DATA_WIDTH - 1 DOWNTO DATA_WIDTH * (72 - 1 - I));
			END LOOP;
			in_unit_to_ctrl.ifmap_values.valid <= '1';
			IF addr_ifmap = DEPTH_IFMAP - 1 THEN
				addr_ifmap_nxt <= 0;
				state_ifmap_nxt <= OUTS;
			ELSE
				addr_ifmap_nxt <= addr_ifmap + 1;
			END IF;
			WHEN OUTS =>
			FOR I IN 0 TO 72 - 1 LOOP
				in_unit_to_ctrl.ifmap_values.data((I + 1) * DATA_WIDTH - 1 DOWNTO DATA_WIDTH * I) <= ifmap((72 - I) * DATA_WIDTH - 1 DOWNTO DATA_WIDTH * (72 - 1 - I));
			END LOOP;
			in_unit_to_ctrl.ifmap_values.valid <= '1';
			state_ifmap_nxt <= FINISHED;

			WHEN FINISHED =>
			in_unit_to_ctrl.ifmaps_loaded <= '1';
			in_unit_to_ctrl.ifmap_values.valid <= '0';
		END CASE;
	END PROCESS;
	kernel_out : PROCESS (ALL)
	BEGIN
		state_kernel_nxt <= state_kernel;
		addr_kernel_nxt <= addr_kernel;
		kernel_ofm_counter_nxt <= 0;
		in_unit_to_ctrl.new_kernels <= (OTHERS => '0');
		in_unit_to_ctrl.kernels_loaded <= '0';
		wait_counter_nxt <= wait_counter;
		in_unit_to_ctrl.kernel_values <= (OTHERS => (OTHERS => '-'));
		CASE (state_kernel) IS
			WHEN IDLE =>
				IF ctrl_to_in.load_kernels = '1' THEN
					IF PARALLEL_OFMS = 1 THEN
						state_kernel_nxt <= OUTS;
					ELSE
						state_kernel_nxt <= STATIONARY;
						IF addr_kernel = DEPTH_KERNEL - 1 THEN
							addr_kernel_nxt <= 0;
							kernel_ofm_counter_nxt <= 0;
						ELSE
							addr_kernel_nxt <= addr_kernel + 1;
							kernel_ofm_counter_nxt <= 0;
						END IF;
					END IF;
				END IF;
			WHEN STATIONARY =>
				in_unit_to_ctrl.new_kernels(kernel_ofm_counter) <= '1';
				kernel_ofm_counter_nxt <= kernel_ofm_counter + 1;
				FOR I IN 0 TO 64 - 1 LOOP
					in_unit_to_ctrl.kernel_values(I) <= signed(kernel(DATA_WIDTH * (64 - I) - 1 DOWNTO DATA_WIDTH * (63 - I)));
				END LOOP;
				IF kernel_ofm_counter = PARALLEL_OFMS - 2 THEN
					state_kernel_nxt <= OUTS;
				ELSE
					IF addr_kernel = DEPTH_KERNEL - 1 THEN
						addr_kernel_nxt <= 0;
					ELSE
						addr_kernel_nxt <= addr_kernel + 1;

					END IF;
				END IF;
			WHEN OUTS =>
				FOR I IN 0 TO 64 - 1 LOOP
					in_unit_to_ctrl.new_kernels(PARALLEL_OFMS - 1) <= '1';
					in_unit_to_ctrl.kernel_values(I) <= signed(kernel(DATA_WIDTH * (64 - I) - 1 DOWNTO DATA_WIDTH * (63 - I)));
				END LOOP;
				state_kernel_nxt <= FINISHED;
				IF addr_kernel = DEPTH_KERNEL - 1 THEN
					addr_kernel_nxt <= 0;
				ELSE
					addr_kernel_nxt <= addr_kernel + 1;

				END IF;

			WHEN FINISHED =>
				in_unit_to_ctrl.kernels_loaded <= '1';

				IF wait_counter = 50 THEN
					wait_counter_nxt <= 0;
					state_kernel_nxt <= IDLE;
				ELSE
					wait_counter_nxt <= wait_counter + 1;
				END IF;
		END CASE;

	END PROCESS;
	ifmap_mem : ENTITY work.rams_init_file
		GENERIC MAP(
			FILENAME => "ifmaps_mem.data",
			ADDRW => ADDRW_IFMAP,
			DATAW => 72 * 8,
			DEPTH => DEPTH_IFMAP
		)
		PORT MAP(
			clk => clk,
			addr => STD_LOGIC_VECTOR(to_unsigned(addr_ifmap, ADDRW_IFMAP)),
			dout => ifmap
		);
	kernel_mem : ENTITY work.rams_init_file
		GENERIC MAP(
			FILENAME => "kernels_mem.data",
			ADDRW => ADDRW_KERNEL,
			DATAW => 64 * 8,
			DEPTH => DEPTH_KERNEL
		)
		PORT MAP(
			clk => clk,
			addr => STD_LOGIC_VECTOR(to_unsigned(addr_kernel, ADDRW_KERNEL)),
			dout => kernel
		);
END ARCHITECTURE;