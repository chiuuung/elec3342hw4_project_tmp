library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity myuart is
    Port ( 
           din : in STD_LOGIC_VECTOR (7 downto 0);
           busy: out STD_LOGIC;
           wen : in STD_LOGIC;
           sout : out STD_LOGIC;
           clr : in STD_LOGIC;
           index_out : out integer;
           clk : in STD_LOGIC);
end myuart;

architecture rtl of myuart is
    signal idle: std_logic := '1';
    signal counter: integer range 0 to 9 := 0;
    signal index: integer range 0 to 8 := 0;
    signal sout_reg: std_logic;

begin
    process(clk, clr)
    begin
        if clr = '1' then
            sout <= '1';
            busy <= '0';
            idle <= '1';
            counter <= 0;
            index <= 0;
        
        elsif rising_edge(clk) then
            if wen = '1' then
                sout <= '0';
                sout_reg <= '0';
                busy <= '1';
                idle <= '0';
                counter <= 0;
                index <= 0;
            elsif idle = '1' then
                sout <= '1';
                busy <= '0';
            else
                if counter = 9 then
                    counter <= 0;
                    if index < 8 then
                        sout_reg <= din(index);
                        index <= index + 1;
                    else
                        sout_reg <= '1';
                        busy <= '0';
                        idle <= '1';
                    end if;
                else
                    counter <= counter + 1;
                end if;
                sout <= sout_reg;
                busy <= '1';
            end if;
            index_out <= index;
        end if;
    end process;
end rtl;
