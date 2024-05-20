--------------------------------------------------------------------------------
--! @file procedures.vhd
--------------------------------------------------------------------------------
library ieee;
library rtu;
library std;
library vunit_lib;

context vunit_lib.vunit_context;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use vunit_lib.com_pkg.all;

-- libraries and packages
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- declarations of the package (types, prototypes of functions and procedures)
package procedures is
  procedure check_sl      (value,expected : in std_logic;        msg : in string);
  procedure check_slv     (value,expected : in std_logic_vector; msg : in string);
  procedure check_unsigned(value,expected : in unsigned;         msg : in string);
end package;


-- implementations of the package (functions, procedures)
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
