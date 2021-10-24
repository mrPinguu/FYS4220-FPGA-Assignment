	component nios2_system is
		port (
			clk_clk                                  : in    std_logic                    := 'X';             -- clk
			interrupt_pio_external_connection_export : in    std_logic_vector(2 downto 0) := (others => 'X'); -- export
			led_pio_external_connection_export       : out   std_logic_vector(9 downto 0);                    -- export
			reset_reset_n                            : in    std_logic                    := 'X';             -- reset_n
			sw_pio_external_connection_export        : in    std_logic_vector(9 downto 0) := (others => 'X'); -- export
			i2c_avalon_mm_if_conduit_end_sda_export  : inout std_logic                    := 'X';             -- export
			i2c_avalon_mm_if_conduit_end_scl_export  : inout std_logic                    := 'X'              -- export
		);
	end component nios2_system;

	u0 : component nios2_system
		port map (
			clk_clk                                  => CONNECTED_TO_clk_clk,                                  --                               clk.clk
			interrupt_pio_external_connection_export => CONNECTED_TO_interrupt_pio_external_connection_export, -- interrupt_pio_external_connection.export
			led_pio_external_connection_export       => CONNECTED_TO_led_pio_external_connection_export,       --       led_pio_external_connection.export
			reset_reset_n                            => CONNECTED_TO_reset_reset_n,                            --                             reset.reset_n
			sw_pio_external_connection_export        => CONNECTED_TO_sw_pio_external_connection_export,        --        sw_pio_external_connection.export
			i2c_avalon_mm_if_conduit_end_sda_export  => CONNECTED_TO_i2c_avalon_mm_if_conduit_end_sda_export,  --  i2c_avalon_mm_if_conduit_end_sda.export
			i2c_avalon_mm_if_conduit_end_scl_export  => CONNECTED_TO_i2c_avalon_mm_if_conduit_end_scl_export   --  i2c_avalon_mm_if_conduit_end_scl.export
		);

