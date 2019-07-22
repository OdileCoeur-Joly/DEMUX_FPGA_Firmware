----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 10/12/2016 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : IO_CONVERTER - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Convert IO single to differential and apply standard LVDS
-- Link DAC internals signals to externals signals names
-- Dependencies: fifo_out_to_daq create xilinx core
--
-- Revision: 
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
library UNISIM;
use UNISIM.VComponents.all;

entity IO_converter is
    Port ( 
		
-- FROM USB_3.0 manager
         DAQ_CLK_USB_OUT		: in  STD_LOGIC; -- 10MHz
	-- DAQ 32 bits for science link
         DAQ_usb_Data			: in  STD_LOGIC_VECTOR (31 downto 0);
         DAQ_usb_Rdy_n			: out STD_LOGIC;
         DAQ_usb_WR 			: in  STD_LOGIC;
	-- DATA SENDING 1MHz 8 bits for HK link
         HK_usb_Data			: in  STD_LOGIC_VECTOR (7 downto 0);
         HK_usb_Rdy_n			: out STD_LOGIC;
         HK_usb_WR 				: in  STD_LOGIC;
	-- DATA RECEIVED 1MHz 8 bits for Config link
		CONF_usb_Data			: out STD_LOGIC_VECTOR (7 downto 0);
		CONF_usb_Rdy_n			: in  STD_LOGIC;
        CONF_usb_WR				: out STD_LOGIC;

-- TO FMC_USB 3.0 OPALKELLY Link I/O
		-- DAQ_CLK_usb_OUT
		HPC1_CLK_P				: out STD_LOGIC;	-- 10MHz Clock for all links DAQ HK and CONF
		HPC1_CLK_N				: out STD_LOGIC;	-- 10MHz Clock for all links DAQ HK and CONF
		-- DAQ DATA 32 bits for science link
		HPC1_DAQ_D_P			: out STD_LOGIC_VECTOR (31 downto 0);
		HPC1_DAQ_D_N			: out STD_LOGIC_VECTOR (31 downto 0);

		-- DAQ RDY_N for science link
		HPC1_DAQ_RDYN_P			: in STD_LOGIC;
		HPC1_DAQ_RDYN_N			: in STD_LOGIC;
		-- DAQ WR 32 for science link
		HPC1_DAQ_WR_P			: out STD_LOGIC;
		HPC1_DAQ_WR_N			: out STD_LOGIC;

		-- DATA SENDING 1MHz 8 bits for HK link
		HPC1_HK_D_P				: out STD_LOGIC_VECTOR (7 downto 0);
		HPC1_HK_D_N				: out STD_LOGIC_VECTOR (7 downto 0);
		-- HK RDY_N for science link
		HPC1_HK_RDYN_P			: in  STD_LOGIC;
		HPC1_HK_RDYN_N			: in  STD_LOGIC;
		-- HK WR 32 for science link
		HPC1_HK_WR_P			: out STD_LOGIC;
		HPC1_HK_WR_N			: out STD_LOGIC;
		
		-- DATA RECEIVING 1MHz 8 bits for CONFIG link
		HPC1_CONF_D_P			: in STD_LOGIC_VECTOR (7 downto 0);
		HPC1_CONF_D_N			: in STD_LOGIC_VECTOR (7 downto 0);
		-- CONF RDY_N for science link
		HPC1_CONF_RDYN_P		: out  STD_LOGIC;
		HPC1_CONF_RDYN_N		: out  STD_LOGIC;
		-- CONF WR 32 for science link
		HPC1_CONF_WR_P			: in STD_LOGIC;
		HPC1_CONF_WR_N			: in STD_LOGIC;
		
-- FROM/TO AD9726 BIAS controler	CH1 and CH2
		DACB_DCLK_FROM			: out t_std_logic_array;
		DACB_DCLK_TO			: in  t_std_logic_array;
		DACB_DATA_OUT			: in  t_std_logic_16_array;
		DACB_SPI_SDO			: out t_std_logic_array;
		DACB_SPI_SDIO			: in  t_std_logic_array;
		DACB_SPI_SCLK			: in  t_std_logic_array;
		DACB_SPI_CS_N			: in  t_std_logic_array;
		DACB_RESET				: in  t_std_logic_array;
-- FROM/TO AD9726 BIAS CH1
		DACB_CH1_SDO			: in  STD_LOGIC;
		DACB_CH1_SDIO			: out STD_LOGIC;
		DACB_CH1_SCLK			: out STD_LOGIC;
		DACB_CH1_CSn			: out STD_LOGIC;
		DACB_CH1_D_P			: out STD_LOGIC_VECTOR(15 downto 0);
		DACB_CH1_D_N			: out STD_LOGIC_VECTOR(15 downto 0);
		DACB_CH1_RESET			: out STD_LOGIC;
		DACB_CH1_DCLK_OUT_P		: in  STD_LOGIC;
		DACB_CH1_DCLK_OUT_N		: in  STD_LOGIC;
		DACB_CH1_DCLK_IN_P		: out STD_LOGIC;
		DACB_CH1_DCLK_IN_N		: out STD_LOGIC;
-- FROM/TO AD9726 BIAS CH2
		DACB_CH2_SDO			: in  STD_LOGIC;
		DACB_CH2_SDIO			: out STD_LOGIC;
		DACB_CH2_SCLK			: out STD_LOGIC;
		DACB_CH2_CSn			: out STD_LOGIC;
		DACB_CH2_D_P			: out STD_LOGIC_VECTOR(15 downto 0);
		DACB_CH2_D_N			: out STD_LOGIC_VECTOR(15 downto 0);
		DACB_CH2_RESET			: out STD_LOGIC;
		DACB_CH2_DCLK_OUT_P		: in  STD_LOGIC;
		DACB_CH2_DCLK_OUT_N		: in  STD_LOGIC;
		DACB_CH2_DCLK_IN_P		: out STD_LOGIC;
		DACB_CH2_DCLK_IN_N		: out STD_LOGIC;
				
-- FROM/TO AD9726 FEEDBACK controler	CH1 and CH2
		DACF_DCLK_FROM			: out t_std_logic_array;
		DACF_DCLK_TO			: in  t_std_logic_array;
		DACF_DATA_OUT			: in  t_std_logic_16_array;
		DACF_SPI_SDO			: out t_std_logic_array;
		DACF_SPI_SDIO			: in  t_std_logic_array;
		DACF_SPI_SCLK			: in  t_std_logic_array;
		DACF_SPI_CS_N			: in  t_std_logic_array;
		DACF_RESET				: in  t_std_logic_array;
-- FROM/TO AD9726 FEEDBACK CH1
		DACF_CH1_SDO			: in  STD_LOGIC;
		DACF_CH1_SDIO			: out STD_LOGIC;
		DACF_CH1_SCLK			: out STD_LOGIC;
		DACF_CH1_CSn			: out STD_LOGIC;
		DACF_CH1_D_P			: out STD_LOGIC_VECTOR(15 downto 0);
		DACF_CH1_D_N			: out STD_LOGIC_VECTOR(15 downto 0);
		DACF_CH1_RESET			: out STD_LOGIC;
		DACF_CH1_DCLK_OUT_P		: in  STD_LOGIC;
		DACF_CH1_DCLK_OUT_N		: in  STD_LOGIC;
		DACF_CH1_DCLK_IN_P		: out STD_LOGIC;
		DACF_CH1_DCLK_IN_N		: out STD_LOGIC;
		
-- FROM/TO AD9726 FEEDBACK CH2
		DACF_CH2_SDO			: in  STD_LOGIC;
		DACF_CH2_SDIO			: out STD_LOGIC;
		DACF_CH2_SCLK			: out STD_LOGIC;
		DACF_CH2_CSn			: out STD_LOGIC;
		DACF_CH2_D_P			: out STD_LOGIC_VECTOR(15 downto 0);
		DACF_CH2_D_N			: out STD_LOGIC_VECTOR(15 downto 0);
		DACF_CH2_RESET			: out STD_LOGIC;
		DACF_CH2_DCLK_OUT_P		: in  STD_LOGIC;
		DACF_CH2_DCLK_OUT_N		: in  STD_LOGIC;
		DACF_CH2_DCLK_IN_P		: out STD_LOGIC;
		DACF_CH2_DCLK_IN_N		: out STD_LOGIC;
		
-- FROM/TO CDCM7005 CONTROLER
		CDCM_SCLK				: in  STD_LOGIC;
		CDCM_SLE				: in  STD_LOGIC;
		CDCM_RSTn				: in  STD_LOGIC;
		CDCM_SDIN				: in  STD_LOGIC;
		CDCM_STATUS_REF			: out STD_LOGIC;
		CDCM_PLL_LOCK			: out STD_LOGIC;
		CDCM_STATUS_VCXO		: out STD_LOGIC;
-- FROM/TO CDCM7005
		DAC_CH1_CDCM_SCLK		: out STD_LOGIC;
		DAC_CH1_CDCM_SLE		: out STD_LOGIC;
		DAC_CH1_CDCM_RST_N		: out STD_LOGIC;
		DAC_CH1_CDCM_SDIN		: out STD_LOGIC;
		DAC_CH1_CDCM_STATUS_REF	: in  STD_LOGIC;
		DAC_CH1_CDCM_PLL_LOCK	: in  STD_LOGIC;
		DAC_CH1_CDCM_STATUS_VCXO: in  STD_LOGIC;

-- FROM/TO ADC128 CONTROLER CH1 and CH2
		DAC_ADC128_SCLK			: in  t_std_logic_array;
		DAC_ADC128_CSn			: in  t_std_logic_array;
		DAC_ADC128_DOUT			: out t_std_logic_array;
		DAC_ADC128_DIN			: in  t_std_logic_array;
		DAC_MUX_S				: in  t_std_logic_3_array;
-- FROM/TO ADC128 DAC CH1

		DAC_CH1_ADC128_SCLK		: out STD_LOGIC;
		DAC_CH1_ADC128_CSn		: out STD_LOGIC;
		DAC_CH1_ADC128_DOUT		: in  STD_LOGIC;
		DAC_CH1_ADC128_DIN		: out STD_LOGIC;
		DAC_CH1_MUX_S			: out STD_LOGIC_VECTOR(2 downto 0);
-- FROM/TO ADC128 DAC CH2

		DAC_CH2_ADC128_SCLK		: out STD_LOGIC;
		DAC_CH2_ADC128_CSn		: out STD_LOGIC;
		DAC_CH2_ADC128_DOUT		: in  STD_LOGIC;
		DAC_CH2_ADC128_DIN		: out STD_LOGIC;
		DAC_CH2_MUX_S			: out STD_LOGIC_VECTOR(2 downto 0);
				
-- FROM/TO ADC RHF1201 CONTROLER CH1
--Clock/Data connection to ADC RHF1201 on FMC_ADC_XIFU

		ADC_CLK					: in  t_std_logic_array;
		ADC_SRC					: in  t_std_logic_array;
		ADC_DR					: out t_std_logic_array;
		ADC_OE_N				: in  t_std_logic_array;
		ADC_DFS_N				: in  t_std_logic_array;
		ADC_DIN					: out t_signed_12_array;
		ADC_OOR					: out t_std_logic_array;
--Clock/Data connection to ADC RHF1201 on FMC_ADC_XIFU

		ADC_CH1_CLK				: out std_logic;
		ADC_CH1_SRC				: out std_logic;
		ADC_CH1_DR				: in  std_logic;
		ADC_CH1_OE_N			: out std_logic;
		ADC_CH1_DFS_N			: out std_logic;
		ADC_CH1_D				: in  std_logic_vector(11 downto 0);
		ADC_CH1_OOR				: in  std_logic;
  --Clock/Data connection to ADC ADC128S102 on FMC_ADC_XIFU
			 
		ADC_CH1_ADC128_SCLK 	: out std_logic;
		ADC_CH1_ADC128_DOUT 	: in  std_logic;
		ADC_CH1_ADC128_DIN  	: out std_logic;
		ADC_CH1_ADC128_CS_N		: out std_logic;
		
-- FROM/TO ADC RHF1201 CH2
--Clock/Data connection to ADC RHF1201 on FMC_ADC_XIFU

		ADC_CH2_CLK				: out std_logic;
		ADC_CH2_SRC				: out std_logic;
		ADC_CH2_DR				: in  std_logic;
		ADC_CH2_OE_N			: out std_logic;
		ADC_CH2_DFS_N			: out std_logic;
		ADC_CH2_D				: in  std_logic_vector(11 downto 0);
		ADC_CH2_OOR				: in  std_logic;
  --Clock/Data connection to ADC ADC128S102 on FMC_ADC_XIFU
			 
		ADC_CH2_ADC128_SCLK 	: out std_logic;
		ADC_CH2_ADC128_DOUT 	: in  std_logic;
		ADC_CH2_ADC128_DIN  	: out std_logic;
		ADC_CH2_ADC128_CS_N		: out std_logic;
-- FROM/TO ADC128 CONTROLER CH1 and CH2
		ADC_ADC128_SCLK			: in  t_std_logic_array;
		ADC_ADC128_CSn			: in  t_std_logic_array;
		ADC_ADC128_DOUT			: out t_std_logic_array;
		ADC_ADC128_DIN			: in  t_std_logic_array
		
			);
