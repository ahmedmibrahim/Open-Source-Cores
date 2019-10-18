-- UART RX
-- 1. Import those libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 2. Describe your entity
entity UART_RX is
  port (
    i_Clk         : in  std_logic;                    -- <signal_name> : <direction> <type>; 
    i_Parity_En   : in  std_logic;
    i_Rx_Serial   : in  std_logic;
    o_Rx_Byte     : out std_logic_vector(7 downto 0);
    o_Parity_True : out std_logic;
    o_Rx_Done     : out std_logic
  );
end UART_RX;

-- 3. Describe the architecture (contents of your entity)
architecture rtl of UART_RX is
  -- Define Constants
  constant c_CLKS_PER_BIT : natural := 3;          -- Clock Frequency / Baud Rate

  -- Signal type definition to constract UART_RX state machine
  type t_RX_State_Machine is (s_Idle, s_Start, s_Data, s_Parity, s_Stop);

  -- p_SAMPLE Signals
  signal r_RX_Data_Metastable : std_logic := '0';
  signal r_RX_Data            : std_logic := '0';

  -- p_UART_RX Signals
  signal r_RX_State_Machine   : t_RX_State_Machine := s_Idle;
  signal r_Clk_Count 	      : integer range 0 to c_CLKS_PER_BIT-1 := 0;
  signal r_Bit_Index          : integer range 0 to 7 := 0;  -- 8 Bits Total
  signal r_RX_Byte            : std_logic_vector(7 downto 0) := (others => '0');
  signal r_RX_Done            : std_logic := '0';
  signal r_RX_Parity          : std_logic := '1';	
  signal r_Parity_Even_Count  : std_logic := '1';	
  signal r_Parity_True	      : std_logic := '0';	

begin
  -- Process "Sample"
  -- Purpose: Double-flop the incoming data (crossing clock domains).
  p_SAMPLE : process (i_Clk)
  begin
    if rising_edge(i_Clk) then
      r_RX_Data_Metastable <= i_RX_Serial;
      r_RX_Data            <= r_RX_Data_Metastable;
    end if;
  end process p_SAMPLE;

  -- Process "UART_RX", 
  -- Purpose: UART RX state machine
  p_UART_RX : process (i_Clk)
  begin
    -- Operate at rising edge
    if rising_edge(i_Clk) then
      -- state machine
      case r_RX_State_Machine is
       -- List all states, signal values of each state, and when transfers should happen in an if else statment

        when s_Idle =>
 	  -- Reset all outputs and counters
          r_Clk_Count <= 0;
          r_Bit_Index <= 0;
          r_RX_Done   <= '0';
	  r_Parity_True <= '0';
	  r_RX_Byte(7 downto 0)	 <= (others => '0');
 	  -- Conditions to exit this state
          if r_RX_Data = '0' then       	-- Start Edge detected
            r_RX_State_Machine <= s_Start;
          else
            r_RX_State_Machine <= s_Idle;       -- Otherwise, stay in s_Idle
          end if;
 
        when s_Start =>
	  -- Check the start bit again to make sure it's still low (to mitigate glitches)
          if r_Clk_Count = (c_CLKS_PER_BIT-1)/2 then
            if r_RX_Data = '0' then
              r_Clk_Count <= 0;  		-- reset counter since we found the middle
              r_RX_State_Machine <= s_Data;
            else
              r_RX_State_Machine <= s_Idle;
            end if;
          else
            r_Clk_Count 	 <= r_Clk_Count + 1;
            r_RX_State_Machine   <= s_Start;
          end if;

        when s_Data =>
          if r_Clk_Count < c_CLKS_PER_BIT-1 then
            r_Clk_Count 	 <= r_Clk_Count + 1;
            r_RX_State_Machine   <= s_Data;
          else
            r_Clk_Count          <= 0;
            r_RX_Byte(r_Bit_Index) <= r_RX_Data;
            if i_Parity_En = '1' then
               -- If the received bit was a '1', adjust the even parity flag
	       if r_RX_Data = '1' then
                  r_Parity_Even_Count <= not r_Parity_Even_Count;
	       else
                  r_Parity_Even_Count <= r_Parity_Even_Count;
               end if;
            else
                  r_Parity_Even_Count <= '0';
            end if;
            -- Check if we have sent out all bits
            if r_Bit_Index < 7 then
              r_Bit_Index  	 <= r_Bit_Index + 1;
              r_RX_State_Machine <= s_Data;
            else
              -- Last data bit
              r_Bit_Index <= 0;
	      if i_Parity_En = '0' then
                 -- Last data bit and i_Parity_En is '0'
	         r_RX_State_Machine <= s_Stop;
	      else
                 -- Last data bit and i_Parity_En is '1'
	         r_RX_State_Machine <= s_Parity;
	      end if;
            end if;
          end if;

        when s_Parity =>
          if r_Clk_Count < c_CLKS_PER_BIT-1 then
            r_Clk_Count        <= r_Clk_Count + 1;
            r_RX_State_Machine <= s_Parity;
          else
            r_Clk_Count <= 0;
            r_RX_Parity <= r_RX_Data;
            -- If the received parity bit "r_RX_Parity" is equal to the calculated parity "r_Parity_Even_Count", set "r_Parity_True"
	    if r_RX_Parity = r_Parity_Even_Count then
               r_Parity_True <= '1';
            else 
	       r_Parity_True <= '0';
            end if;
            -- exit to s_Stop
            r_RX_State_Machine <= s_Stop;
          end if;

        when s_Stop =>
          -- Wait c_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if r_Clk_Count < c_CLKS_PER_BIT-1 then
            r_Clk_Count 	<= r_Clk_Count + 1;
            r_RX_State_Machine  <= s_Stop;
          else
            r_RX_Done   <= '1';
            r_Clk_Count <= 0;
            r_RX_State_Machine   <= s_Idle;
          end if;
 
        -- Default case     
        when others =>
          r_RX_State_Machine 	<= s_Idle;
	  r_RX_Done   		<= '0';

      end case;
    end if;
  end process p_UART_RX;

  -- register the output
  o_RX_Done 	<= r_RX_Done;
  o_RX_Byte 	<= r_RX_Byte;
  o_Parity_True <= r_Parity_True;

end rtl;
