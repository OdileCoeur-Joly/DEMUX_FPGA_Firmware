----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Paul Gumuchian / Christophe Oziol
-- 
-- Create Date   : 12:14:36 01/20/2019 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : Double_two_path_filter - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : third level of all_pass_filter
--
-- Dependencies	 : All_pass_filter
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

entity Double_Two_path_filter is
port(
	CLK_4X		:	in  std_logic;
	ENABLE_4X	:	in  std_logic;
	ENABLE_2X	:	in  std_logic;		
	Reset		:	in  std_logic;
	input		:	in  signed(C_Size_DAC-1 downto 0);
	output		:	out signed(C_Size_DAC-1 downto 0)
);
end Double_Two_path_filter;


--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.Double_Two_path_filter.Behavioral.svg
architecture Behavioral of Double_Two_path_filter is
signal output_2X : signed(C_Size_DAC-1 downto 0);
begin

filter_2X : entity work.Two_path_filter
Port map
(
	Reset		=> Reset,
	CLK_4X		=> CLK_4X,
	ENABLE		=> ENABLE_2X,
	input		=> input,
	output		=> output_2X
);

filter_4X : entity work.Two_path_filter
Port map
(
	Reset		=> Reset,
	CLK_4X		=> CLK_4X,
	ENABLE		=> ENABLE_4X,
	input		=> output_2X,
	output		=> output
);
end Behavioral;