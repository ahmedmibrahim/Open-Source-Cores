-- uart_tx_tb
-- 1. Import those libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ADD: entity uart_tx_tb (without ports)
entity uart_tx_tb is
-- empty
end uart_tx_tb; 

-- ADD: architecture of uart_tx_tb (stimulating and output test signals and the DUT)
architecture tb of uart_tx_tb is
  -- 100 MHz = 10 nanoseconds period
  constant c_CLOCK_PERIOD : time := 10 ns;
  constant c_CLKS_PER_BIT : natural := 3;
  
  signal i_Clk_test         : std_logic := '0';
  signal i_TX_Drive_test    : std_logic := '0';
  signal i_Parity_En_test   : std_logic := '0';
  signal i_Tx_Byte_test     : std_logic_vector(7 downto 0) := x"A6";
  signal o_Tx_Serial_test   : std_logic := '1';
  signal o_Tx_Done_test     : std_logic := '0';

-- 2. Describe your Component (Design entity)
component UART_TX is
  port (
    i_Clk         : in  std_logic;                    -- <signal_name> : <direction> <type>; 
    i_TX_Drive    : in  std_logic;
    i_Parity_En   : in  std_logic;
    i_Tx_Byte     : in std_logic_vector(7 downto 0);
    o_Tx_Serial   : out std_logic;
    o_Tx_Done     : out std_logic
  );
end component;

-- 3. The test itself
begin
  -- Connect DUT to Stimulating and output test signals
  DUT: UART_TX port map(i_Clk_test, i_TX_Drive_test, i_Parity_En_test, i_Tx_Byte_test, o_Tx_Serial_test, o_Tx_Done_test);

  -- Clock Generator (1/c_CLOCK_PERIOD Hz)
  p_CLK_GEN : process is
  begin
    wait for c_CLOCK_PERIOD/2;
    i_Clk_test <= not i_Clk_test;
  end process p_CLK_GEN; 

  p_TX_SERIAL_DATA : process is
  begin
    -- Parity Disabled
    i_Parity_En_test <= '0';
    wait for c_CLOCK_PERIOD*(c_CLKS_PER_BIT+2);
    i_TX_Drive_test <= '1';
    wait for c_CLOCK_PERIOD*(c_CLKS_PER_BIT)*10;
    -- RESET
    i_TX_Drive_test <= '0';


    -- Parity Disabled
    i_Parity_En_test <= '1';
    wait for c_CLOCK_PERIOD*(c_CLKS_PER_BIT+2);
    i_TX_Drive_test <= '1';
    wait for c_CLOCK_PERIOD*(c_CLKS_PER_BIT)*11;
    -- RESET
    i_TX_Drive_test <= '0';

  end process p_TX_SERIAL_DATA; 

end tb;