end IO_converter;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.IO_converter.Behavioral.svg
architecture Behavioral of IO_converter is
begin
-- USB3.0 IO BUFFERS
	-- DAQ_CLK_usb_OUT
  OBUFDS_DAQ_CLK : OBUFDS
   generic map (
      IOSTANDARD => "LVDS_25")
   port map (
      O 	=> HPC1_CLK_P,
      OB => HPC1_CLK_N,
      I 	=> DAQ_CLK_USB_OUT
   );
	
	-- DAQ RDY_N for science link
	  OBUFDS_DAQ_RDYN : IBUFDS
  generic map (
     IOSTANDARD => "LVDS_25")
  port map (
     I 	=> HPC1_DAQ_RDYN_P,
     IB => HPC1_DAQ_RDYN_N,
     O 	=> DAQ_usb_Rdy_n
  );
	
	-- DAQ WR 32 for science link
	OBUFDS_DAQ_WR : OBUFDS
   generic map (
      IOSTANDARD => "LVDS_25")
   port map (
      O 	=> HPC1_DAQ_WR_P,
      OB => HPC1_DAQ_WR_N,
      I 	=> DAQ_usb_WR
   );
	
	-- DAQ DATA 32 bits for science link	
	GENERATE_DAQ_DATA : for I in 31 downto 0 generate
  OBUFDS_DAQ : OBUFDS
   generic map (
      IOSTANDARD => "LVDS_25")
   port map (
      O 	=> HPC1_DAQ_D_P(I),
      OB => HPC1_DAQ_D_N(I),
      I 	=>  DAQ_usb_Data(I)
   );
	end generate GENERATE_DAQ_DATA;
	
	-- HK RDY_N for science link
	  OBUFDS_HK_RDYN : IBUFDS
  generic map (
     IOSTANDARD => "LVDS_25")
  port map (
     I 	=> HPC1_HK_RDYN_P,
     IB => HPC1_HK_RDYN_N,
     O 	=> HK_usb_Rdy_n
  );
	
	-- HK WR 32 for science link
	OBUFDS_HK_WR : OBUFDS
   generic map (
      IOSTANDARD => "LVDS_25")
   port map (
      O 	=> HPC1_HK_WR_P,
      OB => HPC1_HK_WR_N,
      I 	=> HK_usb_WR
   );
	
	-- DATA SENDING 1MHz 8 bits for HK link
	GENERATE_HK_DATA : for I in 7 downto 0 generate
 	OBUFDS_HK : OBUFDS
   generic map (
      IOSTANDARD => "LVDS_25")
   port map (
      O 	=> HPC1_HK_D_P(I),
      OB => HPC1_HK_D_N(I),
      I 	=>  HK_usb_Data(I) 
   );
	end generate GENERATE_HK_DATA;
	
	-- CONF RDY_N for science link
	  OBUFDS_CONF_RDYN : OBUFDS
   generic map (
      IOSTANDARD => "LVDS_25")
   port map (
      O 	=> HPC1_CONF_RDYN_P,
      OB => HPC1_CONF_RDYN_N,
      I 	=> CONF_usb_Rdy_n
   );
	
	-- CONF WR for config link
	IBUFDS_CONF_WR : IBUFDS
  generic map (
     IOSTANDARD => "LVDS_25")
  port map (
     I 	=> HPC1_CONF_WR_P,     	
     IB => HPC1_CONF_WR_N,   	
     O 	=> CONF_usb_WR      		
  );
	
	-- DATA RECEIVING 10MHz 8 bits for CONFIG link	
	GENERATE_CONF_DATA : for I in 7 downto 0 generate
 IBUFDS_CONF : IBUFDS
  generic map (
     IOSTANDARD => "LVDS_25")
  port map (
     I 	=> HPC1_CONF_D_P(I),    
     IB => HPC1_CONF_D_N(I),   	
     O 	=>  CONF_usb_Data(I)   
  );
	end generate GENERATE_CONF_DATA;

