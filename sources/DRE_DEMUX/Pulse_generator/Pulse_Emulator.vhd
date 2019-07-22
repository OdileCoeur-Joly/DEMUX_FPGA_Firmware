----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Antoine CLENET/ Christophe OZIOL 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : Pulse_Emulator - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Pulse emulator for pixel
--
-- Dependencies: Athena package
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;
use work.athena_package.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Pulse_Emulator is
    Port (
--RESET
			Reset		 		: in  STD_LOGIC;
--CLOCKs
    		CLK					: in  STD_LOGIC;
			ENABLE_CLK			: in  STD_LOGIC;
--CONTROL
			Pulse_timescale 	: in  unsigned (3 downto 0);
			Pulse_amplitude 	: in  unsigned (7 downto 0);
			Send_Pulse 			: in  STD_LOGIC;

			Sig_in 				: in  signed (C_Size_DDS-1 downto 0);
        	Sig_out 			: out signed (C_Size_DDS-1 downto 0)
        );
end Pulse_Emulator;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.Pulse_Emulator.Behavioral.svg
architecture Behavioral of Pulse_Emulator is

constant C_PluseLUT_Size_in 	: integer := 18;
constant C_PluseLUT_Size_out 	: integer := 16;
constant C_MaxCount			: positive := ((2**C_PluseLUT_Size_in)-1);


type 	t_state is(idle,pulse);
signal 	state : t_state;

signal 	counter				: unsigned(C_PluseLUT_Size_in-1 downto 0);
signal 	counter_prev		: unsigned(C_PluseLUT_Size_in-1 downto 0);
signal 	LUT_out				: unsigned(C_PluseLUT_Size_out-1 downto 0);
signal 	pulse_amp_buf		: unsigned(LUT_out'length + Pulse_amplitude'length -1 downto 0);
signal 	pulse_amp			: unsigned(LUT_out'length -1 downto 0);
signal 	pulse_amp_offset	: unsigned(LUT_out'length -1 downto 0);
signal 	Bias_Pulse_buf		: signed(pulse_amp_offset'length+Sig_out'length+1 -1 downto 0);
signal 	Bias_Pulse			: signed(Sig_out'length -1 downto 0);
signal 	one_pulse 			: STD_LOGIC;
signal 	one_pulsed 			: STD_LOGIC;

BEGIN

LUT_func_I: entity work.LUT_func 
	Generic map(
		C_Size_in	=> C_PluseLUT_Size_in,	
		C_Size_out	=> C_PluseLUT_Size_out	
		)
	Port map( 
		RESET		=> Reset,
		CLK			=> CLK,
		ENABLE_CLK	=> '1',
		Func_in		=> counter,
		Func_out		=> LUT_out
);

pulse_amp_buf		<= LUT_out*Pulse_amplitude;
pulse_amp			<= pulse_amp_buf(pulse_amp_buf'length-1 downto pulse_amp_buf'length-LUT_out'length);
pulse_amp_offset	<= to_unsigned((2**(LUT_out'length))-1,LUT_out'length) - pulse_amp;
Bias_Pulse_buf		<= signed('0' & pulse_amp_offset) * Sig_in;
Bias_Pulse			<= Bias_Pulse_buf(Bias_Pulse_buf'length-1 -1 downto Bias_Pulse_buf'length-1 - Sig_out'length);

P_ONE_pulse: process(Reset, CLK)
	begin
		if (Reset = '1') then
		 one_pulse <= '0';
		 one_pulsed <= '0';
		elsif (rising_edge(CLK)) then
			if (ENABLE_CLK = '1') then
				if (Send_Pulse ='1' and	one_pulsed = '0') then
					one_pulse 	<='1';
					one_pulsed 	<='1';
				else 
					if (one_pulse ='1' and one_pulsed = '1') then
						one_pulse	<= '0';
						one_pulsed 	<= '1';
					else 
						if (Send_Pulse ='0' ) then
						one_pulse	<= '0';
						one_pulsed 	<= '0';
						end if;
					end if;
				end if;
			end if;
		end if;
end process; 

P_sig_gene: process(Reset, CLK)
begin
	if (Reset = '1') then
		counter 			<= (others=>'0');
		counter_prev 		<= (others=>'0');
		state				<= idle;
		Sig_out 			<= (others=>'0');
	elsif rising_edge(CLK) then
		if (ENABLE_CLK ='1') then
		Sig_out	<= Bias_Pulse;
			Case state is
			when idle	=>
				if one_pulse = '1' then
					counter 	<= (others=>'0');
					counter_prev 	<= (others=>'0');
					state		<= pulse;
				else 
					state		<= idle;
				end if;
			when pulse	=>
				if (counter < C_MaxCount) and (counter >= counter_prev) then
					counter_prev	<= counter;
					counter			<= resize(counter+Pulse_timescale,counter'length);
					state		<= pulse;
				else
					state		<= idle;
				end if;		
		end case;
		end if;
	end if;
end process;

end Behavioral;
