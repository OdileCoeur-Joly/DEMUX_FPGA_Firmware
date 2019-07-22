----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL
-- Create Date   : 21/09/2017 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : DEMUX_TOP - Behavioral 
-- Project Name  : Athena Xifu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : TOP level of DRE BBFB and acquisition system
--						 
-- Dependencies: athena package
--
-- Revision: 
-- Revision 1.02 - Sortie DAC AD9726 à 80MHz avec filtre à 2 étage Enable_clk_2x et enable_clk_1x
-- Revision 1.01 - Nouveaux HK A6A6 avec status
-- Revision 0.1  - Adaptation FPGA_BOARD
-- Revision 0.02 - add of chipscope ADC128
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library unisim;
  use unisim.vcomponents.all;
  use work.athena_package.all;
--! @brief-- BLock diagrams schematics -- 
--! @detail file:documentation.pdf
entity DEMUX_TOP is
	Port (
	 --ML605 Resources
		GPIO_LED					: out   std_logic_vector(7 downto 0);
		GPIO_DIP_SW      			: in    std_logic_vector(7 downto 0);
 		-- USER_SMA_GPIO_P 	  		: out   std_logic;
		-- USER_SMA_GPIO_N   			: out   std_logic;
		-- USER_SMA_CLOCK_P			: out 	std_logic;
		-- USER_SMA_CLOCK_N			: out   std_logic;

		-- FPGA_BOARD DIFF CLOCK RESET =======
		FPGA_RESET         			: in  std_logic; -- FPGA RST button, SW????
		FPGA_CLK_P 					: in  std_logic;
		FPGA_CLK_N 					: in  std_logic;
		
	-- TO/FROM GSE =======================
		HPC1_RESET_GSE				: in   std_logic; -- RESET FROM OPALKELLY
		-- USB3.0 FMC I/O ================
		-- DAQ_CLK_usb_OUT
--		HPC1_DAQ_CLK_P				: out   std_logic;
--		HPC1_DAQ_CLK_N				: out   std_logic;
		-- DAQ DATA 32 bits for science link
		HPC1_DAQ_D_P				: out std_logic_vector(31 downto 0);
		HPC1_DAQ_D_N				: out std_logic_vector(31 downto 0);
		-- DAQ RDY_N for science link
		HPC1_DAQ_RDYN_P				: in  std_logic;
		HPC1_DAQ_RDYN_N				: in  std_logic;
		-- DAQ WR 32 for science link
		HPC1_DAQ_WR_P				: out   std_logic;
		HPC1_DAQ_WR_N				: out   std_logic;

		-- DATA SENDING 1MHz 8 bits for HK link
		HPC1_HK_D_P					: out std_logic_vector(7 downto 0);
		HPC1_HK_D_N					: out std_logic_vector(7 downto 0);
		-- HK RDY_N for science link
		HPC1_HK_RDYN_P				: in  std_logic;
		HPC1_HK_RDYN_N				: in  std_logic;
		-- HK WR 32 for science link
		HPC1_HK_WR_P				: out   std_logic;
		HPC1_HK_WR_N				: out   std_logic;
		
		-- DATA RECEIVING 1MHz 8 bits for CONFIG link
		HPC1_HK_CLK_P				: out  std_logic;	-- 20MHz Clock for all links DAQ HK and CONF
		HPC1_HK_CLK_N				: out  std_logic;	-- 20MHz Clock for all links DAQ HK and CONF
		
		HPC1_CONF_D_P				: in std_logic_vector(7 downto 0);
		HPC1_CONF_D_N				: in std_logic_vector(7 downto 0);
		-- CONF RDY_N for science link
		HPC1_CONF_RDYN_P			: out  std_logic;
		HPC1_CONF_RDYN_N			: out  std_logic;
		-- CONF WR 32 for science link
		HPC1_CONF_WR_P				: in   std_logic;
		HPC1_CONF_WR_N				: in   std_logic;

---------------------------------------------------------------------------------------
-- EXTERNAL CH1 DAC (internal channel 0) DAC BOARD CONNEXIONS 
---------------------------------------------------------------------------------------
-- FROM/TO AD9726 BIAS
		DACB_CH1_SDO				: in   std_logic;
		DACB_CH1_SDIO				: out  std_logic;
		DACB_CH1_SCLK				: out  std_logic;
		DACB_CH1_CSn				: out  std_logic;
		DACB_CH1_D_P				: out  std_logic_vector(15 downto 0);
		DACB_CH1_D_N				: out  std_logic_vector(15 downto 0);
		DACB_CH1_RESET				: out  std_logic;
		DACB_CH1_DCLK_OUT_P			: in   std_logic;
		DACB_CH1_DCLK_OUT_N			: in   std_logic;
		DACB_CH1_DCLK_IN_P			: out  std_logic;
		DACB_CH1_DCLK_IN_N			: out  std_logic;
		
-- FROM/TO AD9726 FEEDBACK
		DACF_CH1_SDO				: in   std_logic;
		DACF_CH1_SDIO				: out  std_logic;
		DACF_CH1_SCLK				: out  std_logic;
		DACF_CH1_CSn				: out  std_logic;
		DACF_CH1_D_P				: out  std_logic_vector(15 downto 0);
		DACF_CH1_D_N				: out  std_logic_vector(15 downto 0);
		DACF_CH1_RESET				: out  std_logic;
		DACF_CH1_DCLK_OUT_P			: in   std_logic;
		DACF_CH1_DCLK_OUT_N			: in   std_logic;
		DACF_CH1_DCLK_IN_P			: out  std_logic;
		DACF_CH1_DCLK_IN_N			: out  std_logic;

-- -- FROM/TO CDCM7005
		DAC_CH1_CDCM_SCLK			: out  std_logic;
		DAC_CH1_CDCM_SLE			: out  std_logic;
		DAC_CH1_CDCM_SDIN			: out  std_logic;
		DAC_CH1_CDCM_RSTn			: out  std_logic;
		DAC_CH1_CDCM_STATUS_REF		: in   std_logic;
		DAC_CH1_CDCM_PLL_LOCK		: in   std_logic;
		DAC_CH1_CDCM_STATUS_VCXO	: in   std_logic;

-- FROM/TO ADC128

		DAC_CH1_ADC128_SCLK			: out  std_logic;
		DAC_CH1_ADC128_CSn			: out  std_logic;
		DAC_CH1_ADC128_DOUT			: in   std_logic;
		DAC_CH1_ADC128_DIN			: out  std_logic;
		DAC_CH1_MUX_S				: out  std_logic_vector(2 downto 0);
		
-- --Clock/Data connection to ADC RHF1201 on FMC_ADC_XIFU
		--ADC_CH1_CLK				: out std_logic;
	    ADC_CH1_SRC					: out std_logic;
		ADC_CH1_DR					: in std_logic;
		ADC_CH1_OE_N				: out std_logic;
		ADC_CH1_DFS_N				: out std_logic;
		ADC_CH1_D					: in  std_logic_vector(11 downto 0);
		ADC_CH1_OR					: in std_logic;
  --Clock/Data connection to ADC ADC128S102 on FMC_ADC_XIFU
 
			 
		ADC_CH1_ADC128_SCLK 		: out   std_logic;
		ADC_CH1_ADC128_DOUT 		: in    std_logic;
		ADC_CH1_ADC128_DIN  		: out   std_logic;
		ADC_CH1_ADC128_CS_N			: out   std_logic
-- ---------------------------------------------------------------------------------------
-- -- EXTERNAL CH2 DAC (internal channel 1) DAC BOARD CONNEXIONS 
-- ---------------------------------------------------------------------------------------
-- -- FROM/TO AD9726 BIAS
		-- DACB_CH2_SDO				: in   std_logic;
		-- DACB_CH2_SDIO				: out  std_logic;
		-- DACB_CH2_SCLK				: out  std_logic;
		-- DACB_CH2_CSn				: out  std_logic;
		-- DACB_CH2_D_P				: out  std_logic_vector(15 downto 0);
		-- DACB_CH2_D_N				: out  std_logic_vector(15 downto 0);
		-- DACB_CH2_RESET				: out  std_logic;
		-- DACB_CH2_DCLK_OUT_P			: in   std_logic;
		-- DACB_CH2_DCLK_OUT_N			: in   std_logic;
		-- DACB_CH2_DCLK_IN_P			: out  std_logic;
		-- DACB_CH2_DCLK_IN_N			: out  std_logic;
		
-- -- FROM/TO AD9726 FEEDBACK
		-- DACF_CH2_SDO				: in   std_logic;
		-- DACF_CH2_SDIO				: out  std_logic;
		-- DACF_CH2_SCLK				: out  std_logic;
		-- DACF_CH2_CSn				: out  std_logic;
		-- DACF_CH2_D_P				: out  std_logic_vector(15 downto 0);
		-- DACF_CH2_D_N				: out  std_logic_vector(15 downto 0);
		-- DACF_CH2_RESET				: out  std_logic;
		-- DACF_CH2_DCLK_OUT_P			: in   std_logic;
		-- DACF_CH2_DCLK_OUT_N			: in   std_logic;
		-- DACF_CH2_DCLK_IN_P			: out  std_logic;
		-- DACF_CH2_DCLK_IN_N			: out  std_logic;


-- -- FROM/TO ADC128

		-- DAC_CH2_ADC128_SCLK			: out  std_logic;
		-- DAC_CH2_ADC128_CSn			: out  std_logic;
		-- DAC_CH2_ADC128_DOUT			: in   std_logic;
		-- DAC_CH2_ADC128_DIN			: out  std_logic;
		-- DAC_CH2_MUX_S				: out  std_logic_vector(2 downto 0);
		
-- --Clock/Data connection to ADC RHF1201 on FMC_ADC_XIFU
-- --		ADC_CH2_CLK_RHF1201			: out std_logic;
	   -- ADC_CH2_SRC					: out std_logic;
		-- ADC_CH2_DR					: in std_logic;
		-- ADC_CH2_OE_N				: out std_logic;
		-- ADC_CH2_DFS_N				: out std_logic;
		-- ADC_CH2_D					: in  std_logic_vector(11 downto 0);
		-- ADC_CH2_OR					: in std_logic;
  -- --Clock/Data connection to ADC ADC128S102 on FMC_ADC_XIFU
 
			 
		-- ADC_CH2_ADC128_SCLK 		: out   std_logic;
		-- ADC_CH2_ADC128_DOUT 		: in    std_logic;
		-- ADC_CH2_ADC128_DIN  		: out   std_logic;
		-- ADC_CH2_ADC128_CS_N			: out   std_logic

	);
