----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : rounding - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Rounding of input signal to n bits, with care of n-1 bit value
--
-- Dependencies: 
--
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.athena_package.all;
  
  
entity rounding is
Generic 
		(
		C_Size_in		: positive;
		C_size_out		: positive
		);
port 	( 
		to_round_in		: in  signed(C_Size_in-1 downto 0);-- signed to rounded
		round_out      	: out signed(C_size_out-1 downto 0)-- signed out rounded
		);
end entity;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.rounding.Behavioral.svg
architecture Behavioral of rounding is
-- contant half LSB to take 1 bit more than input trunked	
constant C_half_lsb 	: signed (C_Size_in downto 0) := (C_Size_in-C_size_out-1 =>'1', others =>'0');
signal sum_half_lsb 	: signed (C_Size_in downto 0);

begin
-- add half lsb to input signal
sum_half_lsb <= to_round_in +  C_half_lsb;
-- trunk signal + half lsb sum result
round_out <= sum_half_lsb(C_Size_in-1 downto C_Size_in-C_size_out);

end Behavioral;
