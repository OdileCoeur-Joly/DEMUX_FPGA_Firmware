----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Laurent Ravera / Antoine CLENET / Christophe OZIOL
-- 
-- Create Date   : 31/07/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : BBFB_full - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Base Band Feedback Block module
--
-- Dependencies: athena_package
--
-- Revision: 
-- Revision 0.2  - Change for one unique process for all the BBFB (name changed to BBFB_full)
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.athena_package.all;


entity BBFB_full is
    Port ( 	
--RESET
		reset			:	in std_logic;	  
		START_STOP		:	in std_logic;
--CLOCKs
    	CLK_4X			:	in std_logic;
    	ENABLE_CLK_1X	:	in std_logic;
--CONTROL
		SW1				:	in std_logic;						-- switch for selecting outscience output I/Q signal (with CIC or without)
		SW2				:	in unsigned(1 downto 0);			-- switch for selecting integrator input for feedback (0, Contant_FB or inphys)
		gain_BBFB		:	in unsigned(C_Size_gain-1 downto 0);	-- Gain of the BBFB integrator
		CONSTANT_FB		: 	in signed(15 downto 0);				-- Constant value for the integrator input

		In_Real			:	in signed(C_Size_In_Real-1 downto 0); -- Physic input from select_input
		DemoduI			:	in signed(C_Size_DDS-1 downto 0);		-- For de-modulation (in-phase signal   -> cos)
		DemoduQ			:	in signed(C_Size_DDS-1 downto 0);		-- For de-modulation (quadrature signal -> sine)
		RemoduI			:	in signed(C_Size_DDS-1 downto 0);		-- For re-modulation (in-phase signal   -> cos)
		RemoduQ			:	in signed(C_Size_DDS-1 downto 0);		-- For re-modulation (quadrature signal -> sine)
				
		Feedback		:	out signed(C_Size_DDS-1 downto 0); -- output feedback (remodulated signal)
								
		Out_Science_I	:	out signed(C_Size_science-1 downto 0); -- Science output I to TM acquisition
		Out_Science_Q	:	out signed(C_Size_science-1 downto 0)	 -- Science output Q to TM acquisition
		);
end BBFB_full;


--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.BBFB_full.Behavioral.svg
architecture Behavioral of BBFB_full is



-- De-modulated signal (before the integrator)
signal signal_Phy_demodu_I	: signed(In_Real'length + DemoduI'length-1 downto 0);	-- I part -- +1 to set the demodulator output to 13 bits
signal signal_Phy_demodu_Q	: signed(In_Real'length + DemoduQ'length-1 downto 0);	-- Q part
signal accu_buffI 		:	signed(C_Size_Accu-1 downto 0); 
signal accu_buffQ 		:	signed(C_Size_Accu-1 downto 0); 
signal accu_halfI 		:	signed(C_Size_Accu-1 downto 0); 
signal accu_halfQ 		:	signed(C_Size_Accu-1 downto 0); 
constant C_half_lsb 	: signed (C_Size_Accu-1 downto 0) := (C_Size_Accu-1-C_Size_science-1 =>'1', others =>'0');

-- Re-modulator input (could be the integrator output or a constant according to the bbfb sw2 mode)

signal sig_IntegratorI		: signed(C_Size_science-1 downto 0); -- Integrator I signal output
signal sig_IntegratorQ		: signed(C_Size_science-1 downto 0); -- Integrator Q signal output

signal to_remodu_I			: signed(C_Size_science-1 downto 0);	-- I part Feedback signal to remodulator
signal to_remodu_Q			: signed(C_Size_science-1 downto 0);	-- Q part Feedback signal to remodulator

