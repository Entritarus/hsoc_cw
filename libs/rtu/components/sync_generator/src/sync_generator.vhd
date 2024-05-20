library ieee;
library rtu;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use rtu.functions.all;
use rtu.data_types.all;

entity sync_generator is
  generic(
    VGA_CONFIG : vga_config_t
  );
  port(
    clk        : in  std_logic;
    rst       : in  std_logic;
    -- input counters
    i_hcounter : in  unsigned(
      log2c(VGA_CONFIG.HOR_DISPLAY+VGA_CONFIG.HOR_FRONT_PORCH+
      VGA_CONFIG.HOR_SYNC+VGA_CONFIG.HOR_BACK_PORCH)-1 downto 0);
    i_vcounter : in  unsigned(
      log2c(VGA_CONFIG.VER_DISPLAY+VGA_CONFIG.VER_FRONT_PORCH+
      VGA_CONFIG.VER_SYNC+VGA_CONFIG.VER_BACK_PORCH)-1 downto 0);
    -- control signals
    o_denable  : out std_logic;
    o_hsync    : out std_logic;
    o_vsync    : out std_logic;
    -- delayed counters
    o_hcounter : out unsigned(
      log2c(VGA_CONFIG.HOR_DISPLAY+VGA_CONFIG.HOR_FRONT_PORCH+
      VGA_CONFIG.HOR_SYNC+VGA_CONFIG.HOR_BACK_PORCH)-1 downto 0);
    o_vcounter : out unsigned(
      log2c(VGA_CONFIG.VER_DISPLAY+VGA_CONFIG.VER_FRONT_PORCH+
      VGA_CONFIG.VER_SYNC+VGA_CONFIG.VER_BACK_PORCH)-1 downto 0)
  );
end entity;


architecture RTL of sync_generator is
  -- VGA sync generation constants
  constant HOR_SYNC_START : natural := 
    VGA_CONFIG.HOR_DISPLAY+VGA_CONFIG.HOR_FRONT_PORCH;
  constant HOR_SYNC_STOP  : natural := 
    HOR_SYNC_START+VGA_CONFIG.HOR_SYNC-1;
  constant VER_SYNC_START : natural := 
    VGA_CONFIG.VER_DISPLAY+VGA_CONFIG.VER_FRONT_PORCH;
  constant VER_SYNC_STOP  : natural := 
    VER_SYNC_START+VGA_CONFIG.VER_SYNC-1;

  -- Sync generation
  -- <your code goes here>
  
  signal h_sync_reg: std_logic := '1';
  signal h_sync_next: std_logic := '1';
  signal h_in_range: boolean;
  
  signal v_sync_reg: std_logic := '1';
  signal v_sync_next: std_logic := '1';
  signal v_in_range: boolean;
  
  signal denable_reg: std_logic := '0';
  signal denable_next: std_logic := '0';
  
  signal hcounter_reg: unsigned(i_hcounter'high downto 0) := (others => '0');
  signal vcounter_reg: unsigned(i_vcounter'high downto 0) := (others => '0');
  
  signal ctrs_in_display_range: boolean;
begin

  -- reg-state logic
  -- <your code goes here>
  
  process (clk)
  begin
    if rst = '1' then
	  h_sync_reg <= '0';
	  v_sync_reg <= '0';
	  hcounter_reg <= (others => '0');
	  vcounter_reg <= (others => '0');
	  denable_reg <= '0';
    elsif rising_edge(clk) then
	  h_sync_reg <= h_sync_next;
	  v_sync_reg <= v_sync_next;
	  hcounter_reg <= i_hcounter;
	  vcounter_reg <= i_vcounter;
	  denable_reg <= denable_next;
	else
	  h_sync_reg <= h_sync_reg;
	  v_sync_reg <= v_sync_reg;
	  hcounter_reg <= hcounter_reg;
	  vcounter_reg <= vcounter_reg;
	  denable_reg <= denable_reg;
	end if;
  end process;
  
  -- next-state logic
  -- <your code goes here>
  
  h_sync_next <= '0' when h_in_range else
                 '1';
  h_in_range <= (i_hcounter >= HOR_SYNC_START) and (i_hcounter <= HOR_SYNC_STOP);
  
  v_sync_next <= '0' when v_in_range else
                 '1';
  v_in_range <= (i_vcounter >= VER_SYNC_START) and (i_vcounter <= VER_SYNC_STOP);
  
  denable_next <= '1' when ctrs_in_display_range else
                  '0';
  ctrs_in_display_range <= (i_hcounter < VGA_CONFIG.HOR_DISPLAY) and (i_vcounter < VGA_CONFIG.VER_DISPLAY);
  
  -- outputs
  -- <your code goes here>
  
  o_hcounter <= hcounter_reg;
  o_vcounter <= vcounter_reg;
  
  o_hsync <= h_sync_reg;
  o_vsync <= v_sync_reg;
  
  o_denable <= denable_reg;

  
  
end architecture;
