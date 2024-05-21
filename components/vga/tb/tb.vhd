library std;
library ieee;
library cwlib;
library osvvm;
library vunit_lib;

context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.data_types_context;

use std.env.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use osvvm.RandomPkg.all;
use vunit_lib.com_pkg.all;
--use vunit_lib.memory_pkg.all;
use vunit_lib.avalon_stream_pkg.all;
use vunit_lib.stream_slave_pkg.all;
use vunit_lib.stream_master_pkg.all;
use cwlib.data_types.all;
use cwlib.functions.all;

entity tb is
  generic(
    runner_cfg : string
  );
end entity;


architecture RTL of tb is
  -----------------------------------------------------------------------------
  -- DUT interfacing
  -----------------------------------------------------------------------------

  signal clk  : std_logic := '0';
  signal rst : std_logic := '1';
  signal i_valid : sl := '0';
  signal o_ready : sl := '0';
  signal i_data : slv(32-1 downto 0) := (others => '0');
  signal i_sop : sl := '0';

	signal o_hsync : sl := '0';
	signal o_vsync : sl := '0';
	signal o_denable : sl := '0';
	signal o_color_r : slv(7 downto 0) := (others => '0');
	signal o_color_g : slv(7 downto 0) := (others => '0');
	signal o_color_b : slv(7 downto 0) := (others => '0');
	signal o_video_clk : sl := '0';


  -----------------------------------------------------------------------------
  -- Clock related
  -----------------------------------------------------------------------------
  constant CLK_PERIOD : time    := 10 ns;

  -----------------------------------------------------------------------------
  -- Verification components
  -----------------------------------------------------------------------------

  
  --constant memory : memory_t := new_memory;

  constant stream_master : avalon_source_t := new_avalon_source(
    data_length => 32,
    valid_high_probability => 1.0);

  
  --constant MEM_OUT_INPUT : integer_array_t := new_2d(IMAGE_WIDTH, IMAGE_HEIGHT);
  --constant MEM_OUT_TEST : integer_array_t := new_3d(OUT_WIDTH, OUT_HEIGHT, FILTER_COUNT);
  --constant MEM_OUT_DUT : integer_array_t := new_3d(OUT_WIDTH, OUT_HEIGHT, FILTER_COUNT);
  --constant csv_o_input : string := "../sim/out_input_" & to_string(STRIDE) & ".csv";
  --constant csv_o_test : string := "../sim/out_test_" & to_string(STRIDE) & ".csv";
  --constant csv_o_dut : string := "../sim/out_dut_" & to_string(STRIDE) & ".csv";

begin

  -----------------------------------------------------------------------------
  -- DUT instantation
  -----------------------------------------------------------------------------
  DUT : entity cwlib.vga
  port map(
    clk => clk,
    rst => rst,

    o_ready => o_ready,
    i_valid => i_valid,
    i_sop => i_sop,
    i_data => i_data,

    o_hsync     => o_hsync,
    o_vsync     => o_vsync,
    o_denable   => o_denable,
    o_color_r   => o_color_r,
    o_color_g   => o_color_g,
    o_color_b   => o_color_b,
    o_video_clk => o_video_clk
  );

  -----------------------------------------------------------------------------
  -- Control signals
  -----------------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD/2;
  rst <= '0' after CLK_PERIOD;
  ----------------------------------------------------------------------------
  -- Verification component instantiation
  ----------------------------------------------------------------------------
  AVALON_SOURCE: entity vunit_lib.avalon_source
    generic map (
      source => stream_master
    )
    port map (
      clk => clk,
      ready => o_ready,
      valid => i_valid,
      sop => i_sop,
      data => i_data
    );
  

  -----------------------------------------------------------------------------
  -- Test sequencer
  -----------------------------------------------------------------------------
  process
    ---------------------------------------------------------------------------
    -- Variables
    ---------------------------------------------------------------------------
    variable rnd : RandomPType;
    --variable rbuffer, wbuffer_modeled, wbuffer_component : buffer_t;

    ---------------------------------------------------------------------------
    -- Procedures
    ---------------------------------------------------------------------------


  begin
    test_runner_setup(runner, runner_cfg);
    rnd.InitSeed(rnd'instance_name);

    --allocate_buf(rbuffer, IN_BYTES*IMAGE_WIDTH*IMAGE_HEIGHT);
    --allocate_buf(wbuffer_component, OUT_BYTES*FILTER_COUNT*OUT_WIDTH*OUT_HEIGHT);
    --allocate_buf(wbuffer_modeled, OUT_BYTES*FILTER_COUNT*OUT_WIDTH*OUT_HEIGHT);
    --model_input(rbuffer);

    while test_suite loop
      if run("Random_test") then
        wait for 1 ms;
        push_avalon_stream(net, stream_master, x"1337C0DE", '1', '0');
        
        wait for 20 ms;
				
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
