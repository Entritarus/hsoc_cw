library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

library vunit_lib;
use vunit_lib.com_pkg.all;
context vunit_lib.vunit_context;

package procedures is
  procedure check_sl      (value,expected : in std_logic;        msg : in string);
  procedure check_slv     (value,expected : in std_logic_vector; msg : in string);
  procedure check_unsigned(value,expected : in unsigned;         msg : in string);
end package;


package body procedures is

  procedure check_sl(value,expected : in std_logic; msg : in string) is
  begin
    check(value = expected, msg & " ("
      & "Expected: " & to_string(expected) & "; "
      & "Got: "      & to_string(value) & ")" );
  end procedure;

  procedure check_slv(value,expected : in std_logic_vector; msg : in string) is
  begin
    check(value = expected, msg & " ("
      & "Expected: " & to_hstring(expected) & "; "
      & "Got: "      & to_hstring(value) & ")" );
  end procedure;

  procedure check_unsigned(value,expected : in unsigned; msg : in string) is
  begin
    check(value = expected, msg & " ("
      & "Expected: " & to_hstring(expected) & "; "
      & "Got: "      & to_hstring(value) & ")" );
  end procedure;

end package body;