end DEMUX_TOP;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.DEMUX_TOP.Behavioral.svg
architecture Behavioral of DEMUX_TOP is
	signal RESET					: std_logic;
--	signal LOOP_ON					: std_logic;
--
--	-- Chipscope spy signals	
--	signal ila_daq_pciex_control	: std_logic_vector(35 downto 0);
--
--	signal ila_xifu_clk      		: std_logic;
--	signal ila_xifu_trig0    		: std_logic_vector(127 downto 0);
--	signal ila_xifu_control  		: std_logic_vector(35 downto 0);
--
--	signal ila_PCIEX_control  		: std_logic_vector(35 downto 0);
--	
--	signal ila_reg_clk      		: std_logic;
--	signal ila_reg_trig0    		: std_logic_vector(127 downto 0);
--	signal ila_reg_control  		: std_logic_vector(35 downto 0);
--
--	signal ila_ADC128_clk    		: std_logic;
--	signal ila_ADC128_trig0   		: std_logic_vector(127 downto 0);
--	signal ila_ADC128_control 		: std_logic_vector(35 downto 0);
--	signal CONF_ADDRESS_out			: integer ;
--	signal CONF_RECEIVED_DATA_out	: std_logic_vector(31 downto 0);
--	signal CONTROL_VIO		 		: std_logic_vector(35 downto 0);
--	signal sync_out			   		: std_logic_vector(15 downto 0);
	
--	constant C_GND					: std_logic_vector(127 downto 0) := (others=>'0');

	--internal clock signals
	signal CLK_LOCKED_200MHz   			: std_logic; -- ALL CLOCK MMCM ARE LOCKED
	signal CLK_LOCKED_CDCM     			: std_logic; -- ALL CLOCK MMCM ARE LOCKED
	signal CLK_4X	       				: std_logic;
	signal CLK_1X	       				: std_logic;

-- CLK divided 
	signal ENABLE_CLK_1X	       		: std_logic;
	signal ENABLE_CLK_2X	       		: std_logic;
--	signal ENABLE_CLK_1X_DIV4 			: STD_LOGIC;
--	signal ENABLE_CLK_1X_DIV16 			: STD_LOGIC;
--	signal ENABLE_CLK_1X_DIV64 			: STD_LOGIC;
	signal ENABLE_CLK_1X_DIV128			: std_logic; 
	signal ONE_SECOND					: std_logic; 
	signal twelve_mili_SECOND			: std_logic; 
	
--	signal SW_TM									: std_logic; 

--	signal reset_bbfb		   					: std_logic;

-- sciences signals
	signal BIAS								: t_bias;
	signal BIAS_to_DAC						: t_bias;
	signal out_squid		  				: t_in_phys;
	signal ADC_DOUT_DC_FILTRED 				: t_signed_12_array;
	signal IN_PHYS			  				: t_in_phys;
	signal feedback		  					: t_feedback_to_DAC;
	signal feedback_to_DAC					: t_feedback_to_DAC;
	signal out_science_filtred_i			: t_science_channel;
	signal out_science_filtred_q 			: t_science_channel;
	signal out_science_unfiltred_tp_i		: t_TP_science_channel;
	signal out_science_unfiltred_tp_q 		: t_TP_science_channel;
	signal BIAS_1ch							: t_bias;
	signal IN_PHYS_1ch			  			: t_in_phys;
	signal feedback_1ch		  				: t_feedback_to_DAC;
	signal out_science_filtred_i_1ch		: t_science_channel;
	signal out_science_filtred_q_1ch 		: t_science_channel;
	signal out_science_unfiltred_tp_i_1ch	: t_TP_science_channel;
	signal out_science_unfiltred_tp_q_1ch 	: t_TP_science_channel;


-- chenillard antoine visu test

	signal chenille					: std_logic_vector (7 downto 0);
	

-- FROM SELECTOR HK and TM
	signal TM_DATA_TO_GSE 			: std_logic_vector(31 downto 0);
	signal WR_en_TM_fifo					: std_logic;	
	signal ADC128_Read_Register_HK	: std_logic;
	signal ADC128_start_HK			: std_logic;
		
	signal HK_DATA_TO_GSE 			: std_logic_vector(31 downto 0);
	signal WR_en_HK_fifo			: std_logic;	
	signal almost_full_HK_fifo		: std_logic;

	-- TO USB_3.0 manager
   signal   DAQ_CLK_usb_OUT			: std_logic;
-- DAQ 32 bits for science link
   signal   DAQ_usb_Data			: std_logic_vector(31 downto 0);
   signal   DAQ_usb_Rdy_n			: std_logic;
   signal   DAQ_usb_WR				: std_logic;
-- DATA SENDING 1MHz 8 bits for HK link
   signal   HK_usb_Data				: std_logic_vector(7 downto 0);
   signal   HK_usb_Rdy_n			: std_logic;
   signal   HK_usb_WR				: std_logic;
-- DATA RECEIVED 1MHz 8 bits for Config link
   signal   CONF_usb_Data			: std_logic_vector(7 downto 0);
   signal   CONF_usb_Rdy_n			: std_logic;
   signal   CONF_usb_WR				: std_logic;
-- STATUS SENDING BAD ADDRESS RECEIVED			
--	signal	Bad_conf_register_write : std_logic;
			
	---------------------------------------------------------------------------------------
-- Channel (CH1 and CH2)(internal Channel 0 and 1) in/out DAC Board signals from controler
------------------------------------------------------------------------------------------


	-- FROM/TO AD9726 BIAS controler
	signal 		DACB_SPI_command 		: t_std_logic_3_array;
	signal 		DACB_SPI_address 		: t_DAC_SPI_address;
	signal 		DACB_SPI_data 			: t_std_logic_8_array;
	signal 		DACB_SPI_write 			: t_std_logic_array;
	signal 		DACB_SPI_ready 			: t_std_logic_array;
	signal 		DACB_SPI_DATA_RECEIVED 	: t_std_logic_8_array;
	signal 		DACB_DCLK_FROM	   		: t_std_logic_array;
	signal 		DACB_DCLK_TO	   		: t_std_logic_array;
	signal 		DACB_DATA_OUT	   		: t_std_logic_16_array;
	signal 		DACB_DATA		   		: t_std_logic_16_array;
	signal 		DACB_SPI_SDO	   		: t_std_logic_array;
	signal 		DACB_SPI_SDIO	   		: t_std_logic_array;
	signal 		DACB_SPI_SCLK	   		: t_std_logic_array;
	signal 		DACB_SPI_CS_N	   		: t_std_logic_array;
	signal 		DACB_RESET_IN			: t_std_logic_array;
	signal 		DACB_RESET		   		: t_std_logic_array;
	
	-- FROM/TO AD9726 FEEDBACK controler	
	signal 		DACF_SPI_command 		: t_std_logic_3_array;
	signal 		DACF_SPI_address 		: t_DAC_SPI_address;
	signal 		DACF_SPI_data 			: t_std_logic_8_array;
	signal 		DACF_SPI_write 			: t_std_logic_array;
	signal 		DACF_SPI_ready 			: t_std_logic_array;
	signal 		DACF_SPI_DATA_RECEIVED 	: t_std_logic_8_array;
	signal 		DACF_DCLK_FROM	   		: t_std_logic_array;
	signal 		DACF_DCLK_TO	   		: t_std_logic_array;
	signal 		DACF_DATA_OUT	   		: t_std_logic_16_array;
	signal 		DACF_DATA		   		: t_std_logic_16_array;
	signal 		DACF_SPI_SDO	   		: t_std_logic_array;
	signal 		DACF_SPI_SDIO	   		: t_std_logic_array;
	signal 		DACF_SPI_SCLK	   		: t_std_logic_array;
	signal 		DACF_SPI_CS_N	   		: t_std_logic_array;
	signal 		DACF_RESET_IN	   		: t_std_logic_array;
	signal 		DACF_RESET		   		: t_std_logic_array;
	signal 		DAC_RESET_STARTUP  		: std_logic;

	-- FROM/TO CDCM7005 CONTROLER
   signal 		CDCM_SPI_command 		: std_logic_vector(29 downto 0);
   signal 		CDCM_SPI_address 		: std_logic_vector(1 downto 0);
   signal 		CDCM_SPI_write 			: std_logic;
   signal 		CDCM_SPI_ready 			: std_logic;
	signal		CDCM_SCLK	   			: std_logic;
	signal 		CDCM_SLE	   			: std_logic;
	signal 		CDCM_RSTn	   			: std_logic;
	signal 		CDCM_SDIN	   			: std_logic;
	signal 		CDCM_STATUS_REF	   		: std_logic;
	signal 		CDCM_PLL_LOCK	   		: std_logic;
	signal 		CDCM_STATUS_VCXO	   	: std_logic;

	-- FROM/TO ADC128 CONTROLER DAC BOARD
	signal		DAC_ADC128_SCLK	  		: t_std_logic_array;
	signal		DAC_ADC128_CSn		  	: t_std_logic_array;
	signal		DAC_ADC128_DOUT	  		: t_std_logic_array;
	signal		DAC_ADC128_DIN		  	: t_std_logic_array;
	signal		DAC_ADC128_MUX_S	  	: t_std_logic_3_array;
	signal 		DAC_ADC128_registers	: t_register_MUXED_ADC128_ARRAY;
	signal 		DAC_adc128_start		: t_std_logic_array;
	signal 		DAC_ADC128_Read_Register: t_std_logic_array;
	signal 		DAC_adc128_done			: t_std_logic_array;

