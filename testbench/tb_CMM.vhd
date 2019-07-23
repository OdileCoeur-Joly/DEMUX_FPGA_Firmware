--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:55:46 01/18/2018
-- Design Name:   
-- Module Name:   D:/athena/BBFBU/ASIC_Firmware/Test_DM_V0/07_USB_2CH_CDCM_1ADC_1DAC_CLKDAC_FPGA_BOARD_V0/USB30_DRE_FPGA_BOARD_V0/sources/tb_CMM.vhd
-- Project Name:  USB30_DRE_FPGA_BOARD_V0
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: CMM
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY tb_CMM IS
END tb_CMM;
 
ARCHITECTURE behavior OF tb_CMM IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT CMM
    PORT(
         FPGA_RESET : IN  std_logic;
         HPC1_RESET_GSE : IN  std_logic;
         SYSCLK_P : IN  std_logic;
         SYSCLK_N : IN  std_logic;
         DAC_CLK : IN  std_logic;
         CLK_CDCM_SELECT : IN  std_logic;
         CDCM_PLL_RESET : IN  std_logic;
         HW_RESET : OUT  std_logic;
         CLK_4X : OUT  std_logic;
         CLK_1X : OUT  std_logic;
         CLK_LOCKED_CDCM : OUT  std_logic;
         CLK_LOCKED : OUT  std_logic;
         ENABLE_CLK_1X : OUT  std_logic;
         ENABLE_CLK_1X_DIV64 : OUT  std_logic;
         ENABLE_CLK_1X_DIV128 : OUT  std_logic;
         ONE_SECOND : OUT  std_logic;
         twelve_mili_SECOND : OUT  std_logic;
         sequencer : OUT  unsigned(1 downto 0);
         Chenille : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal FPGA_RESET : std_logic := '0';
   signal HPC1_RESET_GSE : std_logic := '0';
   signal SYSCLK_P : std_logic := '0';
   signal SYSCLK_N : std_logic := '0';
   signal DAC_CLK : std_logic := '0';
   signal CLK_CDCM_SELECT : std_logic := '0';
   signal CDCM_PLL_RESET : std_logic := '0';

 	--Outputs
   signal HW_RESET : std_logic;
   signal CLK_4X : std_logic;
   signal CLK_1X : std_logic;
   signal CLK_LOCKED_CDCM : std_logic;
   signal CLK_LOCKED : std_logic;
   signal ENABLE_CLK_1X : std_logic;
   signal ENABLE_CLK_2X : std_logic;
   signal ENABLE_CLK_1X_DIV32 : std_logic;
   signal ENABLE_CLK_1X_DIV64 : std_logic;
   signal ENABLE_CLK_1X_DIV128 : std_logic;
   signal ONE_SECOND : std_logic;
   signal twelve_mili_SECOND : std_logic;
   signal sequencer : unsigned(1 downto 0):= "00";
   signal Chenille : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant DAC_CLK_period : time := 50 ns;
   constant SYSCLK_period : time := 12.5 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: CMM PORT MAP (
          FPGA_RESET => FPGA_RESET,
          HPC1_RESET_GSE => HPC1_RESET_GSE,
          SYSCLK_P => SYSCLK_P,
          SYSCLK_N => SYSCLK_N,
          DAC_CLK => DAC_CLK,
          CLK_CDCM_SELECT => CLK_CDCM_SELECT,
          HW_RESET => HW_RESET,
          CDCM_PLL_RESET => CDCM_PLL_RESET,
          CLK_4X => CLK_4X,
          CLK_1X => CLK_1X,
          CLK_LOCKED_CDCM => CLK_LOCKED_CDCM,
          CLK_LOCKED => CLK_LOCKED,
          ENABLE_CLK_1X => ENABLE_CLK_1X,
          ENABLE_CLK_1X_DIV64 => ENABLE_CLK_1X_DIV64,
          ENABLE_CLK_1X_DIV128 => ENABLE_CLK_1X_DIV128,
          ONE_SECOND => ONE_SECOND,
          twelve_mili_SECOND => twelve_mili_SECOND,
          sequencer => sequencer,
          Chenille => Chenille
        );

   -- Clock process definitions
   DAC_CLK_process :process
   begin
		DAC_CLK <= '0';
		wait for DAC_CLK_period/2;
		DAC_CLK <= '1';
		wait for DAC_CLK_period/2;
   end process;
 
   SYSCLK_process :process
   begin
		SYSCLK_N <= '0';
		SYSCLK_P <= '1';
		wait for SYSCLK_period/2;
		SYSCLK_N <= '1';
		SYSCLK_P <= '0';

		wait for SYSCLK_period/2;
   end process;
 
 

   -- Stimulus process
   stim_proc: process
   begin		
	FPGA_RESET<='0';
      -- hold reset state for 100 ns.
      wait for 10000 ns;	
	FPGA_RESET<='1';
      -- hold reset state for 100 ns.
      wait for 1000 ns;	
	FPGA_RESET<='0';
      wait for 1000 ns;	
	
	CLK_CDCM_SELECT <='1';
      -- hold reset state for 100 ns.
      wait for 10000 ns;	
	FPGA_RESET<='1';
      wait for 1000 ns;	
	FPGA_RESET<='0';
      -- hold reset state for 100 ns.
      -- hold reset state for 100 ns.
      wait for 1000 ns;	

      wait for DAC_CLK_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
