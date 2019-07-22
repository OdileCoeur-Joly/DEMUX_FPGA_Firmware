----------------------------------------------------------------------------------
-- Company       : CNRS - INSU - IRAP
-- Engineer      : Antoine CLENET / Christophe OZIOL
-- 
-- Create Date   : 31/07/2015 
-- Design Name   : DRE XIFU FPGA_BOARD
-- Module Name   : MOD_ROM_dds - Behavioral
-- Project Name  : Athena XIfu DRE
-- Target Devices: Virtex 6 LX 240
-- Tool versions : ISE-14.7
-- Description: 	Values of sine function and of sine slope function over one period
-- 					2**(MOD_ROM_Depth-2) values of (MOD_Size_ROM_Sine+MOD_Size_ROM_delta) bits:
-- 						- Sine value:  MOD_Size_ROM_Sine		bits (MOD_Size_ROM_Sine+MOD_Size_ROM_delta downto-1 MOD_Size_ROM_delta)
--							- Slope value: MOD_Size_ROM_delta		bits (MOD_Size_ROM_delta-1 downto 0)
--
-- Dependencies: athena_package
--
-- Revision: 
-- Revision 0.1 - File Created
-- Revision 0.2 - All DDS parameters (all signals) are function of MOD_ROM_Depth, MOD_Size_ROM_Sine and SMOD_ize_ROM_delta defined in the athena_package
-- Additional Comments: 
--
---------------------------------------oOOOo(o_o)oOOOo-----------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.MATH_REAL.ALL;
use work.athena_package.all;


entity MOD_ROM_dds is	
port(
--RESET
	 RESET			: in std_logic;
--CLOCK
    Clk          	: in std_logic;
    en           	: in std_logic;

    address_rom  	: in unsigned((C_MOD_ROM_Depth-2)-1 downto 0);	-- ROM_Depth-2 because only 1/4 of sine period is stored into the LUT
    sine			  	: out unsigned(C_MOD_Size_ROM_Sine-1 downto 0);
    delta			: out unsigned(C_MOD_Size_ROM_delta-1 downto 0)
    );
end entity;

--! @brief-- BLock diagrams schematics -- 
--! @detail file:work.MOD_rom_dds.Behavioral.svg
architecture Behavioral of MOD_ROM_dds is