---------------------------------------------------------------------------------
-- ADC board (CH1) signals
---------------------------------------------------------------------------------		
-- ADC128 signals
	signal ADC_ADC128_SCLK	  			: t_std_logic_array;
	signal ADC_ADC128_CS_N		  		: t_std_logic_array;
	signal ADC_ADC128_DOUT	  			: t_std_logic_array;
	signal ADC_ADC128_DIN		  		: t_std_logic_array;
	signal ADC_ADC128_registers			: t_register_ADC128_ARRAY;
	signal ADC_ADC128_start				: t_std_logic_array;
	signal ADC_ADC128_Read_Register 	: t_std_logic_array;
--	signal ADC_ADC128_Read_Register_DAQ	: t_std_logic_array;
--	signal ADC_ADC128_Read_Register_HK	: t_std_logic_array;
--	signal ADC_adc128_start_HK_USB30	: t_std_logic_array;
--	signal ADC_adc128_start_DAQ_USB		: t_std_logic_array;
	signal ADC_adc128_done				: t_std_logic_array;
	
-- ADCRHF1201 control signals
	signal ADC_OOR						: t_std_logic_array;
--	signal ADC_OOR_int					: t_std_logic_array;
	signal ADC_SRC						: t_std_logic_array;
	signal ADC_OE_N						: t_std_logic_array;
	signal ADC_DFS_N					: t_std_logic_array;
--	signal ADC_ready					: t_std_logic_array;
	signal ADC_CLK						: t_std_logic_array;
--	signal ADC_CLK_int					: t_std_logic_array;
	signal ADC_DR						: t_std_logic_array;
--	signal ADC_DR_int					: t_std_logic_array;
	signal ADC_DIN						: t_signed_12_array;
	signal ADC_DOUT						: t_signed_12_array;
--	signal ADC_D						: t_std_logic_12_array;
	signal CONTROL						: t_CONTROL;
	signal regCONFIG       				: t_ARRAY32bits(C_NB_REG_CONF-1 downto 0);
	signal ADC128_ALL_registers			: t_register_ALL_ADC128;
	signal adc128_ALL_done				: std_logic;
	signal STATUS 						: t_STATUS;

---------------------------------------------------------------------------------
begin
-- version and board Identifiers
STATUS.IDENTIFIER.BOARD_ID				<= b"0000_0000_0000_0001";
STATUS.IDENTIFIER.MODEL_ID				<= x"1";
STATUS.IDENTIFIER.BOARD_VERSION 		<= x"0" & GPIO_DIP_SW(0) & GPIO_DIP_SW(1) & GPIO_DIP_SW(2) & GPIO_DIP_SW(3) & GPIO_DIP_SW(4) & GPIO_DIP_SW(5) & GPIO_DIP_SW(6) & GPIO_DIP_SW(7);
STATUS.IDENTIFIER.FIRMWARE_ID			<= x"0217";
STATUS.IDENTIFIER.NB_CHANNEL			<= std_logic_vector(to_unsigned(C_Nb_channel,2));
STATUS.IDENTIFIER.NB_PIXEL				<= std_logic_vector(to_unsigned(C_Nb_pixel,7));

