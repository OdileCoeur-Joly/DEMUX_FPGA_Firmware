----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Antoine CLENET / Christophe OZIOL
-- 
-- Create Date   : 31/07/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : Mod_dds_generic - Behavioral
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description   : MOD_Sine wave generator
--
-- Dependencies: athena package
--
-- Revision: 
-- Revision 0.2 - All DDS parameters (all signals) are function of MOD_ROM_Depth, MOD_Size_ROM_Sine 
--                and MOD_Size_ROM_delta defined in the athena_package
-- Revision 0.01 - File Created
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.athena_package.all;


entity MOD_dds_generic is
port		(
--RESET
			Reset       		: in std_logic;
--CLOCK
			Clk         		: in std_logic;
    
			counter           : in unsigned(C_MOD_counter_size - 1 downto 0);

			address_rom       : out unsigned((C_MOD_ROM_Depth-2)-1 downto 0);		-- ROM_Depth-2 because only 1/4 of sine period is stored into the LUT

			sine_previous 		: in unsigned(C_MOD_Size_ROM_Sine-1 downto 0);
			delta_previous		: in unsigned(C_MOD_Size_ROM_delta-1 downto 0);
    
			dds_previous  		: out signed(C_MOD_Size_DDS-1 downto 0)
    );
end entity;
---------------------------------------------------------------------------------

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.MOD_dds_generic.Behavioral.svg
architecture Behavioral of MOD_dds_generic is

signal counter_previous       : unsigned(C_MOD_counter_size - 1 downto 0);
signal counter_backward       : unsigned(C_MOD_counter_size-C_Size_quarter - 1 downto 0);
signal interpolation_previous : unsigned(C_MOD_Size_ROM_delta+C_MOD_Size_intrp-1 downto 0);
signal interpol_x             : unsigned(C_MOD_Size_intrp-1 downto 0);
signal interpol_x_previous    : unsigned(C_MOD_Size_intrp-1 downto 0);
signal dds_out_previous_abs   : unsigned(C_MOD_Size_ROM_Sine-1 downto 0);
signal dds_out_previous_P     : signed(C_MOD_Size_DDS-1 downto 0);
signal dds_out_previous_N     : signed(C_MOD_Size_DDS-1 downto 0);
--signal dds_out_previous			: signed(MOD_Size_DDS-1 downto 0);

constant first_cross_zero     : unsigned(C_MOD_counter_size - 1 downto C_MOD_counter_size - C_MOD_ROM_Depth - C_MOD_Size_intrp) := "01" & to_unsigned(0,C_MOD_ROM_Depth + C_MOD_Size_intrp - 2);
constant secon_cross_zero     : unsigned(C_MOD_counter_size - 1 downto C_MOD_counter_size - C_MOD_ROM_Depth - C_MOD_Size_intrp) := "11" & to_unsigned(0,C_MOD_ROM_Depth + C_MOD_Size_intrp - 2);
constant Quarter_of_counter   : unsigned(C_MOD_counter_size-C_Size_quarter-1 downto 0) := (others => '0'); 

-- where we are in the sine period from the 2 MSB of the counter:
constant quarter1 				: unsigned(C_Size_quarter-1 downto 0) := "00";
--constant quarter2 				: unsigned(Size_quarter-1 downto 0) := "01";
constant quarter3 				: unsigned(C_Size_quarter-1 downto 0) := "10";
constant quarter4 				: unsigned(C_Size_quarter-1 downto 0) := "11";

signal quarter          		: unsigned(C_Size_quarter-1 downto 0);
signal quarter_previous 		: unsigned(C_Size_quarter-1 downto 0);


begin

counter_backward 	<= Quarter_of_counter - counter(C_MOD_counter_size-C_Size_quarter-1 downto 0);
quarter 				<= counter(C_MOD_counter_size - 1 downto C_MOD_counter_size - C_Size_quarter);

-----------------------
-- Computation of ROM address (from the counter value) 
mux_quarter_address: 
    address_rom <= counter(C_MOD_counter_size - C_Size_quarter - 1 downto C_MOD_Size_intrp) when (quarter = quarter1 or quarter = quarter3)
                   else counter_backward(C_MOD_counter_size - C_Size_quarter - 1 downto C_MOD_Size_intrp);

-----------------------
-- Computation of X factor for the interpolation (from the counter value) 
mux_quarter_interpol: 
   interpol_x <= counter(C_MOD_Size_intrp-1 downto 0) when (quarter = quarter1 or quarter = quarter3)
                 else counter_backward(C_MOD_Size_intrp-1 downto 0);

-----------------------
P_sync_interpol: process(Reset, Clk)
-- Delay of the "interpol_x" and "quarter" signals to be in-phase with the ROM output
begin
	if Reset = '1' then
		interpol_x_previous 	<= (others => '0');
		counter_previous 		<= (others => '0');
	elsif rising_edge(Clk) then	
		interpol_x_previous <= interpol_x; 
		counter_previous <= counter;
	end if;
end process;
quarter_previous <= counter_previous(C_MOD_counter_size - 1 downto C_MOD_counter_size - C_Size_quarter);

-----------------------
-- Interpolation : Multiplication of the counter's LSB by the slope of the sine function
interpolation_previous <= delta_previous * interpol_x_previous;



-----------------------
-- Addition of the "Sine" value and the "interpolation" value
dds_out_previous_abs <= sine_previous - resize(interpolation_previous(C_MOD_Size_ROM_delta+C_MOD_Size_intrp - 1 downto C_MOD_Size_ROM_delta+C_MOD_Size_intrp-C_MOD_Size_ROM_delta),C_MOD_Size_ROM_Sine);



-- In the 2 following lines I use (Size_Sine_Out-1) instead of Size_Sine_Out because I add the sign which is an extra significant bit

dds_out_previous_P <= signed('0' 	 & resize(dds_out_previous_abs,C_MOD_Size_DDS-1));
dds_out_previous_N <= not signed('0' & resize(dds_out_previous_abs,C_MOD_Size_DDS-1));


-----------------------
P_sine_generator: process(Reset, Clk)
begin
	if Reset = '1' then
	dds_previous <= (others => '0');
	elsif rising_edge(Clk) then
		if (counter_previous(C_MOD_counter_size - 1 downto C_MOD_counter_size - C_MOD_ROM_Depth - C_MOD_Size_intrp) = first_cross_zero or counter_previous(C_MOD_counter_size - 1 downto C_MOD_counter_size - C_MOD_ROM_Depth - C_MOD_Size_intrp) = secon_cross_zero) then 
			dds_previous <= (others => '0');
		elsif (quarter_previous = quarter1 or quarter_previous = quarter4) then
			dds_previous <= dds_out_previous_P;
			else
				dds_previous <= dds_out_previous_N;
		end if;
	end if;
end process;

end Behavioral;
---------------------------------------------------------------------------------
