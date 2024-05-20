library ieee;
library rtu;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use rtu.functions.all;

entity counter_generator is
  generic(
    HOR_COUNTER_MAX_VALUE : natural := 800;
    VER_COUNTER_MAX_VALUE : natural := 600
  );
  port(
    clk        : in std_logic;
    rst        : in std_logic;
    o_hcounter : out unsigned(log2c(HOR_COUNTER_MAX_VALUE+1)-1 downto 0);
    o_vcounter : out unsigned(log2c(VER_COUNTER_MAX_VALUE+1)-1 downto 0)
  );
end entity;

architecture RTL of counter_generator is
  -- Counter interconnect logic  
  signal counter_ver_en : std_logic;
  signal hcounter : unsigned(o_hcounter'range);
  signal vcounter : unsigned(o_vcounter'range);
begin

  -- instantiate horizontal counter
  HOR_COUNTER: entity rtu.counter
  generic map(COUNTER_MAX_VALUE => HOR_COUNTER_MAX_VALUE)
  port map(
    clk       => clk,
    rst       => rst,
    en        => '1',
    o_counter => hcounter);
     
  -- instantiate vertical counter
  VER_COUNTER: entity rtu.counter
  generic map(COUNTER_MAX_VALUE => VER_COUNTER_MAX_VALUE)
  port map(
    clk       => clk,
    rst       => rst,
    en        => counter_ver_en,
    o_counter => vcounter);

  -- counter signal
  counter_ver_en <= '1' when hcounter = HOR_COUNTER_MAX_VALUE-144 else
                    '0';

  -- outputs
  o_hcounter <= hcounter;
  o_vcounter <= vcounter;

end architecture;