----------------------------------------------------------------------------
--	
-- differential I/O converter to HPC LPC
--
----------------------------------------------------------------------------
IO_Converter_FPGA : entity work.IO_converter
    Port map( 
----------------------------------------------------------------------------
---- FROM USB_3.0 internal manager
----------------------------------------------------------------------------
      DAQ_CLK_USB_OUT			=> DAQ_CLK_usb_OUT,
--	-- DAQ 32 bits for science link
      DAQ_usb_Data				=> DAQ_usb_Data,
      DAQ_usb_Rdy_n				=> DAQ_usb_Rdy_n,
      DAQ_usb_WR				=> DAQ_usb_WR,

	-- DATA SENDING 10MHz 8 bits for HK link
      HK_usb_Data				=> HK_usb_Data,
      HK_usb_Rdy_n				=> HK_usb_Rdy_n,
      HK_usb_WR					=> HK_usb_WR,

	-- DATA RECEIVED 10MHz 8 bits for Config link
      CONF_usb_Data				=> CONF_usb_Data,
      CONF_usb_Rdy_n			=> CONF_usb_Rdy_n,
      CONF_usb_WR				=> CONF_usb_WR,
	  
-- UNCOMMENT TO NOT USE USB30 OUTPUT
-->
---- TO FMC_USB 3.0 Link I/O
-- --		-- DAQ_CLK_usb_OUT
		-- HPC1_CLK_P				=> open, 	-- 20MHz Clock for all links DAQ HK and CONF
		-- HPC1_CLK_N				=> open,		-- 20MHz Clock for all links DAQ HK and CONF
		-- -- DAQ DATA 32 bits for science link
		-- HPC1_DAQ_D_P			=> open,
		-- HPC1_DAQ_D_N			=> open,
		-- -- DAQ RDY_N for science link
		-- HPC1_DAQ_RDYN_P			=>  '1',
		-- HPC1_DAQ_RDYN_N			=>  '0',
		-- -- DAQ WR 32 for science link
		-- HPC1_DAQ_WR_P			=> open,
		-- HPC1_DAQ_WR_N			=> open,

-- -- DATA SENDING 1MHz 8 bits for HK link
		-- HPC1_HK_D_P				=> open,
		-- HPC1_HK_D_N				=> open,
		-- -- HK RDY_N for science link
		-- HPC1_HK_RDYN_P			=> '1',
		-- HPC1_HK_RDYN_N			=> '0', 
		-- -- HK WR 32 for science link
		-- HPC1_HK_WR_P			=> open,
		-- HPC1_HK_WR_N			=> open,
		
-- -- DATA RECEIVING 1MHz 8 bits for CONFIG link
		-- HPC1_CONF_D_P			=> (others =>'0'),
		-- HPC1_CONF_D_N			=> (others =>'0'),
		-- -- CONF RDY_N for science link
		-- HPC1_CONF_RDYN_P		=> open,
		-- HPC1_CONF_RDYN_N		=> open,
		-- -- CONF WR 32 for science link
		-- HPC1_CONF_WR_P			=> '1',
		-- HPC1_CONF_WR_N			=> '0',
--< END OF UNCOMMENT TO NOT USE USB30 OUTPUT
-- COMMENT TO NOT USE USB30 OUTPUT	
-->	

---- TO FMC_USB 3.0 Link I/O
--		-- DAQ_CLK_usb_OUT
		HPC1_CLK_P				=> HPC1_HK_CLK_P,	-- 20MHz Clock for all links DAQ HK and CONF
		HPC1_CLK_N				=> HPC1_HK_CLK_N,	-- 20MHz Clock for all links DAQ HK and CONF
		-- DAQ DATA 32 bits for science link
		HPC1_DAQ_D_P			=> HPC1_DAQ_D_P,
		HPC1_DAQ_D_N			=> HPC1_DAQ_D_N,
		-- DAQ RDY_N for science link
		HPC1_DAQ_RDYN_P			=>  HPC1_DAQ_RDYN_P,
		HPC1_DAQ_RDYN_N			=>  HPC1_DAQ_RDYN_N,
		-- DAQ WR 32 for science link
		HPC1_DAQ_WR_P			=> HPC1_DAQ_WR_P,
		HPC1_DAQ_WR_N			=> HPC1_DAQ_WR_N,

-- DATA SENDING 1MHz 8 bits for HK link
		HPC1_HK_D_P				=> HPC1_HK_D_P,
		HPC1_HK_D_N				=> HPC1_HK_D_N,
		-- HK RDY_N for science link
		HPC1_HK_RDYN_P			=> HPC1_HK_RDYN_P,
		HPC1_HK_RDYN_N			=> HPC1_HK_RDYN_N,
		-- HK WR 32 for science link
		HPC1_HK_WR_P			=> HPC1_HK_WR_P,
		HPC1_HK_WR_N			=> HPC1_HK_WR_N,
		
-- DATA RECEIVING 1MHz 8 bits for CONFIG link
		HPC1_CONF_D_P			=> HPC1_CONF_D_P,
		HPC1_CONF_D_N			=> HPC1_CONF_D_N,
		-- CONF RDY_N for science link
		HPC1_CONF_RDYN_P		=> HPC1_CONF_RDYN_P,
		HPC1_CONF_RDYN_N		=> HPC1_CONF_RDYN_N,
		-- CONF WR 32 for science link
		HPC1_CONF_WR_P			=> HPC1_CONF_WR_P,
		HPC1_CONF_WR_N			=> HPC1_CONF_WR_N,
--< END OF COMMENT TO NOT USE USB30 OUTPUT	

-------------------------------------------------------
-- TO/ FROM INTERNAL ADC DAC CDCM CONTROLERS
-------------------------------------------------------
-- FROM/TO AD9726 internal BIAS controlers	
		DACB_DCLK_FROM			=> DACB_DCLK_FROM,
		DACB_DCLK_TO			=> DACB_DCLK_TO,
		DACB_DATA_OUT			=> DACB_DATA_OUT,
		DACB_SPI_SDO			=> DACB_SPI_SDO,
		DACB_SPI_SDIO			=> DACB_SPI_SDIO,
		DACB_SPI_SCLK			=> DACB_SPI_SCLK,
		DACB_SPI_CS_N			=> DACB_SPI_CS_N,
		DACB_RESET				=> DACB_RESET,
		
-- FROM/TO AD9726  internal FEEDBACK controlers	
		DACF_DCLK_FROM			=> DACF_DCLK_FROM,
		DACF_DCLK_TO			=> DACF_DCLK_TO,
		DACF_DATA_OUT			=> DACF_DATA_OUT,
		DACF_SPI_SDO			=> DACF_SPI_SDO,
		DACF_SPI_SDIO			=> DACF_SPI_SDIO,
		DACF_SPI_SCLK			=> DACF_SPI_SCLK,
		DACF_SPI_CS_N			=> DACF_SPI_CS_N,
		DACF_RESET				=> DACF_RESET,

-- FROM/TO internal ADC128 DAC BOARDS CONTROLERS  CH1 and CH2
		DAC_ADC128_SCLK			=> DAC_ADC128_SCLK,
		DAC_ADC128_CSn			=> DAC_ADC128_CSn,
		DAC_ADC128_DOUT			=> DAC_ADC128_DOUT,
		DAC_ADC128_DIN			=> DAC_ADC128_DIN,
		DAC_MUX_S				=> DAC_ADC128_MUX_S,
		
-- FROM/TO internal CDCM7005 CONTROLERS
		CDCM_SCLK				=> CDCM_SCLK,
		CDCM_SLE				=> CDCM_SLE,
		CDCM_RSTn				=> CDCM_RSTn,
		CDCM_SDIN				=> CDCM_SDIN,
		CDCM_STATUS_REF			=> CDCM_STATUS_REF,
		CDCM_PLL_LOCK			=> CDCM_PLL_LOCK,
		CDCM_STATUS_VCXO		=> CDCM_STATUS_VCXO,
		
-- FROM/TO ADC128 internal ADC128 ADC BOARDS CONTROLERS CH1 and CH2

		ADC_ADC128_SCLK			=> ADC_ADC128_SCLK,
		ADC_ADC128_CSn			=> ADC_ADC128_CS_N,
		ADC_ADC128_DOUT			=> ADC_ADC128_DOUT,
		ADC_ADC128_DIN			=> ADC_ADC128_DIN,

-- FROM/TO ADC RHF1201 INTERNALS CONTROLERS
--Clock/Data connection to ADC RHF1201 on FMC_ADC_XIFU

		ADC_CLK						=> ADC_CLK,
	    ADC_SRC						=> ADC_SRC,
		ADC_DR						=> ADC_DR,
		ADC_OE_N					=> ADC_OE_N,
		ADC_DFS_N					=> ADC_DFS_N,
		ADC_DIN						=> ADC_DIN,
		ADC_OOR						=> ADC_OOR,
------------------------------------------------------------------
-- CH1 DAC_HPC_BOARD externals connexions (internal channel 0)
---------------------------------------------------------------------

-- UNCOMMENT TO NOT USE CH1 (internal CH0)
-->	
		-- DACB_CH1_SDO			=> '0',
		-- DACB_CH1_SDIO			=> open,
		-- DACB_CH1_SCLK			=> open,
		-- DACB_CH1_CSn			=> open,
		-- DACB_CH1_D_P			=> open,
		-- DACB_CH1_D_N			=> open,
		-- DACB_CH1_RESET			=> open,
		-- DACB_CH1_DCLK_OUT_P		=> '1',
		-- DACB_CH1_DCLK_OUT_N		=> '0',
		-- DACB_CH1_DCLK_IN_P		=> open,
		-- DACB_CH1_DCLK_IN_N		=> open,
		
-- -- FROM/TO AD9726 FEEDBACK controler	
-- -- FROM/TO AD9726 FEEDBACK
		-- DACF_CH1_SDO			=> '0',
		-- DACF_CH1_SDIO			=> open,
		-- DACF_CH1_SCLK			=> open,
		-- DACF_CH1_CSn			=> open,
		-- DACF_CH1_D_P			=> open,
		-- DACF_CH1_D_N			=> open,
		-- DACF_CH1_RESET			=> open,
		-- DACF_CH1_DCLK_OUT_P		=> '1',
		-- DACF_CH1_DCLK_OUT_N		=> '0',
		-- DACF_CH1_DCLK_IN_P		=> open,
		-- DACF_CH1_DCLK_IN_N		=> open,

-- -- FROM/TO ADC128 CONTROLER
-- -- FROM/TO ADC128

		-- DAC_CH1_ADC128_SCLK		=> open,
		-- DAC_CH1_ADC128_CSn		=> open,
		-- DAC_CH1_ADC128_DOUT		=> '0',
		-- DAC_CH1_ADC128_DIN		=> open,
		-- DAC_CH1_MUX_S			=> open,
-- FROM/TO CDCM7005
		-- DAC_CH1_CDCM_SCLK		=> open,
		-- DAC_CH1_CDCM_SLE		=> open,
		-- DAC_CH1_CDCM_RST_N		=> open,
		-- DAC_CH1_CDCM_SDIN		=> open,
		-- DAC_CH1_CDCM_STATUS_REF	=> '0',
		-- DAC_CH1_CDCM_PLL_LOCK	=> '0',
		-- DAC_CH1_CDCM_STATUS_VCXO=> '0',

-- --Clock/Data connection to ADC RHF1201 on FMC_ADC_XIFU

		-- ADC_CH1_CLK				=> open, --NOT uSED BECAUSE IT IS THE SAME AS INTERNAL CLOCK
	    -- ADC_CH1_SRC				=> open,
		-- ADC_CH1_DR				=> '0',
		-- ADC_CH1_OE_N			=> open,
		-- ADC_CH1_DFS_N			=> open,
		-- ADC_CH1_D				=> (others =>'0'),
		-- ADC_CH1_OOR				=> '0',
		
  -- --Clock/Data connection to ADC ADC128S102 on FMC_ADC_XIFU
			 
		-- ADC_CH1_ADC128_SCLK		=> open,
		-- ADC_CH1_ADC128_DOUT		=> '0',
		-- ADC_CH1_ADC128_DIN		=> open,
		-- ADC_CH1_ADC128_CS_N		=> open,
		
-- END OF UNCOMMENT TO NOT USE CH1 (internal CH0)

-- COMMENT TO REMOVE CH1 (internal CH0)
-->
-- FROM/TO AD9726 BIAS
		DACB_CH1_SDO			=> DACB_CH1_SDO,
		DACB_CH1_SDIO			=> DACB_CH1_SDIO,
		DACB_CH1_SCLK			=> DACB_CH1_SCLK,
		DACB_CH1_CSn			=> DACB_CH1_CSn,
		DACB_CH1_D_P			=> DACB_CH1_D_P,
		DACB_CH1_D_N			=> DACB_CH1_D_N,
		DACB_CH1_RESET			=> DACB_CH1_RESET,
		DACB_CH1_DCLK_OUT_P		=> DACB_CH1_DCLK_OUT_P,
		DACB_CH1_DCLK_OUT_N		=> DACB_CH1_DCLK_OUT_N,
		DACB_CH1_DCLK_IN_P		=> DACB_CH1_DCLK_IN_P,
		DACB_CH1_DCLK_IN_N		=> DACB_CH1_DCLK_IN_N,
		
-- FROM/TO AD9726 FEEDBACK
		DACF_CH1_SDO			=> DACF_CH1_SDO,
		DACF_CH1_SDIO			=> DACF_CH1_SDIO,
		DACF_CH1_SCLK			=> DACF_CH1_SCLK,
		DACF_CH1_CSn			=> DACF_CH1_CSn,
		DACF_CH1_D_P			=> DACF_CH1_D_P,
		DACF_CH1_D_N			=> DACF_CH1_D_N,
		DACF_CH1_RESET			=> DACF_CH1_RESET,
		DACF_CH1_DCLK_OUT_P		=> DACF_CH1_DCLK_OUT_P,
		DACF_CH1_DCLK_OUT_N		=> DACF_CH1_DCLK_OUT_N,
		DACF_CH1_DCLK_IN_P		=> DACF_CH1_DCLK_IN_P,
		DACF_CH1_DCLK_IN_N		=> DACF_CH1_DCLK_IN_N,

-- FROM/TO ADC128

		DAC_CH1_ADC128_SCLK		=> DAC_CH1_ADC128_SCLK,
		DAC_CH1_ADC128_CSn		=> DAC_CH1_ADC128_CSn,
		DAC_CH1_ADC128_DOUT		=> DAC_CH1_ADC128_DOUT,
		DAC_CH1_ADC128_DIN		=> DAC_CH1_ADC128_DIN,
		DAC_CH1_MUX_S			=> DAC_CH1_MUX_S,

		-- -- FROM/TO CDCM7005
		DAC_CH1_CDCM_SCLK		=> DAC_CH1_CDCM_SCLK,
		DAC_CH1_CDCM_SLE		=> DAC_CH1_CDCM_SLE,
		DAC_CH1_CDCM_RST_N		=> DAC_CH1_CDCM_RSTn,
		DAC_CH1_CDCM_SDIN		=> DAC_CH1_CDCM_SDIN,
		DAC_CH1_CDCM_STATUS_REF	=> DAC_CH1_CDCM_STATUS_REF,
		DAC_CH1_CDCM_PLL_LOCK	=> DAC_CH1_CDCM_PLL_LOCK,
		DAC_CH1_CDCM_STATUS_VCXO=> DAC_CH1_CDCM_STATUS_VCXO,
-----------------------------------------------------------------------
---- CH1 ADC_LPC_BOARD externals connexions (internal channel 0)
-----------------------------------------------------------------------

--Clock/Data connection to ADC RHF1201 on FMC_ADC_XIFU

		ADC_CH1_CLK				=> open, --NOT uSED BECAUSE IT IS THE SAME AS INTERNAL CLOCK
	    ADC_CH1_SRC				=> ADC_CH1_SRC,
		ADC_CH1_DR				=> ADC_CH1_DR,
		ADC_CH1_OE_N			=> ADC_CH1_OE_N,
		ADC_CH1_DFS_N			=> ADC_CH1_DFS_N,
		ADC_CH1_D				=> ADC_CH1_D,
		ADC_CH1_OOR				=> ADC_CH1_OR,
		
  --Clock/Data connection to ADC ADC128S102 on FMC_ADC_XIFU
			 
		ADC_CH1_ADC128_SCLK		=> ADC_CH1_ADC128_SCLK,
		ADC_CH1_ADC128_DOUT		=> ADC_CH1_ADC128_DOUT,
		ADC_CH1_ADC128_DIN		=> ADC_CH1_ADC128_DIN,
		ADC_CH1_ADC128_CS_N		=> ADC_CH1_ADC128_CS_N,
		
--< END OF COMMENT TO REMOVE CH1 (internal CH0)		
		
-----------------------------------------------------------------------
---- CH2 DAC_HPC_BOARD externals connexions (internal channel 1)
-----------------------------------------------------------------------
-- UNCOMMENT TO REMOVE CH2 (internal CH1)
-->
-- FROM/TO AD9726 BIAS controler	
-- FROM/TO AD9726 BIAS
		DACB_CH2_SDO			=> '0',
		DACB_CH2_SDIO			=> open,
		DACB_CH2_SCLK			=> open,
		DACB_CH2_CSn			=> open,
		DACB_CH2_D_P			=> open,
		DACB_CH2_D_N			=> open,
		DACB_CH2_RESET			=> open,
		DACB_CH2_DCLK_OUT_P		=> '1',
		DACB_CH2_DCLK_OUT_N		=> '0',
		DACB_CH2_DCLK_IN_P		=> open,
		DACB_CH2_DCLK_IN_N		=> open,
		
-- FROM/TO AD9726 FEEDBACK controler	
-- FROM/TO AD9726 FEEDBACK
		DACF_CH2_SDO			=> '0',
		DACF_CH2_SDIO			=> open,
		DACF_CH2_SCLK			=> open,
		DACF_CH2_CSn			=> open,
		DACF_CH2_D_P			=> open,
		DACF_CH2_D_N			=> open,
		DACF_CH2_RESET			=> open,
		DACF_CH2_DCLK_OUT_P		=> '1',
		DACF_CH2_DCLK_OUT_N		=> '0',
		DACF_CH2_DCLK_IN_P		=> open,
		DACF_CH2_DCLK_IN_N		=> open,

-- FROM/TO ADC128 CONTROLER
-- FROM/TO ADC128

		DAC_CH2_ADC128_SCLK		=> open,
		DAC_CH2_ADC128_CSn		=> open,
		DAC_CH2_ADC128_DOUT		=> '0',
		DAC_CH2_ADC128_DIN		=> open,
		DAC_CH2_MUX_S			=> open,
--< END OF UNCOMMENT TO REMOVE CH2 (internal CH1)		

-- -----------------------------------------------------------------------
---- CH2 DAC_HPC_BOARD externals connexions (internal channel 1)
-----------------------------------------------------------------------
-- COMMENT TO REMOVE PORT CH2 (internal channel 1)
-->
-- ---- FROM/TO AD9726 BIAS controler	
-- ---- FROM/TO AD9726 BIAS
		-- DACB_CH2_SDO			=> DACB_CH2_SDO,
		-- DACB_CH2_SDIO			=> DACB_CH2_SDIO,
		-- DACB_CH2_SCLK			=> DACB_CH2_SCLK,
		-- DACB_CH2_CSn			=> DACB_CH2_CSn,
		-- DACB_CH2_D_P			=> DACB_CH2_D_P,
		-- DACB_CH2_D_N			=> DACB_CH2_D_N,
		-- DACB_CH2_RESET			=> DACB_CH2_RESET,
		-- DACB_CH2_DCLK_OUT_P		=> DACB_CH2_DCLK_OUT_P,
		-- DACB_CH2_DCLK_OUT_N		=> DACB_CH2_DCLK_OUT_N,
		-- DACB_CH2_DCLK_IN_P		=> DACB_CH2_DCLK_IN_P,
		-- DACB_CH2_DCLK_IN_N		=> DACB_CH2_DCLK_IN_N,
		
-- -- FROM/TO AD9726 FEEDBACK controler	
-- -- FROM/TO AD9726 FEEDBACK
		-- DACF_CH2_SDO			=> DACF_CH2_SDO,
		-- DACF_CH2_SDIO			=> DACF_CH2_SDIO,
		-- DACF_CH2_SCLK			=> DACF_CH2_SCLK,
		-- DACF_CH2_CSn			=> DACF_CH2_CSn,
		-- DACF_CH2_D_P			=> DACF_CH2_D_P,
		-- DACF_CH2_D_N			=> DACF_CH2_D_N,
		-- DACF_CH2_RESET			=> DACF_CH2_RESET,
		-- DACF_CH2_DCLK_OUT_P		=> DACF_CH2_DCLK_OUT_P,
		-- DACF_CH2_DCLK_OUT_N		=> DACF_CH2_DCLK_OUT_N,
		-- DACF_CH2_DCLK_IN_P		=> DACF_CH2_DCLK_IN_P,
		-- DACF_CH2_DCLK_IN_N		=> DACF_CH2_DCLK_IN_N,

-- -- FROM/TO ADC128 CONTROLER
-- -- FROM/TO ADC128

		-- DAC_CH2_ADC128_SCLK		=> DAC_CH2_ADC128_SCLK,
		-- DAC_CH2_ADC128_CSn		=> DAC_CH2_ADC128_CSn,
		-- DAC_CH2_ADC128_DOUT		=> DAC_CH2_ADC128_DOUT,
		-- DAC_CH2_ADC128_DIN		=> DAC_CH2_ADC128_DIN,
		-- DAC_CH2_MUX_S			=> DAC_CH2_MUX_S,
		
		
--< END OF 	COMMENT TO REMOVE PORT CH2 (internal channel 1)	




-----------------------------------------------------------------------
---- CH2 ADC_LPC_BOARD (internal channel 1)
-----------------------------------------------------------------------
-- UNCOMMENT TO REMOVE ADC_CH2	(internal channel 1)	
-- FROM/TO ADC RHF1201 CH2
--Clock/Data connection to ADC RHF1201 on FMC_ADC_XIFU

		ADC_CH2_CLK				=> open,
	    ADC_CH2_SRC				=> open,
		ADC_CH2_DR				=> '0',
		ADC_CH2_OE_N				=> open,
		ADC_CH2_DFS_N			=> open,
		ADC_CH2_D				=> (others =>'0'),
		ADC_CH2_OOR				=> '0',
		
--  Clock/Data connection to ADC ADC128S102 on FMC_ADC_XIFU
			 
		ADC_CH2_ADC128_SCLK		=> open,
		ADC_CH2_ADC128_DOUT		=> '0',
		ADC_CH2_ADC128_DIN		=> open,
		ADC_CH2_ADC128_CS_N		=> open

-- COMMENT TO REMOVE ADC_CH2 (internal CH1)
-->
		-- FROM/TO ADC RHF1201 CH2
--Clock/Data connection to ADC RHF1201 on FMC_ADC_XIFU

		-- ADC_CH2_CLK				=> open,--NOT uSED BECAUSE IT IS THE SAME AS INTERNAL CLOCK
	    -- ADC_CH2_SRC				=> ADC_CH2_SRC,
		-- ADC_CH2_DR				=> ADC_CH2_DR,
		-- ADC_CH2_OE_N			=> ADC_CH2_OE_N,
		-- ADC_CH2_DFS_N			=> ADC_CH2_DFS_N,
		-- ADC_CH2_D				=> ADC_CH2_D,
		-- ADC_CH2_OOR				=> ADC_CH2_OR,
		
-- --  Clock/Data connection to ADC ADC128S102 on FMC_ADC_XIFU
			 
		-- ADC_CH2_ADC128_SCLK		=> ADC_CH2_ADC128_SCLK,
		-- ADC_CH2_ADC128_DOUT		=> ADC_CH2_ADC128_DOUT,
		-- ADC_CH2_ADC128_DIN		=> ADC_CH2_ADC128_DIN,
		-- ADC_CH2_ADC128_CS_N		=> ADC_CH2_ADC128_CS_N
--< END OF COMMENT TO REMOVE ADC_CH2 (internal CH1)


			);
			
	-- ***************************************************************
	-- CLOCK MANAGER
	-- ***************************************************************
	-- create clocks for all the module 
	-- allow switching clock between FPGA_BOARD External user_SMA_Clk and DAC board output clock (use BUFMUX xilinx CORE)
	-- We switch clock after programmation of CDCM PLL 

