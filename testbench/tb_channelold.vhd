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
   signal CLK_2X : std_logic := '0';
   signal CLK_1X : std_logic := '0';
   signal CLK_1X_DIV2 : std_logic := '0';
   signal ENABLE_CLK_2X : std_logic := '0';
   signal ENABLE_CLK_1X : std_logic := '0';
   signal ENABLE_CLK_1X_DIV32 : std_logic := '0';
   signal ENABLE_CLK_1X_DIV64 : std_logic := '0';
   signal ENABLE_CLK_1X_DIV128 : std_logic := '0';
   signal CLK_1X_DIV64 			: std_logic;
   signal ONE_SECOND				: std_logic;
   signal RESET : std_logic := '1';
--   signal CONTROL_PIXELS : t_CONTROL_PIXELS;
   signal CONTROL_CHANNELS 	:t_CONTROL_CHANNELS;
   signal CONTROL_SPI		 	:t_CONTROL_SPI;
   signal CONTROL_GSE		 	:t_CONTROL_GSE;
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
	signal DR_RHF1201								: std_logic;
	signal SRC_RHF1201							: std_logic;
	signal OE_RHF1201_n							: std_logic;
	signal CLK_RHF1201							: std_logic;
	signal DFS_RHF1201_n							: std_logic;
--	signal FRONT									: std_logic;
--	signal FRONT_STATUS							: std_logic;
	signal rhf1201_ready							: std_logic;
	signal DOUT_RHF1201							: signed(11 downto 0);
	signal CONTROL_RHF1201S						: t_CONTROL_RHF1201S;
	signal STATUS_RHF1201S						: t_STATUS_RHF1201S;
	signal DATA_RHF1201							: signed (11 downto 0);
	signal regCONFIG       						: ARRAY32bits(0 to C_NB_REG_CONF-1):=(others =>(others=>'0'));
	signal REGISTER_NUMBER						: std_logic_vector (32 downto 1):=(others=>'0');
   signal REGISTER_VALUE						: std_logic_vector (32 downto 1):=(others=>'0');
   signal eog										: std_logic;
--	to 4);

	
--    Clock period definitions
   constant CLK_4X_period : time := 10 ns;
--   constant CLK_1X_period : time := 10 ns;
   constant SYS_CLK_period : time := 5 ns;
	component FILE_READ 
  generic (
           stim_file:       string  := "file.dat"
          );
  port(
       CLK              : in  std_logic;
       RST              : in  std_logic;
		 X                : out std_logic_vector(32 downto 1);
       Y                : out std_logic_vector(32 downto 1);
       EOG              : out std_logic
      );
end component;

COMPONENT adc128s102 

    GENERIC (
        -- Interconnect path delays
        tipd_SCLK           : VitalDelayType01  := VitalZeroDelay01;
        tipd_CSNeg          : VitalDelayType01  := VitalZeroDelay01;
        tipd_DIN            : VitalDelayType01  := VitalZeroDelay01;
        -- Propagation delays
        tpd_SCLK_DOUT       : VitalDelayType01Z := UnitDelay01Z;
        tpd_CSNeg_DOUT      : VitalDelayType01Z := UnitDelay01Z;
        -- Setup/hold violation
        tsetup_CSNeg_SCLK   : VitalDelayType    := UnitDelay;
        tsetup_DIN_SCLK     : VitalDelayType    := UnitDelay;
        thold_CSNeg_SCLK    : VitalDelayType    := UnitDelay;
        thold_DIN_SCLK      : VitalDelayType    := UnitDelay;
        -- Puls width checks
        tpw_SCLK_posedge    : VitalDelayType    := UnitDelay;
        tpw_SCLK_negedge    : VitalDelayType    := UnitDelay;
        -- Period checks
        tperiod_SCLK_posedge: VitalDelayType    := UnitDelay;
        -- generic control parameters
        InstancePath        : STRING            := DefaultInstancePath;
        TimingChecksOn      : BOOLEAN           := DefaultTimingChecks;
        MsgOn               : BOOLEAN           := DefaultMsgOn;
        XOn                 : BOOLEAN           := DefaultXon;
        -- For FMF SDF technology file usage
        TimingModel         : STRING            := DefaultTimingModel
        );

    PORT (
        SCLK  : IN  std_ulogic := 'U';
        CSNeg : IN  std_ulogic := 'U';
        DIN   : IN  std_ulogic := 'U';
        VA    : IN  real       := 2.7;
        IN0   : IN  real       := 0.0;
        IN1   : IN  real       := 0.0;
        IN2   : IN  real       := 0.0;
        IN3   : IN  real       := 0.0;
        IN4   : IN  real       := 0.0;
        IN5   : IN  real       := 0.0;
        IN6   : IN  real       := 0.0;
        IN7   : IN  real       := 0.0;
        DOUT  : OUT std_ulogic := 'U'
        );
