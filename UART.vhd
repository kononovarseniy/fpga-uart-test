library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART is
	port (
		clk_i: in std_logic;
		data_i: in std_logic_vector(7 downto 0);
		data_o: out std_logic_vector(7 downto 0);
		send_i: in std_logic;
		recv_o: out std_logic;
		
		dbg_i: in std_logic;
		dbg_i2: in std_logic;
		dbg_s1: out std_logic;
		dbg_s2: out std_logic;
		dbg_s3: out std_logic;
		dbg_s4: out std_logic;
		dbg_s5: out std_logic;
		
		dbg_clk_o: out std_logic;
		sample_clk_o: out std_logic;
		dbg_rx_o: out std_logic;
		dbg_o: out std_logic
	);
end entity;

architecture rtl of UART is

constant base_freq: positive := 100_000_000; -- 100 MHz.
constant bit_rate: positive := 5_000_000; -- 5 MHz, 20 ticks per bit.

-- MainPLL
signal clk_s: std_logic;
component MainPLL is
	port (
		inclk0: in std_logic := '0';
		c0: out std_logic
	);
end component;

component UartTransmitter is
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
end component;

component UartReceiver is
	generic (
		data_bits: natural := 8;
		baud_rate: natural := 9600;
		oversampling: positive := 2
	);
	port (
		clk_i: in std_logic;
		rx_i: in std_logic;
		dbg_o: out std_logic;
		sample_clk_o: out std_logic;
		
		irq_o: out std_logic;
		data_o: out std_logic_vector(data_bits - 1 downto 0)
	);
end component;

component SynchronousPrescaler is
	generic (
		div: positive
	);
	port (
		clk_i: in std_logic;
		d_i: in std_logic;
		reset_i: in std_logic;
		
		q_o: out std_logic
	);
end component;

signal rx_tx_s: std_logic;

component SynchronousEdgeDetector is
	port (
		clk_i: in std_logic;
		en_i: in std_logic;
		d_i: in std_logic;

		q_o: out std_logic
	);
end component;

begin
	main_pll: MainPLL
		port map (
			inclk0 => clk_i,
			c0 => clk_s
		);
		
	tx: UartTransmitter
		generic map (
			data_bits => 8,
			base_freq => base_freq,
			baud_rate => bit_rate
		)
		port map (
			clk_i => clk_s,
			data_i => data_i,
			send_i => send_i,
			tx_o => rx_tx_s
		);
	rx: UartReceiver
		port map (
			clk_i => clk_s,
			data_o => data_o,
			irq_o => recv_o,
			rx_i => rx_tx_s,
			dbg_o => dbg_rx_o,
			sample_clk_o => sample_clk_o
		);
	
	p1: SynchronousPrescaler
		generic map (
			div => 1
		)
		port map (
			clk_i => clk_s,
			d_i => dbg_i2,
			reset_i => dbg_i,
			q_o => dbg_s1
		);
	
	p2: SynchronousPrescaler
		generic map (
			div => 2
		)
		port map (
			clk_i => clk_s,
			d_i => dbg_i2,
			reset_i => dbg_i,
			q_o => dbg_s2
		);
	
	p3: SynchronousPrescaler
		generic map (
			div => 3
		)
		port map (
			clk_i => clk_s,
			d_i => dbg_i2,
			reset_i => dbg_i,
			q_o => dbg_s3
		);
	
	p4: SynchronousPrescaler
		generic map (
			div => 4
		)
		port map (
			clk_i => clk_s,
			d_i => dbg_i2,
			reset_i => dbg_i,
			q_o => dbg_s4
		);
	
--	p5: SynchronousPrescaler
--		generic map (
--			div => 5
--		)
--		port map (
--			clk_i => clk_s,
--			d_i => dbg_i2,
--			reset_i => dbg_i,
--			q_o => dbg_s5
--		);
	sed: SynchronousEdgeDetector
		port map (
			clk_i => clk_s,
			en_i => clk_s,
			d_i => dbg_i2,
			q_o => dbg_s5
		);
		
	dbg_o <= rx_tx_s;
	dbg_clk_o <= clk_s;

end architecture;
