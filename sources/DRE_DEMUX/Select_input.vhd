----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : Select_input - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Select input of the Channel (external: ADC or internal Squid)
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
	use work.athena_package.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Select_input is
    Port ( ADC			 	: in  signed(C_Size_In_Real-1 downto 0);
           INT_SQUID 		: in  signed(C_Size_In_Real-1 downto 0);
           IN_PHYS 			: out signed(C_Size_In_Real-1 downto 0);
		   select_input		: in  unsigned (1 downto 0)
			);
end Select_input;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.Select_input.Behavioral.svg
architecture Behavioral of Select_input is

begin
Mux_select:	process (select_input,ADC,INT_SQUID)
		begin
   case select_input is
      when "00" 	=> IN_PHYS 		<= ADC;
      when "01" 	=> IN_PHYS 		<= INT_SQUID;
      when others 	=> IN_PHYS 		<= ADC;
   end case;
end process;
 

end Behavioral;

