library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Prescaler is
	generic (
		div: positive
	);
	port (
		clk_i: in std_logic;
		reset_i: in std_logic;
		
		q_o: out std_logic
	);
end entity;

architecture rtl of prescaler is
begin
	process (clk_i)
	variable cnt: natural;
	begin
		if rising_edge(clk_i) then
			if reset_i = '1' then
				cnt := 0;
				q_o <= '0';
			else
				cnt := cnt + 1;
				if cnt = div then
					cnt := 0;
					q_o <= '1';
				else
					q_o <= '0';
				end if;
			end if;
		end if;
	end process;
end architecture rtl;
