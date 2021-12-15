library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UartTransmitter is
	generic (
		data_bits: natural;
		base_freq: natural;
		baud_rate: natural
	);
	port (
		clk_i: in std_logic;
		data_i: in std_logic_vector(data_bits - 1 downto 0);
		send_i: in std_logic;
		
		tx_o: out std_logic
	);
end entity;

architecture rtl of UartTransmitter is

	component EdgeDetector is
		port (
			clk_i, d_i: in std_logic;
			
			q_o: out std_logic
		);
	end component;

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

	constant PRESCALER_DIV: natural := base_freq / baud_rate;

	signal send_rising_s: std_logic;
	signal sample_clk_s: std_logic;
	signal reset_prescaler_s: std_logic;

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
			reset_i => reset_prescaler_s,
			q_o => sample_clk_s
		);

	process(clk_i)
	begin
		if rising_edge(clk_i) then
			reset_prescaler_s <= '0';
			-- Main FSM
			case state_s is
				when Idle =>
					if send_rising_s = '1' then
						state_s <= Start;
						bit_counter_s <= 0;
						parity_s <= '0';
						reset_prescaler_s <= '1';
						tx_o <= '0';
					end if;
				when Start =>
					if sample_clk_s = '1' then
						tx_o <= '1';
						state_s <= Data;
					end if;
				when Data =>
					if bit_counter_s < data_bits then
						if sample_clk_s = '1' then
							tx_o <= data_i(bit_counter_s);
							parity_s <= parity_s xor data_i(bit_counter_s);
							bit_counter_s <= bit_counter_s + 1;
						end if;
					elsif bit_counter_s = data_bits then
						if sample_clk_s = '1' then
							tx_o <= parity_s;
							state_s <= Stop;
						end if;
					end if;
				when Stop =>
					if sample_clk_s = '1' then
						tx_o <= '0';
						state_s <= Idle;
					end if;
			end case;
			-- End Main FSM
		end if;
	end process;
end architecture;
