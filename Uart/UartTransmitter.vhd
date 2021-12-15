library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UartTransmitter is
	generic (
		data_bits: natural := 8;
		baud_rate: natural := 9600;
		oversampling: positive := 2
	);
	port (
		clk_i: in std_logic;
		data_i: in std_logic_vector(data_bits - 1 downto 0);
		send_i: in std_logic;
		
		tx_o: out std_logic
	);
end entity;

architecture rtl of UartTransmitter is

-- Edge detector
signal send_rising_s: std_logic;
component EdgeDetector is
	port (
		clk_i, d_i: in std_logic;
		
		q_o: out std_logic
	);
end component;

-- Sampler
signal sample_clk_s: std_logic;
component Prescaler is
	generic (
		div: positive
	);
	port (
		clk_i: in std_logic;
		reset_i: in std_logic;
		
		q_o: out std_logic
	);
end component;

constant PRESCALER_DIV: natural := 32;--100000000 / 9600;

-- FSM
type State is (Idle, Start, Data, Stop);
signal state_s: State;

signal bit_counter_s: natural;
signal parity_s: std_logic;

begin

	send_rising_edge_detector: EdgeDetector
		port map (
			clk_i => clk_i,
			d_i => send_i,

			q_o => send_rising_s
		);

	sampler: Prescaler
		generic map (
			div => PRESCALER_DIV
		)
		port map (
			clk_i => clk_i,
			reset_i => send_rising_s,

			q_o => sample_clk_s
		);

	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if sample_clk_s = '1' or (state_s = Idle and send_rising_s = '1') then
				case state_s is
					when Idle =>
						if send_rising_s = '1' then
							state_s <= Start;
							bit_counter_s <= 0;
							parity_s <= '0';
							tx_o <= '0';
						end if;
					when Start =>
						tx_o <= '1';
						state_s <= Data;
					when Data =>
						if bit_counter_s < data_bits then
							parity_s <= parity_s xor data_i(bit_counter_s);
							tx_o <= data_i(bit_counter_s);
						end if;
						if bit_counter_s = data_bits then
							tx_o <= parity_s;
							state_s <= Stop;
						end if;
						bit_counter_s <= bit_counter_s + 1;
					when Stop =>
						tx_o <= '0';
						state_s <= Idle;
				end case;
			end if;
		end if;
	end process;

end architecture;
