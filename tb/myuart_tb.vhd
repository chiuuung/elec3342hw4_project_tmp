----------------------------------------------------------------------------------
-- Course: ELEC3342
-- Module Name: mucodec - Behavioral Testbench
-- Project Name: Template for Music Code Decoder for Homework 1
-- Created By: hso
--
-- Copyright (C) 2022 Hayden So
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE std.env.finish;

entity myuart_tb is
end myuart_tb;

architecture tb of myuart_tb is
    component myuart is
        port (
            din : in STD_LOGIC_VECTOR (7 downto 0);
            busy: out STD_LOGIC;
            wen : in STD_LOGIC;
            sout : out STD_LOGIC;
            clr : in STD_LOGIC;
            clk : in STD_LOGIC);
    end component;

    signal clk                  : std_logic;
    signal clr                  : std_logic;
    signal din                  : std_logic_vector(7 downto 0);
    signal wen                  : std_logic;
    signal busy                 : std_logic;
    signal sout                 : std_logic;
    signal baud_en              : std_logic;
    signal baud_en_cnt          : integer := 0;
    signal sout_idx             : integer := 0;

    signal sout_arr             : std_logic_vector(9 downto 0);

    constant clkPeriod : time := 10 ns;
    constant baudPeriod : time := 100 ns;
begin
    myuart_inst : myuart PORT MAP(din, busy, wen, sout, clr, clk);

    clk_process: process begin

        clk <= '0';
        wait for clkPeriod/2;
        clk <= '1';
        wait for clkPeriod/2;

    end process;

    baud_en_process: process (clk)
    begin
        if rising_edge(clk) then
            if baud_en_cnt = 9 then
                baud_en_cnt <= 0;
            else
                baud_en_cnt <= baud_en_cnt + 1;
            end if;
        end if;
    end process;

    baud_en <= '1' when baud_en_cnt = 5 else '0';

    reset_process: process begin
        clr <= '1', '0' after clkPeriod;
        wait;
    end process;

    sout_process: process (clk)
    begin
        if rising_edge(clk) then
            if (baud_en = '1' and busy = '1' and sout_idx < 10) then
                sout_arr(sout_idx) <= sout;
                sout_idx <= sout_idx + 1;
            end if;
        end if;
    end process;

    transition_process: process begin
        wen <= '0';
        -- 0707
        wait for 20*clkPeriod;
        wen <= '1', '0' after clkPeriod;
        din <= "01001011";
        wait for clkPeriod*200;
        std.env.finish;
    end process;

end tb;
