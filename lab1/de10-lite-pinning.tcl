#toggle switches
set_location_assignment PIN_C10 -to sw[0]
set_location_assignment PIN_C11 -to sw[1]
set_location_assignment PIN_D12 -to sw[2]
set_location_assignment PIN_C12 -to sw[3]
set_location_assignment PIN_A12 -to sw[4]
set_location_assignment PIN_B12 -to sw[5]
set_location_assignment PIN_A13 -to sw[6]
set_location_assignment PIN_A14 -to sw[7]
set_location_assignment PIN_B14 -to sw[8]
set_location_assignment PIN_F15 -to sw[9]

#LED outputs
set_location_assignment PIN_A8 -to led[0]
set_location_assignment PIN_A9 -to led[1]
set_location_assignment PIN_A10 -to led[2]
set_location_assignment PIN_B10 -to led[3]
set_location_assignment PIN_D13 -to led[4]
set_location_assignment PIN_C13 -to led[5]
set_location_assignment PIN_E14 -to led[6]
set_location_assignment PIN_D14 -to led[7]
set_location_assignment PIN_A11 -to led[8]
set_location_assignment PIN_B11 -to led[9]

#7-seg display outputs
set_location_assignment PIN_C14 -to hex0[0]
set_location_assignment PIN_E15 -to hex0[1]
set_location_assignment PIN_C15 -to hex0[2]
set_location_assignment PIN_C16 -to hex0[3]
set_location_assignment PIN_E16 -to hex0[4]
set_location_assignment PIN_D17 -to hex0[5]
set_location_assignment PIN_C17 -to hex0[6]
#set_location_assignment PIN_D15 -to hex0[7]

#Key 0 and Key 1 button inputs
set_location_assignment PIN_B8 -to Reset
set_location_assignment PIN_A7 -to cnt_enable
set_location_assignment PIN_P11 -to Clock

#to avoid that the FPGA is driving an unintended value on pins that are not in use:
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"

