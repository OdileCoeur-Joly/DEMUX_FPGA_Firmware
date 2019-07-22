----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL
-- 
-- Create Date   : 31/07/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : SPI_CONTROLER - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : SPI controler with data input 8 bits and sizeable output
-- Dependencies: athena package
--
-- Revision: 

-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_CONTROLER is
	generic 	(
				C_Size_DATA		: positive := 16
				);
	Port 		
			(
--RESET
			RESET 					: in  STD_LOGIC;
--CLOCKs
			CLK_4X 					: in  STD_LOGIC;
			ENABLE_CLK_1X_DIV128	: in  STD_LOGIC;

			SPI_write				: in  STD_LOGIC;
			SPI_DATA_SEND 			: in  STD_LOGIC_VECTOR(C_Size_DATA-1 downto 0);
			SPI_DATA_RECEIVED		: out STD_LOGIC_VECTOR(7 downto 0);
			SPI_SDO	 				: in  STD_LOGIC;
			SPI_SDIO 				: out STD_LOGIC;
			SPI_SCLK 				: out STD_LOGIC;
			SPI_CS_N				: out STD_LOGIC;
			SPI_ready				: out STD_LOGIC
			);
end SPI_CONTROLER;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.SPI_CONTROLER.Behavioral.svg
architecture behavioral of SPI_CONTROLER is

type 	t_state_type is (idle,write_to_spi,sclk_one,end_of_trame);
signal 	state : t_state_type;
signal 	SPI_DATA_SEND_buff 		: std_logic_vector(C_Size_DATA-1 downto 0);
signal 	SPI_DATA_RECEIVED_buff 	: std_logic_vector(7 downto 0);
signal 	bit_number_sending 		: integer range C_Size_DATA downto 0;
begin

P_SPI_FSM:	process(CLK_4X,RESET)	
	begin
		if (RESET = '1') then
			SPI_DATA_SEND_buff		<= (others =>'0');
			SPI_DATA_RECEIVED_buff 	<= (others =>'0');
			SPI_DATA_RECEIVED		<= (others =>'0');
			bit_number_sending		<= C_Size_DATA;
			SPI_SCLK 				<= '0';
			SPI_CS_N 				<= '1';
			SPI_SDIO		 		<= '0';
			SPI_ready 				<= '1';
			state 					<= idle;
		elsif rising_edge(CLK_4X) then	
				if (ENABLE_CLK_1X_DIV128 = '1') then
					case state is
						when idle =>
							SPI_SCLK 				<= '0';
							SPI_CS_N 				<= '1';
							bit_number_sending		<= C_Size_DATA;
							SPI_SDIO 				<= '0';
							SPI_ready 				<= '1';
							SPI_DATA_RECEIVED		<= SPI_DATA_RECEIVED_buff;
							if (SPI_write ='1') then							-- DATA are send to SPI BUS when SPI_WRITE = 1
								SPI_DATA_SEND_buff	<= SPI_DATA_SEND;
								SPI_ready 			<= '0';	
								state 				<= write_to_spi;
							else 
								state 				<= idle;
							end if;

						when write_to_spi =>
							SPI_ready 				<= '0';
							SPI_CS_N 				<= '0';
							SPI_SCLK 				<= '0';
							SPI_SDIO 				<= SPI_DATA_SEND_buff(bit_number_sending-1); -- sending data on SPI bus
							bit_number_sending 		<= bit_number_sending - 1;
							state <= sclk_one;
						when sclk_one =>
							SPI_SCLK 				<= '1';
							if ( bit_number_sending > 0 ) then
								if ( SPI_DATA_SEND_buff (15) = '1') then -- READ MODE on SPI_bus
									if (bit_number_sending <= 7 ) then	 -- data are received from bit 7 to 0
										SPI_DATA_RECEIVED_buff ( bit_number_sending) <= SPI_SDO;
									end if;
								end if;
								state <= write_to_spi;
							else 
								state <= end_of_trame;
							end if;
							
						when end_of_trame =>
							SPI_SCLK 					<= '0';
							bit_number_sending			<= C_Size_DATA;
							SPI_DATA_RECEIVED			<= SPI_DATA_RECEIVED_buff;
							if (SPI_write ='0') then
								SPI_CS_N 				<= '1';
								SPI_SCLK 				<= '0';
								state 					<= idle;
							else 
								SPI_CS_N 				<= '1';
								SPI_SCLK 				<= '0';
								state 					<= end_of_trame;
							end if;
					end case;	
				end if;	
		end if;	
	end process P_SPI_FSM;

end behavioral ;