CMM1:	entity work.CMM 
    Port map 
		(
		FPGA_RESET 				=> FPGA_RESET, 					-- from push button
		HPC1_RESET_GSE			=> HPC1_RESET_GSE,				-- from HPC1 usb3.0 board
		SYSCLK_P 				=> FPGA_CLK_P,  					-- 80MHz from FPGA_BOARD oscilator or user_sma_clock_P
		SYSCLK_N 				=> FPGA_CLK_N,  					-- 80MHz from FPGA_BOARD oscilator or user_sma_clock_P
		DAC_CLK					=> DACF_DCLK_FROM(0),			-- USER_SMA_CLOCK_P19.53MHz from DAC BOARD
		CLK_CDCM_SELECT			=> CONTROL.CMM.CLK_CDCM_SELECT,		--CLOCK select from GSE control Register
		CDCM_PLL_RESET			=> CONTROL.CMM.CLK_CDCM_PLL_RESET,		-- from register to reset internal xilinx CDCM PLL
       	HW_RESET 				=> RESET,					-- General Reset output from CLK_LOCKED anc CPU_RESET
		CLK_4X					=> CLK_4X,	  					-- 80 MHz or 78.12MHz depend on CLK_CDCM_SELECT
		CLK_1X					=> CLK_1X,	  					-- 20MHz or 19.53MHz depend on CLK_CDCM_SELECT for ADC
		CLK_LOCKED_CDCM			=> CLK_LOCKED_CDCM,				-- output for CDCM CLOCK INTERNAL LOCK
		CLK_LOCKED_200MHz		=> CLK_LOCKED_200MHz,			-- output for FPGA_BOARD or user_sma_clock_P INTERNAL PLL LOCKED
 		ENABLE_CLK_1X			=> ENABLE_CLK_1X,				-- Enable Clock at 20MHz or 19.53MHz
 		ENABLE_CLK_2X			=> ENABLE_CLK_2X,				-- Enable Clock at 40MHz or 39.06MHz
 		ENABLE_CLK_1X_DIV4		=> open,--ENABLE_CLK_1X_DIV4,				-- Enable Clock at 40MHz or 39.06MHz
 		ENABLE_CLK_1X_DIV16		=> open,--ENABLE_CLK_1X_DIV16,				-- Enable Clock at 40MHz or 39.06MHz
 		ENABLE_CLK_1X_DIV64		=> open,--ENABLE_CLK_1X_DIV64,				-- Enable Clock at 40MHz or 39.06MHz
        ENABLE_CLK_1X_DIV128	=> ENABLE_CLK_1X_DIV128,		-- Enable Clock at 20MHz/128 or 19.53MHz/128
		ONE_SECOND				=> ONE_SECOND,					-- Enable Clock at one second
		twelve_mili_SECOND		=> twelve_mili_SECOND,			-- Enable Clock at 12 ms
		Chenille				=>	chenille					-- LED chaser
		); 
