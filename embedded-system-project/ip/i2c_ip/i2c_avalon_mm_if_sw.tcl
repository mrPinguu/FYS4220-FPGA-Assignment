# Filename: i2c_avalon_mm_if_sw.tcl
# tcl script to describe the software driver for the I2C mm if.
# this script is used by Nios II SBT(Software Build Tool) when building the BSP(Board Support Package).
# Author:
# Ketil Røed 2019

# Creating and naming the driver:
create_driver i2c_avalon_mm_if

# Associate the driver with hardware:(the I2C mm if)
set_sw_property hw_class_name i2c_avalon_mm_if

# The driver version:
set_sw_property version 1.0

# Specify the oldest harware versions compatible with this driver:
set_sw_property min_compatible_hw_version 1.0

# Specify supported BSP(Board Support Package) types:
add_sw_property supported_bsp_type hal
#add_sw_property supported_bsp_type ucosii

# Location in generated BSP that sources will be copied into
set_sw_property bsp_subdirectory drivers


# Include driver source file(s): (c/c++ or assembly)
add_sw_property c_source HAL/src/i2c_avalon_mm_if.c

# Include driver header file(s):
add_sw_property include_source HAL/inc/i2c_avalon_mm_if.h

# Interrupt properties:
# set_sw_property isr_preemption_supported false
# set_sw_property supported_interrupt_apis "legacy_interrupt_api enhanced_interrupt_api"

# Specify a subdirectory in the generated BSP: (this is where the included files will be copied to)
# (not really necessary since by default the driver files is placed under the "drivers" directory)
#set_sw_property bsp_subdirectory drivers

# End of file