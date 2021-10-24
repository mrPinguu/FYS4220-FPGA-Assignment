
module nios2_system (
	clk_clk,
	interrupt_pio_external_connection_export,
	led_pio_external_connection_export,
	reset_reset_n,
	sw_pio_external_connection_export,
	i2c_avalon_mm_if_conduit_end_sda_export,
	i2c_avalon_mm_if_conduit_end_scl_export);	

	input		clk_clk;
	input	[2:0]	interrupt_pio_external_connection_export;
	output	[9:0]	led_pio_external_connection_export;
	input		reset_reset_n;
	input	[9:0]	sw_pio_external_connection_export;
	inout		i2c_avalon_mm_if_conduit_end_sda_export;
	inout		i2c_avalon_mm_if_conduit_end_scl_export;
endmodule
