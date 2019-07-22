----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : CMM- rtl 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Clock management Module
--						 Create the enables clocks and the sequencer
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity CMM is
    Port 
	(
	FPGA_RESET 				: in  std_logic;
	HPC1_RESET_GSE			: in  std_logic;
	SYSCLK_P 				: in  std_logic;-- Clock from FPGA_BOARD 200MHz
	SYSCLK_N 				: in  std_logic;-- Clock from FPGA_BOARD 200MHz
	DAC_CLK 				: in  std_logic;-- Clock from DAC after CDCM init and DAC reset
	CLK_CDCM_SELECT			: in  std_logic;
	CDCM_PLL_RESET			: in  std_logic;-- DAC Reset from control system
	HW_RESET				: out std_logic;-- Reset from PLL internal CLK_LOCKED
	CLK_4X					: out std_logic;
	CLK_1X					: out std_logic;
	CLK_LOCKED_CDCM			: out std_logic;
	CLK_LOCKED_200MHz		: out std_logic;
	ENABLE_CLK_1X			: out STD_LOGIC;
	ENABLE_CLK_2X			: out STD_LOGIC;
	ENABLE_CLK_1X_DIV4		: out STD_LOGIC;
	ENABLE_CLK_1X_DIV16		: out STD_LOGIC;
	ENABLE_CLK_1X_DIV64		: out STD_LOGIC;
    ENABLE_CLK_1X_DIV128	: out STD_LOGIC;
	ONE_SECOND 				: out STD_LOGIC;
	twelve_mili_SECOND		: out STD_LOGIC;
	Chenille				: out std_logic_vector (7 downto 0)
);
end CMM;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.CMM.Behavioral.svg
architecture Behavioral of CMM is
	signal CLK_1X_SYS		: std_logic;
	signal CLK_1X_CDCM		: std_logic;
	signal CLK_4X_SYS		: std_logic;
	signal CLK_4X_CDCM		: std_logic;
	signal CLK_1Xi			: std_logic;
	signal CLK_4Xi			: std_logic;

	signal LOCKED			: std_logic;
	signal CLKLOCKEDi		: std_logic;
	signal ONE_SECONDi		: std_logic;
	signal HW_RESETi		: std_logic;
	signal HW_RESETi_delayed: std_logic;
	signal EXT_RESET		: std_logic;
	signal cmpt_sequencer	: unsigned (29 downto 0);
	signal chenille_int		: std_logic_vector (7 downto 0);

begin
	CLK_4X				<= CLK_4Xi;-- test at 1X
	CLK_1X				<= CLK_1Xi;
--	HW_RESET			<= HW_RESETi;
	CLK_LOCKED_200MHz	<= CLKLOCKEDi;
	-- ***************************************************************
	-- LOCAL ASSIGN
	-- ***************************************************************
--	CLKLOCKEDi	<= LOCKED and IDELAY_RDY;
	CLKLOCKEDi	<= LOCKED;
	EXT_RESET	<= FPGA_RESET or (not LOCKED) or HPC1_RESET_GSE;
--	=============================================================
--
-- =============================================================
clk_FPGA : entity work.CLK_CORE_FPGA_BOARD
	port map 
		(
		-- Clock in ports
		CLK_IN1_P 	=> SYSCLK_P,-- 200 MHz
		CLK_IN1_N 	=> SYSCLK_N,-- 200 MHz
		
		-- Clock out ports
		CLK_OUT1 	=> CLK_1X_SYS,	--20 MHz
		CLK_OUT2 	=> CLK_4X_SYS,	--80 MHz
		
		-- Status and control signals
		RESET  		=> '0',
		LOCKED 		=> LOCKED
		);
clk_CDCM : entity work.CLK_CORE_CDCM
	port map 
		(
		-- Clock in ports
		CLK_IN1	 	=> DAC_CLK,-- 78.12 MHz
--		CLK_IN1_N 	=> SYSCLK_N,
		
		-- Clock out ports
		CLK_OUT1 	=> CLK_1X_CDCM,	--19.53 MHz
		CLK_OUT2 	=> CLK_4X_CDCM,	--78.12 MHz
		
		-- Status and control signals
		RESET  		=> CDCM_PLL_RESET,
		LOCKED 		=> CLK_LOCKED_CDCM
		);