--DAC_BOARD (CH1) IO BUFFERS

	-- FROM/TO AD9726 BIAS controler	

		--DACB_DCLK_FROM : CLK from DAC
	IBUFDS_DACB_CH1_DCLK_FROM : IBUFGDS
   generic map (
      IOSTANDARD => "LVDS_25")
   port map (
      I 	=> DACB_CH1_DCLK_OUT_P,     	
      IB => DACB_CH1_DCLK_OUT_N,   	
      O 	=> DACB_DCLK_FROM(0)     		
   );
--		-- DACB_DCLK_FROM : CLK from DAC
--	IBUFDS_DACB_CH2_DCLK_FROM : IBUFGDS
--   generic map (
--      IOSTANDARD => "LVDS_25")
--   port map (
--      I 	=> DACB_CH2_DCLK_OUT_P,     	
--      IB => DACB_CH2_DCLK_OUT_N,   	
--      O 	=> DACB_DCLK_FROM(1)     		
--   );
		-- DACB_DCLK_TO : CLK to DAC
OBUFDS_DACB_CH1_DCLK_TO : OBUFDS
   generic map (
      IOSTANDARD => "LVDS_25")
   port map (
      O 	=> DACB_CH1_DCLK_IN_P,
      OB => DACB_CH1_DCLK_IN_N,
      I 	=> DACB_DCLK_TO(0)
   );
		-- -- DACB_DCLK_TO : CLK to DAC
	  -- OBUFDS_DACB_CH2_DCLK_TO : OBUFDS
   -- generic map (
      -- IOSTANDARD => "LVDS_25")
   -- port map (
      -- O 	=> DACB_CH2_DCLK_IN_P,
      -- OB => DACB_CH2_DCLK_IN_N,
      -- I 	=> DACB_DCLK_TO(1)
   -- );
