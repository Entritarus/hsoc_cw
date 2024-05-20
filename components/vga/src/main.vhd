library ieee;
library rtu;
library pll;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use rtu.functions.all;
use rtu.data_types.all;

entity main is
  generic(
    PATTERN : pattern_t := PATTERN_UNIFORM_COLOR
  );
  port(
    -- input to the PLL
    clk_50MHz : in  std_logic; -- 50 MHz quartz clock
    nrst      : in  std_logic; -- switch used as a reset

    

    -- VGA interface signals
    o_hsync     : out std_logic;
    o_vsync     : out std_logic;
    o_denable   : out std_logic;
    o_color_r   : out std_logic_vector(7 downto 0);
    o_color_g   : out std_logic_vector(7 downto 0);
    o_color_b   : out std_logic_vector(7 downto 0);
    o_video_clk : out std_logic
  );
end entity;

architecture RTL of main is
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

  -- VGA counter max values
  constant HOR_COUNTER_MAX_VALUE : natural := VGA_CONFIG.HOR_DISPLAY + 
    VGA_CONFIG.HOR_FRONT_PORCH + VGA_CONFIG.HOR_SYNC + 
    VGA_CONFIG.HOR_BACK_PORCH - 1;
  constant VER_COUNTER_MAX_VALUE : natural := VGA_CONFIG.VER_DISPLAY + 
    VGA_CONFIG.VER_FRONT_PORCH + VGA_CONFIG.VER_SYNC + 
    VGA_CONFIG.VER_BACK_PORCH - 1;

  -- VGA counter widths
  constant HOR_COUNTER_WIDTH : natural := log2c(HOR_COUNTER_MAX_VALUE+1);
  constant VER_COUNTER_WIDTH : natural := log2c(VER_COUNTER_MAX_VALUE+1);

  -- PLL output
  signal clk_65Mhz : std_logic;

  -- COUNTER Generator output
  signal counter_hor : unsigned(HOR_COUNTER_WIDTH-1 downto 0);
  signal counter_ver : unsigned(VER_COUNTER_WIDTH-1 downto 0);

  -- SYNC Generator output
  signal sync_hor, sync_ver, sync_denable : std_logic;
  signal sync_counter_hor : unsigned(HOR_COUNTER_WIDTH-1 downto 0);
  signal sync_counter_ver : unsigned(VER_COUNTER_WIDTH-1 downto 0);

  -- HDMI Initializer
  signal adv_sda_oe, adv_sda_in, adv_sda_out : std_logic;
  signal adv_scl_oe, adv_scl_in, adv_scl_out : std_logic;

  signal rst : std_logic := '0';
begin
  rst <= not nrst;

  -- Instantiate PLL component with the configured output frequency
  -- of 65 MHz
  PLL_65MHz: entity pll.pll
  port map (
    refclk   => clk_50MHz,
    rst      => rst, --not enable_reg, --btn_reset,
    outclk_0 => clk_65Mhz);

  -- Instantiate COUNTER generator
  COUNTER_GEN: entity rtu.counter_generator
  generic map(
    HOR_COUNTER_MAX_VALUE => HOR_COUNTER_MAX_VALUE,
    VER_COUNTER_MAX_VALUE => VER_COUNTER_MAX_VALUE)
  port map(
    clk        => clk_65Mhz,
    rst        => rst,
    o_hcounter => counter_hor,
    o_vcounter => counter_ver);

  -- Instantiate SYNC generator
  SYNC_GEN: entity rtu.sync_generator
  generic map(VGA_CONFIG => VGA_CONFIG)
  port map(
    clk         => clk_65Mhz,
    rst         => rst,
    i_hcounter  => counter_hor,
    i_vcounter  => counter_ver,
    o_denable   => sync_denable,
    o_hsync     => sync_hor,
    o_vsync     => sync_ver,
    o_hcounter  => sync_counter_hor,
    o_vcounter  => sync_counter_ver);
  
  -- Instantiate PATTERN generator
  PATTERN_GEN: entity work.pattern_generator
  generic map(
    VGA_CONFIG => VGA_CONFIG,
    PATTERN    => PATTERN)
  port map(
    clk        => clk_65Mhz,
    rst        => rst,
    i_denable  => sync_denable,
    i_hsync    => sync_hor,
    i_vsync    => sync_ver,
    i_hcounter => sync_counter_hor,
    i_vcounter => sync_counter_ver,
    o_denable  => o_denable,
    o_hsync    => o_hsync,
    o_vsync    => o_vsync,
    o_color_r  => o_color_r,
    o_color_g  => o_color_g,
    o_color_b  => o_color_b);
	 
  -- output video clock
  o_video_clk <= clk_65Mhz;

end architecture;
