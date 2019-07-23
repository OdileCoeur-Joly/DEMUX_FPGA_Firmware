library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use work.txt_util.all;
 
 
entity FILE_LOG is
  generic (
  			size_data:	positive;
			file_name:	string
          );
  port(
       CLK		: in std_logic;
       LOG_START: in std_logic;
       DATA		: in signed(size_data-1 downto 0)
      );
end FILE_LOG;
   
   
architecture log_to_file of FILE_LOG is
  
	file l_file: TEXT open write_mode is file_name;

begin

-- write data and control information to a file

receive_data: process

begin                                       

   -- print header for the logfile
   print(l_file, "#----------");
   print(l_file, "#  Data    ");
   print(l_file, "#----------");
   print(l_file, " ");

   wait until LOG_START = '1';
   
   while true loop
     print(l_file, str(std_logic_vector(DATA)));
     wait until CLK = '1';    
   end loop;

end process receive_data;

end log_to_file;
 