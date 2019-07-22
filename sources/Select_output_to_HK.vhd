----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : Select_output_to_HK - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Selection of HK output to send to Opalkelly bus manager
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.03 - change managment : no fifo, direct connexion to DAQ fifo, changement of name 
-- Revision 0.02 - change managment by  states machines
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;
	use work.athena_package.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Select_output_to_HK is
    Port ( 
--RESET
			RESET					: in  std_logic;
--CLOCKS	
			CLK_4X					: in  std_logic; --CLK_4X
			ENABLE_CLK_1X			: in  std_logic; --CLK_1X_DIV64
			ONE_SECOND				: in  std_logic;
--CONTROL
-- OUTPUT SELECTOR 		: AT CLK_1X 10MHz, 32 bits Words
			select_HK				: in  unsigned (1 downto 0);
			START_SENDING_HK		: in  std_logic;	
-- FROM XIFU
			ADC128_registers		: in  t_register_ALL_ADC128;
			ADC128_Done				: in  std_logic;
			ADC128_start_HK			: out std_logic;
			ADC128_read_register	: out std_logic;
			regCONFIG       		: in  t_ARRAY32bits(C_NB_REG_CONF-1 downto 0);--4);
			STATUS					: in  t_STATUS;

-- TO/FROM Opalkelly manager
			HK_DATA_TO_GSE			: out std_logic_vector(31 downto 0);
			WR_en_HK_fifo			: out std_logic;
			almost_full_HK_fifo		: in  std_logic			);
end Select_output_to_HK;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.Select_output_to_HK.Behavioral.svg
architecture Behavioral of Select_output_to_HK is

	type t_OUT_ON is (OFF,SD_ADC128,SD_CONF,SD_ADC128_AUTO,SD_COUNT);
	signal OUT_ON				: t_OUT_ON;
	

	signal start						: std_logic;
	signal started						: std_logic;
	signal one_second_pulse				: std_logic;
	signal one_second_pulsed			: std_logic;
	signal wr_en						: std_logic;
-- ADC128
	signal CHANNEL_ADC128				: unsigned (8 downto 0);
	signal HK_HEADER					: std_logic_vector (7 downto 0);
	signal CONF_HEADER					: std_logic_vector (7 downto 0);
	signal COUNT_HEADER					: std_logic_vector (7 downto 0);
	signal ADC128_HEADER				: std_logic_vector (7 downto 0);
-- STATE FOR ADC128 WRITE
	type t_STATE_SENDING is (	IDLE,
								SENDING,
								WE_ADC128_HEADER,
								WE_STATUS_0,
								WE_STATUS_1,
								WE_STATUS_2,
								WE_ADC128,
								WAIT_ONE_SECOND,
								SD_CONF,
								WE_CONF_HEADER,
								WE_STATUS_CONF_0,
								WE_STATUS_CONF_1,
								WE_STATUS_CONF_2,
								WE_CONF,
								WE_COUNT_HEADER,
								SD_COUNT	);
								
	signal STATE_SENDING				: t_STATE_SENDING;

-- CONF
	signal REGISTER_NUMBER				: integer range C_NB_HK_FIFO+1 downto 0;
-- COUNT
	signal COUNT						: unsigned (31 downto 0);
	type t_status_to_send is array (2 downto 0)	of std_logic_vector (31 downto 0);
	signal STATUS_TO_SEND :t_status_to_send;
begin
--	 =============================================================
--	 OUTPUT MODE SELECT AFTER HK_ON
--	 =============================================================

HK_HEADER 		<= x"A6";
CONF_HEADER 	<= x"20";
COUNT_HEADER 	<= x"30";
ADC128_HEADER	<= x"00" when OUT_ON = SD_ADC128 else x"10";

--	 =============================================================
--	 OUTPUT MODE SELECT AFTER HK_ON
--	 =============================================================

P_select_out_HK:	process(RESET, CLK_4X)
	begin
		if (RESET = '1') then
			OUT_ON <= OFF;

		elsif rising_edge(CLK_4X) then
	choice_output:		case select_HK is

						when "00" 	=> 
				-- ADC128 7 canaux 12 bits 1 fois apres un DONE, envoye avec numero Canal sur les poids forts
							OUT_ON 			<= SD_ADC128;
						when "01" 	=>
				-- CONFIG registers and status envoi les N registres 1 fois
							OUT_ON 			<= SD_ADC128_AUTO;
						when "10" 	=>  
				-- ADC128 7 canaux 12 bits apres les DONE, envoye avec numero Canal sur les poids forts en boucle
							OUT_ON 			<= SD_CONF;
						when "11" 	=>
				-- CONFIG registers and status envoi les N registres en boucle
							OUT_ON 			<= SD_COUNT;
						when others 	=>
				-- CONFIG registers and status envoi les N registres en boucle
							OUT_ON 			<= OFF;
						end case;
		end if;
	end process P_select_out_HK;

