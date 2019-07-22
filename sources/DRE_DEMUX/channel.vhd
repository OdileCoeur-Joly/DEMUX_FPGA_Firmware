----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : CHANNEL - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Create a sizeable channel of N pixels
--
-- Dependencies: FEEDBACK_ADDER, PIXEL,Slope_bias, Digital_TRC
--
-- Revision:1.02 ajout des filtres all_pass filter en sortie bias et feedback
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------1234oOOOo(o_o)oOOOo-----------------------------


library IEEE;
  use ieee.std_logic_1164.all;
  use work.athena_package.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity channel is
    Port 	(
 --RESET
           RESET 						: in  	STD_LOGIC;
 --CLOCK
           CLK_4X 						: in  	STD_LOGIC;
           ENABLE_CLK_1X 				: in  	STD_LOGIC;
           ENABLE_CLK_1X_DIV128			: in  	STD_LOGIC;
--CONTROL
		   CONTROL						: in	t_CONTROL_CHANNEL;
		   CONSTANT_FB					: in 	signed(15 downto 0);

		   IN_PHYS	 					: in  	signed	(C_Size_In_Real-1 downto 0);
           BIAS 						: out  	signed	(C_Size_bias_to_DAC-1 downto 0);
           FEEDBACK 					: out  	signed	(C_Size_feedback_to_DAC-1 downto 0);
           OUT_SCIENCE_UNFILTRED_TP_I	: out 	signed(C_Size_science-1 downto 0);
           OUT_SCIENCE_UNFILTRED_TP_Q	: out 	signed(C_Size_science-1 downto 0);
           OUT_SCIENCE_FILTRED_I		: out  	t_science;
           OUT_SCIENCE_FILTRED_Q		: out  	t_science
			  );
end channel;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.channel.Behavioral.svg
architecture Behavioral of channel is


type t_IN_PHYS_PIXELS 			is array (C_Nb_pixel-1 downto 0) 	of signed(C_Size_In_Real-1 downto 0);				--type array of phys input
type t_BIAS_PIXELS		 		is array (C_Nb_pixel-1 downto 0) 	of signed(C_Size_DDS-1 downto 0);					--type array of bias output
type t_BIAS_ADDER_S1	 		is array (9 downto 0) 		   		of signed(C_Size_BIAS_ST1_adder_out-1 downto 0);					--type array of bias output
type t_BIAS_ADDER_S2	 		is array (2 downto 0) 		   		of signed(C_Size_BIAS_ST2_adder_out-1 downto 0);					--type array of bias output
type t_FEEDBACK_PIXELS		 	is array (C_Nb_pixel-1 downto 0) 	of signed(C_Size_one_feedback-1 downto 0);			--type array of feedback output
type t_FEEDBACK_ADDER_S1	 	is array (9 downto 0) 		   		of signed(C_Size_FEEDBACK_ST1_adder_out-1 downto 0);					--type array of bias output
type t_FEEDBACK_ADDER_S2	 	is array (2 downto 0) 		   		of signed(C_Size_FEEDBACK_ST2_adder_out-1 downto 0);					--type array of bias output
--type t_BIAS_SUM_PIXELS			is array (Nb_pixel-1 downto 0) of signed(Size_BIAS_adder_out-1 downto 0);		--type array of bias output
--type t_FEEDBACK_SUM_PIXELS		is array (Nb_pixel-1 downto 0) of signed(Size_feedback_adder_out-1 downto 0);	--type array of feedback output

