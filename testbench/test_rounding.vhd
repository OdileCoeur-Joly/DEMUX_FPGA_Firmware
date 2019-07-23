--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:15:20 01/07/2019
-- Design Name:   
-- Module Name:   D:/athena/ASIC_Firmware/Test_DM_V0/DEMUX/testbench/test_rounding.vhd
-- Project Name:  DEMUX
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: rounding
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
 
ENTITY test_rounding IS
END test_rounding;
 
ARCHITECTURE behavior OF test_rounding IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 

   --Inputs
   signal to_round_in : signed (5 downto 0) := (others => '0');

 	--Outputs
   signal round_out : signed (3 downto 0);
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   rounder: entity work.rounding
    generic map
    (
    size_in	 	=> to_round_in'length,
    Size_out	=> round_out'length	
    )    
  PORT MAP (
          to_round_in => to_round_in,
          round_out => round_out
        );

   -- Clock process definitions
   signal_in_process :process
   begin
		to_round_in <= to_round_in +1;
		wait for 10 ns;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	


      -- insert stimulus here 

      wait;
   end process;

END;
