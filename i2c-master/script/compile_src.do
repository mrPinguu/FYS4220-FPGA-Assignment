vlib work
vmap work work

quietly set prj_path "../../"

vcom -2008 -check_synthesis $prj_path/src/i2c_master.vhd
vcom -2008 ../../tb/adxl345_simmodel.vhd
vcom -2008 ../../tb/i2c_master_pkg.vhd
vcom -2008 ../../tb/i2c_master_adv_tb.vhd
