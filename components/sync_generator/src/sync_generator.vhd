library ieee;
library cwlib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use cwlib.functions.all;
use cwlib.data_types.all;

entity sync_generator is
  generic(
    VGA_CONFIG : vga_config_t := (
		HOR_DISPLAY     => 1024,
		 HOR_FRONT_PORCH => 24,
		 HOR_SYNC        => 136,
		 HOR_BACK_PORCH  => 160,
		 VER_DISPLAY     => 768,
		 VER_FRONT_PORCH => 3,
		 VER_SYNC        => 6,
		 VER_BACK_PORCH  => 29 
	 )
  );
  port(
    clk       : in sl;
    rst       : in sl;
		srst			: in sl;
    -- input counters
    i_hcounter : in  unsigned(
      log2c(VGA_CONFIG.HOR_DISPLAY+VGA_CONFIG.HOR_FRONT_PORCH+
      VGA_CONFIG.HOR_SYNC+VGA_CONFIG.HOR_BACK_PORCH)-1 downto 0);
    i_vcounter : in  unsigned(
      log2c(VGA_CONFIG.VER_DISPLAY+VGA_CONFIG.VER_FRONT_PORCH+
      VGA_CONFIG.VER_SYNC+VGA_CONFIG.VER_BACK_PORCH)-1 downto 0);
    -- control signals
    o_denable  : out sl;
    o_hsync    : out sl;
    o_vsync    : out sl
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
  
  signal h_sync_reg: sl := '1';
  signal h_sync_next: sl := '1';
  signal h_in_range: boolean;
  
  signal v_sync_reg: sl := '1';
  signal v_sync_next: sl := '1';
  signal v_in_range: boolean;
  
  signal denable_reg: sl := '0';
  signal denable_next: sl := '0';
  
  signal ctrs_in_display_range: boolean;
begin

  -- reg-state logic
  -- <your code goes here>
  
  process (clk, rst)
  begin
    if rst = '1' then
			h_sync_reg <= '0';
			v_sync_reg <= '0';
			denable_reg <= '0';
    elsif rising_edge(clk) then
			if srst = '1' then
				h_sync_reg <= '0';
				v_sync_reg <= '0';
				denable_reg <= '0';
			else
				h_sync_reg <= h_sync_next;
				v_sync_reg <= v_sync_next;
				denable_reg <= denable_next;
			end if;
		else
			h_sync_reg <= h_sync_reg;
			v_sync_reg <= v_sync_reg;
			denable_reg <= denable_reg;
		end if;
  end process;
  
  -- next-state logic
  -- <your code goes here>
  
  h_in_range <= (i_hcounter >= HOR_SYNC_START) and (i_hcounter <= HOR_SYNC_STOP);
  h_sync_next <= '0' when h_in_range else
                 '1';
  
  v_in_range <= (i_vcounter >= VER_SYNC_START) and (i_vcounter <= VER_SYNC_STOP);
  v_sync_next <= '0' when v_in_range else
                 '1';
  
  ctrs_in_display_range <= (i_hcounter < VGA_CONFIG.HOR_DISPLAY) and (i_vcounter < VGA_CONFIG.VER_DISPLAY);
  denable_next <= '1' when ctrs_in_display_range else
                  '0';
  
  -- outputs
  -- <your code goes here>
  
  o_hsync <= h_sync_reg;
  o_vsync <= v_sync_reg;
  
  o_denable <= denable_reg;

  
  
end architecture;
