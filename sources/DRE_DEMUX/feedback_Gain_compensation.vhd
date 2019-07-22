----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Antoine CLENET/ Christophe OZIOL
-- 
-- Create Date   : 18/08/2015 
-- Design Name   :  DRE XIFU FPGA_BOARD
-- Module Name   : feedback Gain Compensation - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Gain compensation on feedback global signal
--
-- Dependencies: 
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


entity feedback_gain_compensation is
Port 	(
--RESET
		Reset				: in std_logic;
--CLOCK
		CLK_4X				: in std_logic;
		ENABLE_CLK_1X		: in std_logic;
--CONTROL
		Compensation_Gain	: in unsigned(C_Size_feedback_compensation_gain-1 downto 0);
    
		feedback_in			: in  signed(C_Size_FEEDBACK_ST3_adder_out-1 downto 0);
		feedback_out		: out signed(C_Size_FEEDBACK_ST3_adder_out-1 downto 0)
		);
end entity;


--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.feedback_gain_compensation.Behavioral.svg
architecture Behavioral of feedback_gain_compensation is

signal feedback_buffer : signed(C_Size_FEEDBACK_ST3_adder_out + (C_Size_feedback_compensation_gain+1)-1 downto 0);
signal rounded_feedback_buffer : signed (feedback_out'length-1 downto 0);
begin

rounding_gain_out: entity work.rounding
	generic map(
		C_Size_in  => feedback_buffer'length-1,
		C_size_out => rounded_feedback_buffer'length
	)
	port map(
		to_round_in => feedback_buffer(feedback_buffer'length-1-1 downto 0),-- removing 1 sign bit from multiplication result 
		round_out   => rounded_feedback_buffer
	);
----------------------------------------------------------------------------------------------------
-- FEEDBACK GAIN RESINC
----------------------------------------------------------------------------------------------------
P_sync_feedback:process (Reset,CLK_4X)
begin
	if (Reset='1') then
	feedback_buffer <=(others=>'0');
	elsif (rising_edge(CLK_4X)) then
		if (ENABLE_CLK_1X ='1') then
--			feedback_out <= feedback_buffer (Size_FEEDBACK_ST3_adder_out + (Size_feedback_compensation_gain+1)-2) & feedback_buffer (Size_FEEDBACK_ST3_adder_out + (Size_feedback_compensation_gain+1) -1-3  downto Size_FEEDBACK_ST3_adder_out + (Size_feedback_compensation_gain+1)+1-Size_FEEDBACK_ST3_adder_out-3);			-- -2 in order to suppress the duplicated sign bit
			feedback_buffer <= feedback_in * signed ('0' & Compensation_Gain);
		end if;
	end if;
end process;
feedback_out <= rounded_feedback_buffer;-- -2 in order to suppress the duplicated sign bit



end Behavioral;
