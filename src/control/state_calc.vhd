LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;
USE work.core_pck.ALL;
USE work.control_pck.ALL;
USE work.state_calc_pkg.ALL;

ENTITY state_calc IS
	GENERIC (
		PARALLEL_OFMS : NATURAL := 3;
		MAX_OFMS : NATURAL := 255;
		FILTER_DEPTH : NATURAL := 32;
		FILTER_VALUES : NATURAL := 64;
		MAX_RATE : NATURAL := 3
	);
	PORT (
		clk, reset : IN STD_LOGIC;
		new_ifmaps : IN STD_LOGIC;
		need_kernel : OUT STD_LOGIC;
		first_pass : OUT STD_LOGIC;
		write_out_ofms_out : OUT STD_LOGIC;
		ifmap_position : OUT ifmap_position_type;
		psums_position : OUT point;
		psums_position_prev : OUT point;
		psum_prev_address, finished : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF state_calc IS

	--the calculated ifmap/psums positions
	SIGNAL ifmap_position_nxt, ifmap_position_prev_nxt : ifmap_position_type;
	SIGNAL psums_position_prev_nxt, psums_position_curr, psums_position_curr_nxt : point;
	--detect if new ifmap has been writen i.e. advance state
	SIGNAL new_ifmaps_reg, new_ifmaps_reg_nxt, finished_nxt, need_kernel_nxt : STD_LOGIC;
	--rate multiplier, only 1 currently supported
	SIGNAL rate, rate_nxt : NATURAL RANGE 1 TO 3;
	--the kernel position
	SIGNAL kernel, kernel_nxt : NATURAL RANGE 0 TO 8;
	--the ofm position
	SIGNAL ofm, ofm_nxt : NATURAL RANGE 0 TO MAX_OFMS - 1 + PARALLEL_OFMS;
	SIGNAL first_pass_nxt : STD_LOGIC;
	SIGNAL write_out_ofms_nxt, write_out_ofms : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL finished_curr, finished_curr_nxt : STD_LOGIC;
	SIGNAL write_out_ofms_reg : STD_LOGIC;
BEGIN
	sync : PROCESS (clk, reset)
	BEGIN
		IF reset = '0' THEN
			rate <= 1;
			kernel <= 4;
			ifmap_position.x <= 0;
			ifmap_position.y <= 0;
			ifmap_position.depth_pos <= 0;
			ofm <= 0;
			finished <= '0';
			need_kernel <= '1';
			first_pass <= '1';
			psums_position_prev <= (0, 0);
			psums_position_curr <= (0, 0);
			write_out_ofms <= (OTHERS => '0');
			finished_curr <= '0';
		ELSIF rising_edge(clk) THEN
			ifmap_position <= ifmap_position_nxt;
			new_ifmaps_reg <= new_ifmaps_reg_nxt;
			rate <= rate_nxt;
			first_pass <= first_pass_nxt;
			kernel <= kernel_nxt;
			ofm <= ofm_nxt;
			finished <= finished_nxt;
			need_kernel <= need_kernel_nxt;
			psums_position_curr <= psums_position_curr_nxt;
			psums_position_prev <= psums_position_prev_nxt;
			write_out_ofms <= write_out_ofms_nxt;
			finished_curr <= finished_curr_nxt;
			write_out_ofms_reg <= write_out_ofms_out;
		END IF;
	END PROCESS;

	psums_pos : PROCESS (ALL)
	BEGIN
		psums_position_prev_nxt <= psums_position_prev;
		psums_position.x <= ifmap_position.x;
		psums_position.y <= ifmap_position.y;
		finished_nxt <= finished;
		write_out_ofms_out <= write_out_ofms_reg;
		psums_position_curr_nxt <= psums_position_curr;

		IF kernel MOD 3 = 0 THEN
			psums_position.x <= ifmap_position.x + rate * DILATION_RATE/PE_COLUMNS;
		ELSIF kernel MOD 3 = 2 THEN
			psums_position.x <= ifmap_position.x - rate * DILATION_RATE/PE_COLUMNS;
		END IF;

		IF kernel < 3 THEN
			psums_position.y <= ifmap_position.y + rate * DILATION_RATE;
		ELSIF kernel > 5 THEN
			psums_position.y <= ifmap_position.y - rate * DILATION_RATE;
		END IF;
		IF new_ifmaps = '1' AND new_ifmaps_reg = '0' THEN
			psums_position_curr_nxt <= psums_position;
			write_out_ofms_out <= write_out_ofms(1);
			finished_nxt <= finished_curr;
		END IF;
		IF new_ifmaps = '1' AND new_ifmaps_reg = '0' THEN
			psums_position_prev_nxt <= psums_position_curr;
		END IF;
	END PROCESS;

	state : PROCESS (ALL)
		VARIABLE start_point, end_point : point;
		VARIABLE kernel_var : NATURAL RANGE 0 TO 8;
	BEGIN
		ifmap_position_nxt <= ifmap_position;
		rate_nxt <= rate;
		finished_curr_nxt <= finished_curr;

		kernel_nxt <= kernel;
		ifmap_position_nxt.x <= ifmap_position.x;
		ifmap_position_nxt.y <= ifmap_position.y;
		kernel_var := kernel;
		new_ifmaps_reg_nxt <= new_ifmaps;
		need_kernel_nxt <= need_kernel;

		first_pass_nxt <= first_pass;
		write_out_ofms_nxt(1) <= write_out_ofms(1);
		ofm_nxt <= ofm;
		IF new_ifmaps = '1' AND new_ifmaps_reg = '0' THEN
			write_out_ofms_nxt(1) <= '0';
			--calc new ifmap_address
			need_kernel_nxt <= '0';
			start_end_point_calc(kernel_var, rate, start_point, end_point);
			IF end_point.x = ifmap_position.x THEN
				IF end_point.y = ifmap_position.y THEN
					ifmap_position_nxt.x <= start_point.x;
					ifmap_position_nxt.y <= start_point.y;
					need_kernel_nxt <= '1';
					first_pass_nxt <= '0';
					IF kernel = 3 THEN --completly reset the ifmap
						ifmap_position_nxt.x <= 0;
						ifmap_position_nxt.y <= 0;
						kernel_nxt <= 4;
						IF ifmap_position.depth_pos = FILTER_DEPTH - 1 THEN
							write_out_ofms_nxt(1) <= '1';
							ifmap_position_nxt.depth_pos <= 0;
							first_pass_nxt <= '1';
							IF ofm + PARALLEL_OFMS > MAX_OFMS - 1 THEN

								IF rate = MAX_RATE THEN
									finished_curr_nxt <= '1';

								ELSE
									rate_nxt <= rate + 1;
									ofm_nxt <= 0;
								END IF;
							ELSE
								ofm_nxt <= ofm + PARALLEL_OFMS;
							END IF;
						ELSE
							ifmap_position_nxt.depth_pos <= ifmap_position.depth_pos + 1;
						END IF;
					ELSE
						IF kernel_var = 8 THEN
							kernel_var := 0;
						ELSE
							kernel_var := kernel_var + 1;
						END IF;

						start_end_point_calc(kernel_var, rate, start_point, end_point);
						ifmap_position_nxt.x <= start_point.x;
						ifmap_position_nxt.y <= start_point.y;
						kernel_nxt <= kernel_var;

					END IF;
				ELSE
					ifmap_position_nxt.x <= start_point.x;
					ifmap_position_nxt.y <= ifmap_position.y + 1;
				END IF;
			ELSE
				ifmap_position_nxt.x <= ifmap_position.x + 1;
			END IF;
		END IF;
	END PROCESS;
END ARCHITECTURE;