type MOD_rom_dds is array ((2**(C_MOD_ROM_Depth-2))-1 downto 0) of unsigned(C_MOD_Size_ROM_Sine+C_MOD_Size_ROM_delta-1 downto 0);
constant cts_MOD_rom_data : MOD_rom_dds := (
-------------------------------------------------------------------
-- In this version of the ROM:
--   - a quarter of a period only is stored
--   - the absolute value of the Delta is stored (-1 * Delta)
--   - the sine values are stored on MOD_Size_ROM_sine bits
--   - the Delta values are stored on MOD_Size_ROM_delta bits
-------------------------------------------------------------------
0	=>	 "11111111111110000001",
1	=>	 "11111111111100000001",
2	=>	 "11111111111010000100",
3	=>	 "11111111110010000100",
4	=>	 "11111111101010000101",
5	=>	 "11111111100000000111",
6	=>	 "11111111010010001000",
7	=>	 "11111111000010001001",
8	=>	 "11111110110000001011",
9	=>	 "11111110011010001100",
10	=>	 "11111110000010001101",
11	=>	 "11111101101000001110",
12	=>	 "11111101001100001111",
13	=>	 "11111100101110010001",
14	=>	 "11111100001100010001",
15	=>	 "11111011101010010011",
16	=>	 "11111011000100010101",
17	=>	 "11111010011010010101",
18	=>	 "11111001110000010111",
19	=>	 "11111001000010010111",
20	=>	 "11111000010100011001",
21	=>	 "11110111100010011011",
22	=>	 "11110110101100011011",
23	=>	 "11110101110110011101",
24	=>	 "11110100111100011101",
25	=>	 "11110100000010011111",
26	=>	 "11110011000100100001",
27	=>	 "11110010000010100001",
28	=>	 "11110001000000100010",
29	=>	 "11101111111100100100",
30	=>	 "11101110110100100101",
31	=>	 "11101101101010100110",
32	=>	 "11101100011110100111",
33	=>	 "11101011010000101000",
34	=>	 "11101010000000101001",
35	=>	 "11101000101110101010",
36	=>	 "11100111011010101100",
37	=>	 "11100110000010101101",
38	=>	 "11100100101000101101",
39	=>	 "11100011001110101111",
40	=>	 "11100001110000110000",
41	=>	 "11100000010000110001",
42	=>	 "11011110101110110010",
43	=>	 "11011101001010110011",
44	=>	 "11011011100100110101",
45	=>	 "11011001111010110101",
46	=>	 "11011000010000110110",
47	=>	 "11010110100100110111",
48	=>	 "11010100110110111001",
49	=>	 "11010011000100111001",
50	=>	 "11010001010010111011",
51	=>	 "11001111011100111011",
52	=>	 "11001101100110111100",
53	=>	 "11001011101110111110",
54	=>	 "11001001110010111110",
55	=>	 "11000111110110111111",
56	=>	 "11000101111001000001",
57	=>	 "11000011110111000001",
58	=>	 "11000001110101000010",
59	=>	 "10111111110001000011",
60	=>	 "10111101101011000100",
61	=>	 "10111011100011000101",
62	=>	 "10111001011001000101",
63	=>	 "10110111001111000111",
64	=>	 "10110101000001001000",
65	=>	 "10110010110001001000",
66	=>	 "10110000100001001001",
67	=>	 "10101110001111001010",
68	=>	 "10101011111011001011",
69	=>	 "10101001100101001100",
70	=>	 "10100111001101001100",
71	=>	 "10100100110101001110",
72	=>	 "10100010011001001110",
73	=>	 "10011111111101001111",
74	=>	 "10011101011111001111",
75	=>	 "10011011000001010001",
76	=>	 "10011000011111010001",
77	=>	 "10010101111101010010",
78	=>	 "10010011011001010010",
79	=>	 "10010000110101010011",
80	=>	 "10001110001111010100",
81	=>	 "10001011100111010101",
82	=>	 "10001000111101010101",
83	=>	 "10000110010011010110",
84	=>	 "10000011100111010111",
85	=>	 "10000000111001010111",
86	=>	 "01111110001011010111",
87	=>	 "01111011011101011001",
88	=>	 "01111000101011011001",
89	=>	 "01110101111001011001",
90	=>	 "01110011000111011010",
91	=>	 "01110000010011011011",
92	=>	 "01101101011101011011",
93	=>	 "01101010100111011100",
94	=>	 "01100111101111011100",
95	=>	 "01100100110111011100",
96	=>	 "01100001111111011110",
97	=>	 "01011111000011011101",
98	=>	 "01011100001001011110",
99	=>	 "01011001001101011111",
100	=>	 "01010110001111011110",
101	=>	 "01010011010011100000",
102	=>	 "01010000010011011111",
103	=>	 "01001101010101100000",
104	=>	 "01001010010101100001",
105	=>	 "01000111010011100000",
106	=>	 "01000100010011100001",
107	=>	 "01000001010001100010",
108	=>	 "00111110001101100001",
109	=>	 "00111011001011100010",
110	=>	 "00111000000111100011",
111	=>	 "00110101000001100010",
112	=>	 "00110001111101100011",
113	=>	 "00101110110111100011",
114	=>	 "00101011110001100011",
115	=>	 "00101000101011100011",
116	=>	 "00100101100101100100",
117	=>	 "00100010011101100011",
118	=>	 "00011111010111100100",
119	=>	 "00011100001111100100",
120	=>	 "00011001000111100100",
121	=>	 "00010101111111100100",
122	=>	 "00010010110111100101",
123	=>	 "00001111101101100100",
124	=>	 "00001100100101100101",
125	=>	 "00001001011011100100",
126	=>	 "00000110010011100100",
127	=>	 "00000011001011100101"
);

signal MOD_rdata : unsigned(C_MOD_Size_ROM_Sine+C_MOD_Size_ROM_delta-1 downto 0);

begin
MOD_rdata <= cts_MOD_rom_data(to_integer(address_rom));

p_readout_MOD_ROM: process (Clk,RESET)
begin
	if (RESET = '1') then
			sine 		<= (others=>'0');
			delta 		<= (others=>'0');
	elsif (rising_edge(Clk)) then
		if (en = '1') then
			sine 	<= MOD_rdata(C_MOD_Size_ROM_Sine+C_MOD_Size_ROM_delta-1 downto C_MOD_Size_ROM_delta);
			delta 	<= MOD_rdata(C_MOD_Size_ROM_delta-1 downto 0);
		end if;
	end if;
end process;

end Behavioral;