end component;

    
 
BEGIN
	
--CLK_1X <= ENABLE_CLK_1X;
	clk_inst : entity work.CLK_CORE
	port map 
		(
		-- Clock in ports
		CLK_IN1_P 	=> SYSCLK_P,
		CLK_IN1_N 	=> SYSCLK_N,
		
		-- Clock out ports
		CLK_OUT1		=> CLK_4X, 	-- 80 MHz
		CLK_OUT2 	=> CLK_1X,	--20 MHz
		-- Status and control signals
		RESET  		=> '0',
		LOCKED 		=> LOCKED
		);
				
	RESET_HW	<= not LOCKED;
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
 	adc1:	adc128s102
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
ADC128 : ADC128S102_controler
	PORT MAP 
			(
          Reset			 	=> Reset,
          clk_4X	 		 	=> clk_4X,
			 ENABLE_CLK_1X	 	=> ENABLE_CLK_1X,
          Output_registers => ADC128_registers,
          Read_register		=> ADC128_Read_register,
          Start 				=> ADC128_Start,
          Done 				=> ADC128_Done,
          Sclk		 			=> SCLK_ADC128,
          Dout		 			=> DOUT_ADC128,
          Din		 			=> DIN_ADC128,
          Cs_n 				=> CS_ADC128_N
			);


			
ADC128_Start <= ADC128_Start_HK_USB30 ;	
ADC128_Read_register <= ADC128_Read_register_HK;

ADC_RHF1201: RHF1201_controler 
    Port MAP 
			(
 			CLK_4X				=> CLK_4X,
 			CLK_1X				=> CLK_1X,
			ENABLE_CLK_1X		=> ENABLE_CLK_1X,
         RESET					=> RESET,
			CONTROL_RHF1201	=> CONTROL_RHF1201S(0),
			STATUS_RHF1201		=> STATUS_RHF1201S(0),
		ADC_ON				=> control_channels(0).ADC_ON,
         OUT_OF_RANGE_ADC	=> OOR_RHF1201,
         OUT_OF_RANGE 		=> OUT_OF_RANGE_RHF1201_int, 
			DIN					=> DATA_RHF1201,
         DOUT					=> DOUT_RHF1201,
         DATA_READY			=> DR_RHF1201,
         CLOCK_TO_ADC		=> CLK_RHF1201,
         CLOCK_FROM_ADC		=> '0',
			ADC_READY			=>	RHF1201_READY,
         OE_N 					=> OE_RHF1201_N,
         SLEW_RATE_CONTROL => SRC_RHF1201,
         DATA_FORMAT_SEL_N => DFS_RHF1201_N
			);
