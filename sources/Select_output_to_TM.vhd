----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : Select_output_to_DAQ - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Selection of TM output to send to DAQ PCIE bus manager
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.03 - change managment : no fifo, direct connexion to DAQ fifo, changement of name (USB3.0 to PCIE)
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

entity Select_output_to_TM is
    Port ( 
--RESET
			RESET							: in  std_logic;-- CLOCKS	
			CLK_4X							: in  std_logic; --CLK_4X
			ENABLE_CLK_1X					: in  std_logic;
			ENABLE_CLK_1X_DIV128			: in  std_logic;
--CONTROL
			select_TM						: in  unsigned (3 downto 0);
			START_SENDING_TM				: in  std_logic;
-- FROM XIFU
			OUT_SCIENCE_UNFILTRED_TP_I 		: in  t_TP_science_channel;
			OUT_SCIENCE_UNFILTRED_TP_Q 		: in  t_TP_science_channel;
			OUT_SCIENCE_FILTRED_I 			: in  t_science_channel;
			OUT_SCIENCE_FILTRED_Q 			: in  t_science_channel;
			IN_PHYS							: in  t_in_phys;--signed(Size_In_Real-1 downto 0)
			FEEDBACK 						: in  t_feedback_to_DAC;--signed(Size_feedback_TO_DAC-1 downto 0)
			BIAS 							: in  t_bias;--signed(Size_bias_TO_DAC-1 downto 0)
-- 			STATUS							: in t_STATUS;
	
-- TO USB OPKELLY manager
			TM_DATA_TO_GSE					: out std_logic_vector(31 downto 0);
			WR_en_TM_fifo					: out std_logic
			);
end Select_output_to_TM;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.Select_output_to_TM.Behavioral.svg
architecture Behavioral of Select_output_to_TM is

	signal DAQ_HEADER				: std_logic_vector(15 downto 0);
--	signal IN_PHYS		 			: t_in_phys;--signed(Size_In_Real-1 downto 0)


	type t_OUT_ON is (OFF,SD_SCIENCE,SD_DUMP,SD_COUNT);
	signal OUT_ON				: t_OUT_ON;
	signal START_SENDING_TM_int : std_logic;

	


-- SCIENCE I/Q	
	signal wr_en_science			: std_logic;
	signal PIXELNUM_SCIENCE			: unsigned (7 downto 0);
	signal channel_num				: unsigned(0 downto 0);
	signal channel_dump_num			: std_logic_vector(3 downto 0);
	signal SCIENCE_PACKET_NUMBER	: unsigned (31 downto 0);
	signal mem_out_science_I		: t_science_channel;
	signal mem_out_science_Q		: t_science_channel;
	signal shift_enable 			: std_logic;
-- STATE FOR SCIENCE WRITE
	type t_STATE_SCIENCE is (IDLE,WE_SCIENCE_ENTETE,WE_SCIENCE,WE_SCIENCE_END, WE_DUMP_ENTETE, WE_DUMP, WE_COUNT_ENTETE, WE_COUNT);
	signal STATE_SCIENCE				: t_STATE_SCIENCE;
	
-- BIAS AND FEEDBACK
	signal DUMP0					: signed(15 downto 0);
	signal DUMP1					: signed(15 downto 0);

-- COUNT
	signal COUNT						: unsigned (31 downto 0);
	
begin


--	 =============================================================
--	 OUTPUT MODE SELECT AFTER DAQ_ON
--	 =============================================================

P_select_TM:	process(RESET, CLK_4X)
	begin
		if (RESET = '1') then
			OUT_ON <= OFF;
			START_SENDING_TM_int <='0';
		elsif rising_edge(CLK_4X) then
			if ( ENABLE_CLK_1X ='1') then
				START_SENDING_TM_int <= START_SENDING_TM;
				if (select_TM = "1111") then -- envoi du compteur 32 bits
					OUT_ON 			<= SD_COUNT;
				elsif (select_TM = "1000") then
					OUT_ON 			<= SD_SCIENCE;
					else
					OUT_ON 			<= SD_DUMP;
					end if;
				end if;
		end if;
	end process P_select_TM;

