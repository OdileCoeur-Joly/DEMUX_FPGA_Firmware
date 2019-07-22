----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Antoine CLENET 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : RHF1201_CONTROLER - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : data science Filter for data sciences from Test Bias
--
-- Dependencies: Integrator_CIC,
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.athena_package.all;


entity science_filter_CIC is
	 generic	( 
				C_size_in  	: positive := 16;
				C_size_out 	: positive := 16
			);
   	Port 		(
--RESET
				reset    				: in STD_LOGIC;
				START_STOP				: in std_logic;
--CLOCKs
				CLK_4X		 			: in STD_LOGIC;
				ENABLE_CLK_1X 				: in STD_LOGIC;
				ENABLE_CLK_1X_DIV128			: in STD_LOGIC;

				data_in  				: in signed(C_size_in-1 downto 0);
				data_out 				: out signed(C_size_out-1 downto 0)
			);
end science_filter_CIC;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.science_filter_CIC.Behavioral.svg
architecture Behavioral of science_filter_CIC is


signal data_in_buff	: signed(43 downto 0);

signal Int_out_dat_1 : signed(41 downto 0);
signal Int_out_dat_2 : signed(34 downto 0);
signal Int_out_dat_3 : signed(28 downto 0);
signal Int_out_dat_4 : signed(23 downto 0);


signal Comb_out_dat_1 : signed(20 downto 0);
signal Comb_out_dat_2 : signed(19 downto 0);
signal Comb_out_dat_3 : signed(18 downto 0);
signal Comb_out_dat_4 : signed(17 downto 0);
--signal Comb_out_dat_5 : signed(17 downto 0);



begin

	data_in_buff<=resize (data_in,44);

-- Instantiation integrator1
   Integr1: entity work.Integrator_CIC
	Generic map	(
					size_in 		=> 44,
					size_out 		=> 42
			)	
	port map 	(
					reset 			=> reset,
					START_STOP 		=> START_STOP,
					CLK_4X 			=> CLK_4X,
					ENABLE_CLK_1X 		=> ENABLE_CLK_1X,
					Int_in_dat 		=> data_in_buff,
					Int_out_dat 		=> Int_out_dat_1
        		);
-- Instantiation integrator2
   Integr2: entity work.Integrator_CIC
	Generic map	(
					size_in 		=> 42,
					size_out 		=> 35
			)	
	port map 	(
					reset 			=> reset,
					START_STOP 		=> START_STOP,
					CLK_4X 			=> CLK_4X,
					ENABLE_CLK_1X 		=> ENABLE_CLK_1X,
					Int_in_dat 		=> Int_out_dat_1,
					Int_out_dat 		=> Int_out_dat_2
			);
-- Instantiation integrator3
   Integr3: entity work.Integrator_CIC
	Generic map	(
					size_in 		=> 35,
					size_out 		=> 29
			)	
	port map 	(
					reset 			=> reset,
					START_STOP 		=> START_STOP,
					CLK_4X 			=> CLK_4X,
					ENABLE_CLK_1X 		=> ENABLE_CLK_1X,
					Int_in_dat 		=> Int_out_dat_2,
					Int_out_dat 		=> Int_out_dat_3
        		);

-- Instantiation integrator3
	Integr4: entity work.Integrator_CIC
	Generic map	(
					size_in 		=> 29,
					size_out 		=> 24
			)	
	port map 	(
					reset 			=> reset,
					START_STOP 		=> START_STOP,
					CLK_4X 			=> CLK_4X,
					ENABLE_CLK_1X 		=> ENABLE_CLK_1X,
					Int_in_dat 		=> Int_out_dat_3,
					Int_out_dat 		=> Int_out_dat_4
        		);
		  
		  
-- Instantiation comb1
   Comb1: entity work.Comb_CIC 
	Generic map	(
					size_in 				=> 24,
					size_out 				=> 21
			)	
	port map 	(
					reset 					=> reset,
					CLK_4X					=> CLK_4X,
					ENABLE_CLK_1X_DIV128			=> ENABLE_CLK_1X_DIV128,
					comb_in_dat 				=> Int_out_dat_4,
					comb_out_dat 				=> Comb_out_dat_1
			);
		  
-- Instantiation comb2
   Comb2: entity work.Comb_CIC 
	Generic map	(
					size_in 				=> 21,
					size_out 				=> 20
			)	
	port map 	(
					reset 					=> reset,
					CLK_4X					=> CLK_4X,
					ENABLE_CLK_1X_DIV128			=> ENABLE_CLK_1X_DIV128,
					comb_in_dat 				=> Comb_out_dat_1,
					comb_out_dat 				=> Comb_out_dat_2
        		);		  

	-- Instantiation comb3
   Comb3: entity work.Comb_CIC 
	Generic map	(
					size_in 				=> 20,
					size_out 				=> 19
			)	
	port map 	(
					reset 					=> reset,
					CLK_4X					=> CLK_4X,
					ENABLE_CLK_1X_DIV128			=> ENABLE_CLK_1X_DIV128,
					comb_in_dat 				=> Comb_out_dat_2,
					comb_out_dat 				=> Comb_out_dat_3
        		);

-- Instantiation comb4
   Comb4: entity work.Comb_CIC 
	Generic map	(
					size_in 				=> 19,
					size_out 				=> 18
			)	
	port map 	(
					reset 					=> reset,
					CLK_4X					=> CLK_4X,
					ENABLE_CLK_1X_DIV128			=> ENABLE_CLK_1X_DIV128,
					comb_in_dat 				=> Comb_out_dat_3,
					comb_out_dat 				=> Comb_out_dat_4
        		);

	  
--   Compensation_filter: entity work.Filter_compensation_CIC
--	Generic map	(
--					size 					=> 18
--			)
--	port map	(
--					Reset					=> reset,
--					CLK_4X					=> CLK_4X,
--					ENABLE_CLK_1X_DIV128			=> ENABLE_CLK_1X_DIV128,
--					data_in					=> Comb_out_dat_4,
--					data_out				=> Comb_out_dat_5
--			);
data_out <= resize(Comb_out_dat_4(17 downto 2),C_size_out);		  
  
end Behavioral;
