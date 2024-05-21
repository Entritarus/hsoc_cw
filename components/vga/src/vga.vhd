library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library cwlib;
use cwlib.functions.all;
use cwlib.data_types.all;

entity vga is
  port(
    clk       : in sl; -- 50 MHz quartz clock
    rst       : in sl; -- switch used as a reset
    
    -- avalon-st signals
    o_ready         : out sl;
    i_valid         : in  sl;
    i_sop           : in  sl;
    i_data          : in  slv(31 downto 0);
    
    -- VGA interface signals
    o_hsync     : out sl;
    o_vsync     : out sl;
    o_denable   : out sl;
    o_color_r   : out slv(7 downto 0);
    o_color_g   : out slv(7 downto 0);
    o_color_b   : out slv(7 downto 0);
    o_video_clk : out sl
  );
end entity;

architecture RTL of vga is
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
  constant HOR_COUNTER_WIDTH : natural := log2c(HOR_COUNTER_MAX_VALUE);
  constant VER_COUNTER_WIDTH : natural := log2c(VER_COUNTER_MAX_VALUE);

  -- COUNTER Generator output
  signal counter_ver_en : sl := '0';
  signal counter_hor : unsigned(HOR_COUNTER_WIDTH-1 downto 0);
  signal counter_ver : unsigned(VER_COUNTER_WIDTH-1 downto 0);

  -- SYNC Generator output
  signal sync_hor, sync_ver, sync_denable : std_logic;

  signal srst : sl := '0';
  signal red_reg,     red_next    : slv(7 downto 0) := (others => '0');
  signal green_reg,   green_next  : slv(7 downto 0) := (others => '0');
  signal blue_reg,    blue_next   : slv(7 downto 0) := (others => '0');

  signal red_reg_reg,   red_reg_next    : slv(7 downto 0) := (others => '0');
  signal green_reg_reg, green_reg_next  : slv(7 downto 0) := (others => '0');
  signal blue_reg_reg,  blue_reg_next   : slv(7 downto 0) := (others => '0');
begin

  srst <= i_sop;

  process(clk, rst) is
  begin
    if rst = '1' then
      red_reg   <= (others => '0');
      green_reg <= (others => '0');
      blue_reg  <= (others => '0');
      red_reg_reg <= (others => '0');
      green_reg_reg <= (others => '0');
      blue_reg_reg <= (others => '0');
    elsif rising_edge(clk) then
      red_reg   <= red_next;
      green_reg <= green_next;
      blue_reg  <= blue_next;
      red_reg_reg <= red_reg_next;
      green_reg_reg <= green_reg_next;
      blue_reg_reg <= blue_reg_next;
    end if;
  end process;

  -- instantiate horizontal counter
  HOR_COUNTER: entity cwlib.counter
  generic map(COUNTER_MAX_VALUE => HOR_COUNTER_MAX_VALUE)
  port map(
    clk       => clk,
    rst       => rst,
		srst			=> srst,
    en        => '1',
    o_counter => counter_hor);
     
  -- instantiate vertical counter
  VER_COUNTER: entity cwlib.counter
  generic map(COUNTER_MAX_VALUE => VER_COUNTER_MAX_VALUE)
  port map(
    clk       => clk,
    rst       => rst,
		srst			=> srst,
    en        => counter_ver_en,
    o_counter => counter_ver);

  -- counter signal
  counter_ver_en <= '1' when counter_hor = HOR_COUNTER_MAX_VALUE-144 else
                    '0';


  -- Instantiate SYNC generator
  SYNC_GEN: entity cwlib.sync_generator
  generic map(VGA_CONFIG => VGA_CONFIG)
  port map(
    clk         => clk,
    rst         => rst,
    srst        => srst,
    i_hcounter  => counter_hor,
    i_vcounter  => counter_ver,
    o_denable   => sync_denable,
    o_hsync     => sync_hor,
    o_vsync     => sync_ver
    );

    -- Avalon-ST is Big Endian!!!
    -- from mpu:        |red|green|blue|00|
    -- from avalon-st:  |00|blue|green|red|
    
    red_next    <= i_data(7 downto 0) when i_valid = '1' else
                   red_reg;
    green_next  <= i_data(15 downto 8) when i_valid = '1' else
                   green_reg;
    blue_next   <= i_data(23 downto 16) when i_valid = '1' else
                   blue_reg;

    red_reg_next <= red_reg;
    green_reg_next <= green_reg;
    blue_reg_next <= blue_reg;
  
    o_ready     <= sync_denable;
    -- video interface output 
    o_hsync     <= sync_hor;
    o_vsync     <= sync_ver;
    o_denable   <= sync_denable;
    o_color_r   <= red_reg_reg;
    o_color_g   <= green_reg_reg;
    o_color_b   <= blue_reg_reg;
    o_video_clk <= clk;

end architecture;
