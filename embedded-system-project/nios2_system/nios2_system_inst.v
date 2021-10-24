	nios2_system u0 (
		.clk_clk                                  (<connected-to-clk_clk>),                                  //                               clk.clk
		.interrupt_pio_external_connection_export (<connected-to-interrupt_pio_external_connection_export>), // interrupt_pio_external_connection.export
		.led_pio_external_connection_export       (<connected-to-led_pio_external_connection_export>),       //       led_pio_external_connection.export
		.reset_reset_n                            (<connected-to-reset_reset_n>),                            //                             reset.reset_n
		.sw_pio_external_connection_export        (<connected-to-sw_pio_external_connection_export>),        //        sw_pio_external_connection.export
		.i2c_avalon_mm_if_conduit_end_sda_export  (<connected-to-i2c_avalon_mm_if_conduit_end_sda_export>),  //  i2c_avalon_mm_if_conduit_end_sda.export
		.i2c_avalon_mm_if_conduit_end_scl_export  (<connected-to-i2c_avalon_mm_if_conduit_end_scl_export>)   //  i2c_avalon_mm_if_conduit_end_scl.export
	);

