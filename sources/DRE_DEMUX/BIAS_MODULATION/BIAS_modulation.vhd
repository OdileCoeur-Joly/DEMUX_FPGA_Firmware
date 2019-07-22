----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      :  Antoine CLENET / Christophe OZIOL
-- 
-- Create Date   : 31/07/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : BIAS modulation - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description: 	Processing for test pixel to bias modulation
--					amplitude modulation of bias adjust by a bias_modulation_increment for frequency 
--					and bias modulation amplitude (percent of the signal 255 = 100%)
--					equation is BIAS_OUT = BIAS_IN * (offset - ampltude_modulation + ampltude_modulation* sin ( 2*PI*bias_modulation_increment))
-- Dependencies: 	MOD_rom_DDS, Mod_DDS_generic, Athena_package
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.athena_package.all;


entity BIAS_modulation is
	Port (
			CLK_4X							:	in  std_logic;
			ENABLE_CLK_1X					:	in  std_logic;
			Reset							:	in  std_logic;
			START_STOP						:	in  std_logic;
			BIAS_modulation_increment		: 	in  unsigned (C_MOD_counter_size-1 downto 0);
			BIAS_modulation_amplitude		: 	in  unsigned (C_Size_bias_amplitude-1 downto 0);
--			bias_amplitude 					:   in  unsigned(C_Size_bias_amplitude-1 downto 0);
			BIAS_in							:	in  signed(C_Size_DDS-1 downto 0);
			BIAS_Out						:	out signed(C_Size_DDS-1 downto 0)
			);
end BIAS_modulation;


--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.BIAS_modulation.Behavioral.svg
architecture Behavioral of BIAS_modulation is

signal dds_counter      : unsigned(C_MOD_counter_size-1 downto 0);

signal dds_out_previous : signed(C_MOD_Size_DDS-1 downto 0);

signal address_rom      : unsigned((C_MOD_ROM_Depth-2)-1 downto 0);   	-- MOD_ROM_Depth-2 because only 1/4 of sine period is stored into the LUT

signal sine_val         : unsigned(C_MOD_Size_ROM_Sine-1 downto 0);
signal delta_val        : unsigned(C_MOD_Size_ROM_delta-1 downto 0);


-- In the two following lines the +1 is needed to manage the extra MSB introduced by the
-- unsigned to signed conversion of the amplitude

