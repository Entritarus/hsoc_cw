library std;
library ieee;
library uvvm_util;
library vunit_lib;
library osvvm;
library edi;
library edi_neuromorphic;

context uvvm_util.uvvm_util_context;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

use std.env.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;
use ieee.math_real.all;
use osvvm.RandomPkg.all;
use vunit_lib.com_pkg.all;
use vunit_lib.memory_pkg.all;
use vunit_lib.axi_stream_pkg.all;
use vunit_lib.stream_slave_pkg.all;
use vunit_lib.stream_master_pkg.all;
use edi.data_types.all;
use edi.functions.all;

entity tb is
  generic(
    runner_cfg : string;
    FILTER_SIZE : natural := 3;
    LAYER_COUNT : natural := 8;
    IMAGE_WIDTH : natural := 21;
    IMAGE_HEIGHT : natural := 21;
    STRIDE : natural := 2;
    FILTER_COUNT : natural := 8;
    tb_path : string
  );
end entity;


architecture RTL of tb is
  -----------------------------------------------------------------------------
  -- DUT interfacing
  -----------------------------------------------------------------------------
  constant WORD : natural := 18;
  constant PTA_WIDTH_INCREASE : natural := log2c(FILTER_SIZE*FILTER_SIZE*LAYER_COUNT);
  constant IN_BYTES : natural := integer(ceil(real(LAYER_COUNT)/real(8)));
  constant OUT_BYTES : natural := integer(ceil(real(WORD+PTA_WIDTH_INCREASE)/real(8)));
  constant OUT_WIDTH : natural := (IMAGE_WIDTH-FILTER_SIZE)/STRIDE + 1;
  constant OUT_HEIGHT : natural := (IMAGE_HEIGHT-FILTER_SIZE)/STRIDE + 1;

  signal clk  : std_logic := '0';
  signal rst : std_logic := '0';
  signal i_valid : sl := '0';
  signal o_ready : sl := '0';
  signal i_data : slv(LAYER_COUNT-1 downto 0) := (others => '0');
  signal i_last : sl := '0';

  signal i_weights : aslv_4D(0 to FILTER_COUNT-1)(0 to LAYER_COUNT-1)(0 to FILTER_SIZE-1)(0 to FILTER_SIZE-1)(WORD-1 downto 0) := (others => (others => (others => (others => (others => '0')))));
  signal o_data : aslv(0 to FILTER_COUNT-1)(WORD+PTA_WIDTH_INCREASE-1 downto 0) := (others => (others => '0'));
  signal o_valid : slv(0 to FILTER_COUNT-1) := (others => '0');
  signal o_last : slv(0 to FILTER_COUNT-1) := (others => '0');
  signal i_ready : slv(0 to FILTER_COUNT-1) := (others => '0');

  -----------------------------------------------------------------------------
  -- Clock related
  -----------------------------------------------------------------------------
  constant CLK_PERIOD : time    := 10 ns;
  signal clk_en       : boolean := true;

  -----------------------------------------------------------------------------
  -- Verification components
  -----------------------------------------------------------------------------

  
  constant memory : memory_t := new_memory;

  constant STREAM_MASTER_STALL_CONFIG : stall_config_t := new_stall_config(
    stall_probability => 0.1,
    min_stall_cycles => 1,
    max_stall_cycles => 10);
  constant stream_master : axi_stream_master_t := new_axi_stream_master(
    data_length => LAYER_COUNT,
    stall_config => STREAM_MASTER_STALL_CONFIG);

  constant STREAM_SLAVE_STALL_CONFIG : stall_config_t := new_stall_config(
    stall_probability => 0.1,
    min_stall_cycles => 1,
    max_stall_cycles => 10);
  
  type stream_slave_at is array (integer range <>) of axi_stream_slave_t;

  impure function init_stream_slaves(
    count : integer;
    stream_width : integer;
    stall_config : stall_config_t
  ) return stream_slave_at is
    variable slave_array : stream_slave_at(0 to count-1);
  begin
    for i in 0 to count-1 loop
    info("i = " & to_string(i));
      slave_array(i) := new_axi_stream_slave(
        data_length => stream_width,
        stall_config => stall_config
      );
    end loop;

    return slave_array;
  end function;

  constant stream_slaves : stream_slave_at := init_stream_slaves(FILTER_COUNT, WORD+PTA_WIDTH_INCREASE, STREAM_SLAVE_STALL_CONFIG);

  
  constant MEM_OUT_INPUT : integer_array_t := new_2d(IMAGE_WIDTH, IMAGE_HEIGHT);
  constant MEM_OUT_TEST : integer_array_t := new_3d(OUT_WIDTH, OUT_HEIGHT, FILTER_COUNT);
  constant MEM_OUT_DUT : integer_array_t := new_3d(OUT_WIDTH, OUT_HEIGHT, FILTER_COUNT);
  constant csv_o_input : string := "../sim/out_input_" & to_string(STRIDE) & ".csv";
  constant csv_o_test : string := "../sim/out_test_" & to_string(STRIDE) & ".csv";
  constant csv_o_dut : string := "../sim/out_dut_" & to_string(STRIDE) & ".csv";