STATUS.CMM.CLK_LOCKED_CDCM		<= CLK_LOCKED_CDCM;
STATUS.CMM.CLK_LOCKED_200MHz	<= CLK_LOCKED_200MHz;
STATUS.CMM.CLK_CDCM_SELECT		<= CONTROL.CMM.CLK_CDCM_SELECT;
STATUS.CMM.CLK_CDCM_PLL_RESET	<= CONTROL.CMM.CLK_CDCM_PLL_RESET;
STATUS.CDCM.STATUS_REF			<= CDCM_STATUS_REF;
STATUS.CDCM.PLL_LOCK			<= CDCM_PLL_LOCK;
STATUS.CDCM.STATUS_VCXO			<= CDCM_STATUS_VCXO;
----------------------------------------------------------------------------
--	
-- USB 3.0 link manager
--
----------------------------------------------------------------------------

USB30_manager : entity work.USB30_links_manager
    Port map( 
-- RESET	
		RESET 					=> RESET,
		CLK_4X 					=> CLK_4X,
		CLK_1X 					=> CLK_1X, -- clock for usb 3.0 controler (80Mhz/4= 20MHz)
--		ENABLE_CLK_1X 			=> ENABLE_CLK_1X, -- Enable Clock at 20MHz/64  or 19.53MHz/64
		regCONFIG 				=> regCONFIG,
		CONTROL 				=> CONTROL,
		TM_DATA_TO_GSE 			=> TM_DATA_TO_GSE,
		wr_en_TM_fifo 			=> WR_en_TM_fifo,
		HK_DATA_TO_GSE 			=> HK_DATA_TO_GSE,
		wr_en_HK_fifo 			=> WR_en_HK_fifo,
		almost_full_HK_fifo 	=> almost_full_HK_fifo,
		DAQ_CLK_USB_OUT 		=> DAQ_CLK_usb_OUT,
		DAQ_usb_Data 			=> DAQ_usb_Data,
		DAQ_usb_Rdy_n 			=> DAQ_usb_Rdy_n,
		DAQ_usb_WR 				=> DAQ_usb_WR,
		HK_usb_Data 			=> HK_usb_Data,
		HK_usb_Rdy_n			=> HK_usb_Rdy_n,
		HK_usb_WR				=> HK_usb_WR,
		Bad_conf_register_write	=> open,--Bad_conf_register_write,
		CONF_usb_Data 			=> CONF_usb_Data,
		CONF_usb_Rdy_n 			=> CONF_usb_Rdy_n,
		CONF_usb_WR 			=> CONF_usb_WR 
			);

----------------------------------------------------------------------------
--	
-- DATA selector to DAQ 32 bits bus (SCIENCES,RHF1201,ADC128,COUNTER...)
--
----------------------------------------------------------------------------


TM_OUTPUT_SELECT: entity work.Select_output_to_TM
 
    Port MAP( 
-- RESET
	RESET					=>	RESET,
-- CLOCKS	
	CLK_4X					=>	CLK_4X,
	ENABLE_CLK_1X			=>	ENABLE_CLK_1X,
	ENABLE_CLK_1X_DIV128	=>	ENABLE_CLK_1X_DIV128,
	
-- OUTPUT SELECTOR : AT CLK_1X 20MHz, up to 3 32 bits Words
	select_TM 				=> CONTROL.GSE.select_TM,
	START_SENDING_TM		=> CONTROL.GSE.START_SENDING_TM,
-- FROM XIFU
	OUT_SCIENCE_UNFILTRED_TP_I		=>	out_science_unfiltred_tp_i_1ch,
	OUT_SCIENCE_UNFILTRED_TP_Q		=>	out_science_unfiltred_tp_q_1ch,
	OUT_SCIENCE_FILTRED_I			=>	out_science_filtred_i_1ch,
	OUT_SCIENCE_FILTRED_Q			=>	out_science_filtred_q_1ch,
	IN_PHYS							=>	IN_PHYS_1ch,
   	FEEDBACK						=>	feedback_1ch,
   	BIAS							=>	BIAS_1ch,

--	STATUS							=> STATUS,		
			
	
			
-- TO opalkelly manager
	TM_DATA_TO_GSE			=>  TM_DATA_TO_GSE,
	WR_en_TM_fifo			=>  WR_en_TM_fifo
	);
	out_science_unfiltred_tp_i_1ch(0) 		<= out_science_unfiltred_tp_i(0);	
	out_science_unfiltred_tp_q_1ch(0) 		<= out_science_unfiltred_tp_q(0);
	out_science_filtred_i_1ch(0) 			<= out_science_filtred_i(0);
	out_science_filtred_q_1ch(0) 			<= out_science_filtred_q(0);
	IN_PHYS_1ch(0) 							<= IN_PHYS(0);
   	feedback_1ch(0) 						<= feedback(0);
   	BIAS_1ch(0) 							<= BIAS(0);	
	out_science_unfiltred_tp_i_1ch(1) 		<= (others =>'0');--out_science_unfiltred_tp_i(0);	
	out_science_unfiltred_tp_q_1ch(1) 		<= (others =>'0');--out_science_unfiltred_tp_q(0);
	out_science_filtred_i_1ch(1) 			<= (others =>(others =>'0'));--out_science_filtred_i(0);
	out_science_filtred_q_1ch(1) 			<= (others =>(others =>'0'));--out_science_filtred_q(0);
	IN_PHYS_1ch(1) 							<= (others =>'0');--IN_PHYS(0);
   	feedback_1ch(1) 						<= (others =>'0');--feedback(0);
   	BIAS_1ch(1) 							<= (others =>'0');--BIAS(0);	
-- PCIE HK Output selector			
----------------------------------------------------------------------------
--	
-- PCIE HK BUS Output selector (ADC128, CONFIG, COUNTER) automatic(2s) or not
--
----------------------------------------------------------------------------

HK_OUTPUT_SELECT: entity work.Select_output_to_HK
 
    Port MAP( 
		RESET 					=> RESET,

		CLK_4X 					=> CLK_4X,
		ENABLE_CLK_1X 			=> ENABLE_CLK_1X, -- clock for usb 3.0 controler (80Mhz/64= 0.3MHz)
		ONE_SECOND 				=> ONE_SECOND,

		select_HK 				=> CONTROL.GSE.select_HK,
		START_SENDING_HK 		=> CONTROL.GSE.START_SENDING_HK,
-- FROM XIFU
		ADC128_registers 		=> ADC128_ALL_registers,
		ADC128_Done 			=> adc128_ALL_done,
		ADC128_start_HK 		=> ADC128_start_HK,
		ADC128_read_register 	=> ADC128_Read_Register_HK,
		regCONFIG 				=> regCONFIG,
		STATUS 					=> STATUS,

		HK_DATA_TO_GSE 			=> HK_DATA_TO_GSE,
		WR_en_HK_fifo 			=> WR_en_HK_fifo,
		almost_full_HK_fifo 	=> almost_full_HK_fifo
		);

----------------------------------------------------------------------------------------------------
-- CDCM7005 controler by SPI from USB CONTROL_SPI
----------------------------------------------------------------------------------------------------

CDCM: entity work.CDCM7005_CONTROLER 
    Port map	( 
				RESET 					=> RESET,
				CLK_4X					=> CLK_4X,
				ENABLE_CLK_1X_DIV128	=> ENABLE_CLK_1X_DIV128,
-- FROM/TO CDCM7005 CONTROLER
				SPI_command				=> CDCM_SPI_command,
				SPI_address				=> CDCM_SPI_address,
				SPI_write				=> CDCM_SPI_write,
				SPI_ready				=> CDCM_SPI_ready,
				CDCM_SCLK				=> CDCM_SCLK,
				CDCM_SLE				=> CDCM_SLE,
				CDCM_RST_N				=> CDCM_RSTn,
				CDCM_SDIN				=> CDCM_SDIN
				);
STATUS.CMM.CDCM_RESETn 			<= CDCM_RSTn;

----------------------------------------------------------------------------------------------------
-- GLOBAL SPI REDIRECTION selected by SPI_ADDRESS
----------------------------------------------------------------------------------------------------
				
CDCM_SPI_command						<= CONTROL.SPI.SPI_data_to_send (29 downto 0);
CDCM_SPI_address						<= CONTROL.SPI.SPI_data_to_send (31 downto 30);

DACB_SPI_write(0)						<= CONTROL.SPI.SPI_write when CONTROL.SPI.Select_SPI_Channel ="00000" else '0';
DACF_SPI_write(0)						<= CONTROL.SPI.SPI_write when CONTROL.SPI.Select_SPI_Channel ="00001" else '0';
DACB_SPI_write(1)						<= CONTROL.SPI.SPI_write when CONTROL.SPI.Select_SPI_Channel ="00010" else '0';
DACF_SPI_write(1)						<= CONTROL.SPI.SPI_write when CONTROL.SPI.Select_SPI_Channel ="00011" else '0';
CDCM_SPI_write							<= CONTROL.SPI.SPI_write when CONTROL.SPI.Select_SPI_Channel ="00100" else '0';

----------------------------------------------------------------------------------------------------
-- GLOBAL SPI STATUS selected by SPI_ADDRESS
----------------------------------------------------------------------------------------------------
STATUS.SPI_CONTROLER.SPI_data_Received	<= 	DACB_SPI_DATA_RECEIVED(0) 	when CONTROL.SPI.Select_SPI_Channel ="00000" else
											DACF_SPI_DATA_RECEIVED(0) 	when CONTROL.SPI.Select_SPI_Channel ="00001" else
											DACB_SPI_DATA_RECEIVED(1)	when CONTROL.SPI.Select_SPI_Channel ="00010" else
											DACF_SPI_DATA_RECEIVED(1) 	when CONTROL.SPI.Select_SPI_Channel ="00011" else	
												(others =>'0');
												
STATUS.SPI_CONTROLER.SPI_ready			<= 	DACB_SPI_ready(0)		when CONTROL.SPI.Select_SPI_Channel ="00000" else
											DACF_SPI_ready(0)		when CONTROL.SPI.Select_SPI_Channel ="00001" else
											DACB_SPI_ready(1)		when CONTROL.SPI.Select_SPI_Channel ="00010" else
											DACF_SPI_ready(1)		when CONTROL.SPI.Select_SPI_Channel ="00011" else
											CDCM_SPI_ready			when CONTROL.SPI.Select_SPI_Channel ="00100" else '0';	

