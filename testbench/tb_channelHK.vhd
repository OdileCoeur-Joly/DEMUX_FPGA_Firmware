----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU ML605
-- Module Name   : tb_channel - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Vitex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : testbench for athena Channel, acquistion, and ADC modules
--
-- Dependencies: XIFU Channel, ADC modules, CMM, clock core
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.athena_package.all;
use work.util_package.all;
--use WORK.PCIEX_PACKAGE.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
                USE IEEE.VITAL_timing.ALL;
                USE IEEE.VITAL_primitives.ALL;
LIBRARY FMF;
    USE work.gen_utils.ALL; 

ENTITY tb_channel IS
END tb_channel;
 
ARCHITECTURE behavior OF tb_channel IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
 

   --Inputs
   signal CLK_4X : std_logic := '0';
   signal CLK_1X : std_logic := '0';
   signal ENABLE_CLK_1X : std_logic := '0';
   signal ENABLE_CLK_1X_DIV128 : std_logic := '0';
   signal CLK_TO_DAC_LTC2000		: std_logic;
   signal ONE_SECOND				: std_logic;
   signal RESET : std_logic := '1';
--   signal CONTROL_PIXELS : t_CONTROL_PIXELS;
	signal	SYSCLK_P 			:  std_logic;
	signal	SYSCLK_N 			:  std_logic;
	signal LOCKED						: std_logic;
	signal acq_on						: std_logic:= '0';
--	signal DAQ_ENABLE					: std_logic:= '1';
--	signal DAQ_CLK						: std_logic;
--	signal DAQ_RDYn					: std_logic:= '0';
--	signal DAQ_WR						: std_logic;
--	signal DAQ_DATA					: std_logic_vector(31 downto 0);
	signal RESET_HW					: std_logic:= '1';
	-- TO USB 3.0 manager
	signal rd_en_daq_usb_fifo			: std_logic:= '1';
	signal rd_en_HK_usb_fifo			: std_logic:= '1';
	signal wr_en_hk_fifo			: std_logic;
	signal wr_en_tm_fifo			: std_logic;
	signal tm_data_to_gse			: std_logic_vector(31 downto 0);
	signal hk_data_to_gse			: std_logic_vector(31 downto 0);
	signal empty_daq_usb_fifo			: std_logic:= '1';
	signal almost_full_hk_fifo			: std_logic:= '0';
	signal valid_daq_usb_fifo			: std_logic;
	signal bad_conf_register_write			: std_logic;
	signal empty_HK_usb_fifo			: std_logic;
	signal valid_HK_usb_fifo			: std_logic;
	signal DAQ_CLK_to_usb_fifo		: std_logic;
	signal HK_CLK_to_usb_fifo		: std_logic;
-- TO USB_3.0 manager
   signal   DAQ_CLK_usb_OUT					: std_logic;
-- DAQ 32 bits for science link
   signal   DAQ_usb_Data						: std_logic_vector(31 downto 0);
   signal   DAQ_usb_Rdy_n						: std_logic:= '0';
   signal   DAQ_usb_WR							: std_logic;
   signal   START_SENDING_usb_DAQ			: std_logic:= '1';
-- DATA SENDING 1MHz 8 bits for HK link
   signal   HK_usb_Data							: std_logic_vector(7 downto 0);
   signal   HK_usb_Rdy_n						: std_logic:= '0';
   signal   HK_usb_WR							: std_logic;
   signal   START_SENDING_usb_HK				: std_logic:= '1';
-- DATA RECEIVED 1MHz 8 bits for Config link
   signal   START_SENDING_CONF				: std_logic:= '0';
   signal   CONF_usb_Data						: std_logic_vector(7 downto 0);
   signal   CONF_usb_Rdy_n						: std_logic:= '0';
   signal   CONF_usb_WR							: std_logic;
   signal   channel_scoped							: integer := 0;

 	--Outputs
   signal BIAS : t_bias;
   signal FEEDBACK : t_feedback_to_DAC;
   signal OUT_SCIENCE_I : t_science_channel;
   signal OUT_SCIENCE_Q : t_science_channel;
	signal out_squid		  			: t_in_phys;
	signal Sequencer					: unsigned(1 downto 0);

-- chenillard antoine visu test
--signal cmpt_antoine	 			: unsigned (21 downto 0):=(others=>'0');
signal chenille			: std_logic_vector (7 downto 0):="10000000";
	
   --Inputs
   signal Reset_n : std_logic := '0';
   signal clk_20MHz : std_logic := '0';
   signal Start : std_logic := '0';
   signal ADC_Dout : std_logic := '1';

 	--Outputs
--   signal Output_register : register_ADC;
--   signal Done : std_logic;
   signal SCLK_ADC128 : std_logic;
   signal DIN_ADC128 : std_logic;
   signal DOUT_ADC128 : std_logic;
   signal CS_ADC128_N : std_logic;
	
-- ADC128 signals
	signal ADC128_registers				: t_register_ADC128;
	signal adc128_start					: std_logic;
	signal adc128_read_register		: std_logic;
	signal adc128_read_register_DAQ	: std_logic;
	signal adc128_read_register_HK	: std_logic;
	signal adc128_start_HK_USB30		: std_logic;
	signal adc128_start_DAQ_USB		: std_logic;
	signal adc128_done					: std_logic;
	signal ADC128_ALL_registers			: t_register_ALL_ADC128;
	signal adc128_ALL_done				: std_logic;
	signal adc128_start_HK			: std_logic;
		signal status_xifu				: std_logic_vector(31 downto 0);
	signal status_PCIex				: std_logic_vector(127 downto 0);
	signal STATUS_SPI				: t_STATUS_SPI;

-- ADCRHF1201 control signals
	signal OUT_OF_RANGE_RHF1201_int			: std_logic;
	signal OOR_RHF1201							: std_logic;
	signal hpc1_reset_gse							: std_logic;
	signal DR_RHF1201								: std_logic;
	signal SRC_RHF1201							: std_logic;
	signal OE_RHF1201_n							: std_logic;
	signal CLK_RHF1201							: std_logic;
	signal DFS_RHF1201_n							: std_logic;
--	signal FRONT									: std_logic;
--	signal FRONT_STATUS							: std_logic;
	signal rhf1201_ready							: std_logic;
	signal DOUT_RHF1201							: signed(11 downto 0);
	signal CONTROL								: t_CONTROL;
	signal STATUS								: t_STATUS;
	signal DATA_RHF1201							: signed (11 downto 0);
	signal regCONFIG       						: ARRAY32bits(0 to C_NB_REG_CONF-1):=(others =>(others=>'0'));
	signal REGISTER_NUMBER						: std_logic_vector (32 downto 1):=(others=>'0');
   signal REGISTER_VALUE						: std_logic_vector (32 downto 1):=(others=>'0');
   signal eog										: std_logic;
   signal twelve_mili_SECOND					: std_logic;
--	to 4);
	-- FROM/TO AD9726 BIAS controler
	signal 		DACB_SPI_command 		: t_std_logic_vector_array;
	signal 		DACB_SPI_address 		: t_std_logic_7_array;
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
	signal 		DACF_SPI_command 		: t_std_logic_vector_array;
	signal 		DACF_SPI_address 		: t_std_logic_7_array;
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

	
--    Clock period definitions
   constant CLK_4X_period : time := 10 ns;