--signal		OUT_SCIENCE_FILTRED_I_PIXELS		: t_science;									-- all pixels array Science I output signals
--signal		OUT_SCIENCE_FILTRED_Q_PIXELS 		: t_science;									-- all pixels array Science Q output signals
signal		IN_PHYS_PIXELS				: t_IN_PHYS_PIXELS;								-- all pixels physical input signal
signal		BIAS_PIXELS		 			: t_BIAS_PIXELS;								-- all pixels BIAS signals
signal		FEEDBACK_PIXELS 			: t_FEEDBACK_PIXELS;							-- all pixels FEEDBACK signals
--signal		BIAS_SUM_PIXELS				: t_BIAS_SUM_PIXELS;							-- adder bias signals 
signal		BIAS_ADDER_OUT_STAGE1		: t_BIAS_ADDER_S1;								-- adder bias signals 
signal		BIAS_ADDER_OUT_STAGE2		: t_BIAS_ADDER_S2;								-- adder bias signals 
signal		BIAS_ADDER_OUT_STAGE3		: signed(C_Size_BIAS_ST3_adder_out - 1 downto 0);	-- adder bias signals 
signal		FEEDBACK_ADDER_OUT_STAGE1	: t_FEEDBACK_ADDER_S1;								-- adder bias signals 
signal		FEEDBACK_ADDER_OUT_STAGE2	: t_FEEDBACK_ADDER_S2;								-- adder bias signals 
signal		FEEDBACK_ADDER_OUT_STAGE3	: signed(C_Size_FEEDBACK_ST3_adder_out - 1 downto 0);	-- adder bias signals 
--signal		FEEDBACK_SUM_PIXELS		: t_FEEDBACK_SUM_PIXELS;						-- adder Feedback signals
signal 		BIAS_TEST_PIXEL_TO_PULSE	: signed(C_Size_DDS-1 downto 0);
signal		BIAS_TEST_PIXEL				: signed(C_Size_DDS-1 downto 0);					-- output bias of test pixel
signal		BIAS_TO_AMP					: signed(C_Size_bias_to_DAC- 1 downto 0);			-- Link between BIAS truncation output and Rampe module
signal		BIAS_TO_TRC					: signed(C_Size_BIAS_ST3_adder_out -	1 downto 0);	-- link from BIAS adder to bias truncation
signal		BIAS_onoff					: signed(C_Size_bias_to_DAC-	1 downto 0);		-- Bias on off output to bias channel output
signal		FEEDBACK_TO_COMPENSATION	: signed(C_Size_FEEDBACK_ST3_adder_out - 1 downto 0);	-- Feedback Adder output to gain compensation
signal		FEEDBACK_TO_TRC				: signed(C_Size_FEEDBACK_ST3_adder_out - 1 downto 0);	-- Feedback compensation output to truncation
signal		FEEDBACK_onoff				: signed(C_Size_feedback_to_DAC - 1 downto 0);	-- Feedback on off output to bias channel output
begin
-----------------------------------------------------------------------------------
-- PIXELS GENERATION
-----------------------------------------------------------------------------------

	GENERATION_PIXELS : for N in C_Nb_pixel-2 downto 0 generate
		TES_40_pixels : entity work.pixel
		Port map (
							Reset 					=> RESET,
							START_STOP 				=> CONTROL.START_STOP,

							CLK_4X 					=> CLK_4X,
							ENABLE_CLK_1X 			=> ENABLE_CLK_1X,
							ENABLE_CLK_1X_DIV128 	=> ENABLE_CLK_1X_DIV128,

							CONTROL_PIXEL_BBFB 		=> CONTROL.CONTROL_PIXELS(N),
							CONSTANT_FB 			=> CONSTANT_FB,

							In_phys 				=> IN_PHYS_PIXELS(N),
							Bias 					=> BIAS_PIXELS(N),
							Feedback 				=> FEEDBACK_PIXELS(N),
							Out_unfiltred_I 		=> open,
							Out_unfiltred_Q 		=> open,
							Out_filtred_I 			=> OUT_SCIENCE_FILTRED_I(N),
							Out_filtred_Q 			=> OUT_SCIENCE_FILTRED_Q(N)

						);

		IN_PHYS_PIXELS(N)						<= IN_PHYS; -- the same IN_PHYS of the channel input is transmited to all pixels
		end generate GENERATION_PIXELS;
-----------------------------------------------------------------------------------
-- TEST PIXEL GENERATION
-----------------------------------------------------------------------------------
		TEST_pixel1 : entity work.pixel
		Port map (
							Reset 					=> RESET,
							START_STOP 				=> CONTROL.START_STOP,

							CLK_4X 					=> CLK_4X,
							ENABLE_CLK_1X 			=> ENABLE_CLK_1X,
							ENABLE_CLK_1X_DIV128	=> ENABLE_CLK_1X_DIV128,

							CONTROL_PIXEL_BBFB 		=> CONTROL.CONTROL_PIXELS(C_Nb_pixel-1),
							CONSTANT_FB 			=> CONSTANT_FB,

							In_phys 				=> IN_PHYS_PIXELS(C_Nb_pixel-1),
							Bias 					=> BIAS_TEST_PIXEL,
							Feedback 				=> FEEDBACK_PIXELS(C_Nb_pixel-1),
							Out_unfiltred_I 		=> OUT_SCIENCE_UNFILTRED_TP_I,
							Out_unfiltred_Q 		=> OUT_SCIENCE_UNFILTRED_TP_Q,
							Out_filtred_I 			=> OUT_SCIENCE_FILTRED_I(C_Nb_pixel-1),
							Out_filtred_Q 			=> OUT_SCIENCE_FILTRED_Q(C_Nb_pixel-1)

						);

		IN_PHYS_PIXELS(C_Nb_pixel-1)						<= IN_PHYS;		

