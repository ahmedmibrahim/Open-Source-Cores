-- uart_rxtx_tb
-- 1. Import those libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ADD: entity uart_rxtx_tb (without ports)
entity uart_rxtx_tb is
-- empty
end uart_rxtx_tb; 

-- ADD: architecture of uart_rxtx_tb (stimulating and output test signals and the DUT)
architecture tb of uart_rxtx_tb is
  -- 100 MHz = 10 nanoseconds period
  constant c_CLOCK_PERIOD : time := 10 ns;
  constant c_CLKS_PER_BIT : natural := 3;
  
  signal i_Clk_test         : std_logic := '0';
  signal i_Parity_En_test   : std_logic := '0';
  signal o_Tx_Serial_test   : std_logic := '1';

  signal i_TX_Drive_test    : std_logic := '0';
  signal i_Tx_Byte_test     : std_logic_vector(7 downto 0) := x"6A";
  signal o_Tx_Done_test     : std_logic := '0';

  signal o_Rx_Byte_test     : std_logic_vector(7 downto 0) := (others => '0');
  signal o_Parity_True_test : std_logic := '0';
  signal o_Rx_Done_test     : std_logic := '0';

-- 2. Describe your Component (Design entity)
component UART_RX is
  port (
    i_Clk         : in  std_logic;                    -- <signal_name> : <direction> <type>; 
    i_Parity_En   : in  std_logic;
    i_Rx_Serial   : in  std_logic;
    o_Rx_Byte     : out std_logic_vector(7 downto 0);
    o_Parity_True : out std_logic;
    o_Rx_Done     : out std_logic
  );
end component;

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
  DUT_TX: UART_TX port map(i_Clk_test, i_TX_Drive_test, i_Parity_En_test, i_Tx_Byte_test, o_Tx_Serial_test, o_Tx_Done_test);
  DUT_RX: UART_RX port map(i_Clk_test, i_Parity_En_test, o_Tx_Serial_test, o_Rx_Byte_test, o_Parity_True_test, o_Rx_Done_test);

  -- Clock Generator (1/c_CLOCK_PERIOD Hz)
  p_CLK_GEN : process is
  begin
    wait for c_CLOCK_PERIOD/2;
    i_Clk_test <= not i_Clk_test;
  end process p_CLK_GEN; 

  p_TX_SERIAL_DATA : process is
  begin
    -- Parity Disabled
    i_Parity_En_test <= '1';

    -- Give TX_Drive Pulse
    i_TX_Drive_test <= '1';
    wait for c_CLOCK_PERIOD*(c_CLKS_PER_BIT)*1;
    i_TX_Drive_test <= '0';

    -- wait till byte transmission is done before you send the next byte
    wait until rising_edge(o_Tx_Done_test);

    -- Check that the correct command was received
    if o_Rx_Byte_test = i_Tx_Byte_test then
      report "Test Passed - Correct Byte Received" severity note;
    else
      report "Test Failed - Incorrect Byte Received" severity note;
    end if;

    i_Tx_Byte_test(7 downto 0) <= x"43";

  end process p_TX_SERIAL_DATA; 

end tb;