DR_RHF1201 <= CLK_RHF1201;
OOR_RHF1201 <= std_logic(DATA_RHF1201 (11));
----------------------------------------------------------------------------
--	
-- USB 3.0 link manager
--
----------------------------------------------------------------------------
USB30_manager : USB30_links_manager
    Port map( 
-- RESET	
		RESET						=> RESET,
-- CLOCKS	
		CLK_4X						=> CLK_4X,
		CLK_1X						=> CLK_1X, 					-- clock for usb 3.0 controler (80Mhz/4= 20MHz)
         ENABLE_CLK_1X_DIV64 	=> ENABLE_CLK_1X_DIV64,
		LOOP_ON						=> '0',
-- config_out
		regCONFIG					=> regCONFIG,
		CONTROL_GSE					=> CONTROL_GSE,
		CONTROL_CHANNELS			=> CONTROL_CHANNELS,
		CONTROL_RHF1201S			=> CONTROL_RHF1201S,
		CONTROL_SPI					=> CONTROL_SPI,
		Pixels_rd_conf				=> open,--Pixels_rd_conf, drive from VIO#################################################
		CONF_ADDRESS_out			=> open,
		CONF_RECEIVED_DATA_out		=> open,

-- Data control For XIFU selected TM data
		TM_DATA_TO_GSE				=> TM_DATA_TO_GSE,
		wr_en_TM_fifo				=> wr_en_TM_fifo,

-- Data control For XIFU selected HK data
		HK_DATA_TO_GSE				=> HK_DATA_TO_GSE,
		wr_en_HK_fifo				=> wr_en_HK_fifo,
		almost_full_HK_fifo			=> almost_full_HK_fifo,
		
-- TO USB_3.0 manager
      DAQ_CLK_usb_OUT				=> DAQ_CLK_usb_OUT,
-- DAQ 32 bits 10MHz for science link
      DAQ_usb_Data					=> DAQ_usb_Data,
      DAQ_usb_Rdy_n					=> DAQ_usb_Rdy_n,
      DAQ_usb_WR					=> DAQ_usb_WR,
--      START_SENDING_usb_DAQ	=> control_channels(0).START_SENDING_usb_DAQ,
-- DATA SENDING 10MHz 8 bits for HK link
      HK_usb_Data					=> HK_usb_Data,
      HK_usb_Rdy_n					=> HK_usb_Rdy_n,
      HK_usb_WR						=> HK_usb_WR,
--      START_SENDING_usb_HK		=> control_channels(0).START_SENDING_usb_HK,
-- DATA RECEIVED 10MHz 8 bits for Config link
      Bad_conf_register_write 		=> Bad_conf_register_write,
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
		-- control_channels			=> open,--control_channels,
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


TM_OUTPUT_SELECT: Select_output_to_TM
 
    Port MAP( 
-- FROM XIFU
	OUT_SCIENCE_I			=>	Out_Science_I,
	OUT_SCIENCE_Q			=>	Out_Science_Q,
	IN_PHYS					=>	Out_Squid,
   FEEDBACK					=>	FEEDBACK,
   BIAS						=>	BIAS,
			
			
-- OUTPUT SELECTOR : AT CLK_1X 20MHz, up to 3 32 bits Words
	select_TM 				=> control_GSE.select_TM,
	START_SENDING_TM		=> control_GSE.START_SENDING_TM,
	SW_TM					=>	open,
	
-- CLOCKS	
	CLK_4X					=>	CLK_4X,
	ENABLE_CLK_1X			=>	ENABLE_CLK_1X,
	ENABLE_CLK_2X			=>	ENABLE_CLK_2X,
	ENABLE_CLK_1X_DIV32		=>	ENABLE_CLK_1X_DIV32,
	ENABLE_CLK_1X_DIV64		=>	ENABLE_CLK_1X_DIV64,
	ENABLE_CLK_1X_DIV128	=>	ENABLE_CLK_1X_DIV128,
			
-- TO PCIE manager
-- RESET
	RESET					=>	RESET,
	TM_DATA_TO_GSE			=>  TM_DATA_TO_GSE,
	WR_en_TM_fifo			=>  WR_en_TM_fifo
	);
		
-- PCIE HK Output selector			
----------------------------------------------------------------------------
--	
-- PCIE HK BUS Output selector (ADC128, CONFIG, COUNTER) automatic(2s) or not
--
----------------------------------------------------------------------------

HK_OUTPUT_SELECT: Select_output_to_HK
 
    Port MAP( 
-- FROM XIFU
		ADC128_registers		=> ADC128_ALL_registers,
		ADC128_DONE				=> ADC128_ALL_DONE,
		ADC128_Read_Register 	=> ADC128_Read_Register_HK,
		ADC128_START_HK	 		=> ADC128_START_HK,
		regCONFIG				=> regCONFIG,
		STATUS					=> STATUS_XIFU,
		STATUS_RHF1201S			=> STATUS_RHF1201S,
		STATUS_SPI				=> STATUS_SPI,
	
-- OUTPUT SELECTOR : AT CLK_1X 25MHz, up to 3 32 bits Words
	select_HK					=> "11",
	START_SENDING_HK			=> START_SENDING_usb_HK,

-- RESET
		RESET					=>	RESET,
	
-- CLOCKS	
		CLK_4X					=>	CLK_4X,
		ENABLE_CLK_1X_DIV64		=> ENABLE_CLK_1X_DIV64, -- clock for usb 3.0 controler (80Mhz/64= 0.3MHz)
		ONE_SECOND				=> ONE_SECOND,			
-- TO USB 3.0 manager

		HK_DATA_TO_GSE			=> HK_DATA_TO_GSE,
		WR_en_HK_fifo			=> WR_en_HK_fifo,
		almost_full_HK_fifo		=> almost_full_HK_fifo
		);
				
--HK_CLK_to_usb_fifo <= CLK_1X_DIV2;
----------------------------------------------------------------------------------------------------
-- INTERNAL SQUID TO TEST CHANNEL
----------------------------------------------------------------------------------------------------

	label_Internal_Squid_0 : Squid_generic
	 Generic map
		(
		Size_in 		=>  Size_bias_to_dac, 			
		Size_out 	=> Size_In_Real		
		)
    Port map
		( 
		CLK_4X 			=> CLK_4X,
		ENABLE_CLK_1X 	=> ENABLE_CLK_1X,
		RESET 			=> RESET,-- reset a 1!!!!
		In_Squid 		=> BIAS(0),--(others => '0')
		In_Feedback	 => FEEDBACK(0),

		Out_Squid	=> Out_Squid(0)
		);
	-- Instantiate the Unit Under Test (UUT)
   channel_0: channel PORT MAP (
          CLK_4X => CLK_4X,
          ENABLE_CLK_1X => ENABLE_CLK_1X,
          ENABLE_CLK_1X_DIV32 => ENABLE_CLK_1X_DIV32,
			 ENABLE_CLK_1X_DIV64	=> ENABLE_CLK_1X_DIV64,
			 ENABLE_CLK_1X_DIV128	=> ENABLE_CLK_1X_DIV128,
          RESET => RESET,
			 SW_TM => '1',
		CONSTANT_FB				=>C_CONSTANT_FB,
          CONTROL_CHANNEL => CONTROL_CHANNELS(0),
			 sequencer => sequencer,
          IN_PHYS => Out_Squid(0),
          BIAS => BIAS(0),
          FEEDBACK => FEEDBACK(0),
          OUT_SCIENCE_I => OUT_SCIENCE_I(0),
          OUT_SCIENCE_Q => OUT_SCIENCE_Q(0)
        );

	label_Internal_Squid_1 : Squid_generic
	 Generic map
		(
		Size_in 		=>  Size_bias_to_dac, 			
		Size_out 	=> Size_In_Real		
		)
    Port map
		( 
		CLK_4X 			=> CLK_4X,
		ENABLE_CLK_1X 	=> ENABLE_CLK_1X,
		RESET 			=> RESET,-- reset a 1!!!!
		In_Squid 	=> BIAS(1),
		In_Feedback => FEEDBACK(1),

		Out_Squid	=> Out_Squid(1)
		);
	-- Instantiate the Unit Under Test (UUT)
   channel_1: channel PORT MAP (
          CLK_4X => CLK_4X,
          ENABLE_CLK_1X => ENABLE_CLK_1X,
          ENABLE_CLK_1X_DIV32 => ENABLE_CLK_1X_DIV32,
			 ENABLE_CLK_1X_DIV64	=> ENABLE_CLK_1X_DIV64,
			 ENABLE_CLK_1X_DIV128	=> ENABLE_CLK_1X_DIV128,
          RESET => RESET,
			 SW_TM => '1',
		CONSTANT_FB				=>C_CONSTANT_FB,
         CONTROL_CHANNEL => CONTROL_CHANNELS(1),
			 sequencer => sequencer,
          IN_PHYS => Out_Squid(1),
          BIAS => BIAS(1),
          FEEDBACK => FEEDBACK(1),
          OUT_SCIENCE_I => OUT_SCIENCE_I(1),
          OUT_SCIENCE_Q => OUT_SCIENCE_Q(1)
        );
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
CMM1:	CMM 
    Port map (
			GLOBAL_CLK 				=> CLK_4X,
         RESET 					=> RESET_HW,
--			CLK_1X_DIV2				=> CLK_1X_DIV2,
			ENABLE_CLK_2X			=> ENABLE_CLK_2X,
			ENABLE_CLK_1X			=> ENABLE_CLK_1X,
         ENABLE_CLK_1X_DIV32 	=> ENABLE_CLK_1X_DIV32,
         ENABLE_CLK_1X_DIV64 	=> ENABLE_CLK_1X_DIV64,
         ENABLE_CLK_1X_DIV128	=> ENABLE_CLK_1X_DIV128,
			ONE_SECOND				=> ONE_SECOND,
			PULSE						=> CLK_1X_DIV64,
			sequencer(0)			=> sequencer(0),
			sequencer(1)			=> sequencer(1),
			chenille					=>	chenille
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
--   -- Clock process definitions
--   CLK_4X_process :process
--   begin
--		CLK_4X <= '0';
--		wait for CLK_4X_period/2;
--		CLK_4X <= '1';
--		wait for CLK_4X_period/2;
--   end process;
-- 
--   CLK_1X_process :process
--   begin
--		CLK_1X <= '0';
--		wait for CLK_1X_period/2;
--		CLK_1X <= '1';
--		wait for CLK_1X_period/2;
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
		else 
			if (rising_edge(CLK_4X)) then
				if (ENABLE_CLK_1X ='1') then
				DATA_RHF1201			<= DATA_RHF1201 + 1;
				end if;
			end if;
		end if;
	end process;
-- input_stim: FILE_READ
-- generic map(
          -- stim_file =>  "./sources/testbench/sim3.dat"
  -- )
  -- port map(
       -- CLK      => clk_1X,
       -- RST      => RESET,
		 -- X			 => REGISTER_NUMBER,
       -- Y        => REGISTER_VALUE,
       -- EOG      => eog
      -- );
-- regCONFIG (to_integer(unsigned(REGISTER_NUMBER))) <= REGISTER_VALUE;
	-- -- =============================================================
	-- -- WRITE REGISTERS PROCESS ATTENTION LES REGISTRES CHANGENT EN USB30
	-- -- =============================================================
	-- control_GSE.select_HK					<= unsigned(regCONFIG(0) (1 downto 0));
	-- control_GSE.Start_Sending_HK			<= regCONFIG(0) (2);
	-- control_GSE.select_TM					<= unsigned(regCONFIG(0) (6 downto 3));
	-- control_GSE.Start_Sending_TM			<= regCONFIG(0) (7);
	-- GENERATE_CHANNELS_register : for C in 0 to Nb_channel-1 generate	
	-- control_channels(C).Feedback_Truncation				<= unsigned(regCONFIG(1+(C*(Nb_pixel*2+4))) (1 downto 0)); -- 1 registre GSE + C*( 2 registres par pixel*NB pixel + (2 registres conf channel + 2 registres conf test pixel))
	-- control_channels(C).Bias_Truncation					<= unsigned(regCONFIG(1+(C*(Nb_pixel*2+4))) (3 downto 2));
	-- control_channels(C).Bias_Slope_Speed				<= unsigned(regCONFIG(1+(C*(Nb_pixel*2+4))) (5 downto 4));
	-- control_channels(C).FEEDBACK_Enable					<= 			regCONFIG(1+(C*(Nb_pixel*2+4))) (6);
	-- control_channels(C).BIAS_Enable						<= 			regCONFIG(1+(C*(Nb_pixel*2+4))) (7);
	-- control_channels(C).select_Input					<= unsigned(regCONFIG(1+(C*(Nb_pixel*2+4))) (9 downto 8));
	-- control_channels(C).DACF_ON							<= 			regCONFIG(1+(C*(Nb_pixel*2+4))) (10);
	-- control_channels(C).DACB_ON							<= 			regCONFIG(1+(C*(Nb_pixel*2+4))) (11);
	-- CONTROL_channels(C).ADC_ON							<= 			regCONFIG(1+(C*(Nb_pixel*2+4))) (12);
	-- control_channels(C).Start_Stop						<= 			regCONFIG(1+(C*(Nb_pixel*2+4))) (16);
	-- control_channels(C).Loop_Control					<= unsigned(regCONFIG(1+(C*(Nb_pixel*2+4))) (31 downto 28));
	-- control_channels(C).feedback_reverse				<= 			regCONFIG(2+(C*(Nb_pixel*2+4))) (15);
	-- control_channels(C).FEEDBACK_compensation_gain		<= unsigned(regCONFIG(2+(C*(Nb_pixel*2+4))) (31 downto 16));
	-- GENERATE_PIXELS_register : for N in 0 to Nb_pixel-2 generate
	-- control_channels(C).control_pixels(N).BIAS_amplitude	<= unsigned(regCONFIG(3+N*2+(C*(Nb_pixel*2+4)))(7 downto 0));
	-- control_channels(C).control_pixels(N).gain_BBFB			<= unsigned(regCONFIG(3+N*2+(C*(Nb_pixel*2+4)))(15 downto 8));
	-- control_channels(C).control_pixels(N).PHI_ROTATE		<= unsigned(regCONFIG(3+N*2+(C*(Nb_pixel*2+4)))(23 downto 16));
	-- control_channels(C).control_pixels(N).PHI_DELAY			<= unsigned(regCONFIG(3+N*2+(C*(Nb_pixel*2+4)))(31 downto 24));
	-- control_channels(C).control_pixels(N).PHI_INITIAL		<= unsigned(regCONFIG(4+N*2+(C*(Nb_pixel*2+4)))(11 downto 0));
	-- control_channels(C).control_pixels(N).increment			<= unsigned(regCONFIG(4+N*2+(C*(Nb_pixel*2+4)))(counter_size-1+12 downto 12));
	-- control_channels(C).control_pixels(N).SW1				<= '0';
	-- control_channels(C).control_pixels(N).SW2				<= "00";
-- --	control_channels(C).control_pixels(N).BIAS_Modulation_Increment	<= (others=>'0');
-- --	control_channels(C).control_pixels(N).BIAS_Modulation_Amplitude	<= (others=>'0');

	-- end generate GENERATE_PIXELS_register;
-- -- TEST PIXEL CONFIG ---------------------------------------------------------------------------------------------------------------------------------------------
	-- control_channels(C).control_pixels(Nb_pixel-1).BIAS_amplitude					<= unsigned(regCONFIG(3+(Nb_pixel-1)*2+(C*(Nb_pixel*2+4))) (7 downto 0));
	-- control_channels(C).control_pixels(Nb_pixel-1).gain_BBFB						<= unsigned(regCONFIG(3+(Nb_pixel-1)*2+(C*(Nb_pixel*2+4))) (15 downto 8));
	-- control_channels(C).control_pixels(Nb_pixel-1).PHI_ROTATE						<= unsigned(regCONFIG(3+(Nb_pixel-1)*2+(C*(Nb_pixel*2+4))) (23 downto 16));
	-- control_channels(C).control_pixels(Nb_pixel-1).PHI_DELAY						<= unsigned(regCONFIG(3+(Nb_pixel-1)*2+(C*(Nb_pixel*2+4))) (31 downto 24));
	-- control_channels(C).control_pixels(Nb_pixel-1).PHI_INITIAL						<= unsigned(regCONFIG(4+(Nb_pixel-1)*2+(C*(Nb_pixel*2+4))) (11 downto 0));
	-- control_channels(C).control_pixels(Nb_pixel-1).increment						<= unsigned(regCONFIG(4+(Nb_pixel-1)*2+(C*(Nb_pixel*2+4))) (counter_size-1+12 downto 12));
	-- control_channels(C).BIAS_Modulation_Increment									<= unsigned(regCONFIG(5+(Nb_pixel-1)*2+(C*(Nb_pixel*2+4))) (23 downto 0));
	-- control_channels(C).BIAS_Modulation_Amplitude									<= unsigned(regCONFIG(6+(Nb_pixel-1)*2+(C*(Nb_pixel*2+4))) (7 downto 0));
	-- control_channels(C).control_pixels(Nb_pixel-1).SW1								<= 			regCONFIG(6+(Nb_pixel-1)*2+(C*(Nb_pixel*2+4))) (8);
	-- control_channels(C).control_pixels(Nb_pixel-1).SW2								<= unsigned(regCONFIG(6+(Nb_pixel-1)*2+(C*(Nb_pixel*2+4))) (10 downto 9));
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- CONTROL_RHF1201S(C).DATA_FORMAT_SEL_N		<= 			regCONFIG(1+(Nb_channel*(Nb_pixel*2+4)))(24+C*3);
	-- CONTROL_RHF1201S(C).SLEW_RATE_CONTROL		<= 			regCONFIG(1+(Nb_channel*(Nb_pixel*2+4)))(25+C*3);
-- end generate GENERATE_CHANNELS_register;

	-- CONTROL_SPI.DAC_RESET					<=		regCONFIG(1+(Nb_channel*(Nb_pixel*2+4)))(29);
	-- CONTROL_SPI.CLK_CDCM_SELECT				<= 		regCONFIG(1+(Nb_channel*(Nb_pixel*2+4)))(30);
	-- CONTROL_SPI.Select_SPI_Channel			<=		regCONFIG(1+(Nb_channel*(Nb_pixel*2+4)))(4 downto 0);
	-- CONTROL_SPI.SPI_Write					<= 		regCONFIG(1+(Nb_channel*(Nb_pixel*2+4)))(5);
	-- CONTROL_SPI.SPI_data_to_send			<= 		regCONFIG(2+(Nb_channel*(Nb_pixel*2+4)));

process
	begin
	-- =============================================================
	-- WRITE REGISTERS PROCESS ATTENTION LES REGISTRES CHANGENT EN USB30
	-- =============================================================

	
l1: for i in 0 to  4 loop
regCONFIG(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(i+1,32));
end loop L1;
      hold reset state for 100 ns.
		CONTROL_CHANNELS(0).start			<='0';
		CONTROL_PIXELS(1).start			<='0';
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).increment			<= TO_UNSIGNED(3277,counter_size);--pixel increment bias 20 bits
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).BIAS_amplitude	<= TO_UNSIGNED(1023,10);--pixel amplitude bias 10 bits
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).PHI_DELAY			<=	TO_UNSIGNED(500,8);-- pixel COMPENSATION DELAY PHASE 8bits
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).PHI_INI			<=TO_UNSIGNED(0,8);-- pixel START PHASE 8bits
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).PHI_ROTATE		<=TO_UNSIGNED(0,8);--		: unsigned(Nb_bits_PHASE_ROTATE_IQ-1 downto 0);--:="00000000" pixel ROTATEIQ OUPUT PHASE 8bits
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).Mode				<=TO_UNSIGNED(0,2);--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).Clear_BBFB		<='0';--				: std_logic;-- := '1'pixel BBFB reset
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).gain_BBFB			<= TO_UNSIGNED(10,8);--:="00001000" pixel BBFB INTEGRATOR GAIN											
	
	CONTROL_CHANNELS(0).truncation_BIAS			<=TO_UNSIGNED(0,6);--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
	CONTROL_CHANNELS(0).truncation_BBFB			<=TO_UNSIGNED(0,6);--				: std_logic;-- := '1'pixel BBFB reset
	CONTROL_CHANNELS(0).select_Input				<=TO_UNSIGNED(1,2);