-----------------------------------------------------------------------------------
-- TEST PIXEL MODULATION
-----------------------------------------------------------------------------------

TEST_Pixel_Bias_Modulation: entity work.BIAS_modulation
port map (
   CLK_4X						=> CLK_4X,
   ENABLE_CLK_1X				=> ENABLE_CLK_1X,
   Reset						=> RESET,
   START_STOP					=> CONTROL.START_STOP,
   BIAS_modulation_increment 	=> CONTROL.BIAS_modulation_increment,
   BIAS_modulation_amplitude 	=> CONTROL.BIAS_modulation_amplitude,
--   bias_amplitude				=> CONTROL.CONTROL_PIXELS(C_Nb_pixel-1).BIAS_amplitude,
   BIAS_in						=> BIAS_TEST_PIXEL,
   BIAS_Out						=> BIAS_TEST_PIXEL_TO_PULSE
    );
-----------------------------------------------------------------------------------
-- TEST PIXEL PULSE MODULATION
-----------------------------------------------------------------------------------
pulse_modulator_test_pixel: entity work.Pulse_Emulator
	port map(
		Reset           => RESET,
		CLK             => CLK_4X,
		ENABLE_CLK      => ENABLE_CLK_1X,
		Pulse_timescale => CONTROL.Pulse_timescale,
		Pulse_amplitude => CONTROL.Pulse_Amplitude,
		Send_Pulse      => CONTROL.Send_pulse,
		Sig_in          => BIAS_TEST_PIXEL_TO_PULSE,
		Sig_out         => BIAS_PIXELS(C_Nb_pixel-1)
	);	 	 
-----------------------------------------------------------------------------------
-- ADDER OF ALL BIAS and FEEDBACK (with TEST pixel)
-----------------------------------------------------------------------------------


-----------------------------------------------------------------------------------
-- FEEDBACK ADDER
-----------------------------------------------------------------------------------
--									
--	FEEDBACK_SUM_PIXELS(0) <= resize(FEEDBACK_PIXELS(0),Size_feedback_adder_out); 
--	GENERATION_FEEDBACK_FEEDBACK : for N in 1 to Nb_pixel-1 generate
--
--	FEEDBACK_SUM_PIXELS(N) <= FEEDBACK_SUM_PIXELS(N-1) + resize(FEEDBACK_PIXELS(N),Size_feedback_adder_out);
--		end generate GENERATION_FEEDBACK_ADDERS;
adderFED_S1_0 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_PIXELS(0)'length,
		C_size_adder_in2 => FEEDBACK_PIXELS(1)'length,
		C_size_adder_in3 => FEEDBACK_PIXELS(2)'length,
		C_size_adder_in4 => FEEDBACK_PIXELS(3)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST1_adder_out
	)
	port map(
		IN1           => FEEDBACK_PIXELS(0),
		IN2           => FEEDBACK_PIXELS(1),
		IN3           => FEEDBACK_PIXELS(2),
		IN4           => FEEDBACK_PIXELS(3),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE1(0)
	);
adderFED_S1_1 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_PIXELS(4)'length,
		C_size_adder_in2 => FEEDBACK_PIXELS(5)'length,
		C_size_adder_in3 => FEEDBACK_PIXELS(6)'length,
		C_size_adder_in4 => FEEDBACK_PIXELS(7)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST1_adder_out
	)
	port map(
		IN1           => FEEDBACK_PIXELS(4),
		IN2           => FEEDBACK_PIXELS(5),
		IN3           => FEEDBACK_PIXELS(6),
		IN4           => FEEDBACK_PIXELS(7),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE1(1)
	);