BUFGMUX_CLK_1X : BUFGMUX
   	generic map(
   		CLK_SEL_TYPE => "SYNC"
   	)
   port map (
      O 	=> CLK_1Xi,   -- 1-bit output: Clock buffer output
      I0 	=> CLK_1X_SYS, -- 1-bit input: Clock buffer input (S=0)
      I1 	=> CLK_1X_CDCM, -- 1-bit input: Clock buffer input (S=1)
      S 	=> CLK_CDCM_SELECT    -- 1-bit input: Clock buffer select
   );
BUFGMUX_CLK_4X : BUFGMUX
   	generic map(
   		CLK_SEL_TYPE => "SYNC"
   	)
   port map (
      O 	=> CLK_4Xi,   -- 1-bit output: Clock buffer output
      I0 	=> CLK_4X_SYS, -- 1-bit input: Clock buffer input (S=0)
      I1 	=> CLK_4X_CDCM, -- 1-bit input: Clock buffer input (S=1)
      S 	=> CLK_CDCM_SELECT    -- 1-bit input: Clock buffer select
   );

P_clk_div: process(HW_RESETi, CLK_4Xi)
	begin
		if (HW_RESETi = '1') then
		cmpt_sequencer <= (others=>'0');
		chenille_int			<= "10000000";
		ENABLE_CLK_1X  			<= '1';
		ENABLE_CLK_2X  			<= '1';
		ENABLE_CLK_1X_DIV4		<= '1';
		ENABLE_CLK_1X_DIV16		<= '1';
		ENABLE_CLK_1X_DIV64  	<= '1';
		ENABLE_CLK_1X_DIV128  	<= '1';
		ONE_SECONDi  			<= '0';
		twelve_mili_SECOND  	<= '0';
		elsif (rising_edge(CLK_4Xi)) then
--				ENABLE_CLK_1X  		<= '1';
			cmpt_sequencer			<= cmpt_sequencer + 1 ;
			if (cmpt_sequencer(1 downto 0)= b"10") then
				ENABLE_CLK_1X  		<= '1';
			else 
				ENABLE_CLK_1X  		<= '0';
			end if;
			if (cmpt_sequencer(0) = '0') then
				ENABLE_CLK_2X  		<= '1';
			else 
				ENABLE_CLK_2X  		<= '0';
			end if;
			if (cmpt_sequencer(3 downto 0)= b"1110") then
				ENABLE_CLK_1X_DIV4  		<= '1';
			else 
				ENABLE_CLK_1X_DIV4  		<= '0';
			end if;
			if (cmpt_sequencer(5 downto 0)= b"11_1110") then
				ENABLE_CLK_1X_DIV16  		<= '1';
			else 
				ENABLE_CLK_1X_DIV16  		<= '0';
			end if;
			if (cmpt_sequencer(7 downto 0)= b"1111_1110") then
				ENABLE_CLK_1X_DIV64  		<= '1';
			else 
				ENABLE_CLK_1X_DIV64  		<= '0';
			end if;
			if (cmpt_sequencer(8 downto 0)= b"1_1111_1110") then
				ENABLE_CLK_1X_DIV128  		<= '1';
			else 
				ENABLE_CLK_1X_DIV128  		<= '0';
			end if;
			if (cmpt_sequencer(27 downto 0)= b"1001_1000_1001_0110_1000_0000_0010") then
				ONE_SECONDi  		<= '1';
			else 
				ONE_SECONDi  		<= '0';
			end if;
			if (cmpt_sequencer(20 downto 0)= b"1_1111_1111_1111_1111_1110") then
--			if (cmpt_sequencer(7 downto 0)= b"1111_1110") then
				twelve_mili_SECOND  		<= '1';
			else 
				twelve_mili_SECOND  		<= '0';
			end if;
				if (cmpt_sequencer(22 downto 0)= b"111_1111_1111_1111_1111_1111") then
				chenille_int <= chenille_int (6 downto 0) & chenille_int(7);
				end if;
			end if;
	end process;
HW_RESET <= HW_RESETi;	
P_RESET_DELAYED: process(EXT_RESET, CLK_4Xi)
	begin
		if EXT_RESET = '1' then
		HW_RESETi <='1';
		HW_RESETi_delayed <='1';
		elsif (rising_edge(CLK_4Xi)) then
					HW_RESETi_delayed <='0';
				if (HW_RESETi_delayed ='0') then
					HW_RESETi <= '0';
				else
					HW_RESETi <='1';
				end if;
			end if;
	end process; 		

Chenille			<= 	chenille_int;
ONE_SECOND			<= ONE_SECONDi;

end Behavioral;

