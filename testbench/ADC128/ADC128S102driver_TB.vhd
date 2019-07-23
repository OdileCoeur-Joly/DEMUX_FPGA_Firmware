--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:04:51 10/08/2015
-- Design Name:   
-- Module Name:   C:/Users/Yann PAROT/Yann_travail/Yann_travail/SUPERCAM/04-Electronique/09-Simulations/01-VHDL/01-ADC128S102/ADC_128S102_driver/ADC128S102driver_TB.vhd
-- Project Name:  ADC_128S102_driver
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ADC128S102_Driver
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.athena_package.all;
use work.util_package.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
                USE IEEE.VITAL_timing.ALL;
                USE IEEE.VITAL_primitives.ALL;
LIBRARY FMF;    USE work.gen_utils.ALL;
 
--use work.ADC128S102_pkg.ALL;
 
ENTITY ADC128S102driver_TB IS
END ADC128S102driver_TB;
 
ARCHITECTURE behavior OF ADC128S102driver_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ADC128S102_Driver
    PORT(
         Reset_n : IN  std_logic;
         clk_20MHz : IN  std_logic;
         Output_register : out   t_register_ADC128;
         Start : IN  std_logic;
         Done : OUT  std_logic;
         ADC_Sclk : OUT  std_logic;
         ADC_Dout : IN  std_logic;
         ADC_Din : OUT  std_logic;
         ADC_Cs_n : OUT  std_logic
        );
    END COMPONENT;
	 
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

    

   --Inputs
   signal Reset 					: std_logic := '1';
   signal clk_4x 					: std_logic := '0';
   signal ENABLE_CLK_1X 		: std_logic := '0';
   signal ENABLE_CLK_1X_DIV32 : std_logic := '0';
   signal ENABLE_CLK_1X_DIV64 : std_logic := '0';
   signal Start : std_logic 	:= '0';
   signal ADC_Dout : std_logic:= '1';
	signal Sequencer				: unsigned(1 downto 0);

 	--Outputs
   signal Output_registers 	: t_register_ADC128;
   signal Done 					: std_logic;
   signal ADC_Sclk 				: std_logic;
   signal ADC_Din 				: std_logic;
   signal ADC_Cs_n 				: std_logic;
	signal	SYSCLK_P 			:  std_logic;
	signal	SYSCLK_N 			:  std_logic;
	signal LOCKED					: std_logic;

   -- Clock period definitions
   constant clk_20MHz_period : time := 50 ns;
--   -- Clock period definitions
   constant CLK_4X_period : time := 40 ns;
   constant SYS_CLK_period : time := 50 ns;
	BEGIN
	
	adc1:	adc128s102
    PORT MAP(
        SCLK  	=> ADC_Sclk,
        CSNeg 	=> ADC_Cs_n,
        DIN   	=> ADC_Din,
        VA    	=> 3.3,
        IN0   	=> 0.1,
        IN1   	=> 0.2,
        IN2   	=> 0.3,
        IN3   	=> 0.4,
        IN4   	=> 0.5,
        IN5  	=> 0.6,
        IN6   	=> 0.7,
        IN7   	=> 0.8,
        DOUT  	=> ADC_Dout
        ); 
		  
	-- Instantiate the Unit Under Test (UUT)
   uut: ADC128S102_controler PORT MAP (
          Reset => Reset,
          clk_4x => clk_4X,
			 ENABLE_CLK_1X => ENABLE_CLK_1X,
          Output_registers => Output_registers,
          Start => Start,
          Done => Done,
          Sclk => ADC_Sclk,
          Dout => ADC_Dout,
          Din => ADC_Din,
          Cs_n => ADC_Cs_n
        );
--   uut:  ADC128S102_Driver PORT MAP (
--          Reset_n => not Reset,
----          clk_4x => clk_4X,
--			 CLK_20MHz => not ENABLE_CLK_1X,
--          Output_register => Output_registers,
--          Start => Start,
--          Done => Done,
--          ADC_Sclk => ADC_Sclk,
--          ADC_Dout => ADC_Dout,
--          ADC_Din => ADC_Din,
--          ADC_Cs_n => ADC_Cs_n
--        );
		  clk_inst : entity work.CLK_CORE
	port map 
		(
		-- Clock in ports
		CLK_IN1_P 	=> SYSCLK_P,
		CLK_IN1_N 	=> SYSCLK_N,
		
		-- Clock out ports
		CLK_OUT1		=> open, 	-- 200 MHz
		CLK_OUT2 	=> CLK_4X,	--100 MHz
		CLK_OUT3 	=> open,	--50 MHz
		CLK_OUT4		=> open,	--25 MHz
		
		-- Status and control signals
		RESET  		=> '0',
		LOCKED 		=> LOCKED
		);
				
--	RESET_HW	<= not LOCKED;
--	DAQ_CLK <= CLK_4X;    -- Clock process definitions
 CMM1:	CMM 
    Port map (
			GLOBAL_CLK 				=> CLK_4X,
         RESET 					=> RESET or not LOCKED,
			ENABLE_CLK_1X			=> ENABLE_CLK_1X,
         ENABLE_CLK_1X_DIV32 	=> ENABLE_CLK_1X_DIV32,
         ENABLE_CLK_1X_DIV64 	=> ENABLE_CLK_1X_DIV64,
			sequencer(0)			=> sequencer(0),
			sequencer(1)			=> sequencer(1),
			chenille					=>	open
);
  
   CLK_SYS_process :process
   begin
		SYSCLK_N <= '0';
		SYSCLK_P <= '1';
		wait for SYS_CLK_period/2;
		SYSCLK_N <= '1';
		SYSCLK_P <= '0';
		wait for SYS_CLK_period/2;
   end process;
 


   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		Reset <= '1';
      wait for 100 ns;	
		Reset <= '0';
      --wait for clk_20MHz_period*10;

      -- insert stimulus here 
--		Free_run_mode <= '0';
		
		wait for 100 ns;
		Start <= '1';
		wait for 100 ns;
		Start <= '1';
		
      wait;
   end process;

END;
