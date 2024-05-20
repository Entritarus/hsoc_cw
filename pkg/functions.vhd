library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package functions is
  function log2c (input:integer) return integer;
end package;

package body functions is
  function log2c( input:integer ) return integer is
  variable temp,log:integer;
  begin
    temp:=input-1;
    log:=0;
    while (temp > 0) loop
      temp:=temp/2;
      log:=log+1;
    end loop;
    return log;
  end function;

end package body;