Mux_DUMP: process (select_TM,IN_PHYS,BIAS,FEEDBACK, OUT_SCIENCE_UNFILTRED_TP_I(0), OUT_SCIENCE_UNFILTRED_TP_Q(0), OUT_SCIENCE_UNFILTRED_TP_I(1), OUT_SCIENCE_UNFILTRED_TP_Q(1))
begin	
choice_output_DUMP :	 case select_TM is 
								when "0000" 		=> -- sortie de la donnees in_phys et bias  Channel 0 
									DUMP1 				<= resize(IN_PHYS(0),16);
									DUMP0 				<= BIAS(0);
									channel_dump_num <=x"0";
								when "0001" 		=> -- sortie de la donnees in_phys et feedback Channel 0
									DUMP1 				<= resize(IN_PHYS(0),16);
									DUMP0 				<= FEEDBACK(0);
									channel_dump_num <=x"0";
								when "0010" 		=> -- sortie des bias et feedback Channel 0
									DUMP1 				<= BIAS(0);
									DUMP0 				<= FEEDBACK(0);
									channel_dump_num <=x"0";
								when "0100" 		=> -- sortie de la donnees in_phys et bias  Channel 1 
									DUMP1 				<= resize(IN_PHYS(1),16);
									DUMP0 				<= BIAS(1);
									channel_dump_num <=x"1";
								when "0101" 		=> -- sortie de la donnees in_phys et feedback Channel 1
									DUMP1 				<= resize(IN_PHYS(1),16);
									DUMP0 				<= FEEDBACK(1);
									channel_dump_num <=x"1";
								when "0110" 		=> -- sortie des bias et feedback Channel 1
									DUMP1 				<= BIAS(1);
									DUMP0 				<= FEEDBACK(1);
									channel_dump_num <=x"1";
								when "1001" 		=>	-- sortie science I & Q @ Fs = 20 MHz Channel 0 Pixel de test
									DUMP1 				<= OUT_SCIENCE_UNFILTRED_TP_I(0);
									DUMP0 				<= OUT_SCIENCE_UNFILTRED_TP_Q(0);
									channel_dump_num <=x"0";
								when "1010" 		=>	-- sortie science I & Q @ Fs = 20 MHz Channel 1 Pixel de test
									DUMP1 				<= OUT_SCIENCE_UNFILTRED_TP_I(1);
									DUMP0 				<= OUT_SCIENCE_UNFILTRED_TP_Q(1);
									channel_dump_num <=x"1";
								when others =>
								-- sortie par defaut a zero
									DUMP1 				<= x"0000";
									DUMP0 				<= x"0000";
									channel_dump_num <=x"0";
								end case choice_output_DUMP;
end process Mux_DUMP;								
-- selection des sorties en fonction du registre select_TM_DATA_TO_GSE
	
DAQ_HEADER <= x"DADA";

