----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL
-- 
-- Create Date   : 31/07/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : CDCM7005_CONTROLER - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : CDCM SPI controler based on SPI_CONTROLER
--
-- Dependencies: SPI_CONTROLER, athena package
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

entity CDCM7005_CONTROLER is
    Port 	( 
--RESET
				RESET					: in  STD_LOGIC;
--CLOCKs
				CLK_4X					: in  STD_LOGIC;
				ENABLE_CLK_1X_DIV128	: in  STD_LOGIC;
-- FROM/TO CDCM7005 CONTROLER
				SPI_command 			: in  std_logic_vector(29 downto 0);
				SPI_address 			: in  std_logic_vector(1 downto 0);
				SPI_write 				: in  std_logic;
				SPI_ready 				: out  std_logic;
				CDCM_SCLK				: out  STD_LOGIC;
				CDCM_SLE				: out  STD_LOGIC;
				CDCM_RST_N				: out  STD_LOGIC;
				CDCM_SDIN				: out  STD_LOGIC
				);
end CDCM7005_CONTROLER ;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.CDCM7005_CONTROLER.Behavioral.svg
architecture Behavioral of CDCM7005_CONTROLER  is

signal  SPI_DATA_SEND		: STD_LOGIC_VECTOR(31 downto 0);

begin
-- SPI controler
	CDCM_SPI_CONTROLER : entity work.SPI_CONTROLER
	generic map (
					C_Size_DATA 			=> 32
				)
	Port map ( 
				RESET 					=> RESET,
				CLK_4X 					=> CLK_4X,
				ENABLE_CLK_1X_DIV128 	=> ENABLE_CLK_1X_DIV128,
				SPI_write 				=> SPI_write,
				SPI_DATA_SEND 			=> SPI_DATA_SEND,
				SPI_DATA_RECEIVED 		=> open,-- no data returned from CDCM
				SPI_SDO 				=> '0',
				SPI_SDIO 				=> CDCM_SDIN,
				SPI_SCLK 				=> CDCM_SCLK,
				SPI_CS_N 				=> CDCM_SLE,
				SPI_ready 				=> SPI_ready
				);
-- associate CDCM adress and data to send to spi_controler	
p_create_data_spi: process(RESET,CLK_4X)
	begin
		if (RESET='1') then -- RESET
			CDCM_RST_N <= '0'; -- reset CDCM 
			SPI_DATA_SEND <= (others => '0');
		elsif rising_edge(CLK_4X) then
			if (ENABLE_CLK_1X_DIV128 ='1') then -- for slow sending compatibility with SPI
				CDCM_RST_N <= '1';	-- end of reset CDCM
				SPI_DATA_SEND(29 downto 0)	<= SPI_command; -- position of command in 32 bits word for CDCM
				SPI_DATA_SEND(31 downto 30) <= SPI_address; -- position of address in 32 bits word for CDCM
			end if;
		end if;
end process;


end Behavioral;

