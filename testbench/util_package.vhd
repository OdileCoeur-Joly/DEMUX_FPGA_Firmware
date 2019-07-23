----------------------------------------------------------------------------------
-- Company: 	IRAP
-- Engineer:	Laurent Ravera
-- 
-- Create Date:		07/07/2015 
-- Design Name: 	fdm_firmware
-- Module Name:		util_package 
-- Project Name: 	Athena X-IFU
-- Target Devices:	N/A
-- Tool versions:
-- Description:
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.1 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

---------------------------------------------------------------
--
-- PACKAGE
--
---------------------------------------------------------------
package util_package is

----------------------------------------------------------------------------
-- Data logger
----------------------------------------------------------------------------
component FILE_LOG is
	generic (
		size_data:	positive;
		file_name:	string
	);
	port(
		CLK			: in std_logic;
		LOG_START	: in std_logic;
       DATA		: in signed(size_data-1 downto 0)
		);
end component;


end util_package;
----------------------------------------------------------------------------