P_shift_IQ:	process(RESET, CLK_4X)
	begin
		if (RESET = '1') then
			mem_out_science_I <= (others=>(others=>(others=>'0')));
			mem_out_science_Q <= (others=>(others=>(others=>'0')));
		elsif rising_edge(CLK_4X) then
			if ( ENABLE_CLK_1X ='1') then 
				if (OUT_ON = SD_SCIENCE AND	START_SENDING_TM_int = '1') then
					if (ENABLE_CLK_1X_DIV128 ='1') then
					mem_out_science_I(0) <= OUT_SCIENCE_FILTRED_I(0);
					mem_out_science_Q(0) <= OUT_SCIENCE_FILTRED_Q(0);
					mem_out_science_I(1) <= (others=>(others=>'0'));
					mem_out_science_Q(1) <= (others=>(others=>'0'));
					else 
						if (shift_enable = '1') then 
						mem_out_science_I(0)(0) <= mem_out_science_I(0)(1);
						mem_out_science_I(0)(1) <= mem_out_science_I(0)(2);
						mem_out_science_I(0)(2) <= mem_out_science_I(0)(3);
						mem_out_science_I(0)(3) <= mem_out_science_I(0)(4);
						mem_out_science_I(0)(4) <= mem_out_science_I(0)(5);
						mem_out_science_I(0)(5) <= mem_out_science_I(0)(6);
						mem_out_science_I(0)(6) <= mem_out_science_I(0)(7);
						mem_out_science_I(0)(7) <= mem_out_science_I(0)(8);
						mem_out_science_I(0)(8) <= mem_out_science_I(0)(9);
						mem_out_science_I(0)(9) <= mem_out_science_I(0)(10);
						mem_out_science_I(0)(10) <= mem_out_science_I(0)(11);
						mem_out_science_I(0)(11) <= mem_out_science_I(0)(12);
						mem_out_science_I(0)(12) <= mem_out_science_I(0)(13);
						mem_out_science_I(0)(13) <= mem_out_science_I(0)(14);
						mem_out_science_I(0)(14) <= mem_out_science_I(0)(15);
						mem_out_science_I(0)(15) <= mem_out_science_I(0)(16);
						mem_out_science_I(0)(16) <= mem_out_science_I(0)(17);
						mem_out_science_I(0)(17) <= mem_out_science_I(0)(18);
						mem_out_science_I(0)(18) <= mem_out_science_I(0)(19);
						mem_out_science_I(0)(19) <= mem_out_science_I(0)(20);
						mem_out_science_I(0)(20) <= mem_out_science_I(0)(21);
						mem_out_science_I(0)(21) <= mem_out_science_I(0)(22);
						mem_out_science_I(0)(22) <= mem_out_science_I(0)(23);
						mem_out_science_I(0)(23) <= mem_out_science_I(0)(24);
						mem_out_science_I(0)(24) <= mem_out_science_I(0)(25);
						mem_out_science_I(0)(25) <= mem_out_science_I(0)(26);
						mem_out_science_I(0)(26) <= mem_out_science_I(0)(27);
						mem_out_science_I(0)(27) <= mem_out_science_I(0)(28);
						mem_out_science_I(0)(28) <= mem_out_science_I(0)(29);
						mem_out_science_I(0)(29) <= mem_out_science_I(0)(30);
						mem_out_science_I(0)(30) <= mem_out_science_I(0)(31);
						mem_out_science_I(0)(31) <= mem_out_science_I(0)(32);
						mem_out_science_I(0)(32) <= mem_out_science_I(0)(33);
						mem_out_science_I(0)(33) <= mem_out_science_I(0)(34);
						mem_out_science_I(0)(34) <= mem_out_science_I(0)(35);
						mem_out_science_I(0)(35) <= mem_out_science_I(0)(36);
						mem_out_science_I(0)(36) <= mem_out_science_I(0)(37);
						mem_out_science_I(0)(37) <= mem_out_science_I(0)(38);
						mem_out_science_I(0)(38) <= mem_out_science_I(0)(39);
						mem_out_science_I(0)(39) <= mem_out_science_I(0)(40);
						mem_out_science_Q(0)(0) <= mem_out_science_Q(0)(1);
						mem_out_science_Q(0)(1) <= mem_out_science_Q(0)(2);
						mem_out_science_Q(0)(2) <= mem_out_science_Q(0)(3);
						mem_out_science_Q(0)(3) <= mem_out_science_Q(0)(4);
						mem_out_science_Q(0)(4) <= mem_out_science_Q(0)(5);
						mem_out_science_Q(0)(5) <= mem_out_science_Q(0)(6);
						mem_out_science_Q(0)(6) <= mem_out_science_Q(0)(7);
						mem_out_science_Q(0)(7) <= mem_out_science_Q(0)(8);
						mem_out_science_Q(0)(8) <= mem_out_science_Q(0)(9);
						mem_out_science_Q(0)(9) <= mem_out_science_Q(0)(10);
						mem_out_science_Q(0)(10) <= mem_out_science_Q(0)(11);
						mem_out_science_Q(0)(11) <= mem_out_science_Q(0)(12);
						mem_out_science_Q(0)(12) <= mem_out_science_Q(0)(13);
						mem_out_science_Q(0)(13) <= mem_out_science_Q(0)(14);
						mem_out_science_Q(0)(14) <= mem_out_science_Q(0)(15);
						mem_out_science_Q(0)(15) <= mem_out_science_Q(0)(16);
						mem_out_science_Q(0)(16) <= mem_out_science_Q(0)(17);
						mem_out_science_Q(0)(17) <= mem_out_science_Q(0)(18);
						mem_out_science_Q(0)(18) <= mem_out_science_Q(0)(19);
						mem_out_science_Q(0)(19) <= mem_out_science_Q(0)(20);
						mem_out_science_Q(0)(20) <= mem_out_science_Q(0)(21);
						mem_out_science_Q(0)(21) <= mem_out_science_Q(0)(22);
						mem_out_science_Q(0)(22) <= mem_out_science_Q(0)(23);
						mem_out_science_Q(0)(23) <= mem_out_science_Q(0)(24);
						mem_out_science_Q(0)(24) <= mem_out_science_Q(0)(25);
						mem_out_science_Q(0)(25) <= mem_out_science_Q(0)(26);
						mem_out_science_Q(0)(26) <= mem_out_science_Q(0)(27);
						mem_out_science_Q(0)(27) <= mem_out_science_Q(0)(28);
						mem_out_science_Q(0)(28) <= mem_out_science_Q(0)(29);
						mem_out_science_Q(0)(29) <= mem_out_science_Q(0)(30);
						mem_out_science_Q(0)(30) <= mem_out_science_Q(0)(31);
						mem_out_science_Q(0)(31) <= mem_out_science_Q(0)(32);
						mem_out_science_Q(0)(32) <= mem_out_science_Q(0)(33);
						mem_out_science_Q(0)(33) <= mem_out_science_Q(0)(34);
						mem_out_science_Q(0)(34) <= mem_out_science_Q(0)(35);
						mem_out_science_Q(0)(35) <= mem_out_science_Q(0)(36);
						mem_out_science_Q(0)(36) <= mem_out_science_Q(0)(37);
						mem_out_science_Q(0)(37) <= mem_out_science_Q(0)(38);
						mem_out_science_Q(0)(38) <= mem_out_science_Q(0)(39);
						mem_out_science_Q(0)(39) <= mem_out_science_Q(0)(40);