--	CONTROL_CHANNELS(0).select_outputA			<=TO_UNSIGNED(0,2);
--	CONTROL_CHANNELS(0).select_OutputB			<=TO_UNSIGNED(0,2);
	CONTROL_CHANNELS(0).BIAS_on					<=TO_UNSIGNED(1,1);
	CONTROL_CHANNELS(0).DAC_on						<=TO_UNSIGNED(3,2);
	CONTROL_CHANNELS(0).FEEDBACK_on				<=TO_UNSIGNED(1,1);
	CONTROL_CHANNELS(0).START_SENDING_usb_DAQ	<='1';
	CONTROL_CHANNELS(0).START_SENDING_usb_HK	<='1';
	control_channels(0).start	<='1';
--	CONTROL_CHANNELS(0).select_out_data_PCIEX	<=TO_UNSIGNED(7,3);
	CONTROL_CHANNELS(0).select_out_data_USB30	<=TO_UNSIGNED(7,3);
	CONTROL_CHANNELS(0).select_out_to_HK_USB30<=TO_UNSIGNED(7,3);
	CONTROL_CHANNELS(0).slope_speed				<= TO_UNSIGNED(10000,Size_slope_speed);--:="00001000" pixel BBFB INTEGRATOR GAIN	

      wait for 1000 ns;	

