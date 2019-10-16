-- TESTBENCH
-- 1. Import those libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ADD: entity testbench (without ports)
entity testbench is
-- empty
end testbench; 

-- ADD: architecture of testbench (stimulating and output test signals and the DUT)
architecture tb of testbench is
  -- 100 MHz = 10 nanoseconds period
  constant c_CLOCK_PERIOD : time := 10 ns;
  constant c_CLKS_PER_BIT : natural := 3;
  
  signal i_Clk_test         : std_logic := '0';
  signal i_Parity_En_test   : std_logic := '1';
  signal i_Rx_Serial_test   : std_logic := '1';
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

-- 3. The test itself
begin
  -- Connect DUT to Stimulating and output test signals
  DUT: UART_RX port map(i_Clk_test, i_Parity_En_test, i_Rx_Serial_test, o_Rx_Byte_test, o_Parity_True_test, o_Rx_Done_test);

  -- Clock Generator (1/c_CLOCK_PERIOD Hz)
  p_CLK_GEN : process is
  begin
    wait for c_CLOCK_PERIOD/2;
    i_Clk_test <= not i_Clk_test;
  end process p_CLK_GEN; 

  p_RX_SERIAL_DATA : process is
  begin
    -- Wrong Parity
    wait for c_CLOCK_PERIOD*(c_CLKS_PER_BIT+2);
    -- Start Symbol
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    -- Data
    i_Rx_Serial_test <= '1';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '1';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '1';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    -- Parity Bit
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    -- Stop Symbol
    i_Rx_Serial_test <= '1';

    -- Correct Parity
    wait for c_CLOCK_PERIOD*(c_CLKS_PER_BIT+2);
    -- Start Symbol
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    -- Data
    i_Rx_Serial_test <= '1';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '1';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '1';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    i_Rx_Serial_test <= '0';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    -- Parity Bit
    i_Rx_Serial_test <= '1';
    wait for c_CLOCK_PERIOD*c_CLKS_PER_BIT;
    -- Stop Symbol
    i_Rx_Serial_test <= '1';

  end process p_RX_SERIAL_DATA; 

end tb;
