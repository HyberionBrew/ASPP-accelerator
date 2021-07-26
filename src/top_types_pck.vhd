LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.core_pck.ALL;

PACKAGE top_types_pck IS
  TYPE psum_array IS ARRAY(0 TO PARALLEL_OFMS - 1, 0 TO PE_COLUMNS - 1) OF signed(ACC_DATA_WIDTH - 1 DOWNTO 0);
  TYPE iact_values_array IS ARRAY(0 TO FILTER_PER_PE - 1) OF unsigned(DATA_WIDTH - 1 DOWNTO 0);
  TYPE kernel_values_array IS ARRAY(0 TO FILTER_PER_PE - 1) OF signed(DATA_WIDTH - 1 DOWNTO 0);

  TYPE ifmap_DRAM_type IS RECORD
    valid : STD_LOGIC;
    data : STD_LOGIC_VECTOR(72 * 8 - 1 DOWNTO 0);
  END RECORD;

  TYPE ofms_out_type IS RECORD
    data : STD_LOGIC_VECTOR(PARALLEL_OFMS * PE_COLUMNS * ACC_DATA_WIDTH - 1 DOWNTO 0);
    valid : STD_LOGIC;
  END RECORD;
  TYPE from_uart_type IS RECORD
    want_data_ofm : STD_LOGIC;
    want_data_counters : STD_LOGIC;
    ready : STD_LOGIC;
  END RECORD;

  TYPE to_uart_type IS RECORD
    data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    valid : STD_LOGIC;
  END RECORD;

  --just used for determining the utilization
  TYPE mult_counter_array IS ARRAY(0 TO PE_COLUMNS - 1, 0 TO PARALLEL_OFMS - 1) OF unsigned(EXEC_COUNTER_WIDTH - 1 DOWNTO 0);

  TYPE ctrl_to_PEs_type IS RECORD
    new_ifmaps : STD_LOGIC_VECTOR(PE_COLUMNS - 1 DOWNTO 0);
    new_kernels : STD_LOGIC_VECTOR(PARALLEL_OFMS - 1 DOWNTO 0);
    get_psums : STD_LOGIC;
    new_psums : STD_LOGIC;
    new_psum_values : psum_array;
    kernel_values : kernel_values_array;
    ifmap_values : iact_values_array;
  END RECORD;

  TYPE in_unit_to_ctrl_type IS RECORD
    ifmap_values : ifmap_DRAM_type; -- ifmap_values
    ifmaps_loaded : STD_LOGIC; -- all ifmaps have been loaded and are completly written to the ifmap mem
    kernel_values : kernel_values_array; -- values of the kernels
    kernels_loaded : STD_LOGIC; -- all kernels of current position have been provided
    new_kernels : STD_LOGIC_VECTOR(PARALLEL_OFMS - 1 DOWNTO 0); -- what kernels was loaded
  END RECORD;

  TYPE ctrl_to_in_type IS RECORD
    load_ifmaps : STD_LOGIC; -- load ifmaps next
    load_kernels : STD_LOGIC; -- load kernels next
  END RECORD;
  
  
END PACKAGE;