signal BIAS_modulation_amplitude_signed 	: signed(C_Size_bias_amplitude-1+1 downto 0);
--signal BIAS_modulation_amplitude_integer 	: integer range 0 to 255;
signal BIAS_modulation_amplitude_signed_24b	: signed(C_Size_bias_amplitude-1+1+15 downto 0);
--signal BIAS_modulator_constante				: signed(MOD_Size_DDS+ (Size_bias_amplitude-1) downto 0);
signal bias_modulate_buf					: signed(C_Size_DDS+C_MOD_Size_DDS+BIAS_modulation_amplitude_signed'length-1+1 downto 0);-- +8-1+1
signal BIAS_modulationXsin					: signed(dds_out_previous'length+BIAS_modulation_amplitude_signed'length-1 downto 0);-- 
signal BIAS_modulation_const				: signed(dds_out_previous'length+BIAS_modulation_amplitude'length-1 downto 0);-- 

-- DDS controls signals
signal counter				: unsigned(C_MOD_counter_size-1 downto 0);		-- DDS modultation counter for test pixel
signal addrs				: unsigned(C_MOD_ROM_Depth-1 downto 0);			-- ROM address part of the counter,
signal intrp				: unsigned(C_MOD_Size_intrp-1 downto 0);			-- Interpolation part of the counter






begin

BIAS_modulation_amplitude_signed 		<= signed('0' & BIAS_modulation_amplitude); -- in order to not create negative values 
BIAS_modulation_amplitude_signed_24b 	<= resize(BIAS_modulation_amplitude_signed,24) sll dds_out_previous'length-2;-- in order to by in proportional size
BIAS_modulationXsin						<= dds_out_previous*BIAS_modulation_amplitude_signed;
BIAS_modulation_const					<= to_signed((2**(dds_out_previous'length+BIAS_modulation_amplitude'length-1))-1,
													dds_out_previous'length+BIAS_modulation_amplitude'length); -- in order to be in proportional size
----------------------------------
-- DDS input controller (phases => counters)
----------------------------------

P_counter_modulation:process(Reset,CLK_4X)
	begin
-- counter increased with steps equal to counter_step
-- high values of the counter step give a fast rises of the counter and high DDS frequencies
		if (Reset = '1') then
			counter 	<= (others=>'0');
		elsif rising_edge (CLK_4X) then
			if (ENABLE_CLK_1X ='1') then
				if (START_STOP='0') then				
					counter 	<= (others=>'0');
				else
					counter <= (counter + BIAS_modulation_increment (C_MOD_counter_size-1 downto 0));
				end if;
			end if;
		end if;
end process; 	

addrs <= counter(C_MOD_counter_size-1 downto C_MOD_counter_size - C_MOD_ROM_Depth);
intrp <= counter(C_MOD_counter_size - C_MOD_ROM_Depth - 1 downto C_MOD_counter_size - C_MOD_ROM_Depth - C_MOD_Size_intrp);

--------------------------------------------------------
-- The ROM with the SINE values has 2**(MOD_ROM_Depth-2) points. 
-- An address offset of ROM_Range/4 makes a 90 deg phase shift.
-- An address offset of ROM_Range/2 makes a 180 deg phase shift.
-- and so on ...
--------------------------------------------------------


-- Computation of demodulation signals (I (cosine) and Q (sine) and addition of the delay correction phase)
--dds_counter <= 	((addrs - ROM_Range/4) & intrp) when START_STOP = '1'
--						else (others => '0');

----------------------------------
-- DDS ROM
----------------------------------
rom: entity work.MOD_ROM_dds  
port map	(
			RESET 		=> Reset,
			Clk 		=> CLK_4X,
			en 			=> '1',
			address_rom => address_rom,
			sine 		=> sine_val,
			delta 		=> delta_val	
    );
	
----------------------------------
-- DDS
----------------------------------
DDS: entity work.MOD_dds_generic
port map		(
				Reset              => Reset,
				Clk                => CLK_4X,
    
				counter            => dds_counter,
    
				address_rom        => address_rom, 
				sine_previous  	 => sine_val,	
				delta_previous 	 => delta_val,
    
				dds_previous   	 => dds_out_previous
				);

---------------------------------------------------------------------------------
P_modulation_calc:process(Reset, CLK_4X)
	begin

	if(Reset = '1') then
		bias_modulate_buf	<= (others=>'0');
		dds_counter 		<= (others=>'0');
   -- According to a 2 bit counter value the dds input and output are selected.
    -- Two clock periods separate the counter input in the DDS module and the output
    -- of the corresponding value.
	elsif rising_edge(CLK_4X) then
		if (ENABLE_CLK_1X ='1') then
			if START_STOP='0' then
				bias_modulate_buf	<= (others=>'0');
				dds_counter 		<= (others=>'0');
			else
				dds_counter <= 	((addrs - C_MOD_ROM_Range/4) & intrp);
				bias_modulate_buf <= resize(BIAS_in *(
										BIAS_modulation_const
									-  	BIAS_modulation_amplitude_signed_24b 
									+  	BIAS_modulationXsin(BIAS_modulationXsin'length-2 downto 0)),bias_modulate_buf'length);--  *  / BIAS_amplitude_signed+ bias_Modulator_constante   bias_Modulator_constante+bias_Modulator_constante
			end if;
		end if;
	end if;
end process;

BIAS_Out <=bias_modulate_buf(bias_modulate_buf'length-1-3 downto bias_modulate_buf'length-C_Size_DDS-3);--+8-1+1



end Behavioral;

