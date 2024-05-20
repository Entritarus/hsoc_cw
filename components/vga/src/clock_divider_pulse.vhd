library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity clock_divider_pulse is
    generic(
        DIVISION_RATIO : natural := 250
    );
    port(
        rst     : in std_logic;
        clk_in  : in  std_logic;
        clk_out : out std_logic
    );
end entity;

architecture RTL of clock_divider_pulse is
    signal counter_reg, counter_next : integer range 0 to DIVISION_RATIO-1 := 0;
    signal clk_reg, clk_next : std_logic := '0';
begin
    -- reg-state logic
    process(clk_in, rst) is
    begin
        if rst = '1' then
            counter_reg <= 0;
            clk_reg <= '0';
        elsif rising_edge(clk_in) then
            counter_reg <= counter_next;
            clk_reg <= clk_next;
        end if;
    end process;

    -- next-state logic
    counter_next <= 0 when counter_reg = DIVISION_RATIO-1 else
                  counter_reg + 1;
    clk_next <= '1' when counter_reg = DIVISION_RATIO-1 else
              '0';

    -- outputs
    clk_out <= clk_reg;

end architecture;