--	DACB_DATA_OUT : DATA DACB (CH1) to DAC
	GENERATE_DACB_CH1_DATA_OUT : for I in 15 downto 0 generate
		OBUFDS_DAQ : OBUFDS
			generic map (
				IOSTANDARD => "LVDS_25")
			port map (
				O 	=> DACB_CH1_D_P(I),
				OB => DACB_CH1_D_N(I),
				I 	=>  DACB_DATA_OUT(0)(I)
				);
	end generate GENERATE_DACB_CH1_DATA_OUT;
	
--	DACB_DATA_OUT : DATA DACB (CH1) to DAC
	-- GENERATE_DACB_CH2_DATA_OUT : for I in 0 to 15 generate
		-- OBUFDS_DAQ : OBUFDS
			-- generic map (
				-- IOSTANDARD => "LVDS_25")
			-- port map (
				-- O 	=> DACB_CH2_D_P(I),
				-- OB => DACB_CH2_D_N(I),
				-- I 	=>  DACB_DATA_OUT(1)(I)
				-- );
	-- end generate GENERATE_DACB_CH2_DATA_OUT;	
	-- SPI DACB from/to SPI AD9726 CONTROLER LVCMOS25
	
	DACB_SPI_SDO(0)	<= DACB_CH1_SDO; 	-- FROM SPI AD9726
	DACB_CH1_SDIO		<= DACB_SPI_SDIO(0);	-- TO SPI AD9726
	DACB_CH1_SCLK		<= DACB_SPI_SCLK(0);	-- TO SPI AD9726
	DACB_CH1_CSn		<= DACB_SPI_CS_N(0);	-- TO SPI AD9726
	DACB_CH1_RESET		<= DACB_RESET(0);		-- TO RESET AD9726
	
	-- SPI DACB from/to SPI AD9726 CONTROLER LVCMOS25
	
	DACB_SPI_SDO(1)	<= DACB_CH2_SDO; 	-- FROM SPI AD9726
	DACB_CH2_SDIO		<= DACB_SPI_SDIO(1);	-- TO SPI AD9726
	DACB_CH2_SCLK		<= DACB_SPI_SCLK(1);	-- TO SPI AD9726
	DACB_CH2_CSn		<= DACB_SPI_CS_N(1);	-- TO SPI AD9726
	DACB_CH2_RESET		<= DACB_RESET(1);		-- TO RESET AD9726
	

				
