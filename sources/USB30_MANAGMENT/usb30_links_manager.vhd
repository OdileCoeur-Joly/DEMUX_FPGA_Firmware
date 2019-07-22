----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU ML605
-- Module Name   :USB30_links_manager - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Vitex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Manage the USB30 links (DAQ, CONF, HK)
--
-- Dependencies: Config_receiver_USB30,
--				 fifo_out_to_HK_32_8, fifo_out_to_daq_32_32 create xilinx core
--
-- Revision: 
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
--
entity USB30_links_manager is
    Port ( 

-- RESET	
			RESET							: in std_logic; --RESET
-- CLOCKS	
			CLK_4X						: in std_logic; --CLK_4X
			CLK_1X						: in std_logic; --CLK_1X = clk4X div 4
--			ENABLE_CLK_1X				: in std_logic; --CLK_1X = clk4X div 4
-- CONFIG
			regCONFIG	    			: out t_ARRAY32bits( C_NB_REG_CONF-1 downto 0);
			CONTROL						: out t_CONTROL;

-- Data control For XIFU selected ACQ data
			TM_DATA_TO_GSE				: in STD_LOGIC_VECTOR (31 downto 0);
			wr_en_TM_fifo				: in STD_LOGIC;
-- Data control For XIFU selected HK data
			HK_DATA_TO_GSE				: in STD_LOGIC_VECTOR (31 downto 0);
			wr_en_HK_fifo				: in STD_LOGIC;
			almost_full_HK_fifo			: out STD_LOGIC;
-- TO USB_3.0 manager
			DAQ_CLK_USB_OUT				: out STD_LOGIC; -- 10MHz
-- DAQ 32 bits for science link
			DAQ_usb_Data				: out STD_LOGIC_VECTOR (31 downto 0);
			DAQ_usb_Rdy_n				: in  STD_LOGIC;
			DAQ_usb_WR 					: out STD_LOGIC;
--         START_SENDING_usb_DAQ 	: in  STD_LOGIC;
-- DATA SENDING 1MHz 8 bits for HK link
			HK_usb_Data					: out STD_LOGIC_VECTOR (7 downto 0);
			HK_usb_Rdy_n				: in  STD_LOGIC;
			HK_usb_WR 					: out STD_LOGIC;
--         START_SENDING_usb_HK			: in  STD_LOGIC;
-- DATA RECEIVED 1MHz 8 bits for Config link
-- STATUS SENDING BAD ADDRESS RECEIVED			
			Bad_conf_register_write 	: out std_logic;
			CONF_usb_Data				: in  STD_LOGIC_VECTOR (7 downto 0);
			CONF_usb_Rdy_n				: out STD_LOGIC;
			CONF_usb_WR					: in 	STD_LOGIC
			);
end USB30_links_manager;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.USB30_links_manager.Behavioral.svg
architecture Behavioral of USB30_links_manager is

-- STATE FOR HK LINK WRITE
	type t_STATE_HK_WRITER is (IDLE,WAIT_VALID,WAIT_128_CLK);
	signal STATE_HK_WRITER	: t_STATE_HK_WRITER;
--	signal DAQ_CLK_DIV				: std_logic;
--
--	signal HK_CLK_DIV					: std_logic;
	signal 	DATA_TO_usb_SEND			: STD_LOGIC_VECTOR (31 downto 0);
	signal 	rd_en_DAQ_usb_fifo			: STD_LOGIC;
	signal 	valid_DAQ_usb_fifo			: STD_LOGIC;
--	signal 	full_DAQ_usb_fifo			: STD_LOGIC;
	signal 	empty_DAQ_usb_fifo			: STD_LOGIC;
	signal 	DAQ_CLK_to_usb_fifo			: STD_LOGIC; -- 10MHz
	signal	HK_TO_USB_SEND				: STD_LOGIC_VECTOR (7 downto 0);
	signal	rd_en_HK_usb_fifo			: STD_LOGIC;
	signal 	empty_HK_usb_fifo			: STD_LOGIC;
--	signal 	full_HK_usb_fifo			: STD_LOGIC;
	signal 	valid_HK_usb_fifo			: STD_LOGIC;
	signal	HK_CLK_to_usb_fifo			: STD_LOGIC; -- 10MHz
	signal 	cmpt_wait 					: unsigned (6 downto 0);

begin
	
--	 =============================================================
--	 send channel DAQ FROM FIFO WHEN DAQ_Rdy_n and start_sending
--	 =============================================================
P_send_DAQ:	process(RESET, CLK_1X)
	begin
		if (RESET = '1') then
			DAQ_usb_Data					<= (others=>'0');
			rd_en_DAQ_usb_fifo				<= '0';
			DAQ_usb_WR 						<= '0';
		elsif rising_edge(CLK_1X) then
			if (DAQ_usb_Rdy_n ='0' ) then -- attente que la DAQ soit ready 
					if(empty_DAQ_usb_fifo ='0') then					-- attente fifo empty
						rd_en_DAQ_usb_fifo	<= '1';
						DAQ_usb_WR 				<= valid_DAQ_usb_fifo;
						DAQ_usb_Data			<= DATA_TO_usb_SEND;
					else 
						DAQ_usb_WR 				<= valid_DAQ_usb_fifo;
						rd_en_DAQ_usb_fifo	<= '0';
						DAQ_usb_Data			<= DATA_TO_usb_SEND;
					end if;
			else 
				DAQ_usb_WR 				<= '0';
				rd_en_DAQ_usb_fifo		<= '0';
			end if;
		end if;	
	end process;
