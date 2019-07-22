----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Paul Gumuchian / Christophe Oziol
-- 
-- Create Date   : 12:14:36 01/20/2019 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : DAC_filter - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : FIR all_pass_filter
--
-- Dependencies	 :
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.athena_package.all;

entity DAC_filter is
Port(
--RESET
	Reset		:	in  std_logic;
--CLOCK
	CLK_4X		:	in  std_logic;

	sig_in		:	in  signed(C_Size_DAC-1 downto 0);
	sig_out		:	out signed(C_Size_DAC-1 downto 0)
);
end DAC_filter;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.DAC_filter.Behavioral.svg
architecture Behavioral of DAC_filter is
type t_coeffs 	is array (C_order_DAC_FILTER-1 downto 0) of signed(C_Size_DAC_FILTER_coeff-1 downto 0);
type t_inputs 	is array (C_order_DAC_FILTER-1 downto 0) of signed(C_Size_DAC-1 downto 0);
type t_outputs 	is array (C_order_DAC_FILTER-1 downto 0) of signed(C_Size_DAC+C_Size_DAC_FILTER_coeff-1 downto 0);
signal input 		: t_inputs;
signal output 		: t_outputs;
signal output_sum 	: t_outputs;
signal output_trunc : signed(C_Size_DAC+C_Size_DAC_FILTER_coeff-1 downto 0):= (others=>'0');
constant C_coeff : t_coeffs :=
(
"00000000100111011110",
"00000001101010111101",
"00000010011011010001",
"00000010000100000110",
"11111111111100011001",
"11111101001111011101",
"11111100000011010111",
"11111110010011100011",
"00000011001100100001",
"00000111001000101101",
"00000101101011001110",
"11111101110001000000",
"11110100000010110001",
"11110001011001100000",
"11111101000110110111",
"00010110111001000111",
"00110101000101010101",
"01001001011001100000",
"01001001011001100000",
"00110101000101010101",
"00010110111001000111",
"11111101000110110111",
"11110001011001100000",
"11110100000010110001",
"11111101110001000000",
"00000101101011001110",
"00000111001000101101",
"00000011001100100001",
"11111110010011100011",
"11111100000011010111",
"11111101001111011101",
"11111111111100011001",
"00000010000100000110",
"00000010011011010001",
"00000001101010111101",
"00000000100111011110"
);
begin

input(0) <= sig_in;

Shift_input_generate : for i in C_order_DAC_FILTER-1 downto 1 generate
	P_Shift_input : process(Reset, CLK_4X)
	begin
		if Reset='1' then
			input(i) <= (others=>'0');
		elsif rising_edge(CLK_4X) then
			input(i) <= input(i-1);			
		end if;		
	end process P_Shift_input;
end generate Shift_input_generate;


Prod_generate : for i in C_order_DAC_FILTER-1 downto 0 generate
	P_prod : process(Reset, CLK_4X)
	begin
		if Reset='1' then
			output(i) <= (others=>'0');
		elsif rising_edge(CLK_4X) then
			output(i) <= C_coeff(i)*input(i);
		end if;
	end process P_prod;
end generate Prod_generate;

output_sum(0) <= output(0);
Sum_generate : for i in C_order_DAC_FILTER-1 downto 1 generate
	output_sum(i) <= output_sum(i-1) + output(i);
end generate Sum_generate;

output_trunc 	<= output_sum(C_order_DAC_FILTER-1);
sig_out 		<= output_trunc(C_Size_DAC+C_Size_DAC_FILTER_coeff-1) & output_trunc(C_Size_DAC+C_Size_DAC_FILTER_coeff-2 downto C_Size_DAC_FILTER_coeff);

end Behavioral;