adderFED_S1_2 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_PIXELS(8)'length,
		C_size_adder_in2 => FEEDBACK_PIXELS(9)'length,
		C_size_adder_in3 => FEEDBACK_PIXELS(10)'length,
		C_size_adder_in4 => FEEDBACK_PIXELS(11)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST1_adder_out
	)
	port map(
		IN1           => FEEDBACK_PIXELS(8),
		IN2           => FEEDBACK_PIXELS(9),
		IN3           => FEEDBACK_PIXELS(10),
		IN4           => FEEDBACK_PIXELS(11),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE1(2)
	);
adderFED_S1_3 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_PIXELS(12)'length,
		C_size_adder_in2 => FEEDBACK_PIXELS(13)'length,
		C_size_adder_in3 => FEEDBACK_PIXELS(14)'length,
		C_size_adder_in4 => FEEDBACK_PIXELS(15)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST1_adder_out
	)
	port map(
		IN1           => FEEDBACK_PIXELS(12),
		IN2           => FEEDBACK_PIXELS(13),
		IN3           => FEEDBACK_PIXELS(14),
		IN4           => FEEDBACK_PIXELS(15),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE1(3)
	);
adderFED_S1_4 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_PIXELS(16)'length,
		C_size_adder_in2 => FEEDBACK_PIXELS(17)'length,
		C_size_adder_in3 => FEEDBACK_PIXELS(18)'length,
		C_size_adder_in4 => FEEDBACK_PIXELS(19)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST1_adder_out
	)
	port map(
		IN1           => FEEDBACK_PIXELS(16),
		IN2           => FEEDBACK_PIXELS(17),
		IN3           => FEEDBACK_PIXELS(18),
		IN4           => FEEDBACK_PIXELS(19),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE1(4)
	);
adderFED_S1_5 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_PIXELS(20)'length,
		C_size_adder_in2 => FEEDBACK_PIXELS(21)'length,
		C_size_adder_in3 => FEEDBACK_PIXELS(22)'length,
		C_size_adder_in4 => FEEDBACK_PIXELS(23)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST1_adder_out
	)
	port map(
		IN1           => FEEDBACK_PIXELS(20),
		IN2           => FEEDBACK_PIXELS(21),
		IN3           => FEEDBACK_PIXELS(22),
		IN4           => FEEDBACK_PIXELS(23),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE1(5)
	);
adderFED_S1_6 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_PIXELS(24)'length,
		C_size_adder_in2 => FEEDBACK_PIXELS(25)'length,
		C_size_adder_in3 => FEEDBACK_PIXELS(26)'length,
		C_size_adder_in4 => FEEDBACK_PIXELS(27)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST1_adder_out
	)
	port map(
		IN1           => FEEDBACK_PIXELS(24),
		IN2           => FEEDBACK_PIXELS(25),
		IN3           => FEEDBACK_PIXELS(26),
		IN4           => FEEDBACK_PIXELS(27),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE1(6)
	);
adderFED_S1_7 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_PIXELS(28)'length,
		C_size_adder_in2 => FEEDBACK_PIXELS(29)'length,
		C_size_adder_in3 => FEEDBACK_PIXELS(30)'length,
		C_size_adder_in4 => FEEDBACK_PIXELS(31)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST1_adder_out
	)
	port map(
		IN1           => FEEDBACK_PIXELS(28),
		IN2           => FEEDBACK_PIXELS(29),
		IN3           => FEEDBACK_PIXELS(30),
		IN4           => FEEDBACK_PIXELS(31),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE1(7)
	);
adderFED_S1_8 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_PIXELS(32)'length,
		C_size_adder_in2 => FEEDBACK_PIXELS(33)'length,
		C_size_adder_in3 => FEEDBACK_PIXELS(34)'length,
		C_size_adder_in4 => FEEDBACK_PIXELS(35)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST1_adder_out
	)
	port map(
		IN1           => FEEDBACK_PIXELS(32),
		IN2           => FEEDBACK_PIXELS(33),
		IN3           => FEEDBACK_PIXELS(34),
		IN4           => FEEDBACK_PIXELS(35),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE1(8)
	);
