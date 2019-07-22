----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   :  DRE XIFU FPGA_BOARD
-- Module Name   : Digital_TRC - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Digital Truncation module
--
-- Dependencies: 
--
-- Revision:0.02 - changement of truncation to 4 possibilities and direct selection of bits 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
  use ieee.numeric_std.all;
use work.athena_package.all;

entity digital_TRC is

port	( 
--RESET
		reset 					: in  std_logic;
--CLOCK
		CLK_4X					: in  std_logic;
		ENABLE_CLK_1X			: in  std_logic;
--CONTROL		
		BIAS_truncation			: in  unsigned (1 downto 0);
		FEEDBACK_truncation		: in  unsigned (1 downto 0);
	
		signal_in_BIAS			: in  signed (C_Size_BIAS_ST3_adder_out - 1 downto 0);
		signal_in_FEEDBACK		: in  signed (C_Size_FEEDBACK_ST3_adder_out -1  downto 0);
		
		signal_out_BIAS			: out signed (C_Size_bias_to_DAC-1 downto 0);
		signal_out_FEEDBACK		: out signed (C_Size_feedback_to_DAC-1 downto 0)
		);
		
end digital_TRC;
-- Truncation maximum: 24 pour ne garder que le bit 0
-- Trunctation LSB 	: 10
-- Truncation MSB 	: 0
--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.digital_TRC.Behavioral.svg
architecture Behavioral of digital_TRC is

signal buffer_BIAS	 							: signed (signal_out_BIAS'length  		downto 0);
signal buffer_FEEDBACK 							: signed (signal_out_FEEDBACK'length	downto 0);

begin

P_truncation_sync:process(reset,CLK_4X)
	begin
	if (reset = '1')then
	buffer_BIAS 	<=	(others =>'0');
	buffer_FEEDBACK	<= 	(others =>'0');
	elsif (rising_edge(CLK_4X)) then
		if (ENABLE_CLK_1X ='1') then
			case (BIAS_truncation) is
				when b"00" 	=> 	-- truncation = 3
			buffer_BIAS 	<=	(signal_in_BIAS		(( C_Size_BIAS_ST3_adder_out    -1)) & signal_in_BIAS 		(C_Size_bias_to_DAC -1 + 4 - 1 downto 4-1));
				when b"01" 	=> 	-- truncation = 4
			buffer_BIAS 	<=	(signal_in_BIAS		(( C_Size_BIAS_ST3_adder_out    -1)) & signal_in_BIAS 		(C_Size_bias_to_DAC -1 + 5 - 1 downto 5-1));
				when b"10" 	=> 	-- truncation = 5
			buffer_BIAS 	<=	(signal_in_BIAS		(( C_Size_BIAS_ST3_adder_out    -1)) & signal_in_BIAS 		(C_Size_bias_to_DAC -1 + 6 - 1 downto 6-1));
				when b"11" 	=> 	-- truncation = 6
			buffer_BIAS 	<=	(signal_in_BIAS		(( C_Size_BIAS_ST3_adder_out    -1)) & signal_in_BIAS 		(C_Size_bias_to_DAC -1 + 7 - 1 downto 7-1));
				when others =>	-- truncation = 3
			buffer_BIAS 	<=	(signal_in_BIAS		(( C_Size_BIAS_ST3_adder_out    -1)) & signal_in_BIAS 		(C_Size_bias_to_DAC -1 + 4 - 1 downto 4-1));
				end case;
			case (FEEDBACK_truncation) is
				when b"00" 	=> 	-- truncation = 3
			buffer_FEEDBACK	<=	(signal_in_FEEDBACK (( C_Size_FEEDBACK_ST3_adder_out-1)) & signal_in_FEEDBACK	(C_Size_feedback_to_DAC -1  +4 - 1 downto 4-1));
				when b"01" 	=> 	-- truncation = 4
			buffer_FEEDBACK	<=	(signal_in_FEEDBACK (( C_Size_FEEDBACK_ST3_adder_out-1)) & signal_in_FEEDBACK	(C_Size_feedback_to_DAC -1  +5 - 1 downto 5-1));
				when b"10" 	=> 	-- truncation = 5
			buffer_FEEDBACK	<=	(signal_in_FEEDBACK (( C_Size_FEEDBACK_ST3_adder_out-1)) & signal_in_FEEDBACK	(C_Size_feedback_to_DAC -1  +6 - 1 downto 6-1));
				when b"11" 	=> 	-- truncation = 6
			buffer_FEEDBACK	<=	(signal_in_FEEDBACK (( C_Size_FEEDBACK_ST3_adder_out-1)) & signal_in_FEEDBACK	(C_Size_feedback_to_DAC -1  +7 - 1 downto 7-1));
				when others =>	-- truncation = 3
			buffer_FEEDBACK	<=	(signal_in_FEEDBACK (( C_Size_FEEDBACK_ST3_adder_out-1)) & signal_in_FEEDBACK	(C_Size_feedback_to_DAC -1  +4 - 1 downto 4-1));
				end case;
		end if;
	end if;
end process P_truncation_sync;

rounding_bias : entity work.rounding
	generic map(
		C_Size_in  => buffer_BIAS'length,
		C_size_out => signal_out_BIAS'length
	)
	port map(
		to_round_in => buffer_BIAS,
		round_out   => signal_out_BIAS
	);
rounding_feedback : entity work.rounding
	generic map(
		C_Size_in  => buffer_FEEDBACK'length,
		C_size_out => signal_out_FEEDBACK'length
	)
	port map(
		to_round_in => buffer_FEEDBACK,
		round_out   => signal_out_FEEDBACK
	);

end Behavioral;
