----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : RHF1201_CONTROLER - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : RHF1201 ADC managment module
--
-- Dependencies: 
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
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RHF1201_controler is
    Port (
--RESET
			RESET 				: in  STD_LOGIC;
--CLOCKs
			CLK_4X				: in  STD_LOGIC;
			CLK_1X				: in  STD_LOGIC;
			ENABLE_CLK_1X		: in  STD_LOGIC;
--CONTROL
			CONTROL				: in	t_CONTROL_RHF1201;
--STATUS
			STATUS				: out	t_STATUS_RHF1201;
			OUT_OF_RANGE_ADC	: in  STD_LOGIC;
			OUT_OF_RANGE 		: out STD_LOGIC;

			DIN 				: in  signed (11 downto 0);
			DOUT 				: out signed (11 downto 0);
--			DATA_READY 			: in  STD_LOGIC;
			CLOCK_TO_ADC 		: out STD_LOGIC;
--			CLOCK_FROM_ADC 		: in  STD_LOGIC;
			ADC_READY			: OUT STD_LOGIC;
			OE_N 				: out STD_LOGIC;
			SLEW_RATE_CONTROL 	: out STD_LOGIC;
			DATA_FORMAT_SEL_N 	: out STD_LOGIC
			);
end RHF1201_controler;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.RHF1201_controler.Behavioral.svg
architecture Behavioral of RHF1201_controler is

signal COUNT_RESET  			: integer range 1024 downto 0;
signal ADC_READY_int			: STD_LOGIC;
signal OE_N_int					: STD_LOGIC;
signal ADC_ON					: STD_LOGIC;
signal DOUT_CLK_1X				: signed (11 downto 0);
signal OUT_OF_RANGE_int			: STD_LOGIC;
signal CLOCK_TO_ADC_EN			: STD_LOGIC;
begin
	SLEW_RATE_CONTROL 		 	<= CONTROL.SLEW_RATE_CONTROL;
	DATA_FORMAT_SEL_N 		 	<= CONTROL.DATA_FORMAT_SEL_N;
	STATUS.ADC_READY 			<= ADC_READY_int;
	ADC_READY 					<= ADC_READY_int;
	STATUS.OUT_OF_RANGE			<= OUT_OF_RANGE_int;
	OUT_OF_RANGE 				<= OUT_OF_RANGE_int;
	STATUS.ADC_OE_N				<= OE_N_int;
	OE_N						<= OE_N_int;
	CLOCK_TO_ADC 				<= CLK_1X when  CLOCK_TO_ADC_EN ='1' else '0';
	ADC_ON						<= CONTROL.ADC_ON;
----------------------------------------------------------------------------------------------------
-- FADC ENABLE
----------------------------------------------------------------------------------------------------
P_wait_reset_ADC: process (RESET,CLK_4X)
begin
	if (RESET='1') then
	OE_N_int		<= '1';
	CLOCK_TO_ADC_EN <= '0';
	COUNT_RESET 	<= 0;
	ADC_READY_int 	<= '0';
	elsif (rising_edge(CLK_4X)) then
		if (ENABLE_CLK_1X ='1') then
			if (ADC_ON ='1') then
				CLOCK_TO_ADC_EN 	<= '1';
				if (COUNT_RESET < 1023 ) then
					COUNT_RESET 	<= COUNT_RESET + 1;
				else
					OE_N_int		<='0';
					ADC_READY_int 	<= '1';
				end if;
			else
				OE_N_int		<='1';
				CLOCK_TO_ADC_EN <= '0';
				COUNT_RESET 	<= 0;
				ADC_READY_int 	<= '0';
			end if;
		end if;
	end if;
end process P_wait_reset_ADC;
----------------------------------------------------------------------------------------------------
-- FADC DATA_LOAD
----------------------------------------------------------------------------------------------------
P_sync_DATA_ADC: process (RESET,CLK_1X)
begin
	if (RESET='1') then
	DOUT_CLK_1X <= (others=>'0');
	OUT_OF_RANGE_int	<= '0';
	elsif (falling_edge(CLK_1X)) then
		if (ADC_READY_int ='1') then
				DOUT_CLK_1X 		<= DIN;
				OUT_OF_RANGE_int	<= OUT_OF_RANGE_ADC;
		else 
				DOUT_CLK_1X 		<= (others=>'0');
				OUT_OF_RANGE_int	<= '0';
		end if;
	end if;
end process P_sync_DATA_ADC;
----------------------------------------------------------------------------------------------------
-- FADC DATA_LOAD
----------------------------------------------------------------------------------------------------
P_resync_data_enable: process (RESET,CLK_4X)
begin
	if (RESET='1') then
	DOUT <= (others=>'0');
	elsif (rising_edge(CLK_4X)) then
		if (ENABLE_CLK_1X='1') then
			if (ADC_READY_int ='1') then
					DOUT <= DOUT_CLK_1X;
			else 
					DOUT <= (others=>'0');
			end if;
		end if;
	end if;
end process P_resync_data_enable;
end Behavioral;