adderFED_S1_9 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_PIXELS(36)'length,
		C_size_adder_in2 => FEEDBACK_PIXELS(37)'length,
		C_size_adder_in3 => FEEDBACK_PIXELS(38)'length,
		C_size_adder_in4 => FEEDBACK_PIXELS(39)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST1_adder_out
	)
	port map(
		IN1           => FEEDBACK_PIXELS(36),
		IN2           => FEEDBACK_PIXELS(37),
		IN3           => FEEDBACK_PIXELS(38),
		IN4           => FEEDBACK_PIXELS(39),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE1(9)
	);
adderFED_S2_0 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_PIXELS(40)'length,
		C_size_adder_in2 => FEEDBACK_ADDER_OUT_STAGE1(0)'length,
		C_size_adder_in3 => FEEDBACK_ADDER_OUT_STAGE1(1)'length,
		C_size_adder_in4 => FEEDBACK_ADDER_OUT_STAGE1(2)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST2_adder_out
	)
	port map(
		IN1           => FEEDBACK_PIXELS(40),
		IN2           => FEEDBACK_ADDER_OUT_STAGE1(0),
		IN3           => FEEDBACK_ADDER_OUT_STAGE1(1),
		IN4           => FEEDBACK_ADDER_OUT_STAGE1(2),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE2(0)
	);
adderFED_S2_1 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_ADDER_OUT_STAGE1(3)'length,
		C_size_adder_in2 => FEEDBACK_ADDER_OUT_STAGE1(4)'length,
		C_size_adder_in3 => FEEDBACK_ADDER_OUT_STAGE1(5)'length,
		C_size_adder_in4 => FEEDBACK_ADDER_OUT_STAGE1(6)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST2_adder_out
	)
	port map(
		IN1           => FEEDBACK_ADDER_OUT_STAGE1(3),
		IN2           => FEEDBACK_ADDER_OUT_STAGE1(4),
		IN3           => FEEDBACK_ADDER_OUT_STAGE1(5),
		IN4           => FEEDBACK_ADDER_OUT_STAGE1(6),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE2(1)
	);
adderFED_S2_2 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_ADDER_OUT_STAGE1(7)'length,
		C_size_adder_in2 => FEEDBACK_ADDER_OUT_STAGE1(8)'length,
		C_size_adder_in3 => FEEDBACK_ADDER_OUT_STAGE1(9)'length,
		C_size_adder_in4 => FEEDBACK_ADDER_OUT_STAGE1(9)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST2_adder_out
	)
	port map(
		IN1           => FEEDBACK_ADDER_OUT_STAGE1(7),
		IN2           => FEEDBACK_ADDER_OUT_STAGE1(8),
		IN3           => FEEDBACK_ADDER_OUT_STAGE1(9),
		IN4           => (others =>'0'),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE2(2)
	);
adderFED_S3_0 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => FEEDBACK_ADDER_OUT_STAGE2(0)'length,
		C_size_adder_in2 => FEEDBACK_ADDER_OUT_STAGE2(1)'length,
		C_size_adder_in3 => FEEDBACK_ADDER_OUT_STAGE2(2)'length,
		C_size_adder_in4 => FEEDBACK_ADDER_OUT_STAGE2(2)'length,
		C_size_adder_out => C_Size_FEEDBACK_ST3_adder_out
	)
	port map(
		IN1           => FEEDBACK_ADDER_OUT_STAGE2(0),
		IN2           => FEEDBACK_ADDER_OUT_STAGE2(1),
		IN3           => FEEDBACK_ADDER_OUT_STAGE2(2),
		IN4           => (others =>'0'),
		ADDER_OUT     => FEEDBACK_ADDER_OUT_STAGE3
	);
----------------------------------------------------------------------------------------------------
-- FEEDBACK ADDER OUT RESINC
----------------------------------------------------------------------------------------------------
P_sync_compens:process (RESET,CLK_4X)
begin
	if (RESET='1') then
	FEEDBACK_TO_COMPENSATION <=(others=>'0');
	elsif (rising_edge(CLK_4X)) then
		if (ENABLE_CLK_1X ='1') then
--	FEEDBACK_TO_COMPENSATION <= FEEDBACK_SUM_PIXELS(Nb_pixel-1);
			FEEDBACK_TO_COMPENSATION <= FEEDBACK_ADDER_OUT_STAGE3;
		end if;
	end if;