P_START_front1: process(RESET, CLK_4X)
	begin
		if (RESET = '1') then
		 start <= '0';
		 started <= '0';
		elsif (rising_edge(CLK_4X)) then
			if (ENABLE_CLK_1X = '1') then
				if (START_SENDING_HK ='1' and start ='0' and  started = '0') then
				start			<= '1';
				started 		<= '1';
				else
					if (START_SENDING_HK ='1' ) then
						start <='0';
						started <= '1';
					else 
					start <= '0';
					started <= '0';
					end if;
				end if;
			end if;
		end if;
	end process; 
	
P_ONE_SECOND_front2: process(RESET, CLK_4X)
	begin
		if (RESET = '1') then
		 one_second_pulse <= '0';
		 one_second_pulsed <= '0';
		elsif (rising_edge(CLK_4X)) then
			if (ENABLE_CLK_1X = '1') then
				if (START_SENDING_HK ='1' and ONE_SECOND ='1' and one_second_pulsed = '0') then
				one_second_pulse		<= '1';
				one_second_pulsed 	<= '1';
				else
					if (START_SENDING_HK ='1' and ONE_SECOND ='1') then
						one_second_pulse <='0';
						one_second_pulsed <= '1';
					else 
					one_second_pulse <= '0';
					one_second_pulsed <= '0';
					end if;
				end if;
			end if;
		end if;
	end process; 
	
