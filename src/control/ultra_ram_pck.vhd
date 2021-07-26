library ieee;
use ieee.std_logic_1164.all; 

use ieee.numeric_std.all;


package ultra_ram_pck is
  component xilinx_ultraram_true_dual_port_byte_write
  generic (
           AWIDTH : integer := 12;  -- Address Width
           DWIDTH : integer := 72;  -- Data Width
           NUM_COL : integer := 9;  -- Number of columns
           NBPIPE : integer := 3;    -- Number of pipeline Registers
           DEPTH : integer := 32
          );
  port    (
           clk : in std_logic;                                  -- Clock

           rsta : in std_logic;                                  -- Reset
           wea : in std_logic_vector(NUM_COL-1 downto 0);        -- Write Enable
           regcea : in std_logic;                                -- Output Register Enable
           mem_ena : in std_logic;                               -- Memory Enable
           dina : in std_logic_vector(DWIDTH-1 downto 0);        -- Data Input
           addra : in std_logic_vector(AWIDTH-1 downto 0);       -- Address Input
           douta : out std_logic_vector(DWIDTH-1 downto 0);       -- Data Output

           rstb : in std_logic;                                  -- Reset
           web : in std_logic_vector(NUM_COL-1 downto 0);        -- Write Enable
           regceb : in std_logic;                                -- Output Register Enable
           mem_enb : in std_logic;                               -- Memory Enable
           dinb : in std_logic_vector(DWIDTH-1 downto 0);        -- Data Input
           addrb : in std_logic_vector(AWIDTH-1 downto 0);       -- Address Input
           doutb : out std_logic_vector(DWIDTH-1 downto 0)       -- Data Output

          );
        end component;

end package;