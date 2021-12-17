library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UartReceiver is
	generic (
		data_bits: natural;
		base_freq: natural;
		baud_rate: natural
	);
	port (
		clk_i: in std_logic;
		rx_i: in std_logic;
		
		irq_o: out std_logic;
		parity_ok_o: out std_logic;
		data_o: out std_logic_vector(data_bits - 1 downto 0);
		
		sample_clk_o: out std_logic;
		idle_o: out std_logic;
		start_o: out std_logic;
		bits_o: out std_logic;
		stop_o: out std_logic
	);
end entity;

architecture rtl of UartReceiver is

	component EdgeDetector is
		port (
			clk_i, d_i: in std_logic;
			
			q_o: out std_logic
		);
	end component;

	component Prescaler is
		generic (
			div: positive;
			initial_value: positive
		);
		port (
			clk_i: in std_logic;
			reset_i: in std_logic;
			
			q_o: out std_logic
		);
	end component;

	constant PRESCALER_DIV: natural := base_freq / baud_rate;

	signal rx_rising_s: std_logic;
	
	signal sampler_reset_s: std_logic;
	signal sample_clk_s: std_logic;
	-- FSM
	type State is (Idle, Start, Data, Stop);
	signal state_s: State;

	signal data_s: std_logic_vector(data_bits - 1 downto 0);
	signal bit_counter_s: natural;
	signal parity_s: std_logic;

begin
	rx_rising_edge_detector: EdgeDetector
		port map (
			clk_i => clk_i,
			d_i => rx_i,

			q_o => rx_rising_s
		);

	sampler: Prescaler
		generic map (
			div => PRESCALER_DIV,
			initial_value => PRESCALER_DIV / 2
		)
		port map (
			clk_i => clk_i,
			reset_i => sampler_reset_s,

			q_o => sample_clk_s
		);

	sample_clk_o <= sample_clk_s;

	idle_o <= '1' when state_s = Idle else '0';
	start_o <= '1' when state_s = Start else '0';
	bits_o <= '1' when state_s = Data else '0';
	stop_o <= '1' when state_s = Stop else '0';
	
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			sampler_reset_s <= '0';
			irq_o <= '0';

			-- Main FSM
			case state_s is
				when Idle =>
					if rx_rising_s = '1' then
						state_s <= Start;
						sampler_reset_s <= '1';
						bit_counter_s <= 0;
						parity_s <= '0';
					end if;
				when Start =>
					if sample_clk_s = '1' then
						if rx_i = '1' then
							state_s <= Data;
						else
							state_s <= Idle;
						end if;
					end if;
				when Data =>
					if sample_clk_s = '1' then
						if bit_counter_s <= data_bits then
							parity_s <= parity_s xor rx_i;
						end if;
						if bit_counter_s < data_bits then
							data_s(bit_counter_s) <= rx_i;
						end if;
						if bit_counter_s = data_bits then
							state_s <= Stop;
						end if;
						bit_counter_s <= bit_counter_s + 1;
					end if;
				when Stop =>
					if sample_clk_s = '1' then
						parity_ok_o <= not parity_s;
						data_o <= data_s;
						irq_o <= '1';
						state_s <= Idle;
					end if;
			end case;
			-- End Main FSM
		end if;
	end process;

end architecture;