--	 =============================================================
--	 ADC128 and / or CONF IN FIFO WHEN HK enable with CLK_1X_DIV64
--	 =============================================================
P_sending_HK:	process(RESET,CLK_4X)
	begin
		if (RESET = '1') then
			wr_en						<= '0';
			ADC128_start_HK				<= '0';
			ADC128_read_register 		<= '0';
			CHANNEL_ADC128				<= (others=>'0');
			COUNT						<= (others=>'0');
			STATE_SENDING 				<= IDLE;
			HK_DATA_TO_GSE				<= (others=>'0');
			STATUS_TO_SEND				<= (others=>(others=>'0'));
		elsif rising_edge(CLK_4X) then
			if (ENABLE_CLK_1X = '1') then
			-- status word 0
				STATUS_TO_SEND(0)(0)				<= STATUS.CMM.CDCM_RESETn;
				STATUS_TO_SEND(0)(1)				<= STATUS.CMM.CLK_CDCM_PLL_RESET;
				STATUS_TO_SEND(0)(2)				<= STATUS.CMM.CLK_CDCM_SELECT;
				STATUS_TO_SEND(0)(3)				<= STATUS.CMM.CLK_LOCKED_200MHz;
				STATUS_TO_SEND(0)(4)				<= STATUS.CMM.CLK_LOCKED_CDCM;
				STATUS_TO_SEND(0)(5)				<= STATUS.SPI_CONTROLER.SPI_ready;
				STATUS_TO_SEND(0)(6)				<= STATUS.RHF1201s(0).ADC_OE_N;
				STATUS_TO_SEND(0)(7)				<= STATUS.RHF1201s(0).ADC_READY;
				STATUS_TO_SEND(0)(8)				<= STATUS.RHF1201s(0).OUT_OF_RANGE;
				STATUS_TO_SEND(0)(9)				<= STATUS.RHF1201s(1).ADC_OE_N;
				STATUS_TO_SEND(0)(10)				<= STATUS.RHF1201s(1).ADC_READY;
				STATUS_TO_SEND(0)(11)				<= STATUS.RHF1201s(1).OUT_OF_RANGE;
				STATUS_TO_SEND(0)(12)				<= STATUS.AD9726s(0).DACB.DAC_ON;
				STATUS_TO_SEND(0)(13)				<= STATUS.AD9726s(0).DACB.DAC_RESET;
				STATUS_TO_SEND(0)(14)				<= STATUS.AD9726s(0).DACF.DAC_ON;
				STATUS_TO_SEND(0)(15)				<= STATUS.AD9726s(0).DACF.DAC_RESET;
				STATUS_TO_SEND(0)(16)				<= STATUS.AD9726s(1).DACB.DAC_ON;
				STATUS_TO_SEND(0)(17)				<= STATUS.AD9726s(1).DACB.DAC_RESET;
				STATUS_TO_SEND(0)(18)				<= STATUS.AD9726s(1).DACF.DAC_ON;
				STATUS_TO_SEND(0)(19)				<= STATUS.AD9726s(1).DACF.DAC_RESET;
				STATUS_TO_SEND(0)(20)				<= STATUS.CDCM.STATUS_REF;
				STATUS_TO_SEND(0)(21)				<= STATUS.CDCM.PLL_LOCK;
				STATUS_TO_SEND(0)(22)				<= STATUS.CDCM.STATUS_VCXO;
			-- status word 1
				STATUS_TO_SEND(1)(15 downto 0)		<= STATUS.IDENTIFIER.BOARD_ID;
				STATUS_TO_SEND(1)(27 downto 16)		<= STATUS.IDENTIFIER.BOARD_VERSION;
				STATUS_TO_SEND(1)(31 downto 28)		<= STATUS.IDENTIFIER.MODEL_ID;
			-- status word 2
				STATUS_TO_SEND(2)(1 downto 0)		<= STATUS.IDENTIFIER.NB_CHANNEL;
				STATUS_TO_SEND(2)(8 downto 2)		<= STATUS.IDENTIFIER.NB_PIXEL;
				STATUS_TO_SEND(2)(24 downto 9)		<= STATUS.IDENTIFIER.FIRMWARE_ID;
				case STATE_SENDING is
						when IDLE =>
							ADC128_start_HK			<= '0';
							ADC128_read_register	<= '0';
							wr_en					<= '0';
							CHANNEL_ADC128			<= (others=>'0');
							REGISTER_NUMBER			<= 0;
							COUNT					<= (others=>'0');
							HK_DATA_TO_GSE			<= (others=>'0');
							if (start ='1') then 
								STATE_SENDING <= SENDING;
							else 
								STATE_SENDING <= IDLE;
							end if;

						when SENDING =>
								ADC128_read_register <= '0';
								ADC128_start_HK		 <= '0';
								wr_en						<= '0';
								CHANNEL_ADC128			<= (others=>'0');
							if ( OUT_ON = SD_ADC128 or OUT_ON = SD_ADC128_AUTO ) then 
								ADC128_start_HK		 <= '1';
								if (ADC128_Done ='1' ) then
									wr_en					<= '0';
									ADC128_read_register 	<= '1';
									ADC128_start_HK		 	<= '0';
									STATE_SENDING 			<= WE_ADC128_HEADER;
									HK_DATA_TO_GSE <= x"00000" & std_logic_vector(unsigned(ADC128_registers(to_integer(CHANNEL_ADC128(5 downto 0)))));
								else
									ADC128_read_register <= '0';									
									STATE_SENDING <= SENDING;
								end if;
							else -- SD_CONF SD_COUNT
								ADC128_start_HK		 <= '0';
								if ( OUT_ON = SD_CONF) then
									STATE_SENDING <= SD_CONF;
								else -- SD_COUNT
									if (OUT_ON = SD_COUNT) then
										STATE_SENDING <= WE_COUNT_HEADER;
									else 
										STATE_SENDING <= IDLE;
									end if;
								end if;
							end if;

						when WE_ADC128_HEADER =>
								ADC128_start_HK		 <= '0';
									wr_en	<= '1';
									HK_DATA_TO_GSE		<= (HK_HEADER & HK_HEADER & ADC128_HEADER & std_logic_vector(to_unsigned(C_NB_HK_FIFO,8)));
									STATE_SENDING <= WE_STATUS_0;
							
						when WE_STATUS_0 =>
								ADC128_start_HK		 <= '0';
									wr_en	<= '1';
									HK_DATA_TO_GSE		<= STATUS_TO_SEND (0);
									STATE_SENDING <= WE_STATUS_1;
						when WE_STATUS_1 =>
								ADC128_start_HK		 <= '0';
									wr_en	<= '1';
									HK_DATA_TO_GSE		<= STATUS_TO_SEND (1);
									STATE_SENDING <= WE_STATUS_2;
						when WE_STATUS_2 =>
								ADC128_start_HK		 <= '0';
									wr_en	<= '1';
									HK_DATA_TO_GSE		<= STATUS_TO_SEND (2);
									STATE_SENDING <= WE_ADC128;

						when WE_ADC128 =>
							ADC128_read_register 	<= '0';
							ADC128_start_HK		 	<= '0';
									wr_en	<= '1';
									STATE_SENDING <= WE_ADC128;