--   constant CLK_1X_period : time := 10 ns;
   constant SYS_CLK_period : time := 5 ns;
   signal OUT_SCIENCE_UNFILTRED_TP_I : t_TP_science_channel;
   signal OUT_SCIENCE_UNFILTRED_TP_Q : t_TP_science_channel;
   signal OUT_SCIENCE_FILTRED_I : t_science_channel;
   signal OUT_SCIENCE_FILTRED_Q : t_science_channel;
	signal		DAC_ADC128_SCLK	  		: t_std_logic_array;
	signal		DAC_ADC128_CSn		  	: t_std_logic_array;
	signal		DAC_ADC128_DOUT	  		: t_std_logic_array;
	signal		DAC_ADC128_DIN		  	: t_std_logic_array;
	signal		DAC_ADC128_MUX_S	  	: t_std_logic_3_array;
	signal 		DAC_ADC128_registers	: t_register_MUXED_ADC128_ARRAY;
	signal 		DAC_adc128_start		: t_std_logic_array;
	signal 		DAC_ADC128_Read_Register: t_std_logic_array;
	signal 		DAC_adc128_done			: t_std_logic_array;
	signal IN0_MUXED : real;
	signal DATA_OUT_TO_PINS : std_logic_vector(15 downto 0);
	signal CLK_TO_PINS : std_logic;
	signal DATA_LTC 	: unsigned(15 downto 0);
	signal DATA_LTC_mem : unsigned(15 downto 0);
	signal DATA_LTC_32b : std_logic_vector(31 downto 0);
	signal CLK_2X : std_logic;
	
--	component FILE_READ 
--  generic (
--           stim_file:       string  := "file.dat"
--          );
--  port(
--       CLK              : in  std_logic;
--       RST              : in  std_logic;
--		 X                : out std_logic_vector(32 downto 1);
--       Y                : out std_logic_vector(32 downto 1);
--       EOG              : out std_logic
--      );
--end component;

--COMPONENT adc128s102 
--
--    GENERIC (
--        -- Interconnect path delays
--        tipd_SCLK           : VitalDelayType01  := VitalZeroDelay01;
--        tipd_CSNeg          : VitalDelayType01  := VitalZeroDelay01;
--        tipd_DIN            : VitalDelayType01  := VitalZeroDelay01;
--        -- Propagation delays
--        tpd_SCLK_DOUT       : VitalDelayType01Z := UnitDelay01Z;
--        tpd_CSNeg_DOUT      : VitalDelayType01Z := UnitDelay01Z;
--        -- Setup/hold violation
--        tsetup_CSNeg_SCLK   : VitalDelayType    := UnitDelay;
--        tsetup_DIN_SCLK     : VitalDelayType    := UnitDelay;
--        thold_CSNeg_SCLK    : VitalDelayType    := UnitDelay;
--        thold_DIN_SCLK      : VitalDelayType    := UnitDelay;
--        -- Puls width checks
--        tpw_SCLK_posedge    : VitalDelayType    := UnitDelay;
--        tpw_SCLK_negedge    : VitalDelayType    := UnitDelay;
--        -- Period checks
--        tperiod_SCLK_posedge: VitalDelayType    := UnitDelay;
--        -- generic control parameters
--        InstancePath        : STRING            := DefaultInstancePath;
--        TimingChecksOn      : BOOLEAN           := DefaultTimingChecks;
--        MsgOn               : BOOLEAN           := DefaultMsgOn;
--        XOn                 : BOOLEAN           := DefaultXon;
--        -- For FMF SDF technology file usage
--        TimingModel         : STRING            := DefaultTimingModel
--        );
--
--    PORT (
--        SCLK  : IN  std_ulogic := 'U';
--        CSNeg : IN  std_ulogic := 'U';
--        DIN   : IN  std_ulogic := 'U';
--        VA    : IN  real       := 2.7;
--        IN0   : IN  real       := 0.0;
--        IN1   : IN  real       := 0.0;
--        IN2   : IN  real       := 0.0;
--        IN3   : IN  real       := 0.0;
--        IN4   : IN  real       := 0.0;
--        IN5   : IN  real       := 0.0;
--        IN6   : IN  real       := 0.0;
--        IN7   : IN  real       := 0.0;
--        DOUT  : OUT std_ulogic := 'U'
--        );
--end component;

    
 
BEGIN
	
--CLK_1X <= ENABLE_CLK_1X;

--	DAQ_CLK <= CLK_4X; 


 --	ADCRHF1201 CONTROLER

--ADC_RHF1201: RHF1201_controler 
--    Port MAP 
--			(
-- 			CLK_4X				=> CLK_4X,
--			ENABLE_CLK_1X		=> ENABLE_CLK_1X,
--         RESET					=> RESET,
--			CONTROL_RHF1201	=> CONTROL_RHF1201,
--			STATUS_RHF1201		=> STATUS_RHF1201,
--
--         OUT_OF_RANGE_ADC	=> OOR_RHF1201,
--         OUT_OF_RANGE 		=> OUT_OF_RANGE_RHF1201_int, 
--				DIN					=> DATA_RHF1201,
--         DOUT					=> DOUT_RHF1201,
--         DATA_READY			=> DR_RHF1201,
--         CLOCK_TO_ADC		=> CLK_RHF1201,
--         CLOCK_FROM_ADC		=> '0',
--			ADC_READY			=>	RHF1201_READY,
--         OE_N 					=> OE_RHF1201_N,
--         SLEW_RATE_CONTROL => SRC_RHF1201,
--         DATA_FORMAT_SEL_N => DFS_RHF1201_N
--			);

 --	ADC128S102 CONTROLER
 	adc1:	entity work.adc128s102
    PORT MAP(
        SCLK  	=> SCLK_ADC128,
        CSNeg 	=> CS_ADC128_N,
        DIN   	=> DIN_ADC128,
        VA    	=> 3.3,
        IN0   	=> 0.1,
        IN1   	=> 0.18,
        IN2   	=> 0.12,
        IN3   	=> 0.13,
        IN4   	=> 0.14,
        IN5  	=> 0.15,
        IN6   	=> 0.16,
        IN7   	=> 0.17,
        DOUT  	=> DOUT_ADC128
        );
 IN0_MUXED <= 	0.1 when  DAC_ADC128_MUX_S(0) ="000" else
 				0.2 when  DAC_ADC128_MUX_S(0) ="001" else
 				0.3 when  DAC_ADC128_MUX_S(0) ="010" else
 				0.4 when  DAC_ADC128_MUX_S(0) ="011" else
 				0.5 when  DAC_ADC128_MUX_S(0) ="100" else
 				0.6 when  DAC_ADC128_MUX_S(0) ="101" else
 				0.7 when  DAC_ADC128_MUX_S(0) ="110" else
 				0.8 when  DAC_ADC128_MUX_S(0) ="111";    
 --	ADC128S102 CONTROLER
 	adc2:	entity work.adc128s102
    PORT MAP(
        SCLK  	=> DAC_ADC128_SCLK(0),
        CSNeg 	=> DAC_ADC128_CSn(0),
        DIN   	=> DAC_ADC128_DIN(0),
        VA    	=> 3.3,
        IN0   	=> IN0_MUXED,
        IN1   	=> 0.18,
        IN2   	=> 0.12,
        IN3   	=> 0.13,
        IN4   	=> 0.14,
        IN5  	=> 0.15,
        IN6   	=> 0.16,
        IN7   	=> 0.17,
        DOUT  	=> DAC_ADC128_DOUT(0)
        ); 		
 	adc3:	entity work.adc128s102
    PORT MAP(
        SCLK  	=> DAC_ADC128_SCLK(1),
        CSNeg 	=> DAC_ADC128_CSn(1),
        DIN   	=> DAC_ADC128_DIN(1),
        VA    	=> 3.3,
        IN0   	=> 0.1,
        IN1   	=> 0.18,
        IN2   	=> 0.12,
        IN3   	=> 0.13,
        IN4   	=> 0.14,
        IN5  	=> 0.15,
        IN6   	=> 0.16,
        IN7   	=> 0.17,
        DOUT  	=> DAC_ADC128_DOUT(1)
        ); 		
