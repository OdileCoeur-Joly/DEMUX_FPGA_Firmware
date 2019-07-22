----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Laurent Ravera, Antoine Clenet
-- 
-- Create Date   : 09/07/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : dds_signals_ctrl - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description: 	Setting of the DDS inputs (counter values) for the different 
--					sine waves needed for the processing of the BBFB of a canal
--					according to the signal phases.
--
-- Dependencies	 : 
--
-- Revision: 
-- Revision 0.1 - File Created
-- Revision 0.2 - All DDS parameters (all signals) are function of ROM_Depth, Size_ROM_Sine and Size_ROM_delta defined in the athena_package
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.athena_package.all;



entity dds_signals_ctrl is	
port	(
--RESET
		Reset         	: in std_logic; 
		START_STOP    	: in std_logic;
--CLOCKs
		CLK_4X			: in std_logic;
		ENABLE_CLK_1X	: in std_logic;

--CONTROL
		counter_step  	: in unsigned(C_counter_size-1 downto 0); 
		phi_delay     	: in unsigned(C_Size_dds_phi-1 downto 0);
--		phi_rotate    	: in unsigned(C_Size_dds_phi-1 downto 0);
		phi_initial   	: in unsigned(C_Size_dds_phi_ini-1 downto 0);
    
		count_demoduI 	: out unsigned(C_counter_size-1 downto 0);
		count_demoduQ 	: out unsigned(C_counter_size-1 downto 0);
		count_remoduI 	: out unsigned(C_counter_size-1 downto 0);
		count_remoduQ 	: out unsigned(C_counter_size-1 downto 0)
		);
end entity;


--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.dds_signals_ctrl.Behavioral.svg
architecture Behavioral of dds_signals_ctrl is

signal counter				: unsigned(C_counter_size-1 downto 0);		-- DDS counter for one pixel
signal addrs				: unsigned(C_ROM_Depth-1 downto 0);			-- ROM address part of the counter,
signal intrp				: unsigned(C_Size_intrp-1 downto 0);			-- Interpolation part of the counter
signal phi_initial_buf		: unsigned(C_counter_size -1 downto 0);
signal phi_delay_buf		: unsigned(C_counter_size-1 downto 0);




begin
phi_initial_buf <= 	resize(phi_initial,C_counter_size) sll (integer( C_counter_size - C_Size_dds_phi_ini ));
phi_delay_buf 	<= 	resize(phi_delay,C_counter_size)   sll (integer( C_counter_size - C_Size_dds_phi));

P_counter: process(Reset, CLK_4X)
	begin
-- counter increased with steps equal to counter_step
-- high values of the counter step give a fast rises of the counter and high DDS frequencies
		if (Reset = '1') then
			counter 				<= (others=>'0');
		elsif rising_edge (CLK_4X) then
			if (ENABLE_CLK_1X ='1') then
				if (START_STOP ='0') then
					counter 	<= (others=>'0');	
				else
					counter <= (counter + counter_step);
				end if;
			end if;
		end if;
end process P_counter; 	
--phi_initial_sized(counter_size-1 downto counter_size-Size_dds_phi_ini) 	<= phi_initial;
--phi_delay_sized(counter_size-1 downto counter_size-Size_dds_phi)		 	<= phi_delay;

addrs <= counter(C_counter_size-1 downto C_counter_size - C_ROM_Depth);
--intrp <= counter(Size_ROM_delta-1 downto 0);
intrp <= counter(C_counter_size - C_ROM_Depth - 1 downto C_counter_size - C_ROM_Depth - C_Size_intrp);

--------------------------------------------------------
-- The ROM with the SINE values has 2**(ROM_Depth-2) points. 
-- An address offset of ROM_Range/4 makes a 90 deg phase shift.
-- An address offset of ROM_Range/2 makes a 180 deg phase shift.
-- and so on ...
--------------------------------------------------------


-- Computation of demodulation signals (I (cosine) and Q (sine) and addition of the delay correction phase)
count_demoduI <= 	(addrs & intrp) + resize(phi_initial_buf + phi_delay_buf,C_counter_size);-- when START_STOP = '1' 
						--else (others => '0');	

count_demoduQ <= 	((addrs - C_ROM_Range/4) & intrp) + resize(phi_initial_buf + phi_delay_buf,C_counter_size);-- when START_STOP = '1'
						--else (others => '0');

-- Computation of re-modulation signals (I (cosine) and Q (sine))
count_remoduI <= 	(addrs & intrp) + resize(phi_initial_buf,C_counter_size);-- when START_STOP = '1'
						--else (others => '0');

count_remoduQ <= 	((addrs - C_ROM_Range/4) & intrp) + resize(phi_initial_buf,C_counter_size);-- when START_STOP = '1'
						--else (others => '0');
							
end Behavioral;
---------------------------------------------------------------------------------
