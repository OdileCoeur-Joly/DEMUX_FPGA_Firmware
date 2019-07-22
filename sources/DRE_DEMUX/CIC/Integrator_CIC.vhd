----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Antoine CLENET 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : Integrator_CIC - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Integrator for the CIC filter
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Integrator_CIC is
	 Generic	(
				size_in  		: positive := 16;
				size_out 		: positive :=17
				);
    Port 	(
--RESET
				reset 			: in  std_logic;
				START_STOP		: in  std_logic;
--CLOCKs
				CLK_4X			: in  std_logic;
				ENABLE_CLK_1X	: in  std_logic;

				Int_in_dat 		: in  signed(size_in-1 downto 0);
				Int_out_dat 	: out signed(size_out-1 downto 0));
end Integrator_CIC;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.Integrator_CIC.Behavioral.svg
architecture Behavioral of Integrator_CIC is

signal add_buf : signed(size_in-1 downto 0);

begin
P_integrator_CIC:process(reset,CLK_4X)
	begin
	if reset = '1' then
		add_buf  <= (others => '0');
	
	else
		if (rising_edge (CLK_4X)) then
			if (ENABLE_CLK_1X ='1') then
				if (START_STOP = '0') then
					add_buf <=  (others => '0');
				else 
					add_buf <= add_buf + Int_in_dat;
				end if;
			else
			add_buf <= add_buf;
		end if;
	end if;
end if;

end process;

Int_out_dat <= add_buf(size_in-1 downto size_in-size_out);

end Behavioral;