begin

  -----------------------------------------------------------------------------
  -- DUT instantation
  -----------------------------------------------------------------------------
  DUT : entity edi_neuromorphic.spatial_binary_filter
  generic map(
    WORD => WORD,
    FILTER_SIZE => FILTER_SIZE,
    LAYER_COUNT => LAYER_COUNT,
    IMAGE_WIDTH => IMAGE_WIDTH,
    IMAGE_HEIGHT => IMAGE_HEIGHT,
    STRIDE => STRIDE,
    FILTER_COUNT => FILTER_COUNT
  )
  port map(
    clk => clk,
    rst => rst,

    i_valid => i_valid,
    o_ready => o_ready,
    i_data => i_data,
    i_last => i_last,

    i_weights => i_weights,

    o_valid => o_valid,
    i_ready => i_ready,
    o_data => o_data,
    o_last => o_last
  );

  -----------------------------------------------------------------------------
  -- Clock instantation
  -----------------------------------------------------------------------------
  clock_generator(clk, clk_en, CLK_PERIOD, "TB clock");

  ----------------------------------------------------------------------------
  -- Verification component instantiation
  ----------------------------------------------------------------------------
  VUNIT_AXIS_MASTER: entity vunit_lib.axi_stream_master
    generic map (
      master => stream_master
    )
    port map (
      aclk => clk,
      tvalid => i_valid,
      tready => o_ready,
      tdata => i_data,
      tlast => i_last
    );
  
  SLAVES: for i in stream_slaves'range generate
    VUNIT_AXIS_S: entity vunit_lib.axi_stream_slave
      generic map (
        slave => stream_slaves(i)
      )
      port map (
        aclk => clk,
        tvalid => o_valid(i),
        tready => i_ready(i),
        tdata => o_data(i),
        tlast => o_last(i)
      );
  end generate;

  -----------------------------------------------------------------------------
  -- Test sequencer
  -----------------------------------------------------------------------------
  process
    ---------------------------------------------------------------------------
    -- Variables
    ---------------------------------------------------------------------------
    variable rnd : RandomPType;
    variable rbuffer, wbuffer_modeled, wbuffer_component : buffer_t;
    variable spikes : slv(LAYER_COUNT-1 downto 0);
    variable last : sl;
    variable dout : slv(WORD+PTA_WIDTH_INCREASE-1 downto 0);
    variable inputs : aslv(0 to (IMAGE_WIDTH)*(IMAGE_HEIGHT)-1)(LAYER_COUNT-1 downto 0);
    variable weights : aslv_4D(0 to FILTER_COUNT-1)(0 to LAYER_COUNT-1)(0 to FILTER_SIZE-1)(0 to FILTER_SIZE-1)(WORD-1 downto 0) := (others => (others => (others => (others => (others => '0')))));

    ---------------------------------------------------------------------------
    -- Procedures
    ---------------------------------------------------------------------------
    function count_bits(vec : slv) return integer is
      variable bit_count : integer := 0;
    begin
      for i in vec'range loop
        bit_count := bit_count + 1 when vec(i) = '1' else bit_count;
      end loop;
      return bit_count;
    end function;

    procedure allocate_buf(buf : inout buffer_t; num_bytes : in natural) is
    begin
      buf := allocate(memory, num_bytes => num_bytes, name => "buf",
                      permissions => read_and_write, alignment => 4);
    end procedure;

    procedure model_input(buf : inout buffer_t) is
      variable spikes : slv(LAYER_COUNT-1 downto 0) := (others => '0');
    begin
      for i in 0 to num_bytes(buf)/IN_BYTES-1 loop
        spikes := rnd.RandSlv(spikes'length);
        write_word(memory, base_address(buf) + i*IN_BYTES, spikes);
        set(MEM_OUT_INPUT, i mod IMAGE_WIDTH, i / IMAGE_HEIGHT, count_bits(spikes));
      end loop;
      save_csv(MEM_OUT_INPUT, tb_path & csv_o_input);
    end procedure;

    procedure model_output(rbuffer, wbuffer : inout buffer_t) is
      variable kernel_element_word : slv(8*IN_BYTES-1 downto 0);
      variable kernel_element : slv(LAYER_COUNT-1 downto 0);
      variable sum : signed(WORD+PTA_WIDTH_INCREASE-1 downto 0);
    begin
--      for i in 0 to LAYER_COUNT-1 loop
--        info(to_string(weights(i)(1)(1)));
--      end loop;
      for f in 0 to FILTER_COUNT-1 loop
        for y in FILTER_SIZE/2 to IMAGE_HEIGHT-FILTER_SIZE/2-1 loop
          for x in FILTER_SIZE/2 to IMAGE_WIDTH-FILTER_SIZE/2-1 loop
            sum := (others => '0');
            for fy in 0 to FILTER_SIZE-1 loop
              for fx in 0 to FILTER_SIZE-1 loop
                kernel_element_word := read_word(memory, base_address(rbuffer) + (IMAGE_WIDTH*(y-FILTER_SIZE/2 + fy) + (x-FILTER_SIZE/2 + fx))*IN_BYTES, IN_BYTES);
                kernel_element := kernel_element_word(kernel_element'range);
                for d in LAYER_COUNT-1 downto 0 loop
                  if kernel_element(d) = '1' then
                    sum := sum + signed(weights(f)(d)(fy)(fx));
                    
                  end if;
                end loop;
              end loop;
            end loop;
            if (x-FILTER_SIZE/2) mod STRIDE = 0 then
              if (y-FILTER_SIZE/2) mod STRIDE = 0 then
                --info("x = " & to_string(x) & ", y = " & to_string(y));
                --info("Fitted x = " & to_string((x-FILTER_SIZE/2)/STRIDE) & ", y = " & to_string((y-FILTER_SIZE/2)/STRIDE));
                write_word(memory, 
                         base_address(wbuffer) + (f*OUT_WIDTH*OUT_HEIGHT + (y-FILTER_SIZE/2)/STRIDE*OUT_WIDTH + (x-FILTER_SIZE/2)/STRIDE)*OUT_BYTES,
                         slv(sum)); -- mrc 10.10
                set(MEM_OUT_TEST, (x-FILTER_SIZE/2)/STRIDE, (y-FILTER_SIZE/2)/STRIDE, f, to_integer(unsigned(sum)));
              end if;
            end if;
          end loop;
        end loop;
      end loop;
      save_csv(MEM_OUT_TEST, tb_path & csv_o_test);
    end procedure;

    procedure run_test_loop(rbuffer, wbuffer : inout buffer_t) is
      variable tlast : sl := '0';
      variable in_data_word : slv(8*IN_BYTES-1 downto 0);
      variable in_data : slv(LAYER_COUNT-1 downto 0);
      variable tdata : slv(WORD+PTA_WIDTH_INCREASE-1 downto 0);
    begin
      info("Pushing input buffer to the AXIS master");
      for write_addr in 0 to IMAGE_WIDTH*IMAGE_HEIGHT-1 loop
        if write_addr = IMAGE_WIDTH*IMAGE_HEIGHT-1 then
          tlast := '1';
        end if;
        in_data_word := read_word(memory, base_address(rbuffer) + write_addr*IN_BYTES, IN_BYTES);
        in_data := in_data_word(in_data'range);
        push_axi_stream(net, stream_master, in_data, tlast => tlast); 
      end loop;

      tlast := '0';
      info("Popping to the output buffer");
      for read_addr in 0 to OUT_WIDTH*OUT_HEIGHT-0-1 loop
        for f in 0 to FILTER_COUNT-1 loop
          pop_axi_stream(net, stream_slaves(f), tdata, tlast);
          set(MEM_OUT_DUT, read_addr mod OUT_WIDTH, read_addr / OUT_WIDTH, f, to_integer(unsigned(tdata)));
          write_word(memory, base_address(wbuffer) + (f*OUT_WIDTH*OUT_HEIGHT + read_addr)*OUT_BYTES, tdata);
        end loop;
      end loop;

      save_csv(MEM_OUT_DUT, tb_path & csv_o_dut);
    end procedure;

    procedure check_expected(wbuffer_m, wbuffer_c : inout buffer_t) is
      variable dut_data_word, test_data_word : slv(8*OUT_BYTES-1 downto 0);
      variable dut_data, test_data : slv(WORD+PTA_WIDTH_INCREASE-1 downto 0);
    begin
      info("Checking...");
      for f in 0 to FILTER_COUNT-1 loop
        for read_addr in 0 to OUT_WIDTH*OUT_HEIGHT-1 loop -- mrc 10.10
          dut_data_word := read_word(memory, base_address(wbuffer_c) + (f*OUT_WIDTH*OUT_HEIGHT + read_addr)*OUT_BYTES, OUT_BYTES);
          dut_data := dut_data_word(dut_data'range);
          test_data_word := read_word(memory, base_address(wbuffer_m) +(f*OUT_WIDTH*OUT_HEIGHT + read_addr)*OUT_BYTES, OUT_BYTES);
          test_data := test_data_word(test_data'range);
          --info("dut_data = " & to_string(unsigned(dut_data)) & ", test_data = " & to_string(unsigned(test_data)));
          --info("dut_data = " & to_string(unsigned(dut_data)) & ", test_data = " & to_string(unsigned(test_data)));
          check_equal(dut_data, test_data, "DUT data must be equal to modeled data. " &
          "Read Address = " & to_string(read_addr) & 
          " DUT = " & to_string(dut_data_word) & 
          " test = " & to_string(test_data_word) &
          " filter = " & to_string(f));
        end loop;
      end loop;
    end procedure;

    procedure initialize_test(rbuffer, wbuffer_m, wbuffer_c : inout buffer_t; repeat : natural := 1) is
    begin
      model_output(rbuffer, wbuffer_m);
      for i in 0 to repeat-1 loop
        run_test_loop(rbuffer, wbuffer_c);
        check_expected(wbuffer_m, wbuffer_c);
      end loop;
    end procedure;

  begin
    test_runner_setup(runner, runner_cfg);
    gen_pulse(rst, 1*CLK_PERIOD, "Activated reset for 1 period");
    rnd.InitSeed(rnd'instance_name);

    allocate_buf(rbuffer, IN_BYTES*IMAGE_WIDTH*IMAGE_HEIGHT);
    allocate_buf(wbuffer_component, OUT_BYTES*FILTER_COUNT*OUT_WIDTH*OUT_HEIGHT);
    allocate_buf(wbuffer_modeled, OUT_BYTES*FILTER_COUNT*OUT_WIDTH*OUT_HEIGHT);
    model_input(rbuffer);

    while test_suite loop
      if run("Random_test") then
        for f in 0 to FILTER_COUNT-1 loop
          for i in 0 to LAYER_COUNT-1 loop
            for j in 0 to FILTER_SIZE-1 loop
              for k in 0 to FILTER_SIZE-1 loop

                weights(f)(i)(j)(k) := rnd.RandSlv(WORD);
                --weights(f)(i)(1)(1) :=  (0 => '1', others => '0');
                i_weights(f)(i)(j)(k) <= weights(f)(i)(j)(k);
              end loop;
            end loop;
          end loop;
        end loop;  
        info("OUT_BYTES = " & to_string(OUT_BYTES));
        info("IN_BYTES = " & to_string(IN_BYTES));
        info("Out width = " & to_string((IMAGE_WIDTH-FILTER_SIZE)/STRIDE + 1));
        info("Out height = " & to_string((IMAGE_HEIGHT-FILTER_SIZE)/STRIDE + 1));
        
        set_timeout(runner, 2 ms);
        initialize_test(rbuffer, wbuffer_modeled, wbuffer_component, 2);
        wait for 10 us;
      end if;
      -- if run("Input_only") then
      --   for i in 0 to FILTER_COUNT*OUT_WIDTH*OUT_HEIGHT-1 loop
      --     push_axi_stream(net, stream_master, rnd.RandSlv(i_data'length), '0');
      --   end loop;
      -- end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
