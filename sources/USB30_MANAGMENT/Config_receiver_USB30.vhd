----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : Config_receiver_USB30 - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : CONFIG Receiver to REGCONFIG
--
-- Dependencies: fifo_in_config_8_to_32 create xilinx core
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

entity Config_receiver_USB30 is
    Port ( 
-- FROM USB 3.0 manager
--RESET
			RESET						: in  std_logic;-- CLOCKS	
			CLK_4X						: in  std_logic; --CLK_4X
			CLK_1X						: in  std_logic; --CLK_4X_DIV4
--			ENABLE_CLK_1X				: in  std_logic; --CLK_1X

			CONF_usb_Data				: in  STD_LOGIC_VECTOR (7 downto 0);
			CONF_usb_Rdy_n				: out STD_LOGIC;
        	CONF_usb_WR					: in  STD_LOGIC;
-- TO XIFU
			regCONFIG_OUT    			: out t_ARRAY32bits(C_NB_REG_CONF-1 downto 0);
			CONTROL						: out t_CONTROL;
-- STATUS SENDING BAD ADDRESS RECEIVED			
			Bad_conf_register_write 	: out std_logic

			);
end Config_receiver_USB30;
--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.Config_receiver_USB30.Behavioral.svg
architecture Behavioral of Config_receiver_USB30 is

	signal rd_en_CONF_FIFO			: std_logic;
	signal empty_conf_DATA			: std_logic;
	signal valid_conf_DATA			: std_logic;
--	signal bad_conf_register_write: std_logic;
	signal CONF_RECEIVED_DATA		: std_logic_vector(31 downto 0);
	signal CONF_ADDRESS				: integer  range C_NB_REG_CONF-1 downto 0;
	signal END_OF_CONF				: unsigned (31 downto 0);
	signal regCONFIG       			: t_ARRAY32bits(C_NB_REG_CONF-1 downto 0);

-- STATE_MACHINE_CONFIG_WRITER
	type t_STATE_CONF_WRITER is (IDLE,WE_ADDR_REG,READ_DATA_CONF,WE_DATA_CONF);
	signal STATE_CONF_WRITER		: t_STATE_CONF_WRITER;


begin
END_OF_CONF <= x"FFFFFFFF";
	-- =============================================================
	-- WRITE REGISTERS PROCESS EN USB30
	-- =============================================================
	CONTROL.GSE.select_HK					<= unsigned(regCONFIG(0) (1 downto 0));
	CONTROL.GSE.START_SENDING_HK			<= regCONFIG(0) (2);
	CONTROL.GSE.select_TM					<= unsigned(regCONFIG(0) (6 downto 3));
	CONTROL.GSE.START_SENDING_TM			<= regCONFIG(0) (7);
	GENERATE_CHANNELS_register : for C in C_Nb_channel-1 downto 0 generate	
	CONTROL.CHANNELs(C).FEEDBACK_truncation				<= unsigned(regCONFIG(1+(C*(C_Nb_pixel*2+4))) (1 downto 0)); -- 1 registre GSE + C*( 2 registres par pixel*NB pixel + (2 registres conf channel + 2 registres conf test pixel))
	CONTROL.CHANNELs(C).BIAS_truncation					<= unsigned(regCONFIG(1+(C*(C_Nb_pixel*2+4))) (3 downto 2));
	CONTROL.CHANNELs(C).BIAS_slope_speed				<= unsigned(regCONFIG(1+(C*(C_Nb_pixel*2+4))) (5 downto 4));
	CONTROL.CHANNELs(C).FEEDBACK_Enable					<= 			regCONFIG(1+(C*(C_Nb_pixel*2+4))) (6);
	CONTROL.CHANNELs(C).BIAS_Enable						<= 			regCONFIG(1+(C*(C_Nb_pixel*2+4))) (7);
	CONTROL.CHANNELs(C).select_Input					<= unsigned(regCONFIG(1+(C*(C_Nb_pixel*2+4))) (9 downto 8));
	CONTROL.AD9726s(C).DACF.DAC_ON						<= 			regCONFIG(1+(C*(C_Nb_pixel*2+4))) (10);
	CONTROL.AD9726s(C).DACB.DAC_ON						<= 			regCONFIG(1+(C*(C_Nb_pixel*2+4))) (11);
	CONTROL.RHF1201s(C).ADC_ON							<= 			regCONFIG(1+(C*(C_Nb_pixel*2+4))) (12);
	CONTROL.CHANNELs(C).START_STOP						<= 			regCONFIG(1+(C*(C_Nb_pixel*2+4))) (16);
	CONTROL.CHANNELs(C).Loop_control					<= unsigned(regCONFIG(1+(C*(C_Nb_pixel*2+4))) (31 downto 28));
	CONTROL.CHANNELs(C).feedback_reverse				<= 			regCONFIG(2+(C*(C_Nb_pixel*2+4))) (15);
	CONTROL.CHANNELs(C).FEEDBACK_compensation_gain		<= unsigned(regCONFIG(2+(C*(C_Nb_pixel*2+4))) (31 downto 16));
	GENERATE_PIXELS_register : for N in C_Nb_pixel-2 downto 0 generate
	CONTROL.CHANNELs(C).CONTROL_PIXELS(N).BIAS_amplitude	<= unsigned(regCONFIG(3+N*2+(C*(C_Nb_pixel*2+4)))(7 downto 0));
	CONTROL.CHANNELs(C).CONTROL_PIXELS(N).gain_BBFB			<= unsigned(regCONFIG(3+N*2+(C*(C_Nb_pixel*2+4)))(15 downto 8));
	CONTROL.CHANNELs(C).CONTROL_PIXELS(N).PHI_ROTATE		<= unsigned(regCONFIG(3+N*2+(C*(C_Nb_pixel*2+4)))(23 downto 16));
	CONTROL.CHANNELs(C).CONTROL_PIXELS(N).PHI_DELAY			<= unsigned(regCONFIG(3+N*2+(C*(C_Nb_pixel*2+4)))(31 downto 24));
	CONTROL.CHANNELs(C).CONTROL_PIXELS(N).PHI_INITIAL		<= unsigned(regCONFIG(4+N*2+(C*(C_Nb_pixel*2+4)))(11 downto 0));
	CONTROL.CHANNELs(C).CONTROL_PIXELS(N).increment			<= unsigned(regCONFIG(4+N*2+(C*(C_Nb_pixel*2+4)))(C_counter_size-1+12 downto 12));
	CONTROL.CHANNELs(C).CONTROL_PIXELS(N).SW1				<= '0';
	CONTROL.CHANNELs(C).CONTROL_PIXELS(N).SW2				<= "00";
