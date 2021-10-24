if {[batch_mode]} {
  onerror {abort all; exit -f -code 1}
  onbreak {abort all; exit -f}
} else {
  onerror {abort all}
}

quit -sim

vlib work
vmap work work

quietly set prj_path "../.."


quietly set root_path "../../UVVM_light"
do $root_path/script/compile.do $root_path/ $root_path/sim


# Compile project source files
vcom -2008 -check_synthesis $prj_path/src/i2c_master.vhd
vcom -2008 -check_synthesis $prj_path/src/i2c_avalon_mm_if.vhd
vcom -2008 ../../tb/adxl345_simmodel.vhd
vcom -2008 ../../tb/i2c_master_pkg.vhd
vcom -2008 ../../tb/i2c_avalon_mm_if_tb.vhd


# Run simulation of I2C Avalon MM IF
vsim i2c_avalon_mm_if_tb

view wave

add wave -noupdate -divider testbench
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/clk
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/reset_n
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/addr_reg
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/ctrl_reg
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/read_reg
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/write_reg
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/cmd_rst
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/cmd
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/state
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/sda
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/scl
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/address
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/chipselect
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/write
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/read
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/busy
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/i2c_ack_error
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/i2c_busy
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/mm_if_busy
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/mm_if_busy_state
add wave i2c_avalon_mm_if_tb/i2c_avalon_mm_if_i/no_bytes
configure wave -namecolwidth 300
configure wave -valuecolwidth 100
configure wave -timelineunits ns
update



run -all

wave zoom full