ADC128 : entity work.ADC128S102_controler
	PORT MAP 
			(
          Reset			 	=> RESET,
          clk_4X	 		 	=> CLK_4X,
			 ENABLE_CLK_1X	 	=> ENABLE_CLK_1X,
          Output_registers => ADC128_registers,
          read_register		=> adc128_read_register,
          Start 				=> adc128_start,
          Done 				=> adc128_done,
          Sclk		 			=> SCLK_ADC128,
          Dout		 			=> DOUT_ADC128,
          Din		 			=> DIN_ADC128,
          Cs_n 				=> CS_ADC128_N
			);
adc128_ALL_done <= DAC_adc128_done(0) and DAC_adc128_done(1) and adc128_done;
ADC128_DAC_0 : entity work.ADC128S102_MUXED_controler
	PORT MAP 
			(
			Reset			 	=> RESET,
			clk_4X	 		 	=> CLK_4X,
			ENABLE_CLK_1X	 	=> ENABLE_CLK_1X,
			twelve_mili_SECOND	=> twelve_mili_SECOND,

			Output_registers 	=> DAC_ADC128_registers(0),
			Start 				=> DAC_adc128_start(0),
			read_register		=> DAC_ADC128_Read_Register(0),
			Done 				=> DAC_adc128_done(0),
			Sclk		 		=> DAC_ADC128_SCLK(0),
			Dout		 		=> DAC_ADC128_DOUT(0),
			Din		 			=> DAC_ADC128_DIN(0),
			Cs_n 				=> DAC_ADC128_CSn(0),
			DAC_MUX_S			=> DAC_ADC128_MUX_S(0)
			);
ADC128_DAC_1 : entity work.ADC128S102_MUXED_controler
	PORT MAP 
			(
			Reset			 	=> RESET,
			clk_4X	 		 	=> CLK_4X,
			ENABLE_CLK_1X	 	=> ENABLE_CLK_1X,
			twelve_mili_SECOND	=> twelve_mili_SECOND,

			Output_registers 	=> DAC_ADC128_registers(1),
			Start 				=> DAC_adc128_start(1),
			read_register		=> DAC_ADC128_Read_Register(1),
			Done 				=> DAC_adc128_done(1),
			Sclk		 		=> DAC_ADC128_SCLK(1),
			Dout		 		=> DAC_ADC128_DOUT(1),
			Din		 			=> DAC_ADC128_DIN(1),
			Cs_n 				=> DAC_ADC128_CSn(1),
			DAC_MUX_S			=> DAC_ADC128_MUX_S(1)
			);

DAC_adc128_start(0)		    <= adc128_start_HK ;	
DAC_ADC128_Read_Register(0) <= adc128_read_register_HK;
DAC_adc128_start(1)		    <= adc128_start_HK ;	
DAC_ADC128_Read_Register(1) <= adc128_read_register_HK;
adc128_start <= adc128_start_HK ;	
adc128_read_register <= adc128_read_register_HK;

ADC_RHF1201: entity work.RHF1201_controler 
    Port MAP 
			(
 			CLK_4X				=> CLK_4X,
 			CLK_1X				=> CLK_1X,
			ENABLE_CLK_1X		=> ENABLE_CLK_1X,
         RESET					=> RESET,
			CONTROL				=> CONTROL.RHF1201s(0),
			STATUS				=> STATUS.RHF1201s(0),
         OUT_OF_RANGE_ADC	=> OOR_RHF1201,
         OUT_OF_RANGE 		=> OUT_OF_RANGE_RHF1201_int, 
			DIN					=> DATA_RHF1201,
         DOUT					=> DOUT_RHF1201,
         DATA_READY			=> DR_RHF1201,
         CLOCK_TO_ADC		=> CLK_RHF1201,
         CLOCK_FROM_ADC		=> '0',
			ADC_READY			=>	rhf1201_ready,
         OE_N 					=> OE_RHF1201_n,
         SLEW_RATE_CONTROL => SRC_RHF1201,
         DATA_FORMAT_SEL_N => DFS_RHF1201_n
			);
			ADC_RHF12012: entity work.RHF1201_controler 
    Port MAP 
			(
 			CLK_4X				=> CLK_4X,
 			CLK_1X				=> CLK_1X,
			ENABLE_CLK_1X		=> ENABLE_CLK_1X,
         RESET					=> RESET,
			CONTROL				=> CONTROL.RHF1201s(1),
			STATUS				=> STATUS.RHF1201s(1),
         OUT_OF_RANGE_ADC	=> OOR_RHF1201,
         OUT_OF_RANGE 		=> OUT_OF_RANGE_RHF1201_int, 
			DIN					=> DATA_RHF1201,
         DOUT					=> DOUT_RHF1201,
         DATA_READY			=> DR_RHF1201,
         CLOCK_TO_ADC		=> CLK_RHF1201,
         CLOCK_FROM_ADC		=> '0',
			ADC_READY			=>	rhf1201_ready,
         OE_N 					=> OE_RHF1201_n,
         SLEW_RATE_CONTROL => SRC_RHF1201,
         DATA_FORMAT_SEL_N => DFS_RHF1201_n
			);
DR_RHF1201 <= CLK_RHF1201;
OOR_RHF1201 <= std_logic(DATA_RHF1201 (11));
----------------------------------------------------------------------------
--	
-- USB 3.0 link manager
--
----------------------------------------------------------------------------
USB30_manager : entity work.USB30_links_manager
    Port map( 
-- RESET	
		RESET						=> RESET,
-- CLOCKS	
		CLK_4X						=> CLK_4X,
		CLK_1X						=> CLK_1X, 					-- clock for usb 3.0 controler (80Mhz/4= 20MHz)
         ENABLE_CLK_1X 	=> ENABLE_CLK_1X,
		LOOP_ON						=> '0',
-- config_out
		regCONFIG					=> regCONFIG,
		CONTROL						=> open,--CONTROL,
		Pixels_rd_conf				=> open,--Pixels_rd_conf, drive from VIO#################################################
		CONF_ADDRESS_out			=> open,
		CONF_RECEIVED_DATA_out		=> open,

-- Data control For XIFU selected TM data
		TM_DATA_TO_GSE				=> tm_data_to_gse,
		wr_en_TM_fifo				=> wr_en_tm_fifo,

-- Data control For XIFU selected HK data
		HK_DATA_TO_GSE				=> hk_data_to_gse,
		wr_en_HK_fifo				=> wr_en_hk_fifo,
		almost_full_HK_fifo			=> almost_full_hk_fifo,
		
-- TO USB_3.0 manager
      DAQ_CLK_USB_OUT				=> DAQ_CLK_usb_OUT,
-- DAQ 32 bits 10MHz for science link
      DAQ_usb_Data					=> DAQ_usb_Data,
      DAQ_usb_Rdy_n					=> DAQ_usb_Rdy_n,
      DAQ_usb_WR					=> DAQ_usb_WR,
--      START_SENDING_usb_DAQ	=> CONTROL.CHANNELs(0).START_SENDING_usb_DAQ,
-- DATA SENDING 10MHz 8 bits for HK link
      HK_usb_Data					=> HK_usb_Data,
      HK_usb_Rdy_n					=> HK_usb_Rdy_n,
      HK_usb_WR						=> HK_usb_WR,
--      START_SENDING_usb_HK		=> CONTROL.CHANNELs(0).START_SENDING_usb_HK,
-- DATA RECEIVED 10MHz 8 bits for Config link
      Bad_conf_register_write 		=> bad_conf_register_write,
	  CONF_usb_Data					=> CONF_usb_Data,
      CONF_usb_Rdy_n				=> CONF_usb_Rdy_n,
      CONF_usb_WR					=> CONF_usb_WR 
			);
