----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Antoine CLENET/ Laurent RAVERA/ Christophe OZIOL 
-- 
-- Create Date   : 18/08/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : slope_bias - Behavioral 
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : progressive rise of the bias signal at start-up
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.athena_package.all;


entity slope_bias is
Port 	(
--RESET
		Reset			: in  std_logic;
--CLOCK
		CLK_4X			: in  std_logic;
		ENABLE_CLK_1X	: in  std_logic;
--CONTROL
		slope_speed		: in  unsigned(1 downto 0);
		START_STOP		: in  std_logic;
    
		bias_in			: in  signed(C_Size_bias_to_DAC-1 downto 0);
		bias_out		: out signed(C_Size_bias_to_DAC-1 downto 0)
		);
end entity;


--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.slope_bias.Behavioral.svg
architecture Behavioral of slope_bias is

-- In the following line the "+1" adds a MSB to the counter
-- in order to avoid a "return to 0".

signal counter_slope	: unsigned(C_Size_slope_counter-1+1 downto 0);
signal one				: unsigned(C_Size_slope_factor-1 downto 0);

-- In the following line the "+1" compensates the extra MSB due to 
-- the unsigned to signed conversion of the counter
signal bias_internal	: signed(C_Size_bias_to_DAC+C_Size_slope_factor-1+1 downto 0);
signal slope_speed_high	: unsigned(C_Size_slope_factor-1 downto 0);

begin
P_slope_counter: process(Reset, CLK_4X)
	begin
		if Reset = '1' then
			counter_slope 		<= (others => '0');
			one					<= (others => '1'); 
			slope_speed_high 	<=	TO_UNSIGNED(1,C_Size_slope_factor);
		elsif rising_edge(CLK_4X) then
			if (ENABLE_CLK_1X='1') then
				if (START_STOP = '0') then
					counter_slope <= (others => '0');
choice_SPEED:	case slope_speed is
				when "00" 	=> 
					slope_speed_high <= TO_UNSIGNED(1023,C_Size_slope_factor);
				when "01" 	=>
					slope_speed_high <= TO_UNSIGNED(511,C_Size_slope_factor);
				when "10" 	=>  
					slope_speed_high <= TO_UNSIGNED(255,C_Size_slope_factor);
				when "11" 	=>
					slope_speed_high <= TO_UNSIGNED(1,C_Size_slope_factor);
				when others =>
					slope_speed_high <= TO_UNSIGNED(1023,C_Size_slope_factor);
					end case;
				else
					if (counter_slope >= C_max_slope_counter) then
						counter_slope <= (others => '1');
					else
						counter_slope <= counter_slope + slope_speed_high;
					end if;
				end if;
			end if;
		end if;
end process;

P_slope_x_bias: process(Reset, CLK_4X)
begin
	if Reset = '1' then
   bias_internal <= (others => '0');
	elsif rising_edge(CLK_4X) then
		if (ENABLE_CLK_1X='1') then
			if (slope_speed = "00") then
				bias_internal <= bias_in * signed('0' & one);
			else
				if counter_slope(C_Size_slope_counter-1+1) = '0' then -- during the slope
					bias_internal <= bias_in * signed('0' & counter_slope(C_Size_slope_counter-1 downto C_Size_slope_counter-C_Size_slope_factor));
				else -- after the slope
					bias_internal <= bias_in * signed('0' & one);
				end if; 
			end if;
		end if;
	end if;
end process;

-- Here we do not use the extra MSB
rounding_bias_out: entity work.rounding
	generic map(
		C_Size_in  => bias_internal'length-1,
		C_size_out => bias_out'length
	)
	port map(
		to_round_in => bias_internal(bias_internal'length-2 downto 0),-- removing 1 sign bit from multiplication result
		round_out   => bias_out
	);
--bias_out <= (Size_bias_to_DAC+Size_slope_factor-1  downto Size_slope_factor);

end Behavioral;
