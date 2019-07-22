----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : Squid_generic- rtl 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : internal squid emulator
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.athena_package.all;

entity Squid_generic is
	 Generic 
		(
		C_Size_in			: positive :=16;
		C_Size_out			: positive :=12
		);
    Port 
		( 	
--RESET
		RESET			: in  std_logic;
--CLOCK
		CLK_4X			: in  std_logic;
--		Enable_CLK_1X   : in  std_logic;

		In_Squid 		: in  signed(C_Size_in-1 downto 0);
		In_Feedback 	: in  signed(C_Size_in-1 downto 0);
		Out_Squid 		: out signed(C_Size_out-1 downto 0)
		);
end Squid_generic;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.Squid_generic.Behavioral.svg
architecture Behavioral of Squid_generic is

signal diff 				: SIGNED(C_Size_in-1 downto 0) := (others => '0');

begin
	
P_sync_squid: process(RESET,CLK_4X)
	begin
		if (RESET='1') then
			diff <= (others => '0');

		elsif rising_edge(CLK_4X) then

			diff <= In_Squid - In_Feedback;
		end if;
end process P_sync_squid;

Out_Squid	 	<=  diff(C_Size_in-1) & diff(C_Size_out-2 downto 0);

end Behavioral;