-- USB30_manager : USB30_links_manager
    -- Port map( 
-- -- RESET	
		-- RESET							=> RESET,
-- -- CLOCKS	
		-- CLK_4X						=> CLK_4X,
		-- CLK_1X						=> CLK_1X, -- clock for usb 3.0 controler (80Mhz/8= 10MHz)
		-- ENABLE_CLK_1X_DIV64		=> ENABLE_CLK_1X_DIV64, -- clock for usb 3.0 controler (80Mhz/256= 0.312MHz)
		-- Regconfig					=> open,--RegConfig,
		-- LOOP_ON						=> '0',
		-- CONTROL.CHANNELs			=> open,--CONTROL.CHANNELs,
		-- control_RHF1201S			=> control_RHF1201S,
-- -- Data control For XIFU selected ACQ data
		-- DATA_TO_USB_SEND			=> DATA_TO_USB_SEND,
		-- rd_en_DAQ_usb_fifo		=> rd_en_DAQ_usb_fifo,
		-- empty_DAQ_usb_fifo		=> empty_DAQ_usb_fifo,
		-- valid_DAQ_usb_fifo		=> valid_DAQ_usb_fifo,
		-- DAQ_CLK_to_usb_fifo		=> DAQ_CLK_to_usb_fifo,

-- -- Data control For XIFU selected HK data
		-- HK_TO_USB_SEND				=> HK_TO_USB_SEND,
		-- rd_en_HK_usb_fifo			=> rd_en_HK_usb_fifo,
		-- empty_HK_usb_fifo			=> empty_HK_usb_fifo,
		-- valid_HK_usb_fifo			=> valid_HK_usb_fifo,
		-- HK_CLK_to_usb_fifo		=> HK_CLK_to_usb_fifo,
		
-- -- TO USB_3.0 manager
      -- DAQ_CLK_usb_OUT			=> DAQ_CLK_usb_OUT,
-- -- DAQ 32 bits for science link
      -- DAQ_usb_Data				=> DAQ_usb_Data,
      -- DAQ_usb_Rdy_n				=> DAQ_usb_Rdy_n,
      -- DAQ_usb_WR					=> DAQ_usb_WR,
-- -- DATA SENDING 1MHz 8 bits for HK link
      -- HK_usb_Data					=> HK_usb_Data,
      -- HK_usb_Rdy_n				=> HK_usb_Rdy_n,
      -- HK_usb_WR					=> HK_usb_WR,
-- -- DATA RECEIVED 1MHz 8 bits for Config link
      -- CONF_usb_Data				=> CONF_usb_Data,
      -- CONF_usb_Rdy_n				=> CONF_usb_Rdy_n,
      -- CONF_usb_WR					=> CONF_usb_WR
			-- );
	-- =============================================================
	-- READ_OUT_TO_DAQ
----------------------------------------------------------------------------
--	
-- DATA selector to DAQ 32 bits bus (SCIENCES,RHF1201,ADC128,COUNTER...)
--
----------------------------------------------------------------------------


TM_OUTPUT_SELECT: entity work.Select_output_to_TM
 
    Port MAP( 
-- FROM XIFU
--	OUT_SCIENCE_I			=>	Out_Science_I,
--	OUT_SCIENCE_Q			=>	Out_Science_Q,
	STATUS => STATUS,
	OUT_SCIENCE_UNFILTRED_TP_I => OUT_SCIENCE_UNFILTRED_TP_I,
	OUT_SCIENCE_UNFILTRED_TP_Q => OUT_SCIENCE_UNFILTRED_TP_Q,
	OUT_SCIENCE_FILTRED_I => OUT_SCIENCE_FILTRED_I,
	OUT_SCIENCE_FILTRED_Q => OUT_SCIENCE_FILTRED_Q,
	IN_PHYS					=>	out_squid,
   FEEDBACK					=>	FEEDBACK,
   BIAS						=>	BIAS,
			
			
-- OUTPUT SELECTOR : AT CLK_1X 20MHz, up to 3 32 bits Words
	select_TM 				=> CONTROL.GSE.select_TM,
	START_SENDING_TM		=> CONTROL.GSE.START_SENDING_TM,
	
-- CLOCKS	
	CLK_4X					=>	CLK_4X,
	ENABLE_CLK_1X			=>	ENABLE_CLK_1X,
	ENABLE_CLK_1X_DIV128	=>	ENABLE_CLK_1X_DIV128,
			
-- TO PCIE manager
-- RESET
	RESET					=>	RESET,
	TM_DATA_TO_GSE			=>  tm_data_to_gse,
	WR_en_TM_fifo			=>  wr_en_tm_fifo
	);
		
