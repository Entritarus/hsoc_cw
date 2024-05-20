library std;
library ieee;
library osvvm;
library vunit_lib;
library cwlib;

context vunit_lib.vunit_context;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use osvvm.RandomPkg.all;
use std.env.all;
use vunit_lib.com_pkg.all;
use cwlib.functions.all;
use cwlib.procedures.all;


entity tb is
  generic(
    runner_cfg : string;
    COUNTER_MAX_VALUE : natural := 800
  );
end entity;

architecture RTL of tb is
  -----------------------------------------------------------------------------
  -- DUT interfacing
  -----------------------------------------------------------------------------
  signal clk       : std_logic := '0';
  signal rst       : std_logic := '0';
  signal en        : std_logic := '0';
  signal o_counter : unsigned(log2c(COUNTER_MAX_VALUE+1)-1 downto 0);

  -----------------------------------------------------------------------------
  -- Clock-related
  -----------------------------------------------------------------------------
  constant CLK_PERIOD : time := 10 ns;
begin
  -----------------------------------------------------------------------------
  -- DUT instantation
  -----------------------------------------------------------------------------
  DUT: entity cwlib.counter
  generic map(
    COUNTER_MAX_VALUE => COUNTER_MAX_VALUE)
  port map(
    clk       => clk,
    rst       => rst,
    en        => en,
    o_counter => o_counter);

  -----------------------------------------------------------------------------
  -- Clock generator
  -----------------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD/2;

  -----------------------------------------------------------------------------
  -- Test sequencer
  -----------------------------------------------------------------------------
  process
    variable v_en      : std_logic;
    variable v_counter : integer := 0;
    variable random    : RandomPType;
    variable i         : integer := 0;
  begin
    test_runner_setup(runner, runner_cfg);
    random.InitSeed(random'instance_name);

    while test_suite loop
      if run("two_full_cycles") then
        wait until falling_edge(clk);
        check(unsigned(o_counter) = v_counter, "Checking initial counter value"
          & "EXPECTED: 0; GOT: " & to_hstring(o_counter));

        while true loop
          v_en := random.RandSl;
          en   <= v_en;
          wait until falling_edge(clk);

          -- update model
          if v_en = '1' then
            i := i + 1;
            if v_counter = COUNTER_MAX_VALUE then
              v_counter := 0;
            else
              v_counter := v_counter + 1;
            end if;
          end if;

          -- check expected
          check(unsigned(o_counter)=v_counter, "Checking counter value "
            & "EXPECTED: " & integer'image(v_counter) 
            & "; GOT: " & integer'image(to_integer(unsigned(o_counter))));

          -- check if two full cycles have been checked
          if i >= 2*COUNTER_MAX_VALUE then
            exit;
          end if;
        end loop;
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;
end architecture;