adc128_ALL_done <= DAC_adc128_done(0) and ADC_adc128_done(0);--and DAC_ADC128_DONE(1) and ADC_ADC128_DONE(1)

-- wait for a DAC_reset from GSE on CONTROL.DACs_RESET to remove DACs reset

P_DAC_RESET_LOCKED: process(RESET, CLK_4X)
	begin
		if (RESET = '1') then
		 DAC_RESET_STARTUP <= '1';
		 DACB_RESET_IN(0) <= '1';
		 DACB_RESET_IN(1) <= '1';
		 DACF_RESET_IN(0) <= '1';
		 DACF_RESET_IN(1) <= '1';
		elsif (rising_edge(CLK_4X)) then
			if (ENABLE_CLK_1X='1') then
			if ( CONTROL.DACs_RESET ='0') then
					if (DAC_RESET_STARTUP ='1') then
					DACB_RESET_IN(0) <= '1';
					DACB_RESET_IN(1) <= '1';
					DACF_RESET_IN(0) <= '1';
					DACF_RESET_IN(1) <= '1';
					else
					DACB_RESET_IN(0) <= CONTROL.DACs_RESET;
					DACB_RESET_IN(1) <= CONTROL.DACs_RESET;
					DACF_RESET_IN(0) <= CONTROL.DACs_RESET;
					DACF_RESET_IN(1) <= CONTROL.DACs_RESET;
					end if;
				else
					DAC_RESET_STARTUP <= '0';
					DACB_RESET_IN(0) <= CONTROL.DACs_RESET;
					DACB_RESET_IN(1) <= CONTROL.DACs_RESET;
					DACF_RESET_IN(0) <= CONTROL.DACs_RESET;
					DACF_RESET_IN(1) <= CONTROL.DACs_RESET;
				end if;
			end if;
		end if;
	end process; 


----------------------------------------------------------------------------
--	
-- CHANNELs and Manager Creation for C_Nb_channel
--
----------------------------------------------------------------------------

GENERATE_CHANNELS : for C in C_Nb_channel-1 downto 0 generate

----------------------------------------------------------------------------
--	
-- RHF1201 manager
--
----------------------------------------------------------------------------

--	ADCRHF1201 CONTROLER
ADC_RHF1201_C: entity work.RHF1201_controler 
    Port MAP 
			(
			RESET				=> RESET,
 			CLK_4X				=> CLK_4X,
 			CLK_1X				=> CLK_1X,
			ENABLE_CLK_1X		=> ENABLE_CLK_1X,
			CONTROL				=> CONTROL.RHF1201s(C),
			STATUS				=> STATUS.RHF1201s(C),
--signals
			OUT_OF_RANGE_ADC	=> ADC_OOR(C),
			OUT_OF_RANGE 		=> open,--ADC_OOR_int(C), 
			DIN					=> ADC_DIN(C),
			DOUT				=> ADC_DOUT(C),
--			DATA_READY			=> ADC_DR(C),
			CLOCK_TO_ADC		=> ADC_CLK(C),
--			CLOCK_FROM_ADC		=> '0',
			ADC_READY			=>	open,--ADC_ready(C),
			OE_N 				=> ADC_OE_N(C),
			SLEW_RATE_CONTROL 	=> ADC_SRC(C),
			DATA_FORMAT_SEL_N 	=> ADC_DFS_N(C)
			);

----------------------------------------------------------------------------
--	
-- ADC128S102s REGISTERs TRANSFERT FOR HK
--
----------------------------------------------------------------------------
		
ADC128_ALL_registers (0+23*C) 	<= ADC_ADC128_registers (C)(0);-- ADC128 CH1 ADC IN0
ADC128_ALL_registers (1+23*C) 	<= ADC_ADC128_registers (C)(1);-- ADC128 CH1 ADC IN1
ADC128_ALL_registers (2+23*C) 	<= ADC_ADC128_registers (C)(2);-- ADC128 CH1 ADC IN2
ADC128_ALL_registers (3+23*C) 	<= ADC_ADC128_registers (C)(3);-- ADC128 CH1 ADC IN3
ADC128_ALL_registers (4+23*C) 	<= ADC_ADC128_registers (C)(4);-- ADC128 CH1 ADC IN4
ADC128_ALL_registers (5+23*C) 	<= ADC_ADC128_registers (C)(5);-- ADC128 CH1 ADC IN5
ADC128_ALL_registers (6+23*C) 	<= ADC_ADC128_registers (C)(6);-- ADC128 CH1 ADC IN6
ADC128_ALL_registers (7+23*C) 	<= ADC_ADC128_registers (C)(7);-- ADC128 CH1 ADC IN7
ADC128_ALL_registers (8+23*C) 	<= DAC_ADC128_registers (C)(0);-- ADC128 CH1 DAC IN0_0 MUX
ADC128_ALL_registers (9+23*C) 	<= DAC_ADC128_registers (C)(1);-- ADC128 CH1 DAC IN0_1 MUX
ADC128_ALL_registers (10+23*C) 	<= DAC_ADC128_registers (C)(2);-- ADC128 CH1 DAC IN0_2 MUX
ADC128_ALL_registers (11+23*C) 	<= DAC_ADC128_registers (C)(3);-- ADC128 CH1 DAC IN0_3 MUX
ADC128_ALL_registers (12+23*C) 	<= DAC_ADC128_registers (C)(4);-- ADC128 CH1 DAC IN0_4 MUX
ADC128_ALL_registers (13+23*C) 	<= DAC_ADC128_registers (C)(5);-- ADC128 CH1 DAC IN0_5 MUX
ADC128_ALL_registers (14+23*C) 	<= DAC_ADC128_registers (C)(6);-- ADC128 CH1 DAC IN0_6 MUX
ADC128_ALL_registers (15+23*C) 	<= DAC_ADC128_registers (C)(7);-- ADC128 CH1 DAC IN0_7 MUX
ADC128_ALL_registers (16+23*C) 	<= DAC_ADC128_registers (C)(8);-- ADC128 CH1 DAC IN1
ADC128_ALL_registers (17+23*C) 	<= DAC_ADC128_registers (C)(9);-- ADC128 CH1 DAC IN2
ADC128_ALL_registers (18+23*C) 	<= DAC_ADC128_registers (C)(10);-- ADC128 CH1 DAC IN3
ADC128_ALL_registers (19+23*C) 	<= DAC_ADC128_registers (C)(11);-- ADC128 CH1 DAC IN4
ADC128_ALL_registers (20+23*C) 	<= DAC_ADC128_registers (C)(12);-- ADC128 CH1 DAC IN5
ADC128_ALL_registers (21+23*C) 	<= DAC_ADC128_registers (C)(13);-- ADC128 CH1 DAC IN6
ADC128_ALL_registers (22+23*C) 	<= DAC_ADC128_registers (C)(14);-- ADC128 CH1 DAC IN7

----------------------------------------------------------------------------
--	
-- ADC128S102 CONTROLER ADC BOARD
--
----------------------------------------------------------------------------	
 
ADC128_ADC_C : entity work.ADC128S102_controler
	PORT MAP 
			(
			Reset			 	=> RESET,
			clk_4X	 		 	=> CLK_4X,
			ENABLE_CLK_1X	 	=> ENABLE_CLK_1X,
			Start 				=> ADC_ADC128_start(C),
			read_register		=> ADC_ADC128_Read_Register(C),
			Done 				=> ADC_adc128_done(C),
			Output_registers 	=> ADC_ADC128_registers(C),
			Sclk		 		=> ADC_ADC128_SCLK(C),
			Dout		 		=> ADC_ADC128_DOUT(C),
			Din		 			=> ADC_ADC128_DIN(C),
			Cs_n 				=> ADC_ADC128_CS_N(C)
			);

ADC_ADC128_start(C) 			<= ADC128_start_HK;
ADC_ADC128_Read_Register(C)		<= ADC128_Read_Register_HK;

----------------------------------------------------------------------------
--	
-- ADC128S102 MUXED CONTROLER DAC BOARD
--
----------------------------------------------------------------------------
ADC128_DAC_C : entity work.ADC128S102_MUXED_controler
	PORT MAP 
			(
			Reset			 	=> RESET,
			clk_4X	 		 	=> CLK_4X,
			ENABLE_CLK_1X	 	=> ENABLE_CLK_1X,
			twelve_mili_SECOND	=> twelve_mili_SECOND,

			Output_registers 	=> DAC_ADC128_registers(C),
			Start 				=> DAC_adc128_start(C),
			read_register		=> DAC_ADC128_Read_Register(C),
			Done 				=> DAC_adc128_done(C),
			Sclk		 		=> DAC_ADC128_SCLK(C),
			Dout		 		=> DAC_ADC128_DOUT(C),
			Din		 			=> DAC_ADC128_DIN(C),
			Cs_n 				=> DAC_ADC128_CSn(C),
			DAC_MUX_S			=> DAC_ADC128_MUX_S(C)
			);

DAC_adc128_start(C) 			<= ADC128_start_HK;
DAC_ADC128_Read_Register(C)		<= ADC128_Read_Register_HK;
----------------------------------------------------------------------------
--	
-- DACs AD9726 CONTROLER SPI DATA
--
----------------------------------------------------------------------------

DACB_SPI_data(C)				<= CONTROL.SPI.SPI_data_to_send (7 downto 0);
DACB_SPI_address(C)				<= CONTROL.SPI.SPI_data_to_send (12 downto 8);
DACB_SPI_command(C)				<= CONTROL.SPI.SPI_data_to_send (15 downto 13);
DACF_SPI_data(C)				<= CONTROL.SPI.SPI_data_to_send (7 downto 0);
DACF_SPI_address(C)				<= CONTROL.SPI.SPI_data_to_send (12 downto 8);
DACF_SPI_command(C)				<= CONTROL.SPI.SPI_data_to_send (15 downto 13);
					
