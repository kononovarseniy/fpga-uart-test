library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART is
	port (
		clk_i: in std_logic
	);
end entity;

architecture rtl of UART is

-- MainPLL
signal clk_s: std_logic;
component MainPLL is
	port (
		inclk0: in std_logic := '0';
		c0: out std_logic
	);
end component;

begin
	main_pll: MainPLL
		port map (
			inclk0 => clk_i,
			c0 => clk_s
		);

end architecture;
