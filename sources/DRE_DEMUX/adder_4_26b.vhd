----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Christophe OZIOL 
-- Create Date   : 15:53 18/12/2018 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : adder_4_26b - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : Create a 4 inputs adder
--
-- Dependencies: 
--
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

entity adder_4_26b is
	
	generic (
		C_size_adder_in1 : positive:= 20;
		C_size_adder_in2 : positive:= 20;
		C_size_adder_in3 : positive:= 20;
		C_size_adder_in4 : positive:= 20;
		C_size_adder_out : integer := 26
			);
			
    Port 	(
		   IN1							: in 	signed(C_size_adder_in1-1 downto 0);
		   IN2							: in 	signed(C_size_adder_in2-1 downto 0);
		   IN3							: in 	signed(C_size_adder_in3-1 downto 0);
		   IN4							: in 	signed(C_size_adder_in4-1 downto 0);
		   ADDER_OUT					: out	signed(C_size_adder_out-1 downto 0)		
			  );
end adder_4_26b;
--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.adder_4_26b.Behavioral.svg
architecture Behavioral of adder_4_26b is
	signal IN1_IN2_ADDER :signed(C_size_adder_out-1 downto 0);
	signal IN3_IN4_ADDER :signed(C_size_adder_out-1 downto 0);
begin
-- adder IN1 + IN2
	IN1_IN2_ADDER 	<= resize(IN1,C_size_adder_out) + resize(IN2,C_size_adder_out);
-- adder IN3 + IN4
	IN3_IN4_ADDER 	<= resize(IN3,C_size_adder_out) + resize(IN4,C_size_adder_out);
-- adder IN1_IN2 + IN3_IN4 
	ADDER_OUT 	  	<= IN1_IN2_ADDER + IN3_IN4_ADDER;
	
end Behavioral;


