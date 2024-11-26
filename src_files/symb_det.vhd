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
use IEEE.NUMERIC_STD.ALL;

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
            symbol_out: out STD_LOGIC_VECTOR(2 DOWNTO 0) -- output 3-bit detection symbol
            );
end symb_det;

architecture Behavioral of symb_det is
    -- Constants
    constant SAMPLE_RATE : integer := 96000;  -- 96kHz
    constant SYMBOL_PERIOD : integer := 6000;  -- 96kHz/16Hz = 6000 samples per symbol
    constant THRESHOLD : integer := 100;       -- Threshold for signal detection
    
    -- Types
    type state_type is (IDLE, COUNTING, OUTPUT_SYMBOL);
    signal state : state_type;
    
    -- Signals
    signal sample_count : integer range 0 to SYMBOL_PERIOD := 0;
    signal zero_cross_count : integer range 0 to 1000 := 0;
    signal prev_sample : signed(11 downto 0) := (others => '0');
    signal curr_sample : signed(11 downto 0) := (others => '0');
    signal last_cross : integer range 0 to SYMBOL_PERIOD := 0;
    signal period_sum : integer range 0 to SYMBOL_PERIOD * 10 := 0;
    signal period_count : integer range 0 to 100 := 0;
    
    -- Function to map frequency to symbol
    function get_symbol(avg_period: integer) return std_logic_vector is
    begin
        case avg_period is
            when 0 =>
                return "000";
            when 42 to 50 =>
                return "000";  -- Symbol 0
            when 51 to 58 =>
                return "001";  -- Symbol 1
            when 59 to 74 =>
                return "010";  -- Symbol 2
            when 75 to 87 =>
                return "011";  -- Symbol 3
            when 88 to 101 =>
                return "100";  -- Symbol 4
            when 102 to 125 =>
                return "101";  -- Symbol 5
            when 126 to 147 =>
                return "110";  -- Symbol 6
            when 148 to 183 =>
                return "111";  -- Symbol 7
            when others =>
                return "000";  -- Default case
        end case;
    end function;

begin
    process(clk, clr)
        variable avg_period : integer := 0;
    begin
        if clr = '1' then
            state <= IDLE;
            symbol_valid <= '0';
            symbol_out <= "000";
            sample_count <= 0;
            zero_cross_count <= 0;
            prev_sample <= (others => '0');
            curr_sample <= (others => '0');
            last_cross <= 0;
            period_sum <= 0;
            period_count <= 0;
            
        elsif rising_edge(clk) then
            curr_sample <= signed(adc_data);
            
            case state is
                when IDLE =>
                    symbol_valid <= '0';
                    symbol_out <= "000";
                    if abs(signed(adc_data)) > THRESHOLD then
                        state <= COUNTING;
                        sample_count <= 0;
                        zero_cross_count <= 0;
                        last_cross <= 0;
                        period_sum <= 0;
                        period_count <= 0;
                    end if;
                    
                when COUNTING =>
                    if sample_count < SYMBOL_PERIOD-1 then
                        sample_count <= sample_count + 1;
                        
                        -- Zero crossing detection (positive going) with hysteresis
                        if (prev_sample < -THRESHOLD and curr_sample >= THRESHOLD) then
                            zero_cross_count <= zero_cross_count + 1;
                            if last_cross /= 0 and period_count < 50 then
                                period_sum <= period_sum + (sample_count - last_cross);
                                period_count <= period_count + 1;
                            end if;
                            last_cross <= sample_count;
                        end if;
                        
                    else
                        state <= OUTPUT_SYMBOL;
                    end if;
                    
                when OUTPUT_SYMBOL =>
                    if period_count >= 10 then  -- Minimum number of measurements
                        avg_period := period_sum / period_count;
                        symbol_out <= get_symbol(avg_period);
                    else
                        symbol_out <= "000";  -- Invalid measurement
                    end if;
                    symbol_valid <= '1';
                    state <= IDLE;
                    
            end case;
            
            prev_sample <= curr_sample;
        end if;
    end process;
    
end Behavioral;