----------------------------------------------------------------------------
--	
-- DAC Bias AD9726 (DAC BOARD) CONTROLERs
--
----------------------------------------------------------------------------
DACB_CONTROLER_C : entity work.AD9726_CONTROLER PORT MAP (
        RESET					=> RESET,
        CLK_4X 				=> CLK_4X,
--        CLK_1X 				=> CLK_1X,
        ENABLE_CLK_1X_DIV128 	=> ENABLE_CLK_1X_DIV128,
		DAC_ON					=> CONTROL.AD9726s(C).DACB.DAC_ON,
        SPI_command 			=> DACB_SPI_command(C),
        SPI_address 			=> DACB_SPI_address(C),
        SPI_data 				=> DACB_SPI_data(C),
        SPI_write 				=> DACB_SPI_write(C),
        SPI_DATA_RECEIVED 		=> DACB_SPI_DATA_RECEIVED(C),
        SPI_ready 				=> DACB_SPI_ready(C),
--		DCLK_FROM_DAC			=> DACB_DCLK_FROM(C),
		DATA_TO_DAC				=> DACB_DATA(C),
		DCLK_TO_DAC				=> DACB_DCLK_TO(C),
		DB_OUT					=> DACB_DATA_OUT(C),
        SPI_SDO 				=> DACB_SPI_SDO(C),
        SPI_SDIO 				=> DACB_SPI_SDIO(C),
        SPI_SCLK 				=> DACB_SPI_SCLK(C),
        SPI_CS_N 				=> DACB_SPI_CS_N(C),
        DAC_RESET_IN			=> DACB_RESET_IN(C),
        DAC_RESET 				=> DACB_RESET(C)
        );
-- DACs Bias STATUS READ
STATUS.AD9726s(C).DACB.DAC_ON 		<= CONTROL.AD9726s(C).DACB.DAC_ON;
STATUS.AD9726s(C).DACB.DAC_RESET	<= DACB_RESET(C);
----------------------------------------------------------------------------
--	
-- DAC Feedback AD9726 (DAC BOARD) CONTROLERs
--
----------------------------------------------------------------------------

DACF_CONTROLER_C : entity work.AD9726_CONTROLER PORT MAP (
         RESET					=> RESET,
         CLK_4X 				=> CLK_4X,
--         CLK_1X 				=> CLK_1X,
         ENABLE_CLK_1X_DIV128 	=> ENABLE_CLK_1X_DIV128,
		 DAC_ON					=> CONTROL.AD9726s(C).DACF.DAC_ON,
         SPI_command 			=> DACF_SPI_command(C),
         SPI_address 			=> DACF_SPI_address(C),
         SPI_data 				=> DACF_SPI_data(C),
         SPI_write 				=> DACF_SPI_write(C),
         SPI_DATA_RECEIVED 		=> DACF_SPI_DATA_RECEIVED(C),
         SPI_ready 				=> DACF_SPI_ready(C),
--		 DCLK_FROM_DAC			=> DACF_DCLK_FROM(C),
		 DATA_TO_DAC			=> DACF_DATA(C),
		 DCLK_TO_DAC			=> DACF_DCLK_TO(C),
		 DB_OUT					=> DACF_DATA_OUT(C),
         SPI_SDO 				=> DACF_SPI_SDO(C),
         SPI_SDIO 				=> DACF_SPI_SDIO(C),
         SPI_SCLK 				=> DACF_SPI_SCLK(C),
         SPI_CS_N 				=> DACF_SPI_CS_N(C),
         DAC_RESET_IN			=> DACF_RESET_IN(C),
         DAC_RESET 				=> DACF_RESET(C)
        );
-- DACs Feedback STATUS READ
STATUS.AD9726s(C).DACF.DAC_ON 						<= CONTROL.AD9726s(C).DACF.DAC_ON;
STATUS.AD9726s(C).DACF.DAC_RESET					<= DACF_RESET(C);

----------------------------------------------------------------------------------------------------
-- X-IFU PHYSIC CHANNEL SIZABLE FOR C CHANNELS WITH N PIXELS
----------------------------------------------------------------------------------------------------

	Channel_C: entity work.channel
    Port map
		(
		RESET 						=> RESET, -- reset a 1!!!!
		CLK_4X 						=> CLK_4X,
		ENABLE_CLK_1X 				=> ENABLE_CLK_1X,
		ENABLE_CLK_1X_DIV128 		=> ENABLE_CLK_1X_DIV128,
		CONTROL			 			=> CONTROL.CHANNELs(C),
		CONSTANT_FB 				=> C_Constant_FB,
		IN_PHYS 					=> IN_PHYS(C),
		BIAS 						=> BIAS(C),
		FEEDBACK 					=> feedback(C),
		OUT_SCIENCE_UNFILTRED_TP_I 	=> out_science_unfiltred_tp_i(C),
		OUT_SCIENCE_UNFILTRED_TP_Q 	=> out_science_unfiltred_tp_q(C),
		OUT_SCIENCE_FILTRED_I 		=> out_science_filtred_i(C),
		OUT_SCIENCE_FILTRED_Q 		=> out_science_filtred_q(C)
		);
----------------------------------------------------------------------------------------------------
-- SELECT INPUT OF X-IFU CHANNELS (C channels)
----------------------------------------------------------------------------------------------------
		
select_input_channels : entity work.Select_input 
    Port map 
		(
		ADC 					=>  ADC_DOUT(C),--(others=>'0'), ADC_DOUT_DC_FILTRED(C),
		INT_SQUID 				=> out_squid(C),
		IN_PHYS 				=> IN_PHYS(C),
		select_input			=> CONTROL.CHANNELs(C).select_Input
		);
			
----------------------------------------------------------------------------------------------------
-- INTERNAL SQUID TO TEST X-IFU CHANNELS (C SQUIDs 1 per channels)
----------------------------------------------------------------------------------------------------

Internal_Squid_C : entity work.Squid_generic
	 Generic map
		(
		C_Size_in 				=>  C_Size_bias_to_DAC, 			
		C_Size_out 				=> C_Size_In_Real		
		)
    Port map
		( 
		RESET 					=> RESET,-- reset a 1!!!!
		CLK_4X 					=> CLK_4X,
		In_Squid 				=> BIAS(C),
		In_Feedback 			=> feedback(C),
		Out_Squid				=> out_squid(C)
		);

low_pass_filter_BIAS: entity work.Double_Two_path_filter
	port map(
		CLK_4X    => CLK_4X,
		ENABLE_4X => '1',
		ENABLE_2X => ENABLE_CLK_2X,
		Reset     => RESET,
		input     => BIAS(C),
		output    =>  BIAS_to_DAC(C)
	);		
low_pass_filter_FEEDBACK: entity work.Double_Two_path_filter
	port map(
		CLK_4X    => CLK_4X,
		ENABLE_4X => '1',
		ENABLE_2X => ENABLE_CLK_2X,
		Reset     => RESET,
		input     => feedback(C),
		output    =>  feedback_to_DAC(C)
	);		
	
--low_pass_filter_BIAS: entity work.DAC_filter
--	port map(
--		CLK_4X        => CLK_4X,
--		Reset         => RESET,
--		sig_in        => BIAS(C),
--		sig_out       => BIAS_to_DAC(C)
--	);

--low_pass_filter_FEEDBACK: entity work.DAC_filter
--	port map(
--		CLK_4X        => CLK_4X,
--		Reset         => RESET,
--		sig_in        => feedback(C),
--		sig_out       => feedback_to_DAC(C)
--	);	 	 

-- data transfert from Channels to DACs DATA bus (with Feedback reverse possiblity)
DACB_DATA(C) <= std_logic_vector(BIAS_to_DAC(C));
DACF_DATA(C) <= std_logic_vector(feedback_to_DAC(C)) when CONTROL.CHANNELs(C).feedback_reverse ='0' else std_logic_vector(-feedback_to_DAC(C));

end generate GENERATE_CHANNELS;

	-- =============================================================
	-- CHIP SCOPE
	-- =============================================================
	-- icon_inst : entity work.iCON
	-- Port map 
		-- (
		-- CONTROL0 					=> ila_xifu_control
		-- );


----------------------------------------------------------------------------------------------------
-- ILA XIFU display in chipscope of the XIFU internal signals 
-- ----------------------------------------------------------------------------------------------------
	-- ila_xifu_inst : entity work.ILA
	-- port map 
		-- (
		-- clk     => ila_xifu_clk,
		-- trig0   => ila_xifu_trig0,
		-- control => ila_xifu_control
		-- );

-- ----------------------------------------------------------------------------------------------------
-- -- ILA xifu Mapping
-- ----------------------------------------------------------------------------------------------------
-- ila_xifu_clk <= CLK_4X;
-- ila_xifu_trig0(11 downto 0) 	<=  std_logic_vector(Out_Squid(0));
-- ila_xifu_trig0(27 downto 12) 	<= std_logic_vector(BIAS(0));
-- ila_xifu_trig0(43 downto 28) 	<= std_logic_vector(DACF_DATA(0));
-- ila_xifu_trig0(59 downto 44) 	<= std_logic_vector(Out_Science_Q(0)(40));
-- ila_xifu_trig0(75 downto 60) 	<= std_logic_vector(Out_Science_I(0)(40));
-- ila_xifu_trig0(87 downto 76) 	<=(std_logic_vector(ADC_DOUT(0)));
-- ila_xifu_trig0(103 downto 88) 	<= std_logic_vector(DACB_DATA(0));
-- ila_xifu_trig0(119 downto 104) 	<= std_logic_vector(FEEDBACK(0));
-- ila_xifu_trig0(127 downto 120) 	<= C_GND(127 downto 120);

----------------------------------------------------------------------------------------------------
-- LEDs for Chrnille and control
----------------------------------------------------------------------------------------------------

GPIO_LED(0) <= chenille(0);
GPIO_LED(1) <= chenille(1);
GPIO_LED(2) <= chenille(2);
GPIO_LED(3) <= chenille(3);
GPIO_LED(4) <= chenille(4);
GPIO_LED(5) <= chenille(5);
GPIO_LED(6) <= RESET;
GPIO_LED(7) <= CLK_LOCKED_CDCM;


end Behavioral;

