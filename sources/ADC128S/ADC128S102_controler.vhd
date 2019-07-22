----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL/ Yann Parot
-- 
-- Create Date   : 12:14:36 05/26/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : ADC128S102_CONTROLER - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : ADC128S102 ADC managment module
--
-- Dependencies: athena_package
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
--Output_register(0) <= IN0
--Output_register(1) <= IN1
--Output_register(2) <= IN2
--Output_register(3) <= IN3
--Output_register(4) <= IN4
--Output_register(5) <= IN5
--Output_register(6) <= IN6
--Output_register(7) <= IN7
-----------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
--use work.ADC128S102_pkg.ALL;
use work.athena_package.all;

entity ADC128S102_controler is
	port ( 
--RESET
			Reset	        : in    std_logic; 
--CLOCKs
			clk_4X	     	: in    std_logic; 
			ENABLE_CLK_1X	: in    std_logic; 
-- Control
			Start           : in    std_logic; 
			read_register	: in    std_logic; 
			Done            : out   std_logic; -- indique que le registre est Ã  jour (toutes les valeurs demandÃ©es sont updatées)
			 
			Output_registers: out   t_register_ADC128; -- array de 8 std_logic_vector (max de channel qu'on peut acquérir)
			 
			 -- ADC signals
			 
			Sclk       		: out   std_logic;
			Dout       		: in    std_logic;
			Din        		: out   std_logic;
			Cs_n 	   		: out   std_logic
			 
			 );
end ADC128S102_controler;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.ADC128S102_controler.Behavioral.svg
architecture Behavioral of ADC128S102_controler is


--Déclaration des signaux internes

--ADC control register
signal 	i_ADC_control_register 	: std_logic_vector(15 downto 0);
alias 	i_channel_address 		: std_logic_vector(2 downto 0) is i_ADC_control_register (13 downto 11);

--indices de tableaux
signal 	i_channel_val 			: unsigned(2 downto 0);
signal 	i_output_reg_ind 		: unsigned(2 downto 0);
signal 	i_din_ind 				: unsigned(3 downto 0);
signal 	ADC_Sclk   				: std_logic;
signal 	ADC_Dout   				: std_logic;
signal 	ADC_Din   				: std_logic;
signal 	ADC_Cs_n   				: std_logic;
--Machine à  état
type t_FSM_state is (waiting,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11);
signal state : t_FSM_state;

--Generation Sclk
signal	i_Sclk					: std_logic;

--Compteur
signal	i_count_Dout_Din		: unsigned(3 downto 0);
signal	i_count_nb_acq			: unsigned(2 downto 0);

--Autres
signal	i_Dout					: std_logic_vector (15 downto 0);
signal	Output_register			: t_register_ADC128;
alias	i_Dout_utile			: std_logic_vector (11 downto 0) is i_Dout(11 downto 0);
--signal s5_flag : std_logic;



begin
--Output_registers <= Output_register;
Sclk 				<= ADC_Sclk;
ADC_Dout 			<= Dout;
Din 				<= ADC_Din;
Cs_n 				<= ADC_Cs_n;
--Combinatoire
i_channel_val 		<= i_count_nb_acq +2;
i_output_reg_ind 	<= i_count_nb_acq -1;
i_din_ind 			<= i_count_Dout_Din +1;

ADC_Sclk 			<= i_Sclk;

--Machine à état ADC
P_state_ADC128:process(clk_4X,Reset)
begin
-- partie clockée
if Reset = '1' then
	--init des états
				i_Sclk					<= '1';
				i_count_Dout_Din		<= to_unsigned(15,4);--(others =>'1');
				i_count_nb_acq			<= (others=>'0');
				i_Dout					<= (others => '0');
				i_ADC_control_register	<= (others => '0');
				--init des sorties
				Done					<= '0';
				ADC_Cs_n				<= '1';
				ADC_Din					<= '0';
				Output_registers		<= (others=>(others=>'0'));
				Output_register			<= (others=>(others=>'0'));
				state					<= waiting;
elsif rising_edge(clk_4X) then
	if (ENABLE_CLK_1X = '1') then
	case state is
	
		when waiting =>
		
				--On est dans le cas ou on reset tout
				--init des signaux internes
				i_Sclk 					<= '1';
				i_count_Dout_Din 		<= to_unsigned(15,4);--(others =>'1');
				i_count_nb_acq 			<= (others=>'0');
				i_Dout 					<= (others => '0');
				i_ADC_control_register 	<= (others => '0');
				--init des sorties
				Done 					<= '0';
				ADC_Cs_n 				<= '1';
				ADC_Din 				<= '0';
			--	s5_flag 				<= '0';

				--L'état suivant n'est atteint que si le start passe à  1
				if Start='1' then
					state <= s1;
				else
					state <= waiting;
				end if;
		
		when s1 =>
		
		--On prepare le registre de control
		i_channel_address <= "001";
			state <= s2;
			
		when s2 =>
		--On active l'ADC en on commence l'envoi du registre de control
		i_Sclk 		<= '0';
		ADC_Cs_n 	<= '0';
		ADC_Din 	<= i_ADC_control_register(15);
		
			state 	<= s3;
			
		when s3 =>
		--Changement état SClk
		i_Sclk 		<= '1'; --not i_Sclk; --(Sclk passe à 1)
		
		--On décrémente le compteur de Dout
		i_count_Dout_Din <= i_count_Dout_Din -1;
		
			state 	<= s4;
			
		when s4 =>
		
		--Changement état SClk
		i_Sclk 		<= '0';--not i_Sclk; --(Sclk passe à 0)
		
		--on envoie le registre
		ADC_Din 	<= i_ADC_control_register(to_integer(i_count_Dout_Din));
		
		--on lit Dout
		i_Dout(to_integer(i_din_ind)) <= ADC_Dout;
		
		
		--On stocke dans le registre Dout qui est complet
		if i_count_Dout_Din = to_unsigned(14,4) then
			Output_register(to_integer(i_output_reg_ind)) <= i_Dout_utile;
			-- le flag de s5 est remis à zero
		   --s5_flag <= '0';
		end if;
			--On regarde si on doit recevoir d'autres dout
			if i_count_Dout_Din = 1 then
				state <= s5;
			else
				state <= s3;
			end if;			
		
		when s5 =>
		
		--Changement état SClk
		i_Sclk <= '1';--not i_Sclk; --(Sclk passe à 1)
		
		--On décrémente le compteur de Dout
		i_count_Dout_Din <= i_count_Dout_Din -1;
		
		--On incrémente le compteur de channel
		i_count_nb_acq <= i_count_nb_acq +1;
		
		--On prepare le registre de control
		i_channel_address <= std_logic_vector(i_channel_val);
		
		-- mise à 1 du flag
		--s5_flag <= '1';

			state <= s6;

		when s6 =>
		
		--Changement état SClk
		i_Sclk <= '0';--not i_Sclk; --(Sclk passe à 0)
		
		--on envoie le registre
		ADC_Din <= i_ADC_control_register(to_integer(i_count_Dout_Din));
		
		--on lit Dout
		i_Dout(to_integer(i_din_ind)) <= ADC_Dout;
		
			--On regarde si on boucle
			if i_count_nb_acq = 0 then
				state <= s7;
			else
				state <= s3;
			end if;
		
		when s7 =>
		
			   --Changement état SClk
		i_Sclk <= '1';--not i_Sclk; --(Sclk passe à 1)
		
		--On décrémente le compteur de Dout
		i_count_Dout_Din <= i_count_Dout_Din -1;
		
			state <= s8;
		
		when s8 =>
			--on lit Dout
		i_Dout(to_integer(i_din_ind)) <= ADC_Dout;
		
			state <= s9;
			
		when s9 =>
				--On a fini
		Done <= '0';
		Output_register(to_integer(i_output_reg_ind)) <= i_Dout_utile;
		
			state <= s10;
			
		when s10 =>
				--On a fini
		Done <= '1';
		Output_registers <= Output_register;
			if (read_register ='1') then
				state <= s11;	
			else 
				state <= s10;
			end if;
		when s11 =>
				--On a fini
		Done <= '0';
		Output_registers <= Output_register; 
			state <= waiting;	
		
--		when others =>
--			state <= waiting;
	
	end case;
	end if;	
end if;
end process;

end Behavioral;