-- fifo de sortie de changment de frequence d'horloge DATA et DAQ( 20MHz)
	fifo_to_daq_USB : entity work.fifo_out_to_daq_32_32
  PORT MAP (
    rst 			=> RESET,
    wr_clk 			=> CLK_4X,
    rd_clk 			=> DAQ_CLK_to_usb_fifo,
    din 			=> TM_DATA_TO_GSE,
    wr_en 			=> wr_en_TM_fifo,
    rd_en 			=> rd_en_DAQ_usb_fifo,
    dout 			=> DATA_TO_usb_SEND,
    full 			=> open,
    empty 			=> empty_DAQ_usb_fifo,
    valid 			=> valid_DAQ_usb_fifo
  );	
--	DAQ_usb_WR 						<= valid_DAQ_usb_fifo;
--	 =============================================================
--	 send channel HK FROM FIFO WHEN HK_Rdy_n and start_sending
--	 =============================================================
P_send_HK:	process(RESET, CLK_1X)
	begin
		if (RESET = '1') then
			HK_usb_Data					<= (others=>'0');
			rd_en_HK_usb_fifo			<= '0';
			HK_usb_WR 					<= '0';
			cmpt_wait <= (others =>'0');	
			STATE_HK_WRITER 			<= IDLE;

		elsif rising_edge(CLK_1X) then
				if (HK_usb_Rdy_n ='0') then
					case STATE_HK_WRITER is
						when IDLE =>
							HK_usb_WR 		<= '0';
							if (empty_HK_usb_fifo = '0') then
								rd_en_HK_usb_fifo	<= '1';
								STATE_HK_WRITER <= WAIT_VALID;
							else
								rd_en_HK_usb_fifo	<= '0';
								STATE_HK_WRITER <= IDLE;
							end if;

						when WAIT_VALID =>
							rd_en_HK_usb_fifo	<= '0';
								if (valid_HK_usb_fifo = '1') then
								HK_usb_WR 		<= '1';
								HK_usb_Data	<= HK_TO_USB_SEND;
								STATE_HK_WRITER <= WAIT_128_CLK;
								else 
								STATE_HK_WRITER <= WAIT_VALID;
								end if;
								
								
						when WAIT_128_CLK =>
								HK_usb_WR 		<= '0';
								rd_en_HK_usb_fifo	<= '0';
								cmpt_wait <= cmpt_wait + 1;
								if (cmpt_wait = b"111_1111") then 
									cmpt_wait <= (others =>'0');	
									STATE_HK_WRITER <= IDLE;
								else 
									STATE_HK_WRITER <= WAIT_128_CLK;
							end if;
							
						end case;
				else 
				rd_en_HK_usb_fifo	<= '0';
				HK_usb_WR 		<= '0';
				end if;
		end if;
	end process;	
	
	fifo_to_HK_USB : entity work.fifo_out_to_HK_32_8
  PORT MAP (
				rst 		=> RESET,
				wr_clk 		=> CLK_4X,
				rd_clk 		=> HK_CLK_to_usb_fifo,
				din 		=> HK_DATA_TO_GSE,
				wr_en 		=> wr_en_HK_fifo,
				rd_en 		=> rd_en_HK_usb_fifo,
				dout 		=> HK_TO_USB_SEND,
				full 		=> open,
				almost_full => almost_full_HK_fifo,
				empty 		=> empty_HK_usb_fifo,
				valid 		=> valid_HK_usb_fifo
  );	

input_Config_receiver_USB30: entity work.Config_receiver_USB30 
PORT MAP(
			RESET 					=> RESET,
			CLK_4X 					=> CLK_4X,
			CLK_1X 					=> CLK_1X,
			CONF_usb_Data 			=> CONF_usb_Data,
			CONF_usb_Rdy_n 			=> CONF_usb_Rdy_n,
			CONF_usb_WR 			=> CONF_usb_WR,
			regCONFIG_OUT 			=> regCONFIG,
			CONTROL 				=> CONTROL,
			Bad_conf_register_write => Bad_conf_register_write
--			ENABLE_CLK_1X				=> ENABLE_CLK_1X
		);
DAQ_CLK_USB_OUT 		<= CLK_1X;
DAQ_CLK_to_usb_fifo 	<= CLK_1X;
HK_CLK_to_usb_fifo 	<= CLK_1X;
end Behavioral;

