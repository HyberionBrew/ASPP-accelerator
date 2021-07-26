LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.core_pck.ALL;
USE work.pe_pack.ALL;

PACKAGE fetch_unit_pck IS
	TYPE state_type IS (LOADING_VALUES, PROCESSING);

	PROCEDURE mask_last (VARIABLE bitvec_var : INOUT STD_LOGIC_VECTOR(COMPARISON_BITVEC_WIDTH - 1 DOWNTO 0);
	VARIABLE index_var : OUT NATURAL RANGE 0 TO COMPARISON_BITVEC_WIDTH - 1;
	VARIABLE valid_var : OUT STD_LOGIC);
END PACKAGE;
PACKAGE BODY fetch_unit_pck IS

	PROCEDURE mask_last (VARIABLE bitvec_var : INOUT STD_LOGIC_VECTOR(COMPARISON_BITVEC_WIDTH - 1 DOWNTO 0);
	VARIABLE index_var : OUT NATURAL RANGE 0 TO COMPARISON_BITVEC_WIDTH - 1;
	VARIABLE valid_var : OUT STD_LOGIC) IS
BEGIN
	valid_var := '0';
	index_var := COMPARISON_BITVEC_WIDTH - 1;
	FOR I IN bitvec_var'low TO bitvec_var'high LOOP
		IF bitvec_var(I) = '1' THEN
			valid_var := '1';
			index_var := I;
			--bitvec_var(I) := '0';
			EXIT;
		END IF;
	END LOOP;

END PROCEDURE;
END PACKAGE BODY;