--							mem_out_science_I(1)(0) <= mem_out_science_I(1)(1);
--							mem_out_science_I(1)(1) <= mem_out_science_I(1)(2);
--							mem_out_science_I(1)(2) <= mem_out_science_I(1)(3);
--							mem_out_science_I(1)(3) <= mem_out_science_I(1)(4);
--							mem_out_science_I(1)(4) <= mem_out_science_I(1)(5);
--							mem_out_science_I(1)(5) <= mem_out_science_I(1)(6);
--							mem_out_science_I(1)(6) <= mem_out_science_I(1)(7);
--							mem_out_science_I(1)(7) <= mem_out_science_I(1)(8);
--							mem_out_science_I(1)(8) <= mem_out_science_I(1)(9);
--							mem_out_science_I(1)(9) <= mem_out_science_I(1)(10);
--							mem_out_science_I(1)(10) <= mem_out_science_I(1)(11);
--							mem_out_science_I(1)(11) <= mem_out_science_I(1)(12);
--							mem_out_science_I(1)(12) <= mem_out_science_I(1)(13);
--							mem_out_science_I(1)(13) <= mem_out_science_I(1)(14);
--							mem_out_science_I(1)(14) <= mem_out_science_I(1)(15);
--							mem_out_science_I(1)(15) <= mem_out_science_I(1)(16);
--							mem_out_science_I(1)(16) <= mem_out_science_I(1)(17);
--							mem_out_science_I(1)(17) <= mem_out_science_I(1)(18);
--							mem_out_science_I(1)(18) <= mem_out_science_I(1)(19);
--							mem_out_science_I(1)(19) <= mem_out_science_I(1)(20);
--							mem_out_science_I(1)(20) <= mem_out_science_I(1)(21);
--							mem_out_science_I(1)(21) <= mem_out_science_I(1)(22);
--							mem_out_science_I(1)(22) <= mem_out_science_I(1)(23);
--							mem_out_science_I(1)(23) <= mem_out_science_I(1)(24);
--							mem_out_science_I(1)(24) <= mem_out_science_I(1)(25);
--							mem_out_science_I(1)(25) <= mem_out_science_I(1)(26);
--							mem_out_science_I(1)(26) <= mem_out_science_I(1)(27);
--							mem_out_science_I(1)(27) <= mem_out_science_I(1)(28);
--							mem_out_science_I(1)(28) <= mem_out_science_I(1)(29);
--							mem_out_science_I(1)(29) <= mem_out_science_I(1)(30);
--							mem_out_science_I(1)(30) <= mem_out_science_I(1)(31);
--							mem_out_science_I(1)(31) <= mem_out_science_I(1)(32);
--							mem_out_science_I(1)(32) <= mem_out_science_I(1)(33);
--							mem_out_science_I(1)(33) <= mem_out_science_I(1)(34);
--							mem_out_science_I(1)(34) <= mem_out_science_I(1)(35);
--							mem_out_science_I(1)(35) <= mem_out_science_I(1)(36);
--							mem_out_science_I(1)(36) <= mem_out_science_I(1)(37);
--							mem_out_science_I(1)(37) <= mem_out_science_I(1)(38);
--							mem_out_science_I(1)(38) <= mem_out_science_I(1)(39);
--							mem_out_science_I(1)(39) <= mem_out_science_I(1)(40);
--							mem_out_science_Q(1)(0) <= mem_out_science_Q(1)(1);
--							mem_out_science_Q(1)(1) <= mem_out_science_Q(1)(2);
--							mem_out_science_Q(1)(2) <= mem_out_science_Q(1)(3);
--							mem_out_science_Q(1)(3) <= mem_out_science_Q(1)(4);
--							mem_out_science_Q(1)(4) <= mem_out_science_Q(1)(5);
--							mem_out_science_Q(1)(5) <= mem_out_science_Q(1)(6);
--							mem_out_science_Q(1)(6) <= mem_out_science_Q(1)(7);
--							mem_out_science_Q(1)(7) <= mem_out_science_Q(1)(8);
--							mem_out_science_Q(1)(8) <= mem_out_science_Q(1)(9);
--							mem_out_science_Q(1)(9) <= mem_out_science_Q(1)(10);
--							mem_out_science_Q(1)(10) <= mem_out_science_Q(1)(11);
--							mem_out_science_Q(1)(11) <= mem_out_science_Q(1)(12);
--							mem_out_science_Q(1)(12) <= mem_out_science_Q(1)(13);
--							mem_out_science_Q(1)(13) <= mem_out_science_Q(1)(14);
--							mem_out_science_Q(1)(14) <= mem_out_science_Q(1)(15);
--							mem_out_science_Q(1)(15) <= mem_out_science_Q(1)(16);
--							mem_out_science_Q(1)(16) <= mem_out_science_Q(1)(17);
--							mem_out_science_Q(1)(17) <= mem_out_science_Q(1)(18);
--							mem_out_science_Q(1)(18) <= mem_out_science_Q(1)(19);
--							mem_out_science_Q(1)(19) <= mem_out_science_Q(1)(20);
--							mem_out_science_Q(1)(20) <= mem_out_science_Q(1)(21);
--							mem_out_science_Q(1)(21) <= mem_out_science_Q(1)(22);
--							mem_out_science_Q(1)(22) <= mem_out_science_Q(1)(23);
--							mem_out_science_Q(1)(23) <= mem_out_science_Q(1)(24);
--							mem_out_science_Q(1)(24) <= mem_out_science_Q(1)(25);
--							mem_out_science_Q(1)(25) <= mem_out_science_Q(1)(26);
--							mem_out_science_Q(1)(26) <= mem_out_science_Q(1)(27);
--							mem_out_science_Q(1)(27) <= mem_out_science_Q(1)(28);
--							mem_out_science_Q(1)(28) <= mem_out_science_Q(1)(29);
--							mem_out_science_Q(1)(29) <= mem_out_science_Q(1)(30);
--							mem_out_science_Q(1)(30) <= mem_out_science_Q(1)(31);
--							mem_out_science_Q(1)(31) <= mem_out_science_Q(1)(32);
--							mem_out_science_Q(1)(32) <= mem_out_science_Q(1)(33);
--							mem_out_science_Q(1)(33) <= mem_out_science_Q(1)(34);
--							mem_out_science_Q(1)(34) <= mem_out_science_Q(1)(35);
--							mem_out_science_Q(1)(35) <= mem_out_science_Q(1)(36);
--							mem_out_science_Q(1)(36) <= mem_out_science_Q(1)(37);
--							mem_out_science_Q(1)(37) <= mem_out_science_Q(1)(38);
--							mem_out_science_Q(1)(38) <= mem_out_science_Q(1)(39);
--							mem_out_science_Q(1)(39) <= mem_out_science_Q(1)(40);

						end if;
					end if;
				end if;
			end if;
		end if;
	end process P_shift_IQ;
