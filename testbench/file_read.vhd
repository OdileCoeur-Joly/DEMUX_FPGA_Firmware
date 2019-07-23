library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_textio.all;
use std.textio.all;
--use work.txt_util.all;
 
 
entity FILE_READ is
  generic (
           stim_file:       string  := "file.dat"
          );---------------------------------ATTENTION seule le file indiqué dans le component est effectif pas celui-la!!!!!!!!!!!---------
  port(
       CLK              : in  std_logic;
       RST              : in  std_logic;
       X                : out std_logic_vector(32 downto 1);
       Y                : out std_logic_vector(32 downto 1);
       EOG              : out std_logic
      );
end FILE_READ;

 
-- I/O Dictionary
--
-- Inputs:
--
-- CLK:              new cell needed
-- RST:              reset signal, wait with reading till reset seq complete
--   
-- Outputs:
--
-- Y:                Output vector
-- EOG:              End Of Generation, all lines have been read from the file
--
   
   
architecture read_from_file of FILE_READ is
  
  
    file stimulus: TEXT ;
	type t_STATE_FILE_READ is (IDLE,READ_ADDRESS,READ_VALUE,EOF,THAT_ALL_FOLK);
	signal STATE_FILE_READ				: t_STATE_FILE_READ;


begin
file_open (stimulus, "./sources/testbench/sim3.dat",read_mode);


-- read data and control information from a file


   

	
process(RST, CLK)
	variable l: line;
	variable s0: std_logic_vector(x'range);
	variable s1: std_logic_vector(y'range);
begin
	if (RST = '1') then
		EOG	<= '0';
		X 		<=	(others	=>'0');
		Y 		<=	(others	=>'0');
	else
		if rising_edge(CLK) then
			case STATE_FILE_READ is 
			when IDLE =>
				EOG	<= '0';
				X 		<=	(others	=>'0');
				Y 		<=	(others	=>'0');
				STATE_FILE_READ <=READ_ADDRESS;
			
			when READ_ADDRESS =>
				readline(stimulus, l);
				hread(l, s0);
				X <= s0;
				if (not endfile (stimulus)) then
					STATE_FILE_READ <= READ_VALUE;
				else 
				STATE_FILE_READ <= EOF;
				end if;
			
			when READ_VALUE =>
				readline(stimulus, l);
				hread(l, s1);
				Y <=  s1;
				if (not endfile (stimulus)) then
					STATE_FILE_READ <= READ_ADDRESS;
				else 
				STATE_FILE_READ <= EOF;
				end if;
			when EOF =>
					file_close(	stimulus);
					EOG	<= '1';
					STATE_FILE_READ <= THAT_ALL_FOLK;
			when THAT_ALL_FOLK =>
					STATE_FILE_READ <= THAT_ALL_FOLK;
			end case;
		end if;
	end if;
end process;
		

end read_from_file;
 
