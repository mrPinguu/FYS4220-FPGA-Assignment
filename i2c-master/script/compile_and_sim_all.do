if {[batch_mode]} {
  onerror {abort all; exit -f -code 1}
  onbreak {abort all; exit -f}
} else {
  onerror {abort all}
}

quit -sim

quietly set prj_path "../.."

do $prj_path/script/compile_uvvm_util.do
do $prj_path/script/compile_src.do
vsim i2c_master_adv_tb
do $prj_path/script/wave_i2c_master.do
run -all
