----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Antoine CLENET/ Laurent RAVERA/ Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : RHF1201_CONTROLER - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Select input of the Channel (external: ADC or internal Squid)
--
-- Dependencies: 
--
-- Revision:0.1 - BBFB not multiplexed (4 DDS)
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.athena_package.all;


entity pixel is
	Port (
--RESET
			Reset					:	in std_logic;
			START_STOP				:	in std_logic;
--CLOCK
			CLK_4X					:	in std_logic;
			ENABLE_CLK_1X			:	in std_logic;
			ENABLE_CLK_1X_DIV128	:	in std_logic;
--CONTROL
			CONTROL_PIXEL_BBFB		:	in t_CONTROL_PIXEL;
			CONSTANT_FB				: 	in 	signed(15 downto 0);

			In_phys					:	in signed(C_Size_In_Real-1 downto 0);
			Bias					:	out signed(C_Size_DDS-1 downto 0);
			Feedback				:	out signed(C_Size_one_feedback-1 downto 0);
			Out_unfiltred_I			:	out signed(C_Size_science-1 downto 0);
			Out_unfiltred_Q			:	out signed(C_Size_science-1 downto 0);
			Out_filtred_I			:	out signed(C_Size_science-1 downto 0);
			Out_filtred_Q			:	out signed(C_Size_science-1 downto 0)
			);
end pixel;


--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.pixel.Behavioral.svg
architecture Behavioral of pixel is

signal DemoduI					: signed(C_Size_DDS-1 downto 0);
signal DemoduQ					: signed(C_Size_DDS-1 downto 0);
signal RemoduI					: signed(C_Size_DDS-1 downto 0);
signal RemoduQ					: signed(C_Size_DDS-1 downto 0);
signal Science_data_in_CIC_I	: signed(C_Size_science-1 downto 0);
signal Science_data_in_CIC_Q	: signed(C_Size_science-1 downto 0);
signal Science_data_out_CIC_I	: signed(C_Size_science-1 downto 0);
signal Science_data_out_CIC_Q	: signed(C_Size_science-1 downto 0);

begin

-----------------------------------------------------------------------------------
-- BaseBand Feedback module
-----------------------------------------------------------------------------------
BBFB_module : entity work.BBFB_full
    Port map
			(
			reset			=> Reset,
			START_STOP		=> START_STOP,

			CLK_4X			=> CLK_4X,
			ENABLE_CLK_1X	=> ENABLE_CLK_1X,
		
			SW1 			=> CONTROL_PIXEL_BBFB.SW1,
			SW2 			=> CONTROL_PIXEL_BBFB.SW2,
			gain_BBFB		=> CONTROL_PIXEL_BBFB.gain_BBFB,	
			CONSTANT_FB		=> CONSTANT_FB,
				
			In_Real 		=> In_phys,
							
			DemoduI		 	=> DemoduI,	-- For de-modulation (in-phase signal   -> cos)
			DemoduQ		 	=> DemoduQ,	-- For de-modulation (quadrature signal -> sine)
			RemoduI		 	=> RemoduI,	-- For re-modulation (in-phase signal   -> cos)
			RemoduQ		 	=> RemoduQ,	-- For re-modulation (quadrature signal -> sine)
--			DemoduI		 	=> (others =>'0'),	-- For de-modulation (in-phase signal   -> cos)
--			DemoduQ		 	=> (others =>'0'),	-- For de-modulation (quadrature signal -> sine)
--			RemoduI		 	=> (others =>'0'),	-- For re-modulation (in-phase signal   -> cos)
--			RemoduQ		 	=> (others =>'0'),	-- For re-modulation (quadrature signal -> sine)
				
			Feedback 		=> Feedback,
								
			Out_Science_I	=> Science_data_in_CIC_I,
			Out_Science_Q	=> Science_data_in_CIC_Q
			);
			
-----------------------------------------------------------------------------------
-- Instanciate CIC REAL PART
-----------------------------------------------------------------------------------
CIC_SCIENCE_I : entity work.science_filter_CIC
	 generic map
				(
				C_size_in 	=>		C_Size_science,
				C_size_out	=>		C_Size_science
			   )
    Port map(
				reset					=>	Reset,
				START_STOP				=>	START_STOP,

				CLK_4X					=>  CLK_4X,
				ENABLE_CLK_1X			=>	ENABLE_CLK_1X,
				ENABLE_CLK_1X_DIV128	=>	ENABLE_CLK_1X_DIV128,
				
				data_in  				=> Science_data_in_CIC_I,
				data_out  				=>	Science_data_out_CIC_I
				);

----------------------------------------------------------------------------------
-- Instanciate CIC IMAGINARY PART
-----------------------------------------------------------------------------------
CIC_SCIENCE_Q : entity work.science_filter_CIC
	 generic map
				(
				C_size_in 	=>		C_Size_science,
				C_size_out	=>		C_Size_science
			   )
    Port map(
				reset					=>	Reset,
				START_STOP				=>	START_STOP,
				CLK_4X					=> CLK_4X,
				ENABLE_CLK_1X			=>	ENABLE_CLK_1X,
				ENABLE_CLK_1X_DIV128	=>	ENABLE_CLK_1X_DIV128,
				
				data_in  				=> Science_data_in_CIC_Q,
				data_out  				=>	Science_data_out_CIC_Q
				);

-- transfer of output filtred
-- and not filtred data
-----------------------------------------------------------------------------------
Out_unfiltred_I	<= 	Science_data_in_CIC_I; 	--20 MHz enable_clk_1X
Out_filtred_I 	<=	Science_data_out_CIC_I;	-- 256kHz enable_clk_1x_div128
Out_unfiltred_Q	<= 	Science_data_in_CIC_Q;	--20 MHz enable_clk_1X
Out_filtred_Q 	<=	Science_data_out_CIC_Q;	-- 256kHz enable_clk_1x_div128			

-----------------------------------------------------------------------------------
-- DDS module to compute bias, modulation and demodulation sine waves 
-----------------------------------------------------------------------------------

Mod_Demod_signals_generator : entity work.sine_generator
port map
		( 
		Reset 			=> Reset,
		START_STOP		=> START_STOP,

		CLK_4X			=> CLK_4X,				
		ENABLE_CLK_1X 	=> ENABLE_CLK_1X,

		increment		=> CONTROL_PIXEL_BBFB.increment,
		phi_delay		=> CONTROL_PIXEL_BBFB.PHI_DELAY,
--		phi_rotate		=> CONTROL_PIXEL_BBFB.PHI_ROTATE,
		phi_initial		=> CONTROL_PIXEL_BBFB.PHI_INITIAL,
		bias_amplitude	=> CONTROL_PIXEL_BBFB.BIAS_amplitude,	

		bias 			=> Bias,
		demoduI 		=> DemoduI,
		demoduQ 		=> DemoduQ,
		remoduI 		=> RemoduI,
		remoduQ 		=> RemoduQ
		);

end Behavioral;