--  	control_GSE.start_stop	<='0';
	wait for CLK_4X_period*500;
		RESET <='0';
      -- insert stimulus here 



	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).increment			<= TO_UNSIGNED(23763,21);--pixel increment bias 20 bits
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).BIAS_amplitude		<= TO_UNSIGNED(256,10);--pixel amplitude bias 11 bits
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).PHI_DELAY			<=	TO_UNSIGNED(12,8);-- pixel COMPENSATION DELAY PHASE 8bits
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).PHI_INI				<=TO_UNSIGNED(12,8);-- pixel START PHASE 8bits
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).PHI_ROTATE			<=TO_UNSIGNED(12,8);--		: unsigned(Nb_bits_PHASE_ROTATE_IQ-1 downto 0);--:="00000000" pixel ROTATEIQ OUPUT PHASE 8bits
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).Mode					<=TO_UNSIGNED(0,2);--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).Clear_BBFB			<='0';--				: std_logic;-- := '1'pixel BBFB reset
	CONTROL_CHANNELS(0).CONTROL_PIXELS(0).gain_BBFB			<= TO_UNSIGNED(4,8);--:="00001000" pixel BBFB INTEGRATOR GAIN											

	CONTROL_CHANNELS(0).truncation_BIAS		<=TO_UNSIGNED(0,6);--			: unsigned(Nb_bits_CONFIG_BBFB-1 downto 0);-- :="010"pixels BBFB CONFIG (1 for all) 3 bits													start_stop				: STD_LOGIC;
	CONTROL_CHANNELS(0).truncation_BBFB		<=TO_UNSIGNED(0,6);--				: std_logic;-- := '1'pixel BBFB reset
	CONTROL_CHANNELS(0).select_Input			<=TO_UNSIGNED(1,2);
	CONTROL_CHANNELS(0).BIAS_on					<=TO_UNSIGNED(1,1);
	CONTROL_CHANNELS(0).FEEDBACK_on			<=TO_UNSIGNED(1,1);
