----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Paul Gumuchian / Christophe Oziol
-- 
-- Create Date   : 12:14:36 01/20/2019 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : All_pass_filter - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : first level of all_pass_filter
--
-- Dependencies	 :
--
-- Revision: 
-- Revision 0.02 - Coeff modified
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.athena_package.all;

entity All_pass_filter is
Generic 
( 		
	C_Coeff		:	signed(C_Size_DAC_FILTER_coeff-1 downto 0)
);
Port 
(
	CLK_4X		:	in  std_logic;
	ENABLE		:	in  std_logic;
	Reset		:	in  std_logic;
	sig_in		:	in  signed(C_Size_DAC-1 downto 0);
	sig_out		:	out signed(C_Size_DAC-1 downto 0)
);
end All_pass_filter;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.All_pass_filter.Behavioral.svg
architecture Behavioral of All_pass_filter is

type t_inputs_ARRAY is array (3 downto 0) of signed(C_Size_DAC-1 downto 0);
type t_outputs_ARRAY is array (1 downto 0) of signed(C_Size_DAC-1 downto 0);
type t_product_ARRAY is array (2 downto 0) of signed(C_Size_DAC+C_Size_DAC_FILTER_coeff-1 downto 0);

signal input 	: t_inputs_ARRAY;
signal output 	: t_outputs_ARRAY;
signal prod 	: t_product_ARRAY;
signal sum_prod : signed(C_Size_DAC+C_Size_DAC_FILTER_coeff-1 downto 0);

begin

input(0) <= sig_in;

Shift_input_generate : for i in 3 downto 1 generate
	p_Shift_input : process(Reset, CLK_4X)
	begin
		if Reset='1' then
			input(i) <= (others=>'0');
		elsif rising_edge(CLK_4X) then
			if (ENABLE ='1') then
				input(i) <= input(i-1);
			end if;	
		end if;
	end process p_Shift_input;
end generate Shift_input_generate;

p_Shift_output : process(Reset, CLK_4X)
begin
	if Reset='1' then
		output(1) <= (others=>'0');
	elsif rising_edge(CLK_4X) then
		if (ENABLE ='1') then
			output(1) <= output(0);
		end if;			
	end if;
end process p_Shift_output;

p_multi_coeff_input: process(Reset, CLK_4X)
begin
	if Reset='1' then
		prod(0) <= (others=>'0');
	elsif rising_edge(CLK_4X) then
		if (ENABLE ='1') then
			prod(0) <= C_Coeff*input(0);
		end if;			
	end if;
end process p_multi_coeff_input;

p_multi_coeff_output : process(Reset, CLK_4X)
begin
	if Reset='1' then
		prod(1) <= (others=>'0');
	elsif rising_edge(CLK_4X) then
		if (ENABLE ='1') then
			prod(1) <= - C_Coeff*output(1);
		end if;			
	end if;
end process p_multi_coeff_output;

sum_prod <= prod(0) + prod(1);
output(0) <= (sum_prod(C_Size_DAC+C_Size_DAC_FILTER_coeff-1) & sum_prod(C_Size_DAC+C_Size_DAC_FILTER_coeff-3 downto C_Size_DAC_FILTER_coeff-1)) + input(3);
sig_out <= output(0);

end Behavioral;