--	control.channels(C).control_pixels(N).BIAS_Modulation_Increment	<= (others=>'0');
--	control.channels(C).control_pixels(N).BIAS_Modulation_Amplitude	<= (others=>'0');

	end generate GENERATE_PIXELS_register;
-- TEST PIXEL CONFIG ---------------------------------------------------------------------------------------------------------------------------------------------
	CONTROL.CHANNELs(C).CONTROL_PIXELS(C_Nb_pixel-1).BIAS_amplitude					<= unsigned(regCONFIG(3+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (7 downto 0));
	CONTROL.CHANNELs(C).CONTROL_PIXELS(C_Nb_pixel-1).gain_BBFB						<= unsigned(regCONFIG(3+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (15 downto 8));
	CONTROL.CHANNELs(C).CONTROL_PIXELS(C_Nb_pixel-1).PHI_ROTATE						<= unsigned(regCONFIG(3+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (23 downto 16));
	CONTROL.CHANNELs(C).CONTROL_PIXELS(C_Nb_pixel-1).PHI_DELAY						<= unsigned(regCONFIG(3+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (31 downto 24));
	CONTROL.CHANNELs(C).CONTROL_PIXELS(C_Nb_pixel-1).PHI_INITIAL					<= unsigned(regCONFIG(4+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (11 downto 0));
	CONTROL.CHANNELs(C).CONTROL_PIXELS(C_Nb_pixel-1).increment						<= unsigned(regCONFIG(4+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (C_counter_size-1+12 downto 12));
	CONTROL.CHANNELs(C).BIAS_modulation_increment									<= unsigned(regCONFIG(5+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (23 downto 0));
	CONTROL.CHANNELs(C).BIAS_modulation_amplitude									<= unsigned(regCONFIG(6+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (7 downto 0));
	CONTROL.CHANNELs(C).CONTROL_PIXELS(C_Nb_pixel-1).SW1							<= 			regCONFIG(6+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (8);
	CONTROL.CHANNELs(C).CONTROL_PIXELS(C_Nb_pixel-1).SW2							<= unsigned(regCONFIG(6+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (10 downto 9));
	CONTROL.CHANNELs(C).Send_pulse													<= 			regCONFIG(6+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (11);
	CONTROL.CHANNELs(C).Pulse_Amplitude												<= unsigned(regCONFIG(6+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (19 downto 12));
	CONTROL.CHANNELs(C).Pulse_timescale												<= unsigned(regCONFIG(6+(C_Nb_pixel-1)*2+(C*(C_Nb_pixel*2+4))) (23 downto 20));
------------------------------------------------------------------------------------------------------------------------------------------------------------------
	CONTROL.RHF1201s(C).DATA_FORMAT_SEL_N		<= 			regCONFIG(1+(C_Nb_channel*(C_Nb_pixel*2+4)))(24+C*3);
	CONTROL.RHF1201s(C).SLEW_RATE_CONTROL		<= 			regCONFIG(1+(C_Nb_channel*(C_Nb_pixel*2+4)))(25+C*3);
	CONTROL.AD9726s(C).DACB.DAC_RESET			<= 			regCONFIG(1+(C_Nb_channel*(C_Nb_pixel*2+4)))(29);
	CONTROL.AD9726s(C).DACF.DAC_RESET			<= 			regCONFIG(1+(C_Nb_channel*(C_Nb_pixel*2+4)))(29);
end generate GENERATE_CHANNELS_register;

	CONTROL.DACs_RESET						<=		regCONFIG(1+(C_Nb_channel*(C_Nb_pixel*2+4)))(29);
	CONTROL.CMM.CLK_CDCM_SELECT				<= 		regCONFIG(1+(C_Nb_channel*(C_Nb_pixel*2+4)))(30);
	CONTROL.CMM.CLK_CDCM_PLL_RESET			<= 		regCONFIG(1+(C_Nb_channel*(C_Nb_pixel*2+4)))(31);
	CONTROL.SPI.Select_SPI_Channel			<=		regCONFIG(1+(C_Nb_channel*(C_Nb_pixel*2+4)))(4 downto 0);
	CONTROL.SPI.SPI_write					<= 		regCONFIG(1+(C_Nb_channel*(C_Nb_pixel*2+4)))(5);
	CONTROL.SPI.SPI_data_to_send			<= 		regCONFIG(2+(C_Nb_channel*(C_Nb_pixel*2+4)));
	

	regCONFIG_OUT							<= regCONFIG;
	
--	 =============================================================
--	 CONFIG RECEIVER TRANSFERT TO REGISTER read address then read data and write
--	 =============================================================
P_receive_conf:	process(RESET,CLK_4X)
	begin
		if (RESET = '1') then
			rd_en_CONF_FIFO				<= '0';
			regCONFIG 					<= (others=>(others=>'0'));
			Bad_conf_register_write		<= '0';
			CONF_ADDRESS 				<= 0;
			STATE_CONF_WRITER 			<= IDLE;

		elsif rising_edge(CLK_4X) then
state_machine_case:	case STATE_CONF_WRITER is
						when IDLE =>
							if (empty_conf_DATA = '0') then
								rd_en_CONF_FIFO		<= '1';
								CONF_ADDRESS 		<= 0;
								regCONFIG			<= regCONFIG;
								STATE_CONF_WRITER 	<= WE_ADDR_REG;
							else
								CONF_ADDRESS 		<= 0;
								rd_en_CONF_FIFO		<= '0';
								regCONFIG			<= regCONFIG;
								STATE_CONF_WRITER 	<= IDLE;
							end if;

						when WE_ADDR_REG =>
							rd_en_CONF_FIFO	<= '0';
							if (valid_conf_DATA ='1') then
								CONF_ADDRESS 		<=	to_integer(unsigned(CONF_RECEIVED_DATA));
								STATE_CONF_WRITER 	<= READ_DATA_CONF;
							else
								STATE_CONF_WRITER 	<= WE_ADDR_REG;
							end if;
							
							
						when READ_DATA_CONF =>
							if (empty_conf_DATA = '0') then
								rd_en_CONF_FIFO	<= '1';
								CONF_ADDRESS 		<=	CONF_ADDRESS;
								STATE_CONF_WRITER <= WE_DATA_CONF;
							else
								rd_en_CONF_FIFO	<= '0';
								CONF_ADDRESS 		<=	CONF_ADDRESS;
								STATE_CONF_WRITER <= READ_DATA_CONF;
							end if;
							
						when WE_DATA_CONF =>
								rd_en_CONF_FIFO	<= '0';
								CONF_ADDRESS 		<=	CONF_ADDRESS;
							if (valid_conf_DATA ='1') then							
								if (CONF_ADDRESS <= (C_NB_REG_CONF-1)) then
									regCONFIG(CONF_ADDRESS)	<= CONF_RECEIVED_DATA;
									STATE_CONF_WRITER <= IDLE;
								else
									if (CONF_ADDRESS /= END_OF_CONF) then
									Bad_conf_register_write <='1';
									end if;
									STATE_CONF_WRITER <= IDLE;
								end if;
							else 
								STATE_CONF_WRITER <= WE_DATA_CONF;
							end if;
--						when others =>
--								STATE_CONF_WRITER <= IDLE;
					end case;
		end if;
	end process P_receive_conf;
-- fifo de sortie HK(10MHz)



	fifo_CONFIG_IN_USB : entity work.fifo_in_config_8_to_32
  PORT MAP (
				rst 		=> RESET,
				wr_clk 		=> CLK_1X,
				rd_clk 		=> CLK_4X,
				din 		=> CONF_usb_Data,
				wr_en 		=> CONF_usb_WR,
				rd_en 		=> rd_en_CONF_FIFO,
				dout 		=> CONF_RECEIVED_DATA,
				full 		=> open,
				almost_full => CONF_usb_Rdy_n,
				empty 		=> empty_conf_DATA,
				valid 		=> valid_conf_DATA
  );	

end Behavioral;

