----------------------------------------------------------------------------------
-- Company: Computer Architecture and System Research (CASR), HKU, Hong Kong
-- Engineer:
-- 
-- Create Date: 09/09/2022 06:20:56 PM
-- Design Name: system top
-- Module Name: uart
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity myuart is
    Port ( 
           din : in STD_LOGIC_VECTOR (7 downto 0);
           busy: out STD_LOGIC;
           wen : in STD_LOGIC;
           sout : out STD_LOGIC;
           clr : in STD_LOGIC;
           clk : in STD_LOGIC);
end myuart;


architecture rtl of myuart is
    type state_type is (S_IDLE, S_STARTBIT, S_D0, S_D1, S_D2, S_D3, S_D4, S_D5, S_D6, S_D7, S_STOPBIT, IDLE);
    SIGNAL next_state : state_type;
    SIGNAL state : state_type := S_IDLE;
    signal cnt : unsigned (3 downto 0);-- := "0000";
    signal baud : std_logic;-- := '0';

begin
    NEXT_STATE_DECODE : PROCESS (state, wen)
    BEGIN
        next_state <= state;
        case (state) is
            when S_IDLE =>
                if wen = '1' then
                    next_state <= S_STARTBIT;
                --else
                --    next_state <= S_IDLE;
                end if;
            when S_STARTBIT =>
                next_state <= S_D0;
            when S_D0 =>
                next_state <= S_D1;
            when S_D1 =>
                next_state <= S_D2;
            when S_D2 =>
                next_state <= S_D3;
            when S_D3 =>
                next_state <= S_D4;
            when S_D4 =>
                next_state <= S_D5;
            when S_D5 =>
                next_state <= S_D6;
            when S_D6 =>
                next_state <= S_D7;
            when S_D7 =>
                next_state <= S_STOPBIT;
            when S_STOPBIT =>
                next_state <= S_IDLE;
            when others =>
        end case;
    END PROCESS;

OUTPUT_DECODE : PROCESS (state, din)
    BEGIN
        case (state) is
            when S_STARTBIT =>
                busy <= '1';
                sout <= '0';
            when S_IDLE =>
                busy <= '0';
                sout <= '1';
            when S_D0 =>
                sout <= din(0);
            when S_D1 =>
                sout <= din(1);
            when S_D2 =>
                sout <= din(2);
            when S_D3 =>
                sout <= din(3);
            when S_D4 =>
                sout <= din(4);
            when S_D5 =>
                sout <= din(5);
            when S_D6 =>
                sout <= din(6);
            when S_D7 =>
                sout <= din(7);
            when S_STOPBIT =>
                sout <= '1';
            when others =>
        end case;
    END PROCESS;

PROC_BAUD_GEN: process(clk)
begin
    if rising_edge(clk) then
        if clr = '1' then
            cnt <= "0000";
            baud <= '0';
            state <= S_IDLE;
        else
            cnt <= cnt + 1;
            if cnt = "1001" then
                state <= next_state;
                cnt <= (others => '0');
            end if;
        end if;
    end if;
end process;

end rtl;