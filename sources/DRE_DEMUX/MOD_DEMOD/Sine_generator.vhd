----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Laurent Ravera, Antoine Clenet, Christophe Oziol
-- 
-- Create Date   : 07/07/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : sine_generator - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
--
-- Description:		Generation of sine waves with dds components
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.1 - File Created
-- Revision 0.2 - All DDS parameters (all signals) are function of ROM_Depth, Size_ROM_Sine and Size_ROM_delta defined in the athena_package
-- Revision 0.3 - separate DDS sine, sine_90, cos , Cos_90
-- Additional Comments: 
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.athena_package.all;
  
  
entity sine_generator is
port 	( 
--RESET
		Reset          	: in  std_logic;
		START_STOP     	: in  std_logic;
--CLOCKs
		CLK_4X			: in  std_logic;
		ENABLE_CLK_1X	: in  std_logic;
--CONTROL
		increment      	: in  unsigned(C_counter_size-1 downto 0);
		phi_delay      	: in  unsigned(C_Size_dds_phi-1 downto 0);
--		phi_rotate     	: in  unsigned(C_Size_dds_phi-1 downto 0);
		phi_initial    	: in  unsigned(C_Size_dds_phi_ini-1 downto 0);
		bias_amplitude 	: in  unsigned(C_Size_bias_amplitude-1 downto 0); -- pixel bias amplitude

		bias           	: out signed(C_Size_DDS_Sine_Out-1 downto 0);
		demoduI        	: out signed(C_Size_DDS_Sine_Out-1 downto 0);
		demoduQ        	: out signed(C_Size_DDS_Sine_Out-1 downto 0);
		remoduI        	: out signed(C_Size_DDS_Sine_Out-1 downto 0);
		remoduQ        	: out signed(C_Size_DDS_Sine_Out-1 downto 0)
		);
end entity;

---------------------------------------------------------------------------------

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.sine_generator.Behavioral.svg
architecture Behavioral of sine_generator is
---sines
signal address_rom_sines      	: unsigned((C_ROM_Depth-2)-1 downto 0);   	-- ROM_Depth-2 because only 1/4 of sine period is stored into the LUT
signal sine_val_sines         	: unsigned(C_Size_ROM_Sine-1 downto 0);
signal delta_val_sines        	: unsigned(C_Size_ROM_delta-1 downto 0);
signal sines 				  	: signed(C_Size_DDS_Sine_Out-1 downto 0);
---cosines
signal address_rom_cosines      : unsigned((C_ROM_Depth-2)-1 downto 0);   	-- ROM_Depth-2 because only 1/4 of sine period is stored into the LUT
signal sine_val_cosines         : unsigned(C_Size_ROM_Sine-1 downto 0);
signal delta_val_cosines        : unsigned(C_Size_ROM_delta-1 downto 0);
signal cosines 					: signed(C_Size_DDS_Sine_Out-1 downto 0);
---sines_90
signal address_rom_sines_90     : unsigned((C_ROM_Depth-2)-1 downto 0);   	-- ROM_Depth-2 because only 1/4 of sine period is stored into the LUT
signal sine_val_sines_90        : unsigned(C_Size_ROM_Sine-1 downto 0);
signal delta_val_sines_90       : unsigned(C_Size_ROM_delta-1 downto 0);
signal sines_90 				: signed(C_Size_DDS_Sine_Out-1 downto 0);
---cosines_90
signal address_rom_cosines_90	: unsigned((C_ROM_Depth-2)-1 downto 0);   	-- ROM_Depth-2 because only 1/4 of sine period is stored into the LUT
signal sine_val_cosines_90		: unsigned(C_Size_ROM_Sine-1 downto 0);
signal delta_val_cosines_90		: unsigned(C_Size_ROM_delta-1 downto 0);
signal cosines_90 				: signed(C_Size_DDS_Sine_Out-1 downto 0);

signal count_demoduI    		: unsigned(C_counter_size-1 downto 0);
signal count_demoduQ    		: unsigned(C_counter_size-1 downto 0);
signal count_remoduI    		: unsigned(C_counter_size-1 downto 0);
signal count_remoduQ    		: unsigned(C_counter_size-1 downto 0);

-- In the two following lines the +1 is needed to manage the extra MSB introduced by the
-- unsigned to signed conversion of the amplitude

signal bias_amplitude_signed 	: signed(C_Size_bias_amplitude-1+1 downto 0);
signal bias_buf					: signed(C_Size_DDS_Sine_Out+C_Size_bias_amplitude-1+1 downto 0);

begin

bias_amplitude_signed <= signed('0' & bias_amplitude); -- in order to not create negative values 

----------------------------------
-- DDS input controller (phases => counters)
----------------------------------

DDS_sig_controller: entity work.dds_signals_ctrl
port map	(
			Reset 			=> Reset, 
			START_STOP		=> START_STOP,
			CLK_4X			=> CLK_4X,
			ENABLE_CLK_1X 	=> ENABLE_CLK_1X,
			counter_step	=> increment,
			phi_delay		=> phi_delay,
--			phi_rotate		=> phi_rotate,  -- NOT USED YET
			phi_initial		=> phi_initial,
    
			count_demoduI	=> count_demoduI,
			count_demoduQ 	=> count_demoduQ,
			count_remoduI 	=> count_remoduI,
			count_remoduQ	=> count_remoduQ
	);