-- FROM/TO AD9726 FEEDBACK controler	
--		DACB_DCLK_FROM : CLK from DAC
	IBUFDS_DACF_CH1_DCLK_FROM : IBUFGDS
   generic map (
      IOSTANDARD => "LVDS_25")
   port map (
      I 	=> DACF_CH1_DCLK_OUT_P,     	
      IB => DACF_CH1_DCLK_OUT_N,   	
      O 	=> DACF_DCLK_FROM(0)     		
   );
		-- DACB_DCLK_FROM : CLK from DAC
--	IBUFDS_DACF_CH2_DCLK_FROM : IBUFGDS
--   generic map (
--      IOSTANDARD => "LVDS_25")
--   port map (
--      I 	=> DACF_CH2_DCLK_OUT_P,     	
--      IB => DACF_CH2_DCLK_OUT_N,   	
--      O 	=> DACF_DCLK_FROM(1)     		
--   );
	-- DACB_DCLK_TO : CLK to DAC
	  OBUFDS_DACF_CH1_DCLK_TO : OBUFDS
   generic map (
      IOSTANDARD => "LVDS_25")
   port map (
      O 	=> DACF_CH1_DCLK_IN_P,
      OB => DACF_CH1_DCLK_IN_N,
      I 	=> DACF_DCLK_TO(0)
   );
	-- -- DACB_DCLK_TO : CLK to DAC
	  -- OBUFDS_DACF_CH2_DCLK_TO : OBUFDS
   -- generic map (
      -- IOSTANDARD => "LVDS_25")
   -- port map (
      -- O 	=> DACF_CH2_DCLK_IN_P,
      -- OB => DACF_CH2_DCLK_IN_N,
      -- I 	=> DACF_DCLK_TO(1)
   -- );
	-- DACB_DATA_OUT : DATA DACB (CH1) to DAC
	GENERATE_DACF_CH1_DATA_OUT : for I in 15 downto 0 generate
		OBUFDS_DAQ : OBUFDS
			generic map (
				IOSTANDARD => "LVDS_25")
			port map (
				O 	=> DACF_CH1_D_P(I),
				OB => DACF_CH1_D_N(I),
				I 	=>  DACF_DATA_OUT(0)(I)
				);
	end generate GENERATE_DACF_CH1_DATA_OUT;
	-- DACB_DATA_OUT : DATA DACB (CH1) to DAC
	-- GENERATE_DACF_CH2_DATA_OUT : for I in 0 to 15 generate
		-- OBUFDS_DAQ : OBUFDS
			-- generic map (
				-- IOSTANDARD => "LVDS_25")
			-- port map (
				-- O 	=> DACF_CH2_D_P(I),
				-- OB => DACF_CH2_D_N(I),
				-- I 	=>  DACF_DATA_OUT(1)(I)
				-- );
	-- end generate GENERATE_DACF_CH2_DATA_OUT;
	
	-- SPI DACF from/to SPI AD9726 CONTROLER LVCMOS25
	
	DACF_SPI_SDO(0) 		<= DACF_CH1_SDO; 	-- FROM SPI AD9726
	DACF_CH1_SDIO		<= DACF_SPI_SDIO(0);	-- TO SPI AD9726
	DACF_CH1_SCLK		<= DACF_SPI_SCLK(0);	-- TO SPI AD9726
	DACF_CH1_CSn		<= DACF_SPI_CS_N(0);	-- TO SPI AD9726
	DACF_CH1_RESET		<= DACF_RESET(0);		-- TO RESET AD9726
			
	-- SPI DACF from/to SPI AD9726 CONTROLER LVCMOS25
	
	DACF_SPI_SDO(1) 		<= DACF_CH2_SDO; 	-- FROM SPI AD9726
	DACF_CH2_SDIO		<= DACF_SPI_SDIO(1);	-- TO SPI AD9726
	DACF_CH2_SCLK		<= DACF_SPI_SCLK(1);	-- TO SPI AD9726
	DACF_CH2_CSn		<= DACF_SPI_CS_N(1);	-- TO SPI AD9726
	DACF_CH2_RESET		<= DACF_RESET(1);		-- TO RESET AD9726
			
