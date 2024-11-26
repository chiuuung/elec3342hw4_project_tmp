----------------------------------------------------------------------------------
-- Company: Computer Architecture and System Research (CASR), HKU, Hong Kong
-- Engineer: Jiajun Wu, Mo Song
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use STD.TEXTIO.all;
use IEEE.STD_LOGIC_TEXTIO.all;

entity symb_det_tb is
--  Port ( );
end symb_det_tb;

architecture Behavioral of symb_det_tb is
    component symb_det is
        Port (  
            clk         : in std_logic; -- input clock 96kHz
            clr         : in std_logic; -- input synchronized reset
            adc_data    : in std_logic_vector(11 downto 0); -- input 12-bit ADC data
            symbol_valid: out std_logic;
            symbol_out  : out std_logic_vector(2 downto 0) -- output 3-bit detection symbol
        );
    end component symb_det;

    file file_VECTORS   : text;

    constant clkPeriod  : time := 10 ns;
    constant ADC_WIDTH  : integer := 12;
    constant SAMPLE_LEN : integer := 168000;
    constant SYMB_LEN   : integer := 28;
    
    signal clk          : std_logic;
    signal clr          : std_logic;
    signal adc_data     : std_logic_vector(11 downto 0);
    signal sample_cnt   : integer := 0;
    signal symbol_valid : std_logic := '0';
    signal symbol_out   : std_logic_vector(2 downto 0) := "000"; -- output 3-bit detection symbol
    signal symb_out_idx : integer := 0;

    -- sine wave signal
    type wave_array is array (0 to SAMPLE_LEN-1) of std_logic_vector (ADC_WIDTH-1 downto 0);
    signal input_wave: wave_array;

    -- symb out array
    type symb_array is array (0 to SYMB_LEN-1) of std_logic_vector (2 downto 0);
    signal output_symb : symb_array;

    signal expected_symb : symb_array := (
        "000", "111", "000", "111", -- ['0', '7', '0', '7',
        "010", "001", "011", "010", -- '2', '1', '3', '2',
        "001", "010", "100", "110", -- '1', '2', '4', '6', 
        "101", "011", "010", "100", -- '5', '3', '2', '4', 
        "010", "101", "100", "110", -- '2', '5', '4', '6',
        "001", "110", "110", "010", -- '1', '6', '6', '2', 
        "111", "000", "111", "000"  -- '7', '0', '7', '0']
    );

    signal check_flag   : std_logic := '0';
    signal check_flag_d : std_logic := '0';

begin

    symb_det_inst: symb_det port map(
        clk             => clk,
        clr             => clr,
        adc_data        => adc_data,
        symbol_valid    => symbol_valid,
        symbol_out      => symbol_out 
    );

    proc_init_array: process
        -- variable input_wave_temp: wave_array;
        variable wave_amp   : std_logic_vector(ADC_WIDTH-1 downto 0);
        variable line_index : integer := 0;
        variable v_ILINE    : line;
    begin
        -- file_open(file_VECTORS, "/vol/datastore/jiajun/americano_01/elec3342/ELEC3342_fa22_prj/tb/info_wave.txt", read_mode);
        file_open(file_VECTORS, "info_wave.txt", read_mode);
        for i in 0 to (SAMPLE_LEN-1) loop
            readline(file_VECTORS, v_ILINE);
            read(v_ILINE, wave_amp);
            input_wave(i) <= wave_amp;
        end loop;
        wait;
    end process proc_init_array;

    -- clock process
    proc_clk: process
    begin
        clk <= '0';
        wait for clkPeriod/2;
        clk <= '1';
        wait for clkPeriod/2;
    end process proc_clk;

    proc_clr: process
    begin
        clr <= '1', '0' after clkPeriod;
        wait;
    end process proc_clr;

    proc_adc_data: process(clk)
    begin
        if rising_edge(clk) then
            if clr = '1' then
                adc_data <= (others=>'0');
            else
                adc_data <= input_wave(sample_cnt);
            end if;
        end if;
    end process proc_adc_data;

    proc_sample_cnt: process(clk)
    begin
        if rising_edge(clk) then
            if clr = '1' then
                sample_cnt <= 0;
            elsif check_flag = '0' then
                if (sample_cnt = SAMPLE_LEN - 1) then 
                    sample_cnt <= 0;
                    check_flag <= '1';
                else 
                    sample_cnt <= sample_cnt + 1;
                end if;
            end if;
        end if;
    end process proc_sample_cnt;

    proc_get_symb_out: process(clk)
    begin
        if rising_edge(clk) then
            if symbol_valid = '1' then
                output_symb(symb_out_idx) <= symbol_out;
                symb_out_idx <= symb_out_idx + 1;
            end if;
        end if;
    end process proc_get_symb_out;

    -- delay several cycles from check_flag to check_flag_d
    proc_check_flag_d: process(clk)
    begin
        if rising_edge(clk) then
            check_flag_d <= check_flag;
        end if;
    end process proc_check_flag_d;

    -- After check_flag asserted, delay some cycles and then compare the output symb
    proc_check_results: process(check_flag_d)
        variable i : integer := 0;
    begin
        if check_flag_d = '1' then
            for i in 0 to SYMB_LEN-1 loop
                assert output_symb(i) = expected_symb(i) report "SimError: output symbol(" & integer'image(i) & ") is " & to_string(output_symb(i)) & ". The expected symbol is " & to_string(expected_symb(i)) & "." severity error;
            end loop;
            std.env.finish;
        end if;
    end process proc_check_results;

end Behavioral;
