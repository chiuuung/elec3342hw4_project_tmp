
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_textio.all;
use std.env.finish;

entity mucodec_tb is
end mucodec_tb;

architecture rtl of mucodec_tb is
  constant clk_period : time      := 1 ns;
  signal clk, clr     : std_logic := '1';

  component mucodec is
    port (
      din    : in std_logic_vector(2 downto 0);
      valid  : in std_logic;
      clr    : in std_logic;
      clk    : in std_logic;
      dout   : out std_logic_vector(7 downto 0);
      dvalid : out std_logic;
      error  : out std_logic);
  end component;

  signal din    : std_logic_vector(2 downto 0);
  signal valid  : std_logic;
  signal dvalid : std_logic;
  signal error  : std_logic;
  signal dout   : std_logic_vector(7 downto 0);
  signal idx    : integer := 0;

  type t_actual_dout is array (0 to 10) of std_logic_vector(7 downto 0);
  signal r_actual_dout : t_actual_dout;

  type t_expected_dout is array (0 to 10) of std_logic_vector(7 downto 0);
  signal r_expected_dout : t_expected_dout := (
  "01001100", -- L
  "01000001", -- A
  "01010100", -- T
  "01010100", -- T
  "01000101", -- E
  "00100000", -- Space
  "01000010", -- B
  "01000101", -- E
  "01010011", -- S
  "01010100", -- T
  "00100001" -- !
  );

begin
  clk <= not clk after clk_period / 2;
  clr <= '0' after clk_period;
  -- Stop the simulation after 100 cycles
  FINISH : process
  begin
    wait for clk_period * 400;
    std.env.finish;
  end process;

  DUT : mucodec PORT
  map(din, valid, clr, clk, dout, dvalid, error);

  test_process : process (clk)
  begin
    if (clk'event and clk = '0') then
      if dvalid = '1' then
        --     valid_dout <= dout;
        --     r_actual_dout(idx) <= dout;
        --     idx <= idx + 1;
        -- else
        --     valid_dout <= "00000000";
        r_actual_dout(idx) <= dout;
        idx                <= idx + 1;
      end if;
    end if;
  end process;

  transition_process : process begin
    wait for clk_period / 2;
    -- 0707(32 12 46 46 16 65 13 16 45 46 62)7070  => "LATTE BEST!"
    valid <= '0';
    -- 0707
    wait for 5 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "000";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "111";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "000";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "111";
    wait for 10 * clk_period;
    -- L: 32
    valid <= '1', '0' after clk_period;
    din   <= "011";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "010";
    wait for 10 * clk_period;

    -- A: 12
    valid <= '1', '0' after clk_period;
    din   <= "001";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "010";
    wait for 10 * clk_period;

    -- T: 46
    valid <= '1', '0' after clk_period;
    din   <= "100";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "110";
    wait for 10 * clk_period;

    -- T: 46
    valid <= '1', '0' after clk_period;
    din   <= "100";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "110";
    wait for 10 * clk_period;

    -- E: 16
    valid <= '1', '0' after clk_period;
    din   <= "001";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "110";
    wait for 10 * clk_period;

    -- Space: 65
    valid <= '1', '0' after clk_period;
    din   <= "110";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "101";
    wait for 10 * clk_period;

    -- B: 13
    valid <= '1', '0' after clk_period;
    din   <= "001";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "011";
    wait for 10 * clk_period;

    -- E: 16
    valid <= '1', '0' after clk_period;
    din   <= "001";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "110";
    wait for 10 * clk_period;

    -- S: 45
    valid <= '1', '0' after clk_period;
    din   <= "100";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "101";
    wait for 10 * clk_period;

    -- T: 46
    valid <= '1', '0' after clk_period;
    din   <= "100";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "110";
    wait for 10 * clk_period;

    -- !: 62
    valid <= '1', '0' after clk_period;
    din   <= "110";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "010";
    wait for 10 * clk_period;

    -- 7070
    valid <= '1', '0' after clk_period;
    din   <= "111";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "000";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "111";
    wait for 10 * clk_period;
    valid <= '1', '0' after clk_period;
    din   <= "000";
    wait for 10 * clk_period;

    for i in 0 to 10 loop
      assert r_expected_dout(i) = r_actual_dout(i)
      report "SimError: Error at index " & integer'image(i) &
        " | Actual dout: " & to_hstring(r_actual_dout(i)) &
        " and Expected dout: " & to_hstring(r_expected_dout(i)) &
        "." severity WARNING;
    end loop;

    wait;
  end process;

end architecture;