-- FROM/TO CDCM7005  DAC BOARD (CH1)
	--SPI link LVCMOS25
	DAC_CH1_CDCM_SCLK		<= CDCM_SCLK; 	-- TO CDCM7005
	DAC_CH1_CDCM_SLE		<=	CDCM_SLE; 	-- TO CDCM7005
	DAC_CH1_CDCM_SDIN		<=	CDCM_SDIN; 	-- TO CDCM7005
	DAC_CH1_CDCM_RST_N	<=	CDCM_RSTn; -- TO CDCM7005
	CDCM_STATUS_REF		<= DAC_CH1_CDCM_STATUS_REF; 	-- FROM CDCM7005
	CDCM_PLL_LOCK			<= DAC_CH1_CDCM_PLL_LOCK; 		-- FROM CDCM7005
	CDCM_STATUS_VCXO		<= DAC_CH1_CDCM_STATUS_VCXO; 	-- FROM CDCM7005

-- FROM/TO ADC128 DAC BOARD (CH1) LVCMOS25
	DAC_CH1_ADC128_SCLK	<= DAC_ADC128_SCLK(0);			-- TO ADC128
	DAC_CH1_ADC128_CSn	<=	DAC_ADC128_CSn(0);				-- TO ADC128
	DAC_ADC128_DOUT(0)	<= DAC_CH1_ADC128_DOUT; -- FROM ADC128
	DAC_CH1_ADC128_DIN	<= DAC_ADC128_DIN(0);				-- TO ADC128
	
