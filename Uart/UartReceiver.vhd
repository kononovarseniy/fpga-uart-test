library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UartReceiver is
	generic (
		data_bits: natural := 8;
		baud_rate: natural := 9600;
		oversampling: positive := 2
	);
	port (
		clk_i: in std_logic;
		rx_i: in std_logic;
		dbg_o: out std_logic;
		irq_o: out std_logic;
		data_o: out std_logic_vector(data_bits - 1 downto 0);
		
		sample_clk_o: out std_logic
	);
end entity;

architecture rtl of UartReceiver is

-- Edge detector
signal rx_rising_s: std_logic;
component EdgeDetector is
	port (
		clk_i, d_i: in std_logic;
		
		q_o: out std_logic
	);
end component;

-- Sampler
signal sampler_reset_s: std_logic;
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

constant FULL_COUNT: natural := 8;
constant HALF_COUNT: natural := FULL_COUNT / 2;
constant PRESCALER_DIV: natural := 4;--100000000 / 9600 / FULL_COUNT;

-- FSM
type State is (Idle, Start, Data, Stop);
signal state_s: State;

signal data_s: std_logic_vector(data_bits - 1 downto 0);
signal bit_counter_s: natural;
signal counter_s: natural;
signal parity_s: std_logic;

begin
	rx_rising_edge_detector: EdgeDetector
		port map (
			clk_i => sample_clk_s,
			d_i => rx_i,

			q_o => rx_rising_s
		);

	-- Отношение частоты выборки к частоте данных должно быть больше 2.
	-- Поскольку первый бит надо захватить посередине N/2 тактов дальше считать по N.
	sampler: Prescaler
		generic map (
			div => PRESCALER_DIV
		)
		port map (
			clk_i => clk_i,
			reset_i => '0',--sampler_reset_s,

			q_o => sample_clk_s
		);
sample_clk_o <= sample_clk_s;
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			sampler_reset_s <= '0';
			irq_o <= '0';
			if sample_clk_s = '1' then
				case state_s is
					when Idle =>
						if rx_rising_s = '1' then
							state_s <= Start;
							sampler_reset_s <= '1';
							bit_counter_s <= 0;
							counter_s <= 0;
							parity_s <= '0';
							dbg_o <= '1';
						else
							dbg_o <= '0';
						end if;
					when Start =>
						counter_s <= counter_s + 1;
						if counter_s = HALF_COUNT then
							if rx_i = '1' then
								bit_counter_s <= 0;
								state_s <= Data;
							else
								state_s <= Idle;
							end if;
							counter_s <= 0;
						end if;
					when Data =>
						counter_s <= counter_s + 1;
						if counter_s = FULL_COUNT then
							if bit_counter_s <= data_bits then
								parity_s <= parity_s xor rx_i;
							end if;
							if bit_counter_s < data_bits then
								data_s(bit_counter_s) <= rx_i;
							end if;
							bit_counter_s <= bit_counter_s + 1;
							if bit_counter_s = data_bits + 1 then
								state_s <= Stop;
							end if;
							counter_s <= 0;
							dbg_o <= '1';
						else
							dbg_o <= '0';
						end if;
					when Stop =>
						counter_s <= counter_s + 1;
						if counter_s = FULL_COUNT then
							--if parity_s = '0' then
								data_o <= data_s;
								irq_o <= '1';
							--end if;
							state_s <= Idle;
						end if;
				end case;
			end if;
		end if;
	end process;

end architecture;
