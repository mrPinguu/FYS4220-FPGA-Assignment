# TCL File Generated by Component Editor 18.1
# Thu Nov 12 16:18:31 CET 2020
# DO NOT MODIFY


# 
# i2c_avalon_mm_if "i2c_avalon_mm_if" v1.0
# Adrian Bergflodt 2020.11.12.16:18:31
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module i2c_avalon_mm_if
# 
set_module_property DESCRIPTION ""
set_module_property NAME i2c_avalon_mm_if
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP fys4220
set_module_property AUTHOR "Adrian Bergflodt"
set_module_property DISPLAY_NAME i2c_avalon_mm_if
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL i2c_avalon_mm_if
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file i2c_avalon_mm_if.vhd VHDL PATH hdl/i2c_avalon_mm_if.vhd TOP_LEVEL_FILE
add_fileset_file i2c_master.vhd VHDL PATH hdl/i2c_master.vhd


# 
# parameters
# 


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset_n reset_n Input 1


# 
# connection point avalon_slave_0
# 
add_interface avalon_slave_0 avalon end
set_interface_property avalon_slave_0 addressUnits WORDS
set_interface_property avalon_slave_0 associatedClock clock
set_interface_property avalon_slave_0 associatedReset reset
set_interface_property avalon_slave_0 bitsPerSymbol 8
set_interface_property avalon_slave_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_slave_0 burstcountUnits WORDS
set_interface_property avalon_slave_0 explicitAddressSpan 0
set_interface_property avalon_slave_0 holdTime 0
set_interface_property avalon_slave_0 linewrapBursts false
set_interface_property avalon_slave_0 maximumPendingReadTransactions 0
set_interface_property avalon_slave_0 maximumPendingWriteTransactions 0
set_interface_property avalon_slave_0 readLatency 0
set_interface_property avalon_slave_0 readWaitTime 1
set_interface_property avalon_slave_0 setupTime 0
set_interface_property avalon_slave_0 timingUnits Cycles
set_interface_property avalon_slave_0 writeWaitTime 0
set_interface_property avalon_slave_0 ENABLED true
set_interface_property avalon_slave_0 EXPORT_OF ""
set_interface_property avalon_slave_0 PORT_NAME_MAP ""
set_interface_property avalon_slave_0 CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave_0 SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave_0 read read Input 1
add_interface_port avalon_slave_0 write write Input 1
add_interface_port avalon_slave_0 chipselect chipselect Input 1
add_interface_port avalon_slave_0 address address Input 3
add_interface_port avalon_slave_0 writedata writedata Input 32
add_interface_port avalon_slave_0 readdata readdata Output 32
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point conduit_end_sda
# 
add_interface conduit_end_sda conduit end
set_interface_property conduit_end_sda associatedClock clock
set_interface_property conduit_end_sda associatedReset ""
set_interface_property conduit_end_sda ENABLED true
set_interface_property conduit_end_sda EXPORT_OF ""
set_interface_property conduit_end_sda PORT_NAME_MAP ""
set_interface_property conduit_end_sda CMSIS_SVD_VARIABLES ""
set_interface_property conduit_end_sda SVD_ADDRESS_GROUP ""

add_interface_port conduit_end_sda sda export Bidir 1


# 
# connection point conduit_end_scl
# 
add_interface conduit_end_scl conduit end
set_interface_property conduit_end_scl associatedClock clock
set_interface_property conduit_end_scl associatedReset ""
set_interface_property conduit_end_scl ENABLED true
set_interface_property conduit_end_scl EXPORT_OF ""
set_interface_property conduit_end_scl PORT_NAME_MAP ""
set_interface_property conduit_end_scl CMSIS_SVD_VARIABLES ""
set_interface_property conduit_end_scl SVD_ADDRESS_GROUP ""

add_interface_port conduit_end_scl scl export Bidir 1

