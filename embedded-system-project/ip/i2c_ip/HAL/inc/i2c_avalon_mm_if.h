#include "alt_types.h"

//I2C mm if
#define CTRL_REG  0x0
#define ADDR_REG  0x1
#define WRITE_REG  0x2
#define READ_REG_LOW  0x3
#define READ_REG_HIGH 0x4

#define CMD_ENA_WR  0x1
#define CMD_ENA_RD  0x3

#define MM_IF_BUSY 0x7
#define MM_IF_I2C_BUSY 0x6
#define MM_IF_I2C_ACK_ERROR 0x5



//function to check if bit position is 1
#define check_bit(var,pos) ((var) & (1<<(pos)))

// function to check if memory mapped interface is busy
int check_mm_if_busy(void);

//Functions for reading and writing to I2C mm if

void read_from_i2c_device(alt_u8 i2c_device_addr,alt_u8 i2c_reg_addr,alt_u8 no_bytes,alt_u8 *data);

void write_to_i2c_device(alt_u8 i2c_device_addr, alt_u8 i2c_reg_addr,alt_u8 no_bytes,
                         alt_u32 data);