--	 =============================================================
--	 SCIENCE I/Q IN FIFO WHEN DAQ enable with CLK_4X enable_CLK_1X
--	 =============================================================
P_sending_TM:	process(RESET, CLK_4X)
	begin
		if (RESET = '1') then
			wr_en_science	<= '0';
			TM_DATA_TO_GSE 	<= (others=>'0');
			PIXELNUM_SCIENCE<= x"FD";
			STATE_SCIENCE 	<= IDLE;
			SCIENCE_PACKET_NUMBER <= (others=>'0');
			channel_num		<= "0";
			shift_enable <= '0';
			COUNT		 	<= (others=>'0');
		elsif rising_edge(CLK_4X) then
			if ( ENABLE_CLK_1X ='1') then 
					case STATE_SCIENCE is 
							when IDLE =>
								TM_DATA_TO_GSE 		<=(others=>'0');
								wr_en_science		<= '0';
								PIXELNUM_SCIENCE	<= x"FE";
								channel_num			<= "0";
								COUNT		 		<= (others=>'0');
								shift_enable 		<= '0';
								SCIENCE_PACKET_NUMBER <= SCIENCE_PACKET_NUMBER;
								if (OUT_ON = SD_SCIENCE AND	START_SENDING_TM_int = '1') then
									if (ENABLE_CLK_1X_DIV128 ='1') then
										STATE_SCIENCE <= WE_SCIENCE_ENTETE;
										PIXELNUM_SCIENCE	<= x"FE";
										TM_DATA_TO_GSE <=(DAQ_HEADER & x"8" & "000" & std_logic_vector(channel_num) & x"2A");
									else 
										STATE_SCIENCE <= IDLE;
									end if;
								else 
									if (OUT_ON = SD_DUMP AND	START_SENDING_TM_int = '1') then
										TM_DATA_TO_GSE 	<= (DAQ_HEADER  & std_logic_vector(select_TM) & channel_dump_num & x"00");
										STATE_SCIENCE <= WE_DUMP_ENTETE;
									else	
										if (OUT_ON = SD_COUNT AND	START_SENDING_TM_int = '1') then
											STATE_SCIENCE <= WE_COUNT_ENTETE;
										else
											STATE_SCIENCE <= IDLE;
										end if;
									end if;
								end if;
							when WE_SCIENCE_ENTETE =>
									wr_en_science	<= '1';
									if ( PIXELNUM_SCIENCE = x"FF") then
										PIXELNUM_SCIENCE	<= PIXELNUM_SCIENCE + 1;
										SCIENCE_PACKET_NUMBER <= SCIENCE_PACKET_NUMBER + 1;
										TM_DATA_TO_GSE 		 <= std_logic_vector(SCIENCE_PACKET_NUMBER);
										STATE_SCIENCE 		 <= WE_SCIENCE_ENTETE;
										shift_enable <= '1';
									else
										if ( PIXELNUM_SCIENCE /=x"00") then
											PIXELNUM_SCIENCE <= PIXELNUM_SCIENCE + 1;
											TM_DATA_TO_GSE <=(DAQ_HEADER & x"8" & "000" & std_logic_vector(channel_num) & x"2A");
											shift_enable <= '0';
											STATE_SCIENCE 	 <= WE_SCIENCE_ENTETE;
										else 
											wr_en_science	<= '1';
											PIXELNUM_SCIENCE <= PIXELNUM_SCIENCE+1;
											shift_enable <= '1';
											TM_DATA_TO_GSE	 <= std_logic_vector(unsigned(mem_out_science_Q(to_integer(channel_num))(0))) &  std_logic_vector(unsigned(mem_out_science_I(to_integer(channel_num))(0)));
												
										--wilfried		TM_DATA_TO_GSE	 <= std_logic_vector(unsigned(PIXELNUM_SCIENCE)) & std_logic_vector(unsigned(PIXELNUM_SCIENCE+1)) & std_logic_vector(unsigned(PIXELNUM_SCIENCE+2))& std_logic_vector(unsigned(PIXELNUM_SCIENCE+3));
											STATE_SCIENCE 	 <= WE_SCIENCE;
										end if;
									end if;
							when WE_SCIENCE =>

									wr_en_science	<= '1';
									shift_enable <= '1';
									TM_DATA_TO_GSE 			<= std_logic_vector(unsigned(mem_out_science_Q(to_integer(channel_num))(0))) &  std_logic_vector(unsigned(mem_out_science_I(to_integer(channel_num))(0)));
									PIXELNUM_SCIENCE		<= PIXELNUM_SCIENCE + 1;
									if ( PIXELNUM_SCIENCE < (C_Nb_pixel-1)) then
										STATE_SCIENCE 		<= WE_SCIENCE;
										
									else 
										STATE_SCIENCE 		<= WE_SCIENCE_END;
										shift_enable <= '0';
										PIXELNUM_SCIENCE	<= PIXELNUM_SCIENCE; 
									end if;
									
							when WE_SCIENCE_END =>
									shift_enable 	<= '0';
										if (C_Nb_channel = 1 ) then
											STATE_SCIENCE 		<= IDLE;
											PIXELNUM_SCIENCE	<= x"FE";
											wr_en_science	<= '0';
										else
											if (channel_num = "0") then
												PIXELNUM_SCIENCE	<= x"FE";
												STATE_SCIENCE <= WE_SCIENCE_ENTETE;
												channel_num <= "1";
												TM_DATA_TO_GSE <=(DAQ_HEADER & x"8" & "000" & std_logic_vector(channel_num) & x"2A");
												wr_en_science	<= '0';
											else 
												STATE_SCIENCE 		<= IDLE;
												PIXELNUM_SCIENCE	<= x"FE";
												wr_en_science	<= '0';
												channel_num <= "0";
											end if;
										end if;