-- TO Analog MUX 54HC4051 DAC BOARD (CH1) LVCMOS25
	DAC_CH1_MUX_S			<=	DAC_MUX_S(0);					-- TO Analog MUX 54HC4051
	
-- FROM/TO ADC128 DAC BOARD (CH2) LVCMOS25
	DAC_CH2_ADC128_SCLK	<= DAC_ADC128_SCLK(1);			-- TO ADC128
	DAC_CH2_ADC128_CSn	<=	DAC_ADC128_CSn(1);				-- TO ADC128
	DAC_ADC128_DOUT(1)	<= DAC_CH2_ADC128_DOUT; -- FROM ADC128
	DAC_CH2_ADC128_DIN	<= DAC_ADC128_DIN(1);				-- TO ADC128
	
-- TO Analog MUX 54HC4051 DAC BOARD (CH1) LVCMOS25
	DAC_CH2_MUX_S			<=	DAC_MUX_S(1);					-- TO Analog MUX 54HC4051
	
----------------------------------------------------------------------------------------
-- ADC 
----------------------------------------------------------------------------------------
-- FROM/TO ADC RHF1201 CONTROLER CH1
--Clock/Data connection to ADC RHF1201 on FMC_ADC_XIFU


		ADC_CH1_CLK	  				<=  ADC_CLK(0);
		ADC_CH2_CLK	  				<=	ADC_CLK(1);
		ADC_CH1_SRC	  				<=	ADC_SRC(0);
		ADC_CH2_SRC	  				<=	ADC_SRC(1);
		ADC_DR(0)					<=	ADC_CH1_DR;
		ADC_DR(1)					<=	ADC_CH2_DR;
		ADC_CH1_OE_N				<=	ADC_OE_N(0);
		ADC_CH2_OE_N				<=	ADC_OE_N(1);
		ADC_CH1_DFS_N				<=	ADC_DFS_N(0);
		ADC_CH2_DFS_N				<=	ADC_DFS_N(1);
		ADC_DIN(0)					<=	signed(ADC_CH1_D);
		ADC_DIN(1)					<=	signed(ADC_CH2_D);
		ADC_OOR(0)					<=	ADC_CH1_OOR;
		ADC_OOR(1)					<=	ADC_CH2_OOR;
		ADC_CH1_ADC128_SCLK			<=	ADC_ADC128_SCLK(0);
		ADC_CH2_ADC128_SCLK			<=	ADC_ADC128_SCLK(1);
		ADC_ADC128_DOUT(0)			<=	ADC_CH1_ADC128_DOUT;
		ADC_ADC128_DOUT(1)			<=	ADC_CH2_ADC128_DOUT;
		ADC_CH1_ADC128_DIN			<=	ADC_ADC128_DIN(0);
		ADC_CH2_ADC128_DIN			<=	ADC_ADC128_DIN(1);
		ADC_CH1_ADC128_CS_N			<=	ADC_ADC128_CSn(0);
		ADC_CH2_ADC128_CS_N			<=	ADC_ADC128_CSn(1);

	
	
end Behavioral;

