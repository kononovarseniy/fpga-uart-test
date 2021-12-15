library ieee;
use ieee.std_logic_1164.all;

entity EdgeDetector is
	port (
		clk_i, d_i: in std_logic;
		
		q_o: out std_logic
	);
end entity;

architecture rtl of EdgeDetector is
begin
	process (clk_i)
		variable s1, s2: std_logic;
	begin
		if (rising_edge(clk_i)) then
			s2 := s1;
			s1 := d_i;
			q_o <= s1 and not s2;
		end if;
	end process;
end architecture;
