-- UART TXRX
-- Purpose: 			UART_TXRX Top level Module
-- Author: 				Ahmed Ibrahim
--	Last Updated on: 	October 29th, 2019
-- License:				Open Source, No License Required

-- 1. Import those libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 2. Describe your entity IOs
entity UART_TXRX is
  port (

  --                 |-----------------------------------------|
  --                 |              |--------|                 |
  --                 |  i_TX_Byte   |        |                 |
  --              --------/-------->|   TX   |---> o_TX_Serial------>
  --                 |              | Module |                 |
  --                 |              |        |                 |
  --              <-----o_TX_Done<--|--------|                 |
  --                 |                ^   ^                    |
  --              ---------i_clk------|   |                    |
  --              ------i_Parity_En-------|                    |         Outside
  --       Inside    |                |   |                    |          FPGA
  --       FPGA	     |                v   v                    |
  --                 |              |--------|                 |
  --                 |              |        |                 |
  --                 |	o_RX_Byte   |   RX   |<--- i_RX_Serial<------
  --              <-------/---------| Module |                 |
  --                 |              |        |                 |
  --              <-----o_RX_Done<--|--------|                 |
  --                 |-----------------------------------------|
  
  
	 i_Clk         : in  std_logic;                    	-- Input Clock Signal for TX & RX Submodules
    
	 i_Parity_En   : in  std_logic;								-- Enable/Disable Parity Bit Transmission/Reception
    o_Parity_True : out std_logic;								-- RX Submodule's flag: Received Parity bit is correct
    
	 i_TX_Drive    : in  std_logic;								-- TX Submodule drive signal (Start transmission)
    
	 i_Tx_Byte     : in  std_logic_vector(7 downto 0);		-- Input Byte to be transmitted on the TX serial line
  	 o_Rx_Byte     : out std_logic_vector(7 downto 0);		-- Output Byte reveived at the RX serial line
	 
    i_Rx_Serial   : in  std_logic;								-- Serial input to the receiver
    o_Tx_Serial   : out std_logic;								-- serial output of the transmitter
    
	 o_Tx_Done     : out std_logic;							   -- Done Flag for UART TX
	 o_Rx_Done     : out std_logic							   -- Done Flag for UART RX
    );
end UART_TXRX;

-- 3. Describe the architecture (contents of your entity)
architecture rtl of UART_TXRX is
  -- Instantiate UART_TX and UART_RX Modules
	component UART_RX is
	  port (
		 i_Clk         : in  std_logic;                    -- Input Clock Signal
		 i_Parity_En   : in  std_logic;							-- Enable/Disable Parity Bit
		 i_Rx_Serial   : in  std_logic;							-- Serial input to the receiver
		 o_Rx_Byte     : out std_logic_vector(7 downto 0);	-- Output Byte reveived at the RX serial line
		 o_Parity_True : out std_logic;							-- RX's flag: Received Parity bit is correct
		 o_Rx_Done     : out std_logic							-- Done Flag for UART RX
	  );
	end component;

	component UART_TX is
	  port (
		 i_Clk         : in  std_logic;                    -- Input Clock Signal
		 i_TX_Drive    : in  std_logic;							-- TX drive signal (Start transmission)
		 i_Parity_En   : in  std_logic;							-- Enable/Disable Parity Bit
		 i_Tx_Byte     : in  std_logic_vector(7 downto 0); -- Input Byte to be transmitted on the TX serial line
		 o_Tx_Serial   : out std_logic;							-- serial output of the transmitter
		 o_Tx_Done     : out std_logic							-- Done Flag for UART TX
	  );
	end component;
  
begin
-- Connect Submodules (UART_TX, UART_RX) to Top level (UART_TXRX) IOs
  DUT_RX: UART_RX port map(i_Clk, i_Parity_En, i_Rx_Serial, o_Rx_Byte, o_Parity_True, o_Rx_Done);
  DUT_TX: UART_TX port map(i_Clk, i_TX_Drive, i_Parity_En, i_Tx_Byte, o_Tx_Serial, o_Tx_Done);


end rtl;