----------------------------------
-- DDS ROM sines
----------------------------------
rom_sines: entity work.rom_dds  
port map	(
			RESET 			=> Reset,
			CLK_4X 			=> CLK_4X,
			ENABLE_CLK_1X 	=> ENABLE_CLK_1X,
			en 				=> '1',
			address_rom 	=> address_rom_sines,
			sine 			=> sine_val_sines,
			delta 			=> delta_val_sines	
    );
	
----------------------------------
-- DDS_generic sines
----------------------------------
DDS_sines: entity work.dds_generic
port map		(
				Reset            => Reset,
				CLK_4X           => CLK_4X,
				ENABLE_CLK_1X   => ENABLE_CLK_1X,
    
				counter          => count_demoduI,
    
				address_rom      => address_rom_sines, 
				sine_previous  	 => sine_val_sines,	
				delta_previous 	 => delta_val_sines,
    
				dds_previous   	 => sines
				);
----------------------------------
-- DDS ROM cosines
----------------------------------
rom_cosines: entity work.rom_dds  
port map	(
			RESET 			=> Reset,
			CLK_4X 			=> CLK_4X,
			ENABLE_CLK_1X 	=> ENABLE_CLK_1X,
			en 				=> '1',
			address_rom 	=> address_rom_cosines,
			sine 			=> sine_val_cosines,
			delta 			=> delta_val_cosines
    );
	
----------------------------------
-- DDS_generic cosines
----------------------------------
DDS_cosines: entity work.dds_generic
port map		(
				Reset            => Reset,
				CLK_4X           => CLK_4X,
				ENABLE_CLK_1X   => ENABLE_CLK_1X,
    
				counter          => count_demoduQ,
    
				address_rom      => address_rom_cosines, 
				sine_previous  	 => sine_val_cosines,	
				delta_previous 	 => delta_val_cosines,
    
				dds_previous   	 => cosines
				);
----------------------------------
-- DDS ROM sines_90
----------------------------------
rom_sines_90: entity work.rom_dds  
port map	(
			RESET        	=> Reset,
			CLK_4X       	=> CLK_4X,
			ENABLE_CLK_1X   => ENABLE_CLK_1X,
			en           	=> '1',
			address_rom  	=> address_rom_sines_90,	
			sine		 	=> sine_val_sines_90,
			delta		 	=> delta_val_sines_90
    );
	
----------------------------------
-- DDS_generic sines_90
----------------------------------
DDS_sines_90:entity work.dds_generic
port map		(
				Reset            => Reset,
				CLK_4X           => CLK_4X,
				ENABLE_CLK_1X   => ENABLE_CLK_1X,
    
				counter          => count_remoduI,
    
				address_rom      => address_rom_sines_90, 
				sine_previous  	 => sine_val_sines_90,	
				delta_previous 	 => delta_val_sines_90,
    
				dds_previous   	 => sines_90
				);
----------------------------------
-- DDS ROM cosines_90
----------------------------------
rom_cosines_90: entity work.rom_dds  
port map	(
			RESET 			=> Reset,
			CLK_4X 			=> CLK_4X,
			ENABLE_CLK_1X 	=> ENABLE_CLK_1X,
			en 				=> '1',
			address_rom 	=> address_rom_cosines_90,
			sine 			=> sine_val_cosines_90,
			delta 			=> delta_val_cosines_90	
    );
	
----------------------------------
-- DDS_generic cosines_90
----------------------------------
DDS_cosines_90: entity work.dds_generic
port map		(
				Reset            => Reset,
				CLK_4X           => CLK_4X,
				ENABLE_CLK_1X   => ENABLE_CLK_1X,
    
				counter          => count_remoduQ,
    
				address_rom      => address_rom_cosines_90, 
				sine_previous  	 => sine_val_cosines_90,	
				delta_previous 	 => delta_val_cosines_90,
    
				dds_previous   	 => cosines_90
				);

---------------------------------------------------------------------------------

P_sine_gene: process(Reset, CLK_4X)
	begin

	if(Reset = '1') then
		bias_buf		<= (others=>'0');
		demoduI 		<= (others=>'0');
		demoduQ 		<= (others=>'0');
		remoduI 		<= (others=>'0');
		remoduQ 		<= (others=>'0');
   -- According to a 2 bit counter value the dds input and output are selected.
    -- Two clock periods separate the counter input in the DDS module and the output
    -- of the corresponding value.
	elsif rising_edge(CLK_4X) then
		if (ENABLE_CLK_1X = '1' ) then
			if START_STOP='0' then
	        bias_buf		<= (others=>'0');
	        demoduI 		<= (others=>'0');
	        demoduQ 		<= (others=>'0');
	        remoduI 		<= (others=>'0');
	        remoduQ 		<= (others=>'0');
			else
	            demoduI		<= sines;
	            demoduQ		<= cosines;
	            remoduI		<= sines_90;
				remoduQ		<= cosines_90;
	            bias_buf 	<= sines * bias_amplitude_signed;
	        end if;
		end if;
	end if;
end process P_sine_gene;

bias <= bias_buf(C_Size_DDS_Sine_Out-1 + C_Size_bias_amplitude-1 downto C_Size_bias_amplitude-1);


end Behavioral;
---------------------------------------------------------------------------------