end process;		
-------------------------------------------------------------------------------------
---- BIAS ADDER
-------------------------------------------------------------------------------------
--	BIAS_SUM_PIXELS(0) <= resize(BIAS_PIXELS(0),Size_BIAS_adder_out); 
--	GENERATION_BIAS_ADDERS : for N in 1 to Nb_pixel-1 generate
--	BIAS_SUM_PIXELS(N) <= BIAS_SUM_PIXELS(N-1) + resize(BIAS_PIXELS(N),Size_BIAS_adder_out);
--		end generate GENERATION_BIAS_ADDERS;
adderBIAS_S1_0 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_PIXELS(0)'length,
		C_size_adder_in2 => BIAS_PIXELS(1)'length,
		C_size_adder_in3 => BIAS_PIXELS(2)'length,
		C_size_adder_in4 => BIAS_PIXELS(3)'length,
		C_size_adder_out => C_Size_BIAS_ST1_adder_out
	)
	port map(
		IN1           => BIAS_PIXELS(0),
		IN2           => BIAS_PIXELS(1),
		IN3           => BIAS_PIXELS(2),
		IN4           => BIAS_PIXELS(3),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE1(0)
	);
adderBIAS_S1_1 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_PIXELS(4)'length,
		C_size_adder_in2 => BIAS_PIXELS(5)'length,
		C_size_adder_in3 => BIAS_PIXELS(6)'length,
		C_size_adder_in4 => BIAS_PIXELS(7)'length,
		C_size_adder_out => C_Size_BIAS_ST1_adder_out
	)
	port map(
		IN1           => BIAS_PIXELS(4),
		IN2           => BIAS_PIXELS(5),
		IN3           => BIAS_PIXELS(6),
		IN4           => BIAS_PIXELS(7),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE1(1)
	);
adderBIAS_S1_2 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_PIXELS(8)'length,
		C_size_adder_in2 => BIAS_PIXELS(9)'length,
		C_size_adder_in3 => BIAS_PIXELS(10)'length,
		C_size_adder_in4 => BIAS_PIXELS(11)'length,
		C_size_adder_out => C_Size_BIAS_ST1_adder_out
	)
	port map(
		IN1           => BIAS_PIXELS(8),
		IN2           => BIAS_PIXELS(9),
		IN3           => BIAS_PIXELS(10),
		IN4           => BIAS_PIXELS(11),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE1(2)
	);
adderBIAS_S1_3 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_PIXELS(12)'length,
		C_size_adder_in2 => BIAS_PIXELS(13)'length,
		C_size_adder_in3 => BIAS_PIXELS(14)'length,
		C_size_adder_in4 => BIAS_PIXELS(15)'length,
		C_size_adder_out => C_Size_BIAS_ST1_adder_out
	)
	port map(
		IN1           => BIAS_PIXELS(12),
		IN2           => BIAS_PIXELS(13),
		IN3           => BIAS_PIXELS(14),
		IN4           => BIAS_PIXELS(15),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE1(3)
	);
adderBIAS_S1_4 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_PIXELS(16)'length,
		C_size_adder_in2 => BIAS_PIXELS(17)'length,
		C_size_adder_in3 => BIAS_PIXELS(18)'length,
		C_size_adder_in4 => BIAS_PIXELS(19)'length,
		C_size_adder_out => C_Size_BIAS_ST1_adder_out
	)
	port map(
		IN1           => BIAS_PIXELS(16),
		IN2           => BIAS_PIXELS(17),
		IN3           => BIAS_PIXELS(18),
		IN4           => BIAS_PIXELS(19),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE1(4)
	);
adderBIAS_S1_5 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_PIXELS(20)'length,
		C_size_adder_in2 => BIAS_PIXELS(21)'length,
		C_size_adder_in3 => BIAS_PIXELS(22)'length,
		C_size_adder_in4 => BIAS_PIXELS(23)'length,
		C_size_adder_out => C_Size_BIAS_ST1_adder_out
	)
	port map(
		IN1           => BIAS_PIXELS(20),
		IN2           => BIAS_PIXELS(21),
		IN3           => BIAS_PIXELS(22),
		IN4           => BIAS_PIXELS(23),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE1(5)
	);
