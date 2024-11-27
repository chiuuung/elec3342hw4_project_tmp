----------------------------------------------------------------------------------
-- Company: Computer Architecture and System Research (CASR), HKU, Hong Kong
-- Engineer: Jiajun Wu
-- 
-- Create Date: 09/09/2022 06:20:56 PM
-- Design Name: system top
-- Module Name: top - Behavioral
-- Project Name: Music Decoder
-- Target Devices: Xilinx Basys3
-- Tool Versions: Vivado 2022.1
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity symb_det is
    Port (  clk: in STD_LOGIC; -- input clock 96kHz
            clr: in STD_LOGIC; -- input synchronized reset
            adc_data: in STD_LOGIC_VECTOR(11 DOWNTO 0); -- input 12-bit ADC data
            symbol_valid: out STD_LOGIC;
            symbol_out: out STD_LOGIC_VECTOR(2 DOWNTO 0); -- output 3-bit detection symbol
            downcount_out: out integer;
            filter_out: out STD_LOGIC_VECTOR(11 DOWNTO 0)
            );
end symb_det;

architecture Behavioral of symb_det is    
    type frequency_list is array(0 to 7) of integer;  
    constant symbol_chart: frequency_list := (131, 110, 87, 73, 62, 49, 41, 33);

    -- moving average filter
    constant N : integer := 5; -- Size of the moving average filter
    type data_array is array (0 to N-1) of STD_LOGIC_VECTOR(11 DOWNTO 0);
    signal data_buffer : data_array := (others => (others => '0'));
    signal sum : integer := 0;
    signal average : integer := 0;
    -- end
begin
    process(clk, clr)
        variable i: integer := 0;
        variable line_counter: INTEGER := 0; -- Line counter
        variable detected_symbol: integer:= 0; -- Detected symbol
        variable previous_data: STD_LOGIC_VECTOR(11 DOWNTO 0);
        variable current_data: STD_LOGIC_VECTOR(11 DOWNTO 0);
        variable downcount : integer := 0; 
    begin
        if clr = '1' then
            symbol_valid <='0';
            line_counter := 0;
            detected_symbol := 0; 
            symbol_out <= "000"; 
            previous_data := "000000000000";
            downcount := 0;

            -- moving average filter
            data_buffer <= (others => (others => '0'));
            sum <= 0;
            average <= 0;
            -- end
        elsif rising_edge(clk) then
            symbol_valid <='0';
            current_data := adc_data;

            -- moving average filter
            sum <= sum - to_integer(unsigned(data_buffer(0))) + to_integer(unsigned(current_data)); -- Subtract the oldest data point and add the new one
            for i in 0 to N-2 loop
                data_buffer(i) <= data_buffer(i+1); -- Shift the data points
            end loop;
            data_buffer(N-1) <= current_data; -- Add the new data point to the buffer
            average <= sum / N; -- Calculate the moving average
            current_data := std_logic_vector(to_unsigned(average, 12)); -- Use the moving average as the input to the symbol detector
            filter_out <= current_data;
            -- end

            if (line_counter < 5999) then
                line_counter := line_counter + 1;                        
                if (previous_data >= "011111111111" ) and (current_data < "011111111111") then
                    downcount := downcount + 1;
                    downcount_out <= downcount;
                end if;                
                previous_data := current_data;
            else -- 6000 lines counted           
                i := 0;
                for i in 0 to 7 loop -- find the range of the symbol
                    if (downcount > symbol_chart(i) - 4) and (downcount < symbol_chart(i) + 4) then
                        detected_symbol := i;
                        symbol_out <= std_logic_vector(to_unsigned(detected_symbol, 3));
                        symbol_valid <='1';
                        exit;
                    end if;
                end loop;             
                downcount := 0;
                line_counter := 0;
            end if;           
        end if;
    end process;
end Behavioral;
