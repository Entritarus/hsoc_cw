library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library cwlib;
use cwlib.functions.all;
use cwlib.data_types.all;

entity counter is
  generic(
    COUNTER_MAX_VALUE : natural := 800
  );
  port(
    clk       : in sl;
    rst       : in sl;
    en        : in sl;
    o_counter : out unsigned(log2c(COUNTER_MAX_VALUE)-1 downto 0)
  );
end entity;

architecture RTL of counter is
  signal ctr_reg, ctr_next : unsigned(o_counter'range) := (others => '0');
  signal ctr_is_full       : boolean := false;
begin

  process(clk, rst) is
  begin
    if rst = '1' then
      ctr_reg <= (others => '0');
    elsif rising_edge(clk) then
      if en = '1' then
        ctr_reg <= ctr_next;
      end if;

    end if;
  end process;

  ctr_is_full <= ctr_reg = COUNTER_MAX_VALUE;

  ctr_next <= (others => '0') when ctr_is_full else
              ctr_reg + 1;

  o_counter <= ctr_reg;

end architecture;
