library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SynchronousPrescaler is
	generic (
		div: positive
	);
	port (
		clk_i: in std_logic;
		d_i: in std_logic;
		reset_i: in std_logic;
		
		q_o: out std_logic
	);
end entity;

architecture rtl of SynchronousPrescaler is

-- components
	component EdgeDetector is
		port (
			clk_i, d_i: in std_logic;
			
			q_o: out std_logic
		);
	end component;

-- signals
	signal d_rising_s: std_logic;
	
begin
	ed: EdgeDetector
		port map(
			clk_i => clk_i,
			d_i => d_i,
			q_o => d_rising_s
		);

	process (clk_i)
		variable cnt: natural;
	begin
		if rising_edge(clk_i) then
			if reset_i = '1' then
				cnt := 0;
				q_o <= '0';
			else
				if d_rising_s = '1' then
					if cnt = div - 1 then
						cnt := 0;
						q_o <= '1';
					else
						cnt := cnt + 1;
						q_o <= '0';
					end if;
				else
					q_o <= '0';
				end if;
			end if;
		end if;
	end process;
end architecture rtl;