--										HK_DATA_TO_GSE <= b"0000_0000_00" & std_logic_vector(unsigned(CHANNEL_ADC128(5 downto 0))) & "0000" & std_logic_vector(unsigned(ADC128_registers(to_integer(CHANNEL_ADC128(5 downto 0)))));
									CHANNEL_ADC128		<= CHANNEL_ADC128 + 1;
									if ( CHANNEL_ADC128 <= b"0_0010_1101") then
										HK_DATA_TO_GSE <= x"00000" & std_logic_vector(unsigned(ADC128_registers(to_integer(CHANNEL_ADC128(5 downto 0)))));
										STATE_SENDING <= WE_ADC128;
									else
										HK_DATA_TO_GSE <= x"FADAFADA";
										if ( CHANNEL_ADC128 <= b"0_1111_1011") then
											STATE_SENDING <= WE_ADC128;
											wr_en	<= '1';
										else
											CHANNEL_ADC128		<= (others=>'0');
											wr_en					<= '0';
											if ( OUT_ON = SD_ADC128_AUTO) then
												if (START_SENDING_HK ='1') then
													STATE_SENDING <= WAIT_ONE_SECOND;
												else
													STATE_SENDING <= IDLE;
												end if;
											else 
												STATE_SENDING <= IDLE;
											end if;
										end if;
									end if;	
						when WAIT_ONE_SECOND =>
								ADC128_start_HK		<= '0';
								wr_en	<= '0';
							if (START_SENDING_HK ='1') then
								if( one_second_pulse ='1') then
									STATE_SENDING <= SENDING;
								else
									STATE_SENDING <= WAIT_ONE_SECOND;
								end if;
							else 
								STATE_SENDING <= IDLE;
							end if;

						when SD_CONF => 
							ADC128_start_HK		 <= '0';
							STATE_SENDING <= WE_CONF_HEADER;

						when WE_CONF_HEADER =>
							ADC128_start_HK	 <= '0';
							wr_en	<= '1';
							HK_DATA_TO_GSE		<= (HK_HEADER & HK_HEADER & CONF_HEADER & std_logic_vector(to_unsigned(C_NB_HK_FIFO,8)));
							STATE_SENDING <= WE_STATUS_CONF_0;
						when WE_STATUS_CONF_0 =>
							ADC128_start_HK	 <= '0';
							wr_en	<= '1';
							HK_DATA_TO_GSE		<= STATUS_TO_SEND (0);
							STATE_SENDING <= WE_STATUS_CONF_1;
						when WE_STATUS_CONF_1 =>
							ADC128_start_HK	 <= '0';
							wr_en	<= '1';
							HK_DATA_TO_GSE		<= STATUS_TO_SEND (1);
							STATE_SENDING <= WE_STATUS_CONF_2;
						when WE_STATUS_CONF_2 =>
							ADC128_start_HK	 <= '0';
							wr_en	<= '1';
							HK_DATA_TO_GSE		<= STATUS_TO_SEND (2);
							STATE_SENDING <= WE_CONF;
						
						when WE_CONF =>
								ADC128_start_HK		 <= '0';
									if ( REGISTER_NUMBER <= C_NB_HK_FIFO-4) then
											wr_en	<= '1';
											if ( REGISTER_NUMBER <= C_NB_REG_CONF-1) then
												if ( REGISTER_NUMBER = C_NB_REG_CONF-2) then
													HK_DATA_TO_GSE		<= (regCONFIG(REGISTER_NUMBER)(31 downto 23) &"00000000" &	STATUS.SPI_CONTROLER.SPI_data_Received & STATUS.SPI_CONTROLER.SPI_ready & regCONFIG(REGISTER_NUMBER)(5 downto 0));
												else 
													HK_DATA_TO_GSE		<= regCONFIG(REGISTER_NUMBER);
												end if;
											else
												HK_DATA_TO_GSE	<= x"FADAFADA";
											end if;
											REGISTER_NUMBER		<= REGISTER_NUMBER + 1;
											STATE_SENDING 		<= WE_CONF;
									else
										wr_en			<= '0';
										REGISTER_NUMBER	<= 0;
										STATE_SENDING 	<= IDLE;
									end if;

						when WE_COUNT_HEADER =>
								ADC128_start_HK		<= '0';
									wr_en			<= '1';
									HK_DATA_TO_GSE	<= (HK_HEADER & HK_HEADER & COUNT_HEADER & x"00");
									STATE_SENDING 	<= SD_COUNT;
							
						when SD_COUNT => 
								ADC128_start_HK		 <= '0';
								if (START_SENDING_HK ='1') then
									if (almost_full_HK_fifo ='0')then
										wr_en			<= '1';										
										COUNT			<= COUNT + 1;
										HK_DATA_TO_GSE	<= std_logic_vector(COUNT);
										STATE_SENDING 	<= SD_COUNT;
									else 
										wr_en	<= '0';
										COUNT		  <= COUNT;
										STATE_SENDING <= SD_COUNT;
									end if;
								else
									wr_en			<= '0';
									COUNT			<=(others=>'0');
									HK_DATA_TO_GSE 	<=(others=>'0');
									STATE_SENDING 	<= IDLE;
								end if;
				end case;
			else 
			wr_en	<= '0';
			end if;	
		end if;	
	end process P_sending_HK;

WR_en_HK_fifo <= wr_en;

-- fifo de sortie HK(10MHz)




end Behavioral;

