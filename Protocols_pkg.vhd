-- protocol_procedures_pkg
-- Purpose:          A VHDL Package File contains procedures of common protocols (LPC, UART, I2C,....)
-- Author:           Ahmed Ibrahim
-- Last Updated on:  December 9th, 2019

-- 1. Import those libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

-- 2. Package Declaration
package protocols_pkg is
-- UART procedures
    -- Purpose: Procedure to send a Byte to UART RX
    procedure p_SEND_UART_BYTE (
        constant    c_BYTE_UART       : in std_logic_vector(7 downto 0);
        signal    i_UART_CLK        : in std_logic;
        signal   i_Uart_Rx      : inout std_logic
    );

-- LPC procedures/functions
    -- Purpose: LPC Procedure to read a byte from input Address
    procedure p_LPC_READ (
        constant c_LPC_ADDR_R   : in    std_logic_vector(15 downto 0);
        signal    i_LPC_Clk       : in    std_logic;
        signal    i_LPC_Frame        : inout std_logic;
        signal   io_LPC_AD      : inout std_logic_vector(3 downto 0);
        signal    r_BYTE            : out      std_logic_vector(7 downto 0)
    );

    -- Purpose: LPC Procedure to write a byte to specific Address
    procedure p_LPC_WRITE (
        constant c_LPC_ADDR_W   : in    std_logic_vector(15 downto 0);
        constant c_LPC_DATA_W   : in    std_logic_vector(7 downto 0);
        signal    i_LPC_Clk       : in    std_logic;
        signal    i_LPC_Frame        : inout std_logic;
        signal   io_LPC_AD      : inout std_logic_vector(3 downto 0)
    );
    
    -- Purpose: LPC Procedure to trigger a SERIRQ interrupt 
    procedure p_LPC_SERIRQ (
        constant i_quiet_cont    : in       std_logic;    -- Quiet or Continuous Mode
        constant i_low_period    : in       natural;    -- 4 or 8 cycles
        signal    i_LPC_Clk       : in    std_logic;    -- LPC clock
        signal   io_SERIRQ      : inout std_logic        -- SERIRQ Interrupt line
    );
    
-- I2C procedures

end package protocols_pkg;

-- 3. Package Body
package body protocols_pkg is
-- UART procedures
    -- Purpose: Procedure to send a Byte to UART RX
    procedure p_SEND_UART_BYTE (
        constant    c_BYTE_UART       : in std_logic_vector(7 downto 0);
        signal    i_UART_CLK        : in std_logic;
        signal   i_Uart_Rx      : inout std_logic
        ) is
    begin
        i_Uart_Rx <= '1';                                -- 0- Hold UART Input High for 1 CLK Cycle
        wait until rising_edge(i_UART_CLK);
        i_Uart_Rx <= '0';                                -- 1- Send UART Start Symbol
        wait until rising_edge(i_UART_CLK);
        for ii in 0 to 7 loop                            -- 2- Send 8 Bytes
            i_Uart_Rx <= c_BYTE_UART(ii);
        wait until rising_edge(i_UART_CLK);
        end loop;
        i_Uart_Rx <= '1';                                -- 3- Send UART Stop Symbol
        wait until rising_edge(i_UART_CLK);
    end p_SEND_UART_BYTE;

