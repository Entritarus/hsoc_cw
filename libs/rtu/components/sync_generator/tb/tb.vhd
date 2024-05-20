library std;
library ieee;
library rtu;
library osvvm;
library vunit_lib;
library rtu_test;

context vunit_lib.vunit_context;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use osvvm.RandomPkg.all;
use std.env.all;
use vunit_lib.com_pkg.all;
use rtu.functions.all;
use rtu.data_types.all;
use rtu_test.procedures.all;


entity tb is
  generic(
    runner_cfg : string;
    TEST_COUNT : natural := 1000
  );
end entity;

architecture RTL of tb is
  -- VGA interface (1024 x 768)
  constant VGA_CONFIG : vga_config_t := (
    HOR_DISPLAY     => 1024,
    HOR_FRONT_PORCH => 24,
    HOR_SYNC        => 136,
    HOR_BACK_PORCH  => 160,
    VER_DISPLAY     => 768,
    VER_FRONT_PORCH => 3,
    VER_SYNC        => 6,
    VER_BACK_PORCH  => 29 
  );

  constant HOR_SYNC_START : natural := 
    VGA_CONFIG.HOR_DISPLAY+VGA_CONFIG.HOR_FRONT_PORCH;
  constant HOR_SYNC_STOP  : natural := 
    HOR_SYNC_START+VGA_CONFIG.HOR_SYNC-1;
  constant VER_SYNC_START : natural := 
    VGA_CONFIG.VER_DISPLAY+VGA_CONFIG.VER_FRONT_PORCH;
  constant VER_SYNC_STOP  : natural := 
    VER_SYNC_START+VGA_CONFIG.VER_SYNC-1;

  -----------------------------------------------------------------------------
  -- DUT interfacing
  -----------------------------------------------------------------------------
  signal clk        : std_logic := '0';
  signal rst        : std_logic := '0';
  signal i_hcounter : unsigned(
    log2c(VGA_CONFIG.HOR_DISPLAY+VGA_CONFIG.HOR_FRONT_PORCH+
    VGA_CONFIG.HOR_SYNC+VGA_CONFIG.HOR_BACK_PORCH)-1 downto 0)
    := (others => '0');
  signal i_vcounter : unsigned(
    log2c(VGA_CONFIG.VER_DISPLAY+VGA_CONFIG.VER_FRONT_PORCH+
    VGA_CONFIG.VER_SYNC+VGA_CONFIG.VER_BACK_PORCH)-1 downto 0)
    := (others => '0');
  signal o_denable  : std_logic := '0';
  signal o_hsync    : std_logic := '0';
  signal o_vsync    : std_logic := '0';
  signal o_hcounter : unsigned(
    log2c(VGA_CONFIG.HOR_DISPLAY+VGA_CONFIG.HOR_FRONT_PORCH+
    VGA_CONFIG.HOR_SYNC+VGA_CONFIG.HOR_BACK_PORCH)-1 downto 0);
  signal o_vcounter : unsigned(
    log2c(VGA_CONFIG.VER_DISPLAY+VGA_CONFIG.VER_FRONT_PORCH+
    VGA_CONFIG.VER_SYNC+VGA_CONFIG.VER_BACK_PORCH)-1 downto 0);

  -----------------------------------------------------------------------------
  -- Clock-related
  -----------------------------------------------------------------------------
  constant CLK_PERIOD : time := 10 ns;
begin
  -----------------------------------------------------------------------------
  -- DUT instantation
  -----------------------------------------------------------------------------
  DUT: entity rtu.sync_generator
  generic map(
    VGA_CONFIG => VGA_CONFIG)
  port map(
    clk        => clk,
    rst        => rst,
    i_hcounter => i_hcounter,
    i_vcounter => i_vcounter,
    o_denable  => o_denable,
    o_hsync    => o_hsync,
    o_vsync    => o_vsync,
    o_hcounter => o_hcounter,
    o_vcounter => o_vcounter);

  -----------------------------------------------------------------------------
  -- Clock generator
  -----------------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD/2;

  -----------------------------------------------------------------------------
  -- Test sequencer
  -----------------------------------------------------------------------------
  process
    variable random    : RandomPType;
    variable v_hcounter : unsigned(i_hcounter'range);
    variable v_vcounter : unsigned(i_vcounter'range);
    variable v_denable, v_hsync, v_vsync : std_logic;
  begin
    test_runner_setup(runner, runner_cfg);
    random.InitSeed(random'instance_name);

    while test_suite loop
      if run("counter_delay") then
        for i in 0 to TEST_COUNT-1 loop
          v_hcounter := random.RandUnsigned(i_hcounter'length);
          v_vcounter := random.RandUnsigned(i_vcounter'length);
          i_hcounter <= v_hcounter;
          i_vcounter <= v_vcounter;

          wait until falling_edge(clk);
          check(o_hcounter=v_hcounter, "Checking delayed hcounter value "
            & "EXPECTED: " & integer'image(to_integer(v_hcounter))
            & "; GOT: "    & integer'image(to_integer(o_hcounter)));
          check(o_hcounter=v_hcounter, "Checking delayed vcounter value "
            & "EXPECTED: " & integer'image(to_integer(v_vcounter))
            & "; GOT: "    & integer'image(to_integer(o_vcounter)));
        end loop;

      elsif run("denable") then
        wait until falling_edge(clk);
        for i in 0 to TEST_COUNT-1 loop
          v_hcounter := random.RandUnsigned(i_hcounter'length);
          v_vcounter := random.RandUnsigned(i_vcounter'length);
          i_hcounter <= v_hcounter;
          i_vcounter <= v_vcounter;

          if  v_hcounter < VGA_CONFIG.HOR_DISPLAY
          and v_vcounter < VGA_CONFIG.VER_DISPLAY then
            v_denable := '1';
          else
            v_denable := '0';
          end if;

          wait until falling_edge(clk);
          check(v_denable=o_denable, "Checking data enable signal "
            & "EXPECTED: " & to_string(v_denable)
            & "; GOT: "    & to_string(o_denable));
        end loop;

      elsif run("synchronization") then
        wait until falling_edge(clk);
        for i in 0 to TEST_COUNT-1 loop
          v_hcounter := random.RandUnsigned(i_hcounter'length);
          v_vcounter := random.RandUnsigned(i_vcounter'length);
          i_hcounter <= v_hcounter;
          i_vcounter <= v_vcounter;

          if  v_hcounter >= HOR_SYNC_START 
          and v_hcounter <= HOR_SYNC_STOP then
            v_hsync := '0';
          else
            v_hsync := '1';
          end if;

          if  v_vcounter >= VER_SYNC_START 
          and v_vcounter <= VER_SYNC_STOP then
            v_vsync := '0';
          else
            v_vsync := '1';
          end if;


          wait until falling_edge(clk);
          check(v_hsync=o_hsync, "Checking horizontal sync signal "
            & "EXPECTED: " & to_string(v_hsync)
            & "; GOT: "    & to_string(o_hsync));

          check(v_vsync=o_vsync, "Checking vertical sync signal "
            & "EXPECTED: " & to_string(v_vsync)
            & "; GOT: "    & to_string(o_vsync));
        end loop;
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;
end architecture;