--	 =============================================================
--	 BIAS AND FEEDBACK IN FIFO WHEN DAQ enable with CLK_4X enable_CLK_1X
--	 =============================================================
							when WE_DUMP_ENTETE =>
								TM_DATA_TO_GSE 	<= (DAQ_HEADER  & std_logic_vector(select_TM) & channel_dump_num & x"00");
								STATE_SCIENCE <= WE_DUMP;
								wr_en_science	<= '1';
							when WE_DUMP	=>
								TM_DATA_TO_GSE 	<= std_logic_vector(DUMP0) & std_logic_vector(DUMP1);
								wr_en_science	<= '1';
								if (OUT_ON = SD_DUMP AND	START_SENDING_TM_int = '1') then
									STATE_SCIENCE <= WE_DUMP;
								else
								wr_en_science	<= '0';
								STATE_SCIENCE <= IDLE;
								end if;
--	 =============================================================
--	 COUNTER(32) IN FIFO WHEN DAQ enable with CLK_4X enable_CLK_1X_DIV2
--	 =============================================================
							when WE_COUNT_ENTETE =>
								COUNT		 	<= (others=>'0');
								TM_DATA_TO_GSE 	<=(DAQ_HEADER  & std_logic_vector(select_TM) & x"0" & x"00");
								STATE_SCIENCE <= WE_COUNT;
								wr_en_science	<= '1';
								
							when WE_COUNT	=>
								TM_DATA_TO_GSE 	<= std_logic_vector(COUNT);
								wr_en_science	<= '1';
								if (OUT_ON = SD_COUNT AND	START_SENDING_TM_int = '1') then
									COUNT		<= COUNT + 1;
									STATE_SCIENCE <= WE_COUNT;
								else
									COUNT		 	<= (others=>'0');
									wr_en_science	<= '0';
									STATE_SCIENCE <= IDLE;
								end if;
--							when others =>
--							STATE_SCIENCE <= IDLE;
					end case;
			else 
				wr_en_science	<= '0';
			end if;
		end if;
	end process P_sending_TM;
	
WR_en_TM_fifo <= 	wr_en_science;
					

end Behavioral;