signal Real_out_buff			: signed(to_remodu_I'length+RemoduI'length-1 downto 0); -- buffer to store real value 
signal Real_out_half 			: signed (Real_out_buff'length-1 downto 0);
constant C_half_lsb_REAL_out 	: signed (Real_out_buff'length-1 downto 0) := (Real_out_buff'length-1-C_Size_DDS-1 =>'1', others =>'0');



begin

p_demod_and_accu_IQ: process(CLK_4X)
begin
	if rising_edge(CLK_4X) then
		if (reset = '1' or START_STOP = '0') then
			signal_Phy_demodu_I 		<= (others => '0');
			signal_Phy_demodu_Q 		<= (others => '0');
			accu_buffI  				<= (others => '0');	
			accu_halfI 					<= (others => '0'); 
			accu_buffQ  				<= (others => '0');	
			accu_halfQ 					<= (others => '0'); 
			Real_out_buff 				<= (others => '0');
			Real_out_half 				<= (others => '0');
					elsif (ENABLE_CLK_1X='1') then
-----------------------------------------------------------------------------------
-- De-modulation of input signal
-----------------------------------------------------------------------------------
			signal_Phy_demodu_I <= In_Real * DemoduI;
			signal_Phy_demodu_Q <= In_Real * DemoduQ;
-----------------------------------------------------------------------------------
-- Integrator (Real part)
-----------------------------------------------------------------------------------
			accu_buffI <=  (signal_Phy_demodu_I(signal_Phy_demodu_I'length-2 downto 0)*signed('0' & gain_BBFB))+ accu_buffI;-- -2 in order to suppress the duplicated sign bit
			accu_halfI <=  accu_buffI (accu_buffI'length-2 downto 0) +  C_half_lsb;
-----------------------------------------------------------------------------------
-- Integrator (Imaginary part)
-----------------------------------------------------------------------------------
			accu_buffQ <=  (signal_Phy_demodu_Q(signal_Phy_demodu_Q'length-2 downto 0)*signed('0' & gain_BBFB))+ accu_buffQ;-- -2 in order to suppress the duplicated sign bit
			accu_halfQ <=  accu_buffQ (accu_buffQ'length-2 downto 0) +  C_half_lsb;

-----------------------------------------------------------------------------------
-- Re-modulation to compute feedback signal
-----------------------------------------------------------------------------------
			Real_out_buff <= (to_remodu_I * RemoduI) + (to_remodu_Q * RemoduQ); -- Real part calculation
-- signal Real_out_buff -1 sign bit + half lsb sum result
			Real_out_half <= Real_out_buff (Real_out_buff'length-2 downto 0) +  C_half_lsb_REAL_out;
		end if;
	end if;
end process;


-----------------------------------------------------------------------------------
-- trunc part Integrator (Real part)
-----------------------------------------------------------------------------------

			sig_IntegratorI <= accu_halfI(accu_halfI'length-2 downto accu_halfI'length-sig_IntegratorI'length-1);
-----------------------------------------------------------------------------------
-- trunc part Integrator (Imaginary part)
-----------------------------------------------------------------------------------
			sig_IntegratorQ <= accu_halfQ(accu_halfQ'length-2 downto accu_halfQ'length-sig_IntegratorQ'length-1);
			
-----------------------------------------------------------------------------------
-- trunc Real_out_half to feedback size 
-----------------------------------------------------------------------------------
			Feedback <=  Real_out_half(Real_out_buff'length-2 downto Real_out_buff'length-1-Feedback'length);
-----------------------------------------------------------------------------------
-- Signal selection according to bbfb mode
-----------------------------------------------------------------------------------

to_remodu_I <=	sig_IntegratorI		when SW2 = "00"		--mode_bbfb	
				else (CONSTANT_FB)	when SW2 = "01"		--mode_scan_fb
				else (others=>'0')	when SW2 = "10"
				else (others=>'0')	when SW2 = "11";
					
to_remodu_Q <=	sig_IntegratorQ 	when SW2 = "00"		-- mode_bbfb
				else (others=>'0')	when SW2 = "01"		--mode_scan_fb
				else (others=>'0')	when SW2 = "10"
				else (others=>'0')	when SW2 = "11";
				
-- Out_Science_I	<=	sig_IntegratorI								    when SW1 = '0'	--	sig_IntegratorI = 20 bits Out_Science_I )= 16 bits
				-- else 	resize(signal_Phy_demodu_I,Size_science)	when SW1 = '1'; --Changer le nom du signal
				
-- Out_Science_Q	<=	sig_IntegratorQ									when SW1 = '0' 
				-- else 	resize(signal_Phy_demodu_Q,Size_science)	when SW1 = '1';
Out_Science_I	<=	sig_IntegratorI							when SW1 = '0'	--	sig_IntegratorI = 20 bits Out_Science_I )= 16 bits
				else 	signal_Phy_demodu_I(signal_Phy_demodu_I'length-2 downto signal_Phy_demodu_I'length-1-C_Size_science)	when SW1 = '1'; -- -2 in order to suppress the duplicated sign bit
				
Out_Science_Q	<=	sig_IntegratorQ							when SW1 = '0' 
				else 	signal_Phy_demodu_Q(signal_Phy_demodu_Q'length-2 downto signal_Phy_demodu_Q'length-1-C_Size_science)	when SW1 = '1';-- -2 in order to suppress the duplicated sign bit

					
end Behavioral;