adderBIAS_S1_6 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_PIXELS(24)'length,
		C_size_adder_in2 => BIAS_PIXELS(25)'length,
		C_size_adder_in3 => BIAS_PIXELS(26)'length,
		C_size_adder_in4 => BIAS_PIXELS(27)'length,
		C_size_adder_out => C_Size_BIAS_ST1_adder_out
	)
	port map(
		IN1           => BIAS_PIXELS(24),
		IN2           => BIAS_PIXELS(25),
		IN3           => BIAS_PIXELS(26),
		IN4           => BIAS_PIXELS(27),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE1(6)
	);
adderBIAS_S1_7 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_PIXELS(28)'length,
		C_size_adder_in2 => BIAS_PIXELS(29)'length,
		C_size_adder_in3 => BIAS_PIXELS(30)'length,
		C_size_adder_in4 => BIAS_PIXELS(31)'length,
		C_size_adder_out => C_Size_BIAS_ST1_adder_out
	)
	port map(
		IN1           => BIAS_PIXELS(28),
		IN2           => BIAS_PIXELS(29),
		IN3           => BIAS_PIXELS(30),
		IN4           => BIAS_PIXELS(31),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE1(7)
	);
adderBIAS_S1_8 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_PIXELS(32)'length,
		C_size_adder_in2 => BIAS_PIXELS(33)'length,
		C_size_adder_in3 => BIAS_PIXELS(34)'length,
		C_size_adder_in4 => BIAS_PIXELS(35)'length,
		C_size_adder_out => C_Size_BIAS_ST1_adder_out
	)
	port map(
		IN1           => BIAS_PIXELS(32),
		IN2           => BIAS_PIXELS(33),
		IN3           => BIAS_PIXELS(34),
		IN4           => BIAS_PIXELS(35),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE1(8)
	);
adderBIAS_S1_9 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_PIXELS(36)'length,
		C_size_adder_in2 => BIAS_PIXELS(37)'length,
		C_size_adder_in3 => BIAS_PIXELS(38)'length,
		C_size_adder_in4 => BIAS_PIXELS(39)'length,
		C_size_adder_out => C_Size_BIAS_ST1_adder_out
	)
	port map(
		IN1           => BIAS_PIXELS(36),
		IN2           => BIAS_PIXELS(37),
		IN3           => BIAS_PIXELS(38),
		IN4           => BIAS_PIXELS(39),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE1(9)
	);
adderBIAS_S2_0 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_PIXELS(40)'length,
		C_size_adder_in2 => BIAS_ADDER_OUT_STAGE1(0)'length,
		C_size_adder_in3 => BIAS_ADDER_OUT_STAGE1(1)'length,
		C_size_adder_in4 => BIAS_ADDER_OUT_STAGE1(2)'length,
		C_size_adder_out => C_Size_BIAS_ST2_adder_out
	)
	port map(
		IN1           =>  BIAS_PIXELS(40),
		IN2           =>  BIAS_ADDER_OUT_STAGE1(0),
		IN3           =>  BIAS_ADDER_OUT_STAGE1(1),
		IN4           =>  BIAS_ADDER_OUT_STAGE1(2),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE2(0)
	);
adderBIAS_S2_1 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_ADDER_OUT_STAGE1(3)'length,
		C_size_adder_in2 => BIAS_ADDER_OUT_STAGE1(4)'length,
		C_size_adder_in3 => BIAS_ADDER_OUT_STAGE1(5)'length,
		C_size_adder_in4 => BIAS_ADDER_OUT_STAGE1(6)'length,
		C_size_adder_out => C_Size_BIAS_ST2_adder_out
	)
	port map(
		IN1           => BIAS_ADDER_OUT_STAGE1(3),
		IN2           => BIAS_ADDER_OUT_STAGE1(4),
		IN3           => BIAS_ADDER_OUT_STAGE1(5),
		IN4           => BIAS_ADDER_OUT_STAGE1(6),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE2(1)
	);
adderBIAS_S2_2 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_ADDER_OUT_STAGE1(7)'length,
		C_size_adder_in2 => BIAS_ADDER_OUT_STAGE1(8)'length,
		C_size_adder_in3 => BIAS_ADDER_OUT_STAGE1(9)'length,
		C_size_adder_in4 => BIAS_ADDER_OUT_STAGE1(9)'length,
		C_size_adder_out => C_Size_BIAS_ST2_adder_out
	)
	port map(
		IN1           => BIAS_ADDER_OUT_STAGE1(7),
		IN2           => BIAS_ADDER_OUT_STAGE1(8),
		IN3           => BIAS_ADDER_OUT_STAGE1(9),
		IN4           => (others =>'0'),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE2(2)
	);
adderBIAS_S3_0 : entity work.adder_4_26b
	generic map(
		C_size_adder_in1 => BIAS_ADDER_OUT_STAGE2(0)'length,
		C_size_adder_in2 => BIAS_ADDER_OUT_STAGE2(1)'length,
		C_size_adder_in3 => BIAS_ADDER_OUT_STAGE2(2)'length,
		C_size_adder_in4 => BIAS_ADDER_OUT_STAGE2(2)'length,
		C_size_adder_out => C_Size_BIAS_ST3_adder_out
	)
	port map(
		IN1           => BIAS_ADDER_OUT_STAGE2(0),
		IN2           => BIAS_ADDER_OUT_STAGE2(1),
		IN3           => BIAS_ADDER_OUT_STAGE2(2),
		IN4           => (others =>'0'),
		ADDER_OUT     => BIAS_ADDER_OUT_STAGE3
	);
----------------------------------------------------------------------------------------------------
-- BIAS ADDER OUT RESINC
----------------------------------------------------------------------------------------------------
P_sync_adder:process (RESET,CLK_4X)
begin
	if (RESET='1') then
	BIAS_TO_TRC <=(others=>'0');
	elsif (rising_edge(CLK_4X)) then
		if (ENABLE_CLK_1X ='1') then
--	BIAS_TO_TRC <= BIAS_SUM_PIXELS(Nb_pixel-1);
			BIAS_TO_TRC <= BIAS_ADDER_OUT_STAGE3;
		end if;
	end if;
end process;		


Feedback_gain_compens: entity work.feedback_gain_compensation
Port map	(
		Reset				=> RESET,
		CLK_4X				=> CLK_4X,
		ENABLE_CLK_1X		=> ENABLE_CLK_1X,
		Compensation_Gain	=> CONTROL.FEEDBACK_compensation_gain,
--		START_STOP   		=> CONTROL.START_STOP,
    
		feedback_in			=> FEEDBACK_TO_COMPENSATION,
		feedback_out		=> FEEDBACK_TO_TRC
		);

-----------------------------------------------------------------------------------
-- BIAS SLOPE
-----------------------------------------------------------------------------------

Pixels_Bias_Slope: entity work.slope_bias
port map (
    		Reset 			=> RESET,
    		CLK_4X 			=> CLK_4X,
    		ENABLE_CLK_1X 	=> ENABLE_CLK_1X,
    		slope_speed 	=> CONTROL.BIAS_slope_speed,
    		START_STOP 		=> CONTROL.START_STOP,
    		bias_in 		=> BIAS_TO_AMP,
    		bias_out 		=> BIAS_onoff
    );


Truncation_BIAS_FEEDBACK : entity work.digital_TRC 

port map
		( 
		reset 					=> RESET,

		CLK_4X					=> CLK_4X,
		ENABLE_CLK_1X 			=> ENABLE_CLK_1X,

		BIAS_truncation			=> CONTROL.BIAS_truncation,
		FEEDBACK_truncation		=> CONTROL.FEEDBACK_truncation,
		
	
		signal_in_BIAS			=> BIAS_TO_TRC,
		signal_in_FEEDBACK		=> FEEDBACK_TO_TRC,
		
		signal_out_BIAS			=>	BIAS_TO_AMP,
		signal_out_FEEDBACK		=>	FEEDBACK_onoff
	);

-------------------------------------------------------------------------------
--          BIAS OUTPUT ON/OFF
-------------------------------------------------------------------------------

BIAS	 <=	BIAS_onoff				when  CONTROL.BIAS_Enable =	'1'		-- normal mode
				else (others=>'0')	when  CONTROL.BIAS_Enable =	'0'		-- mode bias off
				else (others=>'0');	

-------------------------------------------------------------------------------
--          FEEDBACK OUTPUT ON/OFF
-------------------------------------------------------------------------------

FEEDBACK <=	FEEDBACK_onoff			when  CONTROL.FEEDBACK_Enable =	'1'		-- normal mode
				else (others=>'0')	when  CONTROL.FEEDBACK_Enable =	'0'		-- mode feedback off
				else (others=>'0');	

end Behavioral;

