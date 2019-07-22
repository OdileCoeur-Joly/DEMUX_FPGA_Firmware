----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL/ Yann Parot
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : ADC128S102_MUXED_CONTROLER - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : ADC128S102 MUXED ADC managment module
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.02 - Add 1 step to sate machine 
--						 at the end for done and output registers ready
						 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

-----------------------------------
--the controller for adc128S102
-- La datasheet indique que le premier echantillonage est IN0 et après on a les valeurs programmées
-- tant que CS est actif
--Quand Start passe à 1, l'ADC échantillonne les 8 voies et stocke le resultat dans output register.
--Output_register(0) <= IN0_0
--Output_register(1) <= IN0_1
--Output_register(2) <= IN0_2
--Output_register(3) <= IN0_3
--Output_register(4) <= IN0_4
--Output_register(5) <= IN0_5
--Output_register(6) <= IN0_6
--Output_register(7) <= IN0_7
--Output_register(8) <= IN1
--Output_register(9) <= IN2
--Output_register(10) <= IN3
--Output_register(11) <= IN4
--Output_register(12) <= IN5
--Output_register(13) <= IN6
--Output_register(14) <= IN7
-----------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
--use work.ADC128S102_pkg.ALL;
use work.athena_package.all;

entity ADC128S102_MUXED_controler is
	port ( 
--RESET
			Reset	        	: in    std_logic; 
--CLOCKs
			clk_4X	     		: in    std_logic; 
			ENABLE_CLK_1X		: in    std_logic; 
			twelve_mili_SECOND	: in 	STD_LOGIC;
-- Control
			Output_registers   	: out   t_register_MUXED_ADC128; -- array de 15 std_logic_vector (max de channel qu'on peut acquérir)
			Start              	: in    std_logic; 
			read_register		: in    std_logic; 
			Done               	: out   std_logic; -- indique que le registre est a jour (toutes les valeurs demandees sont updatees)
			 
			 -- ADC
			 
			Sclk       			: out   std_logic;
			Dout       			: in    std_logic;
			Din        			: out   std_logic;
			Cs_n 	   			: out   std_logic;
			
			-- MUX
			 DAC_MUX_S			: out   std_logic_vector(2 downto 0)
			 );
end ADC128S102_MUXED_controler;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.ADC128S102_MUXED_controler.Behavioral.svg
architecture Behavioral of ADC128S102_MUXED_controler is

----------------------------------------------------------------------------
--	
-- ADC128S102 CONTROLER DAC BOARD
--
----------------------------------------------------------------------------
	-- FROM/TO ADC128 CONTROLER
	signal 		ADC128_registers			: t_register_ADC128;
	signal 		adc128_start				: std_logic;
	signal 		ADC128_Read_Register		: std_logic;
	signal 		adc128_done					: std_logic;
	signal 		count_DAC_MUX_S				: unsigned(2 downto 0);
-- STATE FOR ADC128 READ
	type t_STATE_READING is (IDLE,read_channel_0,wait_done1,read_channel_wait_done0,read_others_channels,read_done);
	signal STATE_READING					: t_STATE_READING;
	
begin 

ADC128_MUXED : entity work.ADC128S102_controler
	PORT MAP 
			(
          Reset			 		=> Reset,
          clk_4X	 		 	=> clk_4X,
		  ENABLE_CLK_1X	 		=> ENABLE_CLK_1X,
          Start 				=> adc128_start,
		  read_register			=> ADC128_Read_Register,
          Done 					=> adc128_done,
          Output_registers 		=> ADC128_registers,
          Sclk		 			=> Sclk,
          Dout		 			=> Dout,
          Din		 			=> Din,
          Cs_n 					=> Cs_n
			);


--	 =============================================================
--	 ADC128 READER with MUX changing Only for channel 0
--	 =============================================================
			DAC_MUX_S			<= std_logic_vector(count_DAC_MUX_S);
P_mux_ADC128:	process(Reset,clk_4X)
	begin
		if (Reset = '1') then
			adc128_start		<= '0';
			ADC128_Read_Register<= '0';
			Done 				<= '0';
			count_DAC_MUX_S		<= (others=>'0');
			STATE_READING 		<= IDLE;
			Output_registers	<= (others=>(others=>'0'));

		elsif rising_edge(clk_4X) then
			if (ENABLE_CLK_1X ='1') then
				case STATE_READING is
					when IDLE =>
						adc128_start				<= '0';
						ADC128_Read_Register 		<= '0';
						Done 						<= '0';
						count_DAC_MUX_S				<= (others=>'0');
						if (Start ='1') then
							STATE_READING 			<= read_channel_0;
						else
							STATE_READING 			<= IDLE;
						end if;
					when read_channel_0 =>
						if (twelve_mili_SECOND = '1') then
							ADC128_Read_Register 	<= '0';
							adc128_start			<= '1';
							STATE_READING 	 		<= wait_done1;
						else 
							STATE_READING 	 		<=read_channel_0;
						end if;
					when wait_done1 =>
						if (adc128_done ='1' ) then
							ADC128_Read_Register 	<= '1';
							adc128_start			<= '0';
							Output_registers(to_integer(unsigned('0' & count_DAC_MUX_S)))	<= ADC128_registers(0);
							STATE_READING 	 		<= read_channel_wait_done0;
						else 
						STATE_READING 	 			<= wait_done1;
						end if;
					when read_channel_wait_done0 =>
						if (adc128_done ='0' and twelve_mili_SECOND = '1') then 
							if ( count_DAC_MUX_S < "111") then
							count_DAC_MUX_S 		<= count_DAC_MUX_S + 1;
							STATE_READING 	 		<= read_channel_0;
							else 
							count_DAC_MUX_S 		<= (others=>'0');
							adc128_start			<= '0';
							ADC128_Read_Register 	<= '0';
							STATE_READING 	 		<= read_others_channels;
							end if;
						else
							STATE_READING 	 		<= read_channel_wait_done0;
						end if;
					when read_others_channels =>
						ADC128_Read_Register 		<= '0';
						adc128_start				<= '1';
						if (adc128_done ='1' ) then
							ADC128_Read_Register 	<= '1';
							adc128_start			<= '0';
							Output_registers (14)	<= ADC128_registers (7);
							Output_registers (13)	<= ADC128_registers (6);
							Output_registers (12)	<= ADC128_registers (5);
							Output_registers (11)	<= ADC128_registers (4);
							Output_registers (10)	<= ADC128_registers (3);
							Output_registers (9)	<= ADC128_registers (2);
							Output_registers (8)	<= ADC128_registers (1);
							STATE_READING 	 		<= read_done;
						else 
							STATE_READING 			<= read_others_channels;
						end if;
					when read_done =>
						Done <= '1';
						if (read_register ='1') then
						STATE_READING 	 			<= IDLE;
						else
						STATE_READING 	 			<= read_done;
						end if;
					end case;
				end if;
			end if;
	end process P_mux_ADC128;
end Behavioral;