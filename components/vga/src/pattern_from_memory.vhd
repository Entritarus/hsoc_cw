library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pattern_from_memory is
  port(
    clk        : in  std_logic;
    rst        : in  std_logic;
    i_denable  : in  std_logic;
    i_hsync    : in  std_logic;
    i_vsync    : in  std_logic;
    i_hcounter : in  unsigned;
    i_vcounter : in  unsigned;
    o_denable  : out std_logic;
    o_hsync    : out std_logic;
    o_vsync    : out std_logic;
    o_color_r  : out std_logic_vector;
    o_color_g  : out std_logic_vector;
    o_color_b  : out std_logic_vector
  );
end entity;

architecture RTL of pattern_from_memory is
  -- reg-state logic
begin

  -- reg-state logic
  -- <your code goes here>

  -- next-state logic
  -- <your code goes here>

  -- outputs
  -- <your code goes here>

end architecture;