-- LPC procedures    
    -- Purpose: LPC Procedure to read a byte from input Address
    procedure p_LPC_READ (
        constant c_LPC_ADDR_R   : in    std_logic_vector(15 downto 0);
        signal    i_LPC_Clk       : in    std_logic;
        signal    i_LPC_Frame        : inout std_logic;
        signal   io_LPC_AD      : inout std_logic_vector(3 downto 0);
        signal    r_BYTE            : out      std_logic_vector(7 downto 0)
        ) is
    begin
        r_BYTE <= "ZZZZZZZZ";
        -- read from LPC port
        i_LPC_Frame <= '0';                              -- 0- Reset, start new frame 
        io_LPC_AD <= b"0000";                            -- 1- Start
        wait until rising_edge(i_LPC_Clk);
        i_LPC_Frame <= '1';
        io_LPC_AD <= b"0000";                            -- 2- CT-DIR (Cycle Type / Direction), 0000- IO READ
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= c_LPC_ADDR_R(15 downto 12);         -- 3- address A15-A12
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= c_LPC_ADDR_R(11 downto 8);          -- 4- A11-A8
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= c_LPC_ADDR_R(7 downto 4);           -- 5- A7-A4
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= c_LPC_ADDR_R(3 downto 0);           -- 6- A3-A0
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= b"1111";                            -- 7- Turn-Around (TAR)
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= "ZZZZ";                             -- 8- Turn-Around (TAR)
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= "ZZZZ";                             -- 9- SYNC
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= "ZZZZ";                             -- 10- D3-D0 (DATA)
        wait until rising_edge(i_LPC_Clk);
        r_BYTE(3 downto 0) <= io_LPC_AD;                 ---> Save the Read Byte (Non Protocol Statement)
        io_LPC_AD <= "ZZZZ";                             -- 11- D7-D4 (DATA)
        wait until rising_edge(i_LPC_Clk);
        r_BYTE(7 downto 4) <= io_LPC_AD;                 ---> Save the Read Byte (Non Protocol Statement)
        io_LPC_AD <= "ZZZZ";                             -- 12- Turn-Around (TAR)
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= "ZZZZ";                             -- 13- Turn-Around (TAR)
        wait until rising_edge(i_LPC_Clk);
    end p_LPC_READ;
  
    -- Purpose: LPC Procedure to write a byte to specific Address
    procedure p_LPC_WRITE (
        constant c_LPC_ADDR_W   : in    std_logic_vector(15 downto 0);
        constant c_LPC_DATA_W   : in    std_logic_vector(7 downto 0);
        signal    i_LPC_Clk       : in    std_logic;
        signal    i_LPC_Frame        : inout std_logic;
        signal   io_LPC_AD      : inout std_logic_vector(3 downto 0)
        ) is
    begin
        -- write to LPC port
        i_LPC_Frame <= '0';                                -- 0- Reset, start new frame 
        io_LPC_AD <= b"0000";                            -- 1- start
        wait until rising_edge(i_LPC_Clk);
        i_LPC_Frame <= '1';
        io_LPC_AD <= b"0010";                            -- 2- CT-DIR, 0000- IO WRITE
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= c_LPC_ADDR_W(15 downto 12);    -- 3- address A15-A12
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= c_LPC_ADDR_W(11 downto 8);    -- 4- A11-A8
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= c_LPC_ADDR_W(7 downto 4);        -- 5- A7-A4
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= c_LPC_ADDR_W(3 downto 0);        -- 6- A3-A0
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= c_LPC_DATA_W(3 downto 0);        -- 7- Data D3-D0
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= c_LPC_DATA_W(7 downto 4);        -- 8- D7-D4
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= "1111";                                -- 9- TAR
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= "ZZZZ";                                --10- TAR
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= "ZZZZ";                                --11- SYNC
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= "ZZZZ";                                --12- TAR
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= "ZZZZ";                                --13- TAR
        wait until rising_edge(i_LPC_Clk);
        io_LPC_AD <= "ZZZZ";                                --14- TAR
        wait until rising_edge(i_LPC_Clk);
    end p_LPC_WRITE;

    -- Purpose: LPC Procedure to trigger a SERIRQ interrupt 
    procedure p_LPC_SERIRQ (
        constant i_quiet_cont    : in       std_logic;    -- Quiet (1) or Continuous Mode (0)
        constant i_low_period    : in       natural;        -- 4 or 8 cycles
        signal    i_LPC_Clk       : in    std_logic;    -- LPC clock
        signal   io_SERIRQ      : inout std_logic        -- SERIRQ Interrupt line
        ) is
    begin
        -- Call an interrupt
        -- There are two modes of operation for the SERIRQ Start frame: 
        -- 1- Quiet mode: The peripheral drives the SERIRQ signal active low for one clock, and then tri-states it. 
        --                        This brings all the states machines of the peripherals from idle to active states.
        --                        The host controller will then take over driving SERIRQ signal low in the next clock and will continue
        --                        driving the SERIRQ low for programmable 3 to 7 clock periods. This makes the total number of
        --                        clocks low for 4 to 8 clock periods. After these clocks, the host controller will drive the SERIRQ high
        --                        for one clock and then tri-states it. 
        --    2- Continuous mode: only the host controller initiates the START frame to update IRQ/Data line information. 
        --                        The host controller drives the SERIRQ signal low for 4 to 8 clock periods. Upon a reset, the SERIRQ signal 
        --                        is defaulted to the Continuous mode for the host controller to initiate the first Start frame
        
        if i_quiet_cont = '1' then
            -- Quiet Mode
            io_SERIRQ <= '0';                                -- Emulate another peripheral on the bus driving the SERIRQ line low for one clock
            wait until rising_edge(i_LPC_Clk);
            io_SERIRQ <= 'Z';                                -- Tri-state the line
            wait until rising_edge(i_LPC_Clk);        -- This brings all the states machines of the peripherals from idle to active states
            io_SERIRQ <= '0';                                -- The host controller will then take over driving SERIRQ signal low for 3 to 7 clock periods
            for ii in 0 to i_low_period-1 loop    
                wait until rising_edge(i_LPC_Clk);
            end loop;
            io_SERIRQ <= '1';                                -- The host controller will drive the SERIRQ high and then tristates it
            wait until rising_edge(i_LPC_Clk);
            io_SERIRQ <= 'Z';                                -- Tri-state the line until all SERIRQ frames are sent
            for ii in 0 to 52 loop    
                wait until rising_edge(i_LPC_Clk);
            end loop;
            io_SERIRQ <= '0';                                -- Send the STOP Frame, Stop Frame is low for 2 clocks in Quiet Mode
            for ii in 0 to 2 loop
                wait until rising_edge(i_LPC_Clk);
            end loop;
        else
            -- Continuous Mode
            io_SERIRQ <= '0';                                -- The host controller drives the SERIRQ signal low for 4 to 8 clock periods
            for ii in 0 to i_low_period loop    
                wait until rising_edge(i_LPC_Clk);
            end loop;
            io_SERIRQ <= 'Z';                                -- Tri-state the line
            wait until rising_edge(i_LPC_Clk);
            io_SERIRQ <= '1';                                -- HOST Sent First Frame
            wait until rising_edge(i_LPC_Clk);
            io_SERIRQ <= '0';
            for ii in 0 to i_low_period-1 loop               -- Host controller drives the SERIRQ signal low for 4 to 8 clock periods
                wait until rising_edge(i_LPC_Clk);
            end loop;
            io_SERIRQ <= 'Z';                                -- Tri-state the line for the remaining frames
            for ii in 0 to 53 loop    
                wait until rising_edge(i_LPC_Clk);
            end loop;
            io_SERIRQ <= '0';                                -- Send the STOP Frame, Stop Frame is low for 3 clocks in Continuous Mode
            for ii in 0 to 3 loop    
                wait until rising_edge(i_LPC_Clk);
            end loop;
            
        end if;

        io_SERIRQ <= 'Z';                                    -- Tri-state the line at the end

    end p_LPC_SERIRQ;

-- I2C procedures -- coming soon

end package body protocols_pkg;