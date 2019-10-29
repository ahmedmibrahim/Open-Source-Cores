-- uart_tx_rx_tb
-- Purpose:          Testbench for UART_TX_RX Module
-- Author:           Ahmed Ibrahim
-- Last Updated on:  October 29th, 2019
-- License:          Open Source, No License Required

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
  constant c_CLOCK_PERIOD 	 : time := 10 ns;
  constant c_CLKS_PER_BIT 	 : natural := 3;
  
  signal i_Clk_test         : std_logic := '0';       -- Test Signal for i_Clk input
  
  signal i_Parity_En_test   : std_logic := '0';       -- Test Signal for i_Parity_En input
  signal o_Parity_True_test : std_logic := '0';       -- Test Signal for o_Parity_True input
  
  signal i_TX_Drive_test    : std_logic := '0';       -- Test Signal for i_TX_Drive input
  
  signal i_Tx_Byte_test     : std_logic_vector(7 downto 0) := x"6A";           -- Test Signal for i_Tx_Byte input
  signal o_Rx_Byte_test     : std_logic_vector(7 downto 0) := (others => '0'); -- Test Signal for o_Rx_Byte input
  
  signal i_Rx_Serial_test   : std_logic := '1';       -- Test Signal for i_Rx_Serial input
  signal o_Tx_Serial_test   : std_logic := '1';       -- Test Signal for o_Tx_Serial input

  signal o_Tx_Done_test     : std_logic := '0';       -- Test Signal for o_Tx_Done input
  signal o_Rx_Done_test     : std_logic := '0';       -- Test Signal for o_Rx_Done input

-- 2. Describe your Component (Design entity)
component UART_TXRX is
  port (
	 i_Clk         : in  std_logic;                    -- Input Clock Signal for TX & RX Submodules
    
	 i_Parity_En   : in  std_logic;                    -- Enable/Disable Parity Bit Transmission/Reception
    o_Parity_True : out std_logic;                    -- RX Submodule's flag: Received Parity bit is correct
    
	 i_TX_Drive    : in  std_logic;                    -- TX Submodule drive signal (Start transmission)
    
	 i_Tx_Byte     : in  std_logic_vector(7 downto 0); -- Input Byte to be transmitted on the TX serial line
  	 o_Rx_Byte     : out std_logic_vector(7 downto 0); -- Output Byte reveived at the RX serial line
	 
    i_Rx_Serial   : in  std_logic;                    -- Serial input to the receiver
    o_Tx_Serial   : out std_logic;                    -- serial output of the transmitter
    
	 o_Tx_Done     : out std_logic;                    -- Done Flag for UART TX
	 o_Rx_Done     : out std_logic                     -- Done Flag for UART RX
  );
end component;

-- 3. The test itself
begin
  -- Connect DUT to Stimulating and output test signals
  DUT_TXRX: UART_TXRX 
  port map(
	  i_Clk_test, 
	  i_Parity_En_test, o_Parity_True_test, 
 	  i_TX_Drive_test, 
	  i_Tx_Byte_test, o_Rx_Byte_test,
	  i_Rx_Serial_test, o_Tx_Serial_test, 
	  o_Tx_Done_test, o_Rx_Done_test
  );
  
  -- Loopback UART
  i_Rx_Serial_test <= o_Tx_Serial_test;
  

  -- Clock Generator (1/c_CLOCK_PERIOD Hz)
  p_CLK_GEN : process is
  begin
    wait for c_CLOCK_PERIOD/2;
    i_Clk_test <= not i_Clk_test;
  end process p_CLK_GEN; 

  p_TX_SERIAL_DATA : process is
  begin
 
    -- Parity Enabled/Disabled
    i_Parity_En_test <= '0';

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
