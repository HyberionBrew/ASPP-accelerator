LIBRARY ieee;
USE ieee.std_logic_1164.ALL; --do I need this?
USE ieee.numeric_std.ALL;

USE work.core_pck.ALL;
USE work.control_pck.ALL;

PACKAGE state_calc_pkg IS
	PROCEDURE start_end_point_calc(VARIABLE kernel : IN NATURAL RANGE 0 TO 8;
	SIGNAL rate : IN NATURAL RANGE 1 TO 3;
	VARIABLE start_point, end_point : OUT point);
END PACKAGE;

PACKAGE BODY state_calc_pkg IS
	PROCEDURE start_end_point_calc(VARIABLE kernel : IN NATURAL RANGE 0 TO 8;
	SIGNAL rate : IN NATURAL RANGE 1 TO 3;
	VARIABLE start_point, end_point : OUT point) IS

BEGIN
	IF kernel MOD 3 = 0 THEN
		start_point.x := 0;
		end_point.x := IFMAP_SIZE/PE_COLUMNS - 1 - rate * (DILATION_RATE/PE_COLUMNS);
	ELSIF kernel MOD 3 = 1 THEN
		start_point.x := 0;
		end_point.x := IFMAP_SIZE/PE_COLUMNS - 1;
	ELSE
		start_point.x := rate * (DILATION_RATE/PE_COLUMNS);
		end_point.x := IFMAP_SIZE/PE_COLUMNS - 1;
	END IF;

	IF kernel < 3 THEN
		start_point.y := 0;
		end_point.y := IFMAP_SIZE - 1 - rate * DILATION_RATE;
	ELSIF kernel < 6 THEN
		start_point.y := 0;
		end_point.y := IFMAP_SIZE - 1;
	ELSE
		start_point.y := rate * DILATION_RATE;
		end_point.y := IFMAP_SIZE - 1;
	END IF;
END PROCEDURE;

END PACKAGE BODY;