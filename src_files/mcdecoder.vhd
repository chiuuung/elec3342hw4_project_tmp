----------------------------------------------------------------------------------
-- Company: Computer Architecture and System Research (CASR), HKU, Hong Kong
-- Engineer: Mo Song
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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity mcdecoder is
    port (
        din     : IN std_logic_vector(2 downto 0);
        valid   : IN std_logic;
        clr     : IN std_logic;
        clk     : IN std_logic;
        dout    : OUT std_logic_vector(7 downto 0);
        dvalid  : OUT std_logic;
        error   : OUT std_logic);
end mcdecoder;

architecture Behavioral of mcdecoder is

    type state_type is (IDLE, DECODE_FIRST, DECODE_SECOND, END1, START1, END2, START2, END3, START3);
    signal state : state_type := IDLE;
    signal first_digit : STD_LOGIC_VECTOR(2 downto 0);

    type code_table is array (0 to 5, 0 to 5) of integer range 0 to 255;
    constant DECODE_TABLE : code_table := (
        (0, 65, 66, 67, 68, 69),  -- A, B, C, D, E
        (70, 0, 71, 72, 73, 74),  -- F, G, H, I, J
        (75, 76, 0, 77, 78, 79),  -- K, L, M, N, O
        (80, 81, 82, 0, 83, 84),  -- P, Q, R, S, T
        (85, 86, 87, 88, 0, 89),  -- U, V, W, X, Y
        (90, 33, 46, 63, 32, 0)   -- Z, !, ., ?, SPACE
    );

begin

    process(clk, clr)
    begin
        if clr = '1' then
            state <= IDLE;
            dout <= (others => '0');
            dvalid <= '0';
            error <= '0';
        elsif rising_edge(clk) then
            dvalid <= '0';
            error <= '0';

            if valid = '1' then
                case state is
		
		    when IDLE =>
			if unsigned(din) = 0 then
				state <= START1;
			else
                            error <= '1';
                            state <= IDLE;
			end if;

                    when DECODE_FIRST =>
                        if unsigned(din) > 0 and unsigned(din) < 7 then
                            first_digit <= din;
                            state <= DECODE_SECOND;
			elsif unsigned(din) = 7 then
				state <= END1;
                        else
                            error <= '1';
                            state <= IDLE;
                        end if;

                    when DECODE_SECOND =>
                        if unsigned(din) > 0 and unsigned(din) < 7 then
                            if first_digit /= din then
                                dout <= std_logic_vector(to_unsigned(DECODE_TABLE(to_integer(unsigned(first_digit)) - 1, to_integer(unsigned(din)) - 1), 8));
                                dvalid <= '1';
                                state <= DECODE_FIRST;
                            else
                                error <= '1';
                                state <= IDLE;
                            end if;
                        else
                            error <= '1';
                            state <= IDLE;
                        end if;

		    when END1 =>
			if unsigned(din) = 0 then
				state <= END2;
			else
                            error <= '1';
                            state <= IDLE;
			end if;

		    when END2 =>
			if unsigned(din) = 7 then
				state <= END3;
			else
                            error <= '1';
                            state <= IDLE;
			end if;

		    when END3 =>
			if unsigned(din) = 0 then
				state <= IDLE;
			else
                            error <= '1';
                            state <= IDLE;
			end if;

		    when START1 =>
			if unsigned(din) = 7 then
				state <= START2;
			else
                            error <= '1';
                            state <= IDLE;
			end if;

		    when START2 =>
			if unsigned(din) = 0 then
				state <= START3;
			else
                            error <= '1';
                            state <= IDLE;
			end if;

		    when START3 =>
			if unsigned(din) = 7 then
				state <= DECODE_FIRST;
			else
                            error <= '1';
                            state <= IDLE;
			end if;

                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;