-- PCIE HK Output selector			
----------------------------------------------------------------------------
--	
-- PCIE HK BUS Output selector (ADC128, CONFIG, COUNTER) automatic(2s) or not
--
----------------------------------------------------------------------------
--GENERATE_ADC128_register : for C in 0 to Nb_channel-1 generate
--ADC128_ALL_registers (0+23*C) 	<= ADC128_registers();-- ADC128 CH1 ADC IN0
--ADC128_ALL_registers (1+23*C) 	<= (others =>'0');-- ADC128 CH1 ADC IN1
--ADC128_ALL_registers (2+23*C) 	<= (others =>'0');-- ADC128 CH1 ADC IN2
--ADC128_ALL_registers (3+23*C) 	<= (others =>'0');-- ADC128 CH1 ADC IN3
--ADC128_ALL_registers (4+23*C) 	<= (others =>'0');-- ADC128 CH1 ADC IN4
--ADC128_ALL_registers (5+23*C) 	<= (others =>'0');-- ADC128 CH1 ADC IN5
--ADC128_ALL_registers (6+23*C) 	<= (others =>'0');-- ADC128 CH1 ADC IN6
--ADC128_ALL_registers (7+23*C) 	<= (others =>'0');-- ADC128 CH1 ADC IN7
--ADC128_ALL_registers (8+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN0_0 MUX
--ADC128_ALL_registers (9+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN0_1 MUX
--ADC128_ALL_registers (10+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN0_2 MUX
--ADC128_ALL_registers (11+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN0_3 MUX
--ADC128_ALL_registers (12+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN0_4 MUX
--ADC128_ALL_registers (13+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN0_5 MUX
--ADC128_ALL_registers (14+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN0_6 MUX
--ADC128_ALL_registers (15+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN0_7 MUX
--ADC128_ALL_registers (16+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN1
--ADC128_ALL_registers (17+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN2
--ADC128_ALL_registers (18+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN3
--ADC128_ALL_registers (19+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN4
--ADC128_ALL_registers (20+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN5
--ADC128_ALL_registers (21+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN6
--ADC128_ALL_registers (22+23*C) 	<= (others =>'0');-- ADC128 CH1 DAC IN7
--end generate GENERATE_ADC128_register;
GENERATE_ADC128_register : for C in 0 to Nb_channel-1 generate
		
ADC128_ALL_registers (0+23*C) 	<= ADC128_registers(0);-- ADC128 CH1 ADC IN0
ADC128_ALL_registers (1+23*C) 	<= ADC128_registers(1);-- ADC128 CH1 ADC IN1
ADC128_ALL_registers (2+23*C) 	<= ADC128_registers(2);-- ADC128 CH1 ADC IN2
ADC128_ALL_registers (3+23*C) 	<= ADC128_registers(3);-- ADC128 CH1 ADC IN3
ADC128_ALL_registers (4+23*C) 	<= ADC128_registers(4);-- ADC128 CH1 ADC IN4
ADC128_ALL_registers (5+23*C) 	<= ADC128_registers(5);-- ADC128 CH1 ADC IN5
ADC128_ALL_registers (6+23*C) 	<= ADC128_registers(6);-- ADC128 CH1 ADC IN6
ADC128_ALL_registers (7+23*C) 	<= ADC128_registers(7);-- ADC128 CH1 ADC IN7
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
end generate GENERATE_ADC128_register;
HK_OUTPUT_SELECT: entity work.Select_output_to_HK
 
    Port MAP( 
-- FROM XIFU
		ADC128_registers		=> ADC128_ALL_registers,
		ADC128_Done				=> adc128_ALL_done,
		ADC128_read_register 	=> adc128_read_register_HK,
		ADC128_start_HK	 		=> adc128_start_HK,
		regCONFIG				=> regCONFIG,
		STATUS					=> STATUS,
	
-- OUTPUT SELECTOR : AT CLK_1X 25MHz, up to 3 32 bits Words
	select_HK					=> "01",
	START_SENDING_HK			=> START_SENDING_usb_HK,

-- RESET
		RESET					=>	RESET,
	
-- CLOCKS	
		CLK_4X					=>	CLK_4X,
		ENABLE_CLK_1X			=> ENABLE_CLK_1X, -- clock for usb 3.0 controler (80Mhz/64= 0.3MHz)
		ONE_SECOND				=> ONE_SECOND,			
-- TO USB 3.0 manager

		HK_DATA_TO_GSE			=> hk_data_to_gse,
		WR_en_HK_fifo			=> wr_en_hk_fifo,
		almost_full_HK_fifo		=> almost_full_hk_fifo
		);
				
--HK_CLK_to_usb_fifo <= CLK_1X_DIV2;
----------------------------------------------------------------------------------------------------
-- INTERNAL SQUID TO TEST CHANNEL
----------------------------------------------------------------------------------------------------

	label_Internal_Squid_0 : entity work.Squid_generic
	 Generic map
		(
		Size_in 		=>  Size_bias_to_DAC, 			
		Size_out 	=> Size_In_Real		
		)
    Port map
		( 
		CLk_4X 			=> CLK_4X,
		Enable_CLK_1X 	=> ENABLE_CLK_1X,
		reset 			=> RESET,-- reset a 1!!!!
		In_Squid 		=> BIAS(0),--(others => '0')
		In_Feedback	 => FEEDBACK(0),

		Out_Squid	=> out_squid(0)
		);
	-- Instantiate the Unit Under Test (UUT)
   channel_0: entity work.channel PORT MAP (
          CLK_4X => CLK_4X,
          ENABLE_CLK_1X => ENABLE_CLK_1X,
 			 ENABLE_CLK_1X_DIV128	=> ENABLE_CLK_1X_DIV128,
          RESET => RESET,
		CONSTANT_FB				=>C_Constant_FB,
          CONTROL		 => CONTROL.CHANNELs(0),
          IN_PHYS => out_squid(0),
          BIAS => BIAS(0),
          FEEDBACK => FEEDBACK(0),
	OUT_SCIENCE_UNFILTRED_TP_I => OUT_SCIENCE_UNFILTRED_TP_I(0),
	OUT_SCIENCE_UNFILTRED_TP_Q => OUT_SCIENCE_UNFILTRED_TP_Q(0),
	OUT_SCIENCE_FILTRED_I => OUT_SCIENCE_FILTRED_I(0),
	OUT_SCIENCE_FILTRED_Q => OUT_SCIENCE_FILTRED_Q(0)
        );

	label_Internal_Squid_1 : entity work.Squid_generic
	 Generic map
		(
		Size_in 		=>  Size_bias_to_DAC, 			
		Size_out 	=> Size_In_Real		
		)
    Port map
		( 
		CLk_4X 			=> CLK_4X,
		Enable_CLK_1X 	=> ENABLE_CLK_1X,
		reset 			=> RESET,-- reset a 1!!!!
		In_Squid 	=> BIAS(1),
		In_Feedback => FEEDBACK(1),

		Out_Squid	=> out_squid(1)
		);
	-- Instantiate the Unit Under Test (UUT)
   channel_1: entity work.channel PORT MAP (
          CLK_4X => CLK_4X,
          ENABLE_CLK_1X => ENABLE_CLK_1X,
 			 ENABLE_CLK_1X_DIV128	=> ENABLE_CLK_1X_DIV128,
          RESET => RESET,
		CONSTANT_FB				=>C_Constant_FB,
         CONTROL => CONTROL.CHANNELs(1),
          IN_PHYS => out_squid(1),
          BIAS => BIAS(1),
          FEEDBACK => FEEDBACK(1),
	OUT_SCIENCE_UNFILTRED_TP_I => OUT_SCIENCE_UNFILTRED_TP_I(1),
	OUT_SCIENCE_UNFILTRED_TP_Q => OUT_SCIENCE_UNFILTRED_TP_Q(1),
	OUT_SCIENCE_FILTRED_I => OUT_SCIENCE_FILTRED_I(1),
	OUT_SCIENCE_FILTRED_Q => OUT_SCIENCE_FILTRED_Q(1)
         );
DACF_CONTROLER_C : entity work.LTC2000_CONTROLER PORT MAP (
         CLK_4X 				=> CLK_4X,
         CLK_2X 				=> CLK_2X,
         CLK_1X 				=> CLK_1X,
        ENABLE_CLK_1X_DIV128 	=> ENABLE_CLK_1X_DIV128,
         RESET					=> RESET,
		 DCLK_FROM_DAC			=> '1',
		 DATA_TO_DAC			=> DACF_DATA(0),
		 DAC_ON					=> '1',
		 DCLK_TO_DAC			=> DACF_DCLK_TO(0),
		 DB_OUT					=> DACF_DATA_OUT(0),
         SPI_command 			=> DACF_SPI_command(0),
         SPI_address 			=> DACF_SPI_address(0),
         SPI_data 				=> DACF_SPI_data(0),
         SPI_DATA_RECEIVED 		=> DACF_SPI_DATA_RECEIVED(0),
         SPI_write 				=> DACF_SPI_write(0),
         SPI_ready 				=> DACF_SPI_ready(0),
         SPI_SDO 				=> DACF_SPI_SDO(0),
         SPI_SDIO 				=> DACF_SPI_SDIO(0),
         SPI_SCLK 				=> DACF_SPI_SCLK(0),
         SPI_CS_N 				=> DACF_SPI_CS_N(0),
         DAC_RESET_IN			=> DACF_RESET_IN(0),
         DAC_RESET 				=>  DACF_RESET(0)
        );
        DACB_DATA(0) <= std_logic_vector(BIAS(0));
DACF_DATA(0) <= std_logic_vector(FEEDBACK(0)) when CONTROL.CHANNELs(0).feedback_reverse ='0' else std_logic_vector(-FEEDBACK(0));
        
-- LTC2000_OUTPUT: entity work.single_to_DDR_16b
--  	generic map (
--  		sys_w => 16,
--  		dev_w => 32
--  	)
--  port map
--   (
--  DATA_OUT_FROM_DEVICE => DATA_LTC_32b, --Input pins
--  DATA_OUT_TO_PINS => DATA_OUT_TO_PINS, --Output pins
--  CLK_TO_PINS => CLK_TO_PINS,
--  CLK_IN => CLK_2X, -- Single ended clock from IOB
--  -- From the device out to the system
--  CLK_RESET => RESET,
--  IO_RESET => RESET -- system reset
--  );          
-- 
--clk_div_32: process(RESET, CLK_4X)
--	begin
--		if RESET = '1' then
--		cmpt_antoine <= (others=>'0');
--		chenille_antoine <="10000000";
--		else 
--			if (rising_edge(CLK_4X)) then
--			cmpt_antoine 			<= cmpt_antoine + 1 ;
--				if (cmpt_antoine= "111111111111111111111") then
--				chenille_antoine <= chenille_antoine (6 downto 0) & chenille_antoine (7);
--				end if;
--				if (cmpt_antoine(15 downto 0) = "111111111111111") then
--				end if;
--			end if;
--		end if;
--	end process; 	
CMM1:	entity work.CMM 
    Port map 
		(
		CDCM_PLL_RESET 			=> '0',
		FPGA_RESET 				=> '0', 					-- from push button
		HPC1_RESET_GSE			=> hpc1_reset_gse, 					-- from push button
		CLK_CDCM_SELECT			=> '0',	--CONTROL_SPI.CLK_CDCM_SELECT,CLOCK select from GSE control Register
		SYSCLK_P 				=> SYSCLK_P,  					-- 80MHz from FPGA_BOARD oscilator or user_sma_clock_P
		SYSCLK_N 				=> SYSCLK_N,  					-- 80MHz from FPGA_BOARD oscilator or user_sma_clock_P
		DAC_CLK					=> SYSCLK_P,			-- DACF_DCLK_FROM(0),19.53MHz from DAC BOARD
		CLK_4X					=> CLK_4X,	  					-- 80 MHz or 78.12MHz depend on CLK_CDCM_SELECT
		CLK_1X					=> CLK_1X,	  					-- 20MHz or 19.53MHz depend on CLK_CDCM_SELECT for ADC
		CLK_LOCKED_CDCM			=> open,				-- output for CDCM CLOCK INTERNAL LOCK
		CLK_LOCKED_200MHz		=> open, 					-- output for FPGA_BOARD or user_sma_clock_P INTERNAL PLL LOCKED
        HW_RESET 				=> RESET,					-- General Reset output from CLK_LOCKED anc CPU_RESET
		ENABLE_CLK_1X			=> ENABLE_CLK_1X,				-- Enable Clock at 20MHz or 19.53MHz
        ENABLE_CLK_1X_DIV128	=> ENABLE_CLK_1X_DIV128,		-- Enable Clock at 20MHz/128 or 19.53MHz/128
		ONE_SECOND				=> ONE_SECOND,					-- Enable Clock at one second
		twelve_mili_SECOND		=> twelve_mili_SECOND,			-- Enable Clock at 12 ms
		Chenille				=>	chenille					-- LED chaser
		); 
--CONFSEND1: CONF_sender_USB30 
--    Port map( 
--			START_SENDING_CONF	=>	START_SENDING_CONF,
---- CLOCKS	
--			CLK_4X					=>	CLK_4X,
--			CLK_1X					=>	CLK_1X,
--			ENABLE_CLK_1X_DIV64	=> ENABLE_CLK_1X_DIV64,
--			ONE_SECOND				=> ONE_SECOND,
--			CONF						=> '1',
--			CONF_AUTO				=> '1',
---- TO USB 3.0 manager
--			RESET						=> RESET,
--         CONF_usb_Data			=> CONF_usb_Data,
--         CONF_usb_Rdy_n			=> CONF_usb_Rdy_n,
--         CONF_usb_WR				=> CONF_usb_WR
--
--			);
--

--CLK_1X_DIV32 <= cmpt_antoine(6);
--CLK_1X_DIV64 <= cmpt_antoine(7);
--sequencer(0) 	 <= cmpt_antoine(0);
--sequencer(1) 	 <= cmpt_antoine(1);
   -- Clock process definitions
--   CLK_4X_process :process
--   begin
--		CLK_4X <= '0';
--		wait for CLK_4X_period/2;
--		CLK_4X <= '1';
--		wait for CLK_4X_period/2;
--   end process;
-- 
--   CLK_2X_process :process
--   begin
--		CLK_2X <= '0';
--		wait for SYS_CLK_period/40;
--		CLK_2X <= '1';
--		wait for SYS_CLK_period/40;
--   end process;
 
   CLK_SYS_process : process
   begin
		SYSCLK_N <= '0';
		SYSCLK_P <= '1';
		wait for SYS_CLK_period/2;
		SYSCLK_N <= '1';
		SYSCLK_P <= '0';
		wait for SYS_CLK_period/2;
   end process;

clk_div: process(RESET, CLK_4X)
	begin
		if RESET = '1' then
		 DATA_RHF1201 <= (others=>'0');
		 CLK_2X <='0';
		else 
			if (rising_edge(CLK_4X)) then
				CLK_2X <= not CLK_2X;
				if (ENABLE_CLK_1X ='1') then
				DATA_RHF1201			<= DATA_RHF1201 + 1;
				end if;
			end if;
		end if;
	end process;

process
	begin
	-- =============================================================
	-- WRITE REGISTERS PROCESS ATTENTION LES REGISTRES CHANGENT EN USB30
	-- =============================================================
--														  select_TM <=b"0000";
	-- =============================================================
	-- WRITE REGISTERS PROCESS ATTENTION LES REGISTRES CHANGENT EN USB30
	-- =============================================================
--	control_GSE.select_HK					<= select_HK;
--	control_GSE.Start_Sending_HK			<= START_SENDING_usb_HK;
--	control_GSE.select_TM					<= select_TM;
--	control_GSE.Start_Sending_TM			<= START_SENDING_usb_DAQ;
	CONTROL.RHF1201s(0).ADC_ON <='1';
	CONTROL.CHANNELs(0).CONTROL_PIXELS(4).increment			<= TO_UNSIGNED(52429*0,counter_size);--pixel increment bias 20 bits 
	CONTROL.CHANNELs(0).CONTROL_PIXELS(4).BIAS_amplitude	<= TO_UNSIGNED(0,8);--pixel amplitude bias 10 bits 
	CONTROL.CHANNELs(0).CONTROL_PIXELS(4).PHI_DELAY			<= TO_UNSIGNED(0,8);-- pixel COMPENSATION DELAY PHASE 8bits
	CONTROL.CHANNELs(0).CONTROL_PIXELS(4).PHI_INITIAL		<= TO_UNSIGNED(0,12);-- pixel START PHASE 8bits
	CONTROL.CHANNELs(0).CONTROL_PIXELS(4).PHI_ROTATE		<= TO_UNSIGNED(0,8);--		: unsigned(Nb_bits_PHASE_ROTATE_IQ-1 downto 0);--:="00000000" pixel ROTATEIQ OUPUT PHASE 8bits
	CONTROL.CHANNELs(0).CONTROL_PIXELS(4).SW1				<= '0';--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
	CONTROL.CHANNELs(0).CONTROL_PIXELS(4).SW2				<= "00";--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
--	CONTROL_GSE.select_HK									<= "00";--				: std_logic;-- := '1'pixel BBFB reset
--	CONTROL_GSE.START_SENDING_HK							<= '0';--				: std_logic;-- := '1'pixel BBFB reset
--	CONTROL_GSE.select_TM									<= "1000";--				: std_logic;-- := '1'pixel BBFB reset
--	CONTROL_GSE.START_SENDING_TM							<= '0';--				: std_logic;-- := '1'pixel BBFB reset
	CONTROL.CHANNELs(0).START_STOP							<= '0';--				: std_logic;-- := '1'pixel BBFB reset
	CONTROL.CHANNELs(0).CONTROL_PIXELS(4).gain_BBFB			<= TO_UNSIGNED(0,8);--:="00001000" pixel BBFB INTEGRATOR GAIN											
	
	CONTROL.CHANNELs(0).BIAS_truncation						<= TO_UNSIGNED(0,2);--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
	CONTROL.CHANNELs(0).FEEDBACK_truncation					<= TO_UNSIGNED(0,2);--			: std_logic;-- := '1'pixel BBFB reset
	CONTROL.CHANNELs(0).feedback_reverse					<= '0';--			: std_logic;-- := '1'pixel BBFB reset
	CONTROL.CHANNELs(0).select_Input						<= TO_UNSIGNED(1,2);
--	CONTROL.CHANNELS(0).select_outputA						<= TO_UNSIGNED(0,2);
--	CONTROL.CHANNELS(0).select_OutputB						<= TO_UNSIGNED(0,2);
	CONTROL.CHANNELs(0).BIAS_Enable							<= '1';
	CONTROL.AD9726s(0).DACF.DAC_ON								<= '1';
	CONTROL.AD9726s(0).DACB.DAC_ON								<= '1';
	CONTROL.RHF1201s(0).ADC_ON								<= '1';
	CONTROL.CHANNELs(0).FEEDBACK_Enable						<= '1';
--	CONTROL.CHANNELS(0).select_out_data						<= TO_UNSIGNED(7,3);
	CONTROL.CHANNELs(0).BIAS_slope_speed					<= TO_UNSIGNED(0,2);--:="00001000" pixel BBFB INTEGRATOR GAIN											
l0: for i in 5 to Nb_pixel-2 loop
	CONTROL.CHANNELs(0).CONTROL_PIXELS(i).increment			<= TO_UNSIGNED(52429*0,counter_size);--pixel increment bias 20 bits
	CONTROL.CHANNELs(0).CONTROL_PIXELS(i).BIAS_amplitude	<= TO_UNSIGNED(0,8);--pixel amplitude bias 10 bits
CONTROL.CHANNELs(0).CONTROL_PIXELS(i).PHI_DELAY				<= TO_UNSIGNED(0,8);
CONTROL.CHANNELs(0).CONTROL_PIXELS(i).PHI_INITIAL			<= TO_UNSIGNED(0,12);
CONTROL.CHANNELs(0).CONTROL_PIXELS(i).PHI_ROTATE			<= TO_UNSIGNED(0,8);
CONTROL.CHANNELs(0).CONTROL_PIXELS(i).SW1					<= '0';--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
CONTROL.CHANNELs(0).CONTROL_PIXELS(i).SW2					<= "00";
CONTROL.CHANNELs(0).CONTROL_PIXELS(i).gain_BBFB				<= TO_UNSIGNED(0,8);
end loop l0;
l02: for i in 0 to 3 loop
	CONTROL.CHANNELs(0).CONTROL_PIXELS(i).increment					<= TO_UNSIGNED(52429*0,counter_size);--pixel increment bias 20 bits
	CONTROL.CHANNELs(0).CONTROL_PIXELS(i).BIAS_amplitude			<= TO_UNSIGNED(0,8);--pixel amplitude bias 10 bits
CONTROL.CHANNELs(0).CONTROL_PIXELS(i).PHI_DELAY						<= TO_UNSIGNED(0,8);
CONTROL.CHANNELs(0).CONTROL_PIXELS(i).PHI_INITIAL					<= TO_UNSIGNED(0,12);
CONTROL.CHANNELs(0).CONTROL_PIXELS(i).PHI_ROTATE					<= TO_UNSIGNED(0,8);
CONTROL.CHANNELs(0).CONTROL_PIXELS(i).SW1							<= '0';--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
CONTROL.CHANNELs(0).CONTROL_PIXELS(i).SW2							<= "00";
CONTROL.CHANNELs(0).CONTROL_PIXELS(i).gain_BBFB						<= TO_UNSIGNED(0,8);
end loop l02;

-----------------------------------------------------
---------------------- TEST PIXEL -------------------
CONTROL.CHANNELs(0).CONTROL_PIXELS( Nb_pixel-1).increment			<= TO_UNSIGNED(integer(52429*4.9),counter_size);--pixel increment bias 20 bits 52429 1.664
CONTROL.CHANNELs(0).CONTROL_PIXELS( Nb_pixel-1).BIAS_amplitude		<= TO_UNSIGNED(10,8);--pixel amplitude bias 8 bits
CONTROL.CHANNELs(0).CONTROL_PIXELS( Nb_pixel-1).PHI_DELAY			<= TO_UNSIGNED(200,8);
CONTROL.CHANNELs(0).CONTROL_PIXELS( Nb_pixel-1).PHI_INITIAL			<= TO_UNSIGNED(0,12);
CONTROL.CHANNELs(0).CONTROL_PIXELS( Nb_pixel-1).PHI_ROTATE			<= TO_UNSIGNED(0,8);
CONTROL.CHANNELs(0).CONTROL_PIXELS( Nb_pixel-1).SW1					<= '0';--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
CONTROL.CHANNELs(0).CONTROL_PIXELS( Nb_pixel-1).SW2					<= "00";
CONTROL.CHANNELs(0).Send_pulse										<= '0';
CONTROL.CHANNELs(0).Pulse_Amplitude									<= TO_UNSIGNED(0,8);
CONTROL.CHANNELs(0).Pulse_timescale									<= TO_UNSIGNED(15,4);
CONTROL.CHANNELs(0).CONTROL_PIXELS( Nb_pixel-1).gain_BBFB			<= TO_UNSIGNED(40,8);
CONTROL.CHANNELs(0).BIAS_modulation_increment						<= TO_UNSIGNED(0,24);--839 = 1KHz
CONTROL.CHANNELs(0).FEEDBACK_compensation_gain						<= TO_UNSIGNED(32767,16);--32767
CONTROL.CHANNELs(0).BIAS_modulation_amplitude						<= TO_UNSIGNED(0,8);
CONTROL.CHANNELs(0).Loop_control									<= TO_UNSIGNED(0,4);
-----------------------------------------------------------



--1111111
	CONTROL.CHANNELs(1).CONTROL_PIXELS(0).increment			<= TO_UNSIGNED(52429*0,counter_size);--pixel increment bias 20 bits
	CONTROL.CHANNELs(1).CONTROL_PIXELS(0).BIAS_amplitude	<= TO_UNSIGNED(0,8);--pixel amplitude bias 10 bits
	CONTROL.CHANNELs(1).CONTROL_PIXELS(0).PHI_DELAY			<= TO_UNSIGNED(0,8);-- pixel COMPENSATION DELAY PHASE 8bits
	CONTROL.CHANNELs(1).CONTROL_PIXELS(0).PHI_INITIAL		<= TO_UNSIGNED(0,12);-- pixel START PHASE 8bits
	CONTROL.CHANNELs(1).CONTROL_PIXELS(0).PHI_ROTATE		<= TO_UNSIGNED(0,8);--		: unsigned(Nb_bits_PHASE_ROTATE_IQ-1 downto 0);--:="00000000" pixel ROTATEIQ OUPUT PHASE 8bits
	CONTROL.CHANNELs(1).CONTROL_PIXELS(0).SW1				<= '0';--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
	CONTROL.CHANNELs(1).CONTROL_PIXELS(0).SW2				<="00";--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
CONTROL.CHANNELs(1).Send_pulse										<= '0';
CONTROL.CHANNELs(1).Pulse_Amplitude									<= TO_UNSIGNED(0,8);
CONTROL.CHANNELs(1).Pulse_timescale									<= TO_UNSIGNED(15,4);
	CONTROL.CHANNELs(1).CONTROL_PIXELS(0).gain_BBFB			<= TO_UNSIGNED(255,8);--:="00001000" pixel BBFB INTEGRATOR GAIN											
	
	CONTROL.CHANNELs(1).BIAS_truncation						<= TO_UNSIGNED(0,2);--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
	CONTROL.CHANNELs(1).FEEDBACK_truncation					<= TO_UNSIGNED(0,2);--				: std_logic;-- := '1'pixel BBFB reset
	CONTROL.CHANNELs(1).feedback_reverse					<= '0';--			: std_logic;-- := '1'pixel BBFB reset
	CONTROL.CHANNELs(1).select_Input						<= TO_UNSIGNED(1,2);
	CONTROL.CHANNELs(1).BIAS_Enable							<= '1';
	CONTROL.AD9726s(1).DACF.DAC_ON								<= '1';
	CONTROL.AD9726s(1).DACB.DAC_ON								<= '1';
	CONTROL.RHF1201s(1).ADC_ON								<= '1';
	CONTROL.CHANNELs(1).START_STOP							<= '0';
	CONTROL.CHANNELs(1).FEEDBACK_Enable						<= '1';
	CONTROL.CHANNELs(1).BIAS_slope_speed					<= TO_UNSIGNED(0,2);--:="00001000" pixel BBFB INTEGRATOR GAIN											
l1: for i in 1 to Nb_pixel-1 loop
	CONTROL.CHANNELs(1).CONTROL_PIXELS(i).increment			<= TO_UNSIGNED(52429*1+(100*i),counter_size);--pixel increment bias 20 bits
	CONTROL.CHANNELs(1).CONTROL_PIXELS(i).BIAS_amplitude	<= TO_UNSIGNED(64,8);--pixel amplitude bias 10 bits
CONTROL.CHANNELs(1).CONTROL_PIXELS(i).PHI_DELAY				<= TO_UNSIGNED(0,8);
CONTROL.CHANNELs(1).CONTROL_PIXELS(i).PHI_INITIAL			<= TO_UNSIGNED(0,12);
CONTROL.CHANNELs(1).CONTROL_PIXELS(i).PHI_ROTATE			<= TO_UNSIGNED(0,8);
CONTROL.CHANNELs(1).CONTROL_PIXELS(i).SW1					<= '0';--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
CONTROL.CHANNELs(1).CONTROL_PIXELS(i).SW2					<= "00";
CONTROL.CHANNELs(1).CONTROL_PIXELS(i).gain_BBFB				<= TO_UNSIGNED(25,8);
end loop l1;
CONTROL.CHANNELs(1).BIAS_modulation_increment				<= TO_UNSIGNED(0,24);
CONTROL.CHANNELs(1).FEEDBACK_compensation_gain				<= TO_UNSIGNED(0,16);
CONTROL.CHANNELs(1).BIAS_modulation_amplitude				<= TO_UNSIGNED(0,8);
CONTROL.CHANNELs(1).Loop_control							<= TO_UNSIGNED(0,4);

      -- hold reset state for 100 ns.
		CONTROL.CHANNELs(0).START_STOP			<='0';
      wait for 1000 ns;	
--														  select_TM <=b"0000";

--  	control_GSE.start_stop	<='0';
	wait for CLK_4X_period*500;
		RESET <='0';
      -- insert stimulus here 



--	CONTROL.CHANNELS(0).CONTROL_PIXELS(0).increment			<= TO_UNSIGNED(23763,21);--pixel increment bias 20 bits
--	CONTROL.CHANNELS(0).CONTROL_PIXELS(0).BIAS_amplitude		<= TO_UNSIGNED(256,10);--pixel amplitude bias 11 bits
--	CONTROL.CHANNELS(0).CONTROL_PIXELS(0).PHI_DELAY			<=	TO_UNSIGNED(12,8);-- pixel COMPENSATION DELAY PHASE 8bits
--	CONTROL.CHANNELS(0).CONTROL_PIXELS(0).PHI_INI				<=TO_UNSIGNED(12,8);-- pixel START PHASE 8bits
--	CONTROL.CHANNELS(0).CONTROL_PIXELS(0).PHI_ROTATE			<=TO_UNSIGNED(12,8);--		: unsigned(Nb_bits_PHASE_ROTATE_IQ-1 downto 0);--:="00000000" pixel ROTATEIQ OUPUT PHASE 8bits
--	CONTROL.CHANNELS(0).CONTROL_PIXELS(0).Mode					<=TO_UNSIGNED(0,2);--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
--	CONTROL.CHANNELS(0).CONTROL_PIXELS(0).Clear_BBFB			<='0';--				: std_logic;-- := '1'pixel BBFB reset
--	CONTROL.CHANNELS(0).CONTROL_PIXELS(0).gain_BBFB			<= TO_UNSIGNED(4,8);--:="00001000" pixel BBFB INTEGRATOR GAIN											
--
--	CONTROL.CHANNELS(0).truncation_BIAS		<=TO_UNSIGNED(0,6);--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
--	CONTROL.CHANNELS(0).truncation_BBFB		<=TO_UNSIGNED(0,6);--				: std_logic;-- := '1'pixel BBFB reset
--	CONTROL.CHANNELS(0).select_Input			<=TO_UNSIGNED(1,2);
--	CONTROL.CHANNELS(0).BIAS_on					<=TO_UNSIGNED(1,1);
--	CONTROL.CHANNELS(0).FEEDBACK_on			<=TO_UNSIGNED(1,1);
----	CONTROL.CHANNELS(0).select_Science_data	<=TO_UNSIGNED(1,1);
--	CONTROL.CHANNELS(0).slope_speed				<= TO_UNSIGNED(65534,Size_slope_speed);--:="00001000" pixel BBFB INTEGRATOR GAIN											
--

 wait for CLK_4X_period*10;
--	CONTROL.CHANNELS(0).select_out_data			<=TO_UNSIGNED(0,3);

-- 	CONTROL.CHANNELS(0).START_SENDING_usb_DAQ	<='0';
-- 	CONTROL.CHANNELS(0).START_SENDING_usb_HK	<='1';
--													CONTROL.CHANNELS(0).start				<='1';
													START_SENDING_CONF				<='1';
													HK_usb_Rdy_n <= '0';
													acq_on <='1';
													--				: std_logic;-- := '1'pixel BBFB reset
													     wait for CLK_4X_period*200;
														  --select_HK <="00";
														  START_SENDING_usb_HK <='0';
														  START_SENDING_usb_DAQ <='0';
														  --select_TM <=b"0000";
--														  HK_usb_Rdy_n <= '1';
													     wait for CLK_4X_period*100;
														  CONTROL.CHANNELs(0).START_STOP	<= '1';	
														  START_SENDING_usb_HK <='1';
														  --select_TM <=b"1000";
														  START_SENDING_usb_DAQ <='1';
														  
													     wait for CLK_4X_period*10000;
														  --CONTROL.CHANNELS(0).Send_pulse <='1';	
													     wait for CLK_4X_period*100;
														 -- CONTROL.CHANNELS(0).Send_pulse <='0';													  
														  START_SENDING_usb_HK <='0';
														  START_SENDING_usb_DAQ <='0';
												     wait for CLK_4X_period*1000;
														  
														  START_SENDING_usb_HK <='1';
														  START_SENDING_usb_DAQ <='1';
														  
														  wait for CLK_4X_period*1000;
															HK_usb_Rdy_n <= '0';
-- 													CONTROL_PIXELS(1).start				<='1';
--      wait for CLK_4X_period*100000;
-- 													CONTROL.CHANNELS(0).start				<='0';
--      wait for CLK_4X_period*10000;
-- 													CONTROL.CHANNELS(0).CONTROL_PIXELS(0).Clear_bbfb				<='1';
--      wait for CLK_4X_period*10000;
-- 													CONTROL.CHANNELS(0).CONTROL_PIXELS(0).Clear_bbfb				<='0';
--      wait for CLK_4X_period*10000;
-- 													CONTROL.CHANNELS(0).start				<='1';
    wait;
end process;
------------------------------------------------------------------------------
---- Data logger
------------------------------------------------------------------------------
-- logger_bias: FILE_LOG
	-- generic map(
  		-- size_data	=> Size_bias_TO_DAC,
-- --		size_data => Size_In_Real,
		-- file_name	=> "./simu/OUT_BIAS.log"
	-- )
	-- port map(
		-- CLK			=> CLK_1X,
		-- LOG_START	=> acq_on,
		-- DATA		=> BIAS(0)
-- --		DATA			=> Out_Squid(0)
	-- );

-- logger_feedback: FILE_LOG
	-- generic map(
  		-- size_data	=> Size_feedback_TO_DAC,
		-- file_name	=> "./simu/OUT_FEEDBACK.log"
	-- )
	-- port map(
		-- CLK			=> CLK_1X,
		-- LOG_START	=> acq_on,
		-- DATA		=> feedback(0)
	-- );
--logger_I: FILE_LOG
--	generic map(
--  		size_data	=> Size_science,
--		file_name	=> "./simu/OUT_SQUID.LOG"
--	)
--	port map(
--		CLK			=> CLK_1X,
--		LOG_START	=> acq_on,
--		DATA		=> resize(Out_Squid(0),16)--OUT_SCIENCE_I(0)
--	);
--
--logger_Q: FILE_LOG
--	generic map(
--  		size_data	=> Size_science,
--		file_name	=> "./simu/OUT_SCQ.LOG"
--	)
--	port map(
--		CLK			=> CLK_1X,
--		LOG_START	=> acq_on,
--		DATA		=> OUT_SCIENCE_Q(0)
--	);

END;
