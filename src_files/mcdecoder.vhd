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
use ieee.numeric_std.all;

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
  type state_type is (St_RESET, St_ERROR, St_WAIT_BOS, St_DECODE, St_OUTPUT, St_WAIT_EOS);
  type code_table_type is array(0 to 5, 0 to 5) of std_logic_vector (7 downto 0);
  signal state, next_state : state_type := St_RESET;
  signal bos_count : integer := 0;
  signal eos_count : integer := 0;
  signal last_in : integer := 0;
  signal input_count : integer := 0;

  constant code_table : code_table_type := (
      (x"00", x"42", x"44", x"48", x"4C", x"52"),
      (x"41", x"00", x"47", x"4B", x"51", x"56"),
      (x"43", x"46", x"00", x"50", x"55", x"5A"),
      (x"45", x"4A", x"4F", x"00", x"59", x"2E"),
      (x"49", x"4E", x"54", x"58", x"00", x"3F"),
      (x"4D", x"53", x"57", x"21", x"20", x"00")
  );

  -- Define additional signal needed here as needed
begin
  sync_process: process (clk, clr)
  begin
      if clr = '1' then
          state <= St_RESET;
      elsif rising_edge(clk) then
          state <= next_state;
      end if;
  end process;

  state_logic: process (state, valid, din)
      variable temp_in : integer;
      variable temp_out : std_logic_vector(7 downto 0);
  begin
      -- Next State Logic
      -- Complete the following:
      next_state <= state;
      error <= '0';
      dvalid <= '0';
      case(state) is
          when St_RESET =>
              --dout <= x"00";
              dvalid <= '0';
              bos_count <= 0;
              eos_count <= 0;
              last_in <= 0;
              input_count <= 0;
              error <= '0';
              next_state <= St_WAIT_BOS;
          when St_ERROR =>
              error <= '1';
              next_state <= St_RESET;
          when St_WAIT_BOS =>
              if valid = '1' then
                  temp_in := to_integer(unsigned(din));
                  if bos_count = 0 then
                      if temp_in = 0 then
                          bos_count <= 1;
                      else
                          next_state <= St_ERROR;
                      end if;
                  elsif bos_count = 1 then
                      if temp_in = 7 then
                          bos_count <= 2;
                      else
                          next_state <= St_ERROR;
                      end if;
                  elsif bos_count = 2 then
                      if temp_in = 0 then
                          bos_count <= 3;
                      else
                          next_state <= St_ERROR;
                      end if;
                  elsif bos_count = 3 then
                      if temp_in = 7 then
                          bos_count <= 0;
                          next_state <= St_DECODE;
                      else
                          next_state <= St_ERROR;
                      end if;
                  end if;
              end if;
              
          when St_DECODE =>
              if valid = '1' then
                  temp_in := to_integer(unsigned(din));
                  if temp_in = 0 then
                      next_state <= St_ERROR;
                  elsif temp_in = 7 then
                      if input_count = 0 then
                          eos_count <= 1;
                          next_state <= St_WAIT_EOS;
                      else 
                          next_state <= St_ERROR;
                      end if;
                  else
                      if input_count = 0 then
                          last_in <= temp_in;
                          input_count <= 1;
                      else
                          temp_out := code_table(last_in - 1, temp_in - 1);
                          if temp_out = x"00" then
                              next_state <= St_ERROR;
                          else
                              input_count <= 0;
                              next_state <= St_OUTPUT;
                          end if;
                      end if;
                  end if;
              end if;
              
          when St_OUTPUT =>
              dvalid <= '1';
              dout <= temp_out;
              next_state <= St_DECODE;
              
          when St_WAIT_EOS =>
              if valid = '1' then
                  temp_in := to_integer(unsigned(din));
                  if eos_count = 1 then
                      if temp_in = 0 then
                          eos_count <= 2;
                      else
                          next_state <= St_ERROR;
                      end if;
                  elsif eos_count = 2 then
                      if temp_in = 7 then
                          eos_count <= 3;
                      else
                          next_state <= St_ERROR;
                      end if;
                  elsif eos_count = 3 then
                      if temp_in = 0 then
                          eos_count <= 4;
                          next_state <= St_RESET;
                      else
                          next_state <= St_ERROR;
                      end if;
                  end if;
              end if;
      end case;
  end process;
end Behavioral;

