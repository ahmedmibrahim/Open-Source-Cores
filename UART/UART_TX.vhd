-- UART_TX
-- Purpose:          Testbench for UART_TX Module
-- Author:           Ahmed Ibrahim
-- Last Updated on:  October 29th, 2019
-- License:          Open Source, No License Required

-- 1. Import those libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 2. Describe your entity IOs
entity UART_TX is
  port (

  --                                |--------|						
  --                    i_TX_Byte   |        |						
  --              --------/-------->|   TX   |---> o_TX_Serial------>
  --                                | Module |						
  --                                |        |						
  --              <-----o_TX_Done<--|--------|						
  --                                  ^   ^							
  --              ---------i_clk------|   |							
  --              ------i_Parity_En-------|							
 
	 i_Clk         : in  std_logic;                    -- Input Clock Signal
	 i_TX_Drive    : in  std_logic;                    -- TX drive signal (Start transmission)
	 i_Parity_En   : in  std_logic;                    -- Enable/Disable Parity Bit
	 i_Tx_Byte     : in  std_logic_vector(7 downto 0); -- Input Byte to be transmitted on the TX serial line
	 o_Tx_Serial   : out std_logic;                    -- serial output of the transmitter
	 o_Tx_Done     : out std_logic                     -- Done Flag for UART TX
  );
end UART_TX;

-- 3. Describe the architecture (contents of your entity)
architecture rtl of UART_TX is
  -- Define Constants
  constant c_CLKS_PER_BIT : natural := 3;          -- Clock Frequency / Baud Rate

  -- Signal type definition to constract UART_TX state machine
  type t_TX_State_Machine is (s_Idle, s_Start, s_Data, s_Parity, s_Stop);

  -- p_UART_TX Signals
  signal r_TX_State_Machine   : t_TX_State_Machine := s_Idle;
  signal r_Clk_Count 	      : integer range 0 to c_CLKS_PER_BIT-1 := 0;
  signal r_Bit_Index          : integer range 0 to 7 := 0;  					-- 8 Bits Total
  signal r_Tx_Byte            : std_logic_vector(7 downto 0) := x"00";
  signal r_TX_Done            : std_logic := '0';
  signal r_Parity_Even_Count  : std_logic := '0';	

begin
  -- Process "UART_TX", 
  -- Purpose: UART TX state machine
  p_UART_TX : process (i_Clk)
  begin
    -- Operate at rising edge
    if rising_edge(i_Clk) then
      -- state machine
      case r_TX_State_Machine is
       -- List all states, signal values of each state, and when transfers should happen in an if else statment

        when s_Idle =>
 	  -- Reset all outputs and counters
          o_TX_Serial   <= '1';  -- Drive Line High for Idle
          r_TX_Done     <= '0';
          r_Clk_Count   <= 0;
          r_Bit_Index   <= 0;

 	  -- Conditions to exit this state
          if i_TX_Drive = '1' then       			-- Drive Signal detected
            r_Tx_Byte <= i_Tx_Byte;					-- Sample Input Byte
            r_TX_State_Machine <= s_Start;
          else
            r_TX_State_Machine <= s_Idle;       -- Otherwise, stay in s_Idle
          end if;
 
        when s_Start =>
	  o_TX_Serial   <= '0';  -- r_TX_Serial <= '0';
          r_Bit_Index   <= 0;
          r_TX_Done     <= '0';
	  -- Check the start bit again to make sure it's still low (to mitigate glitches)
          if r_Clk_Count < (c_CLKS_PER_BIT-1) then
            r_Clk_Count <= r_Clk_Count + 1; 
            r_TX_State_Machine <= s_Start;
          else
            r_Clk_Count <= 0;  						-- reset counter since we found the middle
            r_TX_State_Machine <= s_Data;
          end if;

        when s_Data =>
          o_Tx_Serial   <= r_Tx_Byte(r_Bit_Index);
          r_TX_Done     <= '0';
          if r_Clk_Count < (c_CLKS_PER_BIT-1) then
            r_Clk_Count 	 <= r_Clk_Count + 1;
            r_TX_State_Machine   <= s_Data;
          else
            r_Clk_Count   <= 0;
            if i_Parity_En = '1' then
               -- If the transmitted bit was a '1', adjust the even parity flag
  	       if r_TX_Byte(r_Bit_Index) = '1' then
                  r_Parity_Even_Count <= not r_Parity_Even_Count;
	       else
                  r_Parity_Even_Count <= r_Parity_Even_Count;
               end if;
            else
    	       r_Parity_Even_Count <= '0';
            end if;
            if r_Bit_Index < 7 then
                r_Bit_Index <= r_Bit_Index + 1;
                r_TX_State_Machine   <= s_Data;
            else
                r_Bit_Index <= 0;
                if i_Parity_En = '1' then
      	           r_TX_State_Machine   <= s_Parity;
                else
    	           r_TX_State_Machine   <= s_Stop;
                end if;
            end if;
          end if;

        when s_Parity =>
          o_Tx_Serial <= r_Parity_Even_Count;	          -- o_TX_Serial <= '1' when (r_Parity_Even_Count = '1') else '0';
          r_TX_Done     <= '0';
          if r_Clk_Count < (c_CLKS_PER_BIT-1) then
            r_Clk_Count 	 <= r_Clk_Count + 1;
            r_TX_State_Machine   <= s_Parity;
          else
            r_Clk_Count   <= 0;
	    r_TX_State_Machine   <= s_Stop;
          end if;

        when s_Stop =>
	  o_TX_Serial <= '1';          -- Stop Symbol
          -- Wait c_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if r_Clk_Count < c_CLKS_PER_BIT-1 then
            r_Clk_Count 	<= r_Clk_Count + 1;
            r_TX_State_Machine  <= s_Stop;
          else
            r_TX_Done   <= '1';
            r_Clk_Count <= 0;
            r_TX_State_Machine   <= s_Idle;
          end if;
 
        -- Default case     
        when others =>
          r_TX_State_Machine 	<= s_Idle;
	  r_TX_Done   		<= '0';
	  o_TX_Serial <= '1';   -- Idle

      end case;
    end if;
  end process p_UART_TX;

  -- register the output
  o_TX_Done 	<= r_TX_Done;

end rtl;