--	CONTROL_CHANNELS(0).select_Science_data	<=TO_UNSIGNED(1,1);
	CONTROL_CHANNELS(0).slope_speed				<= TO_UNSIGNED(65534,Size_slope_speed);--:="00001000" pixel BBFB INTEGRATOR GAIN											


 wait for CLK_4X_period*10;
--	CONTROL_CHANNELS(0).select_out_data			<=TO_UNSIGNED(0,3);

-- 	CONTROL_CHANNELS(0).START_SENDING_usb_DAQ	<='0';
-- 	CONTROL_CHANNELS(0).START_SENDING_usb_HK	<='1';
--													CONTROL_CHANNELS(0).start				<='1';
													START_SENDING_CONF				<='1';
													HK_usb_Rdy_n <= '0';
													acq_on <='1';
--													control_GSE.start_stop	<='1';
													     wait for CLK_4X_period*10001;
														  START_SENDING_usb_HK <='0';
														  START_SENDING_usb_DAQ <='0';
														  HK_usb_Rdy_n <= '0';
													     wait for CLK_4X_period*5000;
														  	
														  START_SENDING_usb_HK <='1';
														  START_SENDING_usb_DAQ <='1';
														  
													     wait for CLK_4X_period*8800;
														  HK_usb_Rdy_n <= '1';
														  START_SENDING_usb_HK <='1';
														  START_SENDING_usb_DAQ <='0';
												     wait for CLK_4X_period*1000;
														  HK_usb_Rdy_n <= '0';
														  START_SENDING_usb_HK <='1';
														  START_SENDING_usb_DAQ <='1';
														  
														  wait for CLK_4X_period*10000;
															HK_usb_Rdy_n <= '0';
-- 													CONTROL_PIXELS(1).start				<='1';
--      wait for CLK_4X_period*100000;
-- 													CONTROL_CHANNELS(0).start				<='0';
--      wait for CLK_4X_period*10000;
-- 													CONTROL_CHANNELS(0).CONTROL_PIXELS(0).Clear_bbfb				<='1';
--      wait for CLK_4X_period*10000;
-- 													CONTROL_CHANNELS(0).CONTROL_PIXELS(0).Clear_bbfb				<='0';
--      wait for CLK_4X_period*10000;
-- 													CONTROL_CHANNELS(0).start				<='1';
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
