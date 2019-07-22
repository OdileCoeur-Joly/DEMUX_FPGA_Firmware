----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Paul Gumuchian / Christophe Oziol
-- 
-- Create Date   : 12:14:36 01/20/2019 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : Two_path_filter - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : second level of all_pass_filter
--
-- Dependencies	 : Double_two_path_filter, all_pass_filter
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

entity Two_path_filter is
port(
--RESET
	Reset		:	in  std_logic;
--CLOCK
	CLK_4X		:	in  std_logic;
	ENABLE		:	in  std_logic;	

	input		:	in  signed(C_Size_DAC-1 downto 0);
	output		:	out signed(C_Size_DAC-1 downto 0)
);
end Two_path_filter;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.Two_path_filter.Behavioral.svg
architecture Behavioral of Two_path_filter is
signal input_tf1 	: signed(C_Size_DAC-1 downto 0)	:=(others=>'0');
signal input_bf1 	: signed(C_Size_DAC-1 downto 0)	:=(others=>'0');
signal output_tf1 	: signed(C_Size_DAC-1 downto 0)	:=(others=>'0');
signal output_bf1 	: signed(C_Size_DAC-1 downto 0)	:=(others=>'0');
signal output_tf2 	: signed(C_Size_DAC-1 downto 0)	:=(others=>'0');
signal output_bf2 	: signed(C_Size_DAC-1 downto 0)	:=(others=>'0');
signal output_trunc : signed(C_Size_DAC downto 0)	:=(others=>'0');
begin

TF1	: entity work.All_pass_filter
Generic map
(
	C_Coeff		=> "00001010001110100010"
)
Port map
(
	CLK_4X		=> CLK_4X,
	ENABLE		=> ENABLE,
	Reset		=> Reset,
	sig_in		=> input_tf1,
	sig_out		=> output_tf1
);

TF2	: entity work.All_pass_filter
Generic map
(
	C_Coeff		=> "01000101110011000110"
)
Port map
(
	CLK_4X		=> CLK_4X,
	ENABLE		=> ENABLE,
	Reset		=> Reset,
	sig_in		=> output_tf1,
	sig_out		=> output_tf2
);

BF1	: entity work.All_pass_filter
Generic map
(
	C_Coeff		=> "00100100010100111001"
)
Port map
(
	CLK_4X		=> CLK_4X,
	ENABLE		=> ENABLE,
	Reset		=> Reset,
	sig_in		=> input_bf1,
	sig_out		=> output_bf1
);

BF2	: entity work.All_pass_filter
Generic map
(
	C_Coeff		=> "01101010110011011010"
)
Port map
(
	CLK_4X		=> CLK_4X,
	ENABLE		=> ENABLE,
	Reset		=> Reset,
	sig_in		=> output_bf1,
	sig_out		=> output_bf2
);

P_Shift_inputs: process(Reset, CLK_4X)
begin
	if Reset='1' then
		input_tf1 <= (others=>'0');
		input_bf1 <= (others=>'0');
	elsif rising_edge(CLK_4X) then
		if (ENABLE ='1') then
			input_tf1 <= input;
			input_bf1 <= input_tf1;
		end if;
	end if;
end process P_Shift_inputs;


output_trunc <= resize(output_bf2,C_Size_DAC+1) + resize(output_tf2,C_Size_DAC+1);
output <= output_trunc(C_Size_DAC downto 1);

end Behavioral;