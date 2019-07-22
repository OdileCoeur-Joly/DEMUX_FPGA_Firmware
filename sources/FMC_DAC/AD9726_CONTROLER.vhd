----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : AD9726_CONTROLER - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : AD9726 DAC controler via SPI_CONTROLER module
-- 					DATA to DAC are schronized to CLOCK DAC output
--
-- Dependencies	 : SPI_CONTROLER
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


entity AD9726_CONTROLER is
    Port 	( 
--RESET
				RESET					: in  STD_LOGIC;
--CLOCKs
				CLK_4X					: in  STD_LOGIC;
--				CLK_1X					: in  STD_LOGIC;
				ENABLE_CLK_1X_DIV128	: in  STD_LOGIC;
--CONTROL
				DAC_ON					: in  STD_LOGIC;
				SPI_command 			: in  STD_LOGIC_VECTOR(2 downto 0); --R/W_N bit 2 / N1 et N0 transfert number of data bytes 1 2 3 4 (00 = 1 byte)
				SPI_address 			: in  STD_LOGIC_VECTOR(4 downto 0); -- A4 A3 A2 A1 A0
				SPI_data 				: in  STD_LOGIC_VECTOR(7 downto 0);
				SPI_write				: in  STD_LOGIC;
				SPI_DATA_RECEIVED		: out STD_LOGIC_VECTOR(7 downto 0);
				SPI_ready				: out STD_LOGIC;

--				DCLK_FROM_DAC			: in  STD_LOGIC;
				DATA_TO_DAC				: in  STD_LOGIC_VECTOR(15 downto 0);
				DCLK_TO_DAC				: out STD_LOGIC;
				DB_OUT					: out STD_LOGIC_VECTOR(15 downto 0);
				SPI_SDO					: in  STD_LOGIC;
				SPI_SDIO				: out STD_LOGIC;
				SPI_SCLK				: out STD_LOGIC;
				SPI_CS_N				: out STD_LOGIC;
				DAC_RESET_IN			: in  STD_LOGIC;
				DAC_RESET 				: out STD_LOGIC
				);
end AD9726_CONTROLER;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.AD9726_CONTROLER.Behavioral.svg
architecture Behavioral of AD9726_CONTROLER is

signal  SPI_DATA_SEND		: STD_LOGIC_VECTOR(15 downto 0);


begin
	DAC_SPI_CONTROLER : entity work.SPI_CONTROLER
	generic map (
					C_Size_DATA =>16
					)
	Port map ( 
				RESET 					=> RESET,
				CLK_4X 					=> CLK_4X,
				ENABLE_CLK_1X_DIV128 	=> ENABLE_CLK_1X_DIV128,
				SPI_write 				=> SPI_write,
				SPI_DATA_SEND 			=> SPI_DATA_SEND,
				SPI_DATA_RECEIVED 		=> SPI_DATA_RECEIVED,
				SPI_SDO 				=> SPI_SDO,
				SPI_SDIO 				=> SPI_SDIO,
				SPI_SCLK 				=> SPI_SCLK,
				SPI_CS_N 				=> SPI_CS_N,
				SPI_ready 				=> SPI_ready
				);
	
P_SPI_DATA: process(RESET,CLK_4X)
	begin
		if (RESET='1') then
			DAC_RESET <= '1';
			SPI_DATA_SEND <= (others => '0');
		elsif rising_edge(CLK_4X) then
			if (ENABLE_CLK_1X_DIV128 ='1') then
					DAC_RESET <= DAC_RESET_IN;
					SPI_DATA_SEND(15 downto 13) <= SPI_command;
					SPI_DATA_SEND(12 downto 8)  <= SPI_address;
					SPI_DATA_SEND(7 downto 0) 	<= SPI_data;
			end if;
		end if;
end process P_SPI_DATA;

DCLK_TO_DAC <= CLK_4X when (DAC_ON = '1') else '0';

P_sync_data_DAC:process(RESET,CLK_4X)
	begin
		if (RESET='1') then
			DB_OUT <= (others => '0');
		elsif rising_edge(CLK_4X) then
			if (DAC_ON = '1') then
				DB_OUT <= DATA_TO_DAC;
			else 
				DB_OUT <= (others => '0');
			end if;
		end if;
end process P_sync_data_DAC;

end Behavioral;

