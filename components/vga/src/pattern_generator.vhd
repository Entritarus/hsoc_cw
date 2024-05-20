library ieee;
library rtu;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use rtu.data_types.all;

entity pattern_generator is
  generic(
    VGA_CONFIG : vga_config_t;
    PATTERN    : pattern_t := PATTERN_UNIFORM_COLOR
  );
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


architecture RTL of pattern_generator is
begin

  GEN_UNIFORM: if PATTERN = PATTERN_UNIFORM_COLOR generate
    o_denable  <= i_denable;
    o_hsync    <= i_hsync;
    o_vsync    <= i_vsync;
    o_color_r  <= (others => '1');
    o_color_g  <= (others => '0');
    o_color_b  <= (others => '1');
  end generate;

  GEN_FROM_MEMORY: if PATTERN = PATTERN_MEMORY generate
    COMP_PATTERN_FROM_MEMORY: entity work.pattern_from_memory
    port map(
      clk        => clk,
      rst        => rst,
      i_denable  => i_denable,
      i_hsync    => i_hsync,
      i_vsync    => i_vsync,
      i_hcounter => i_hcounter,
      i_vcounter => i_vcounter,
      o_denable  => o_denable,
      o_hsync    => o_hsync,
      o_vsync    => o_vsync,
      o_color_r  => o_color_r,
      o_color_g  => o_color_g,
      o_color_b  => o_color_b);
  end generate;

end architecture;
