#include <stdio.h>
#include "system.h"
#include "i2c_avalon_mm_if.h"
#include "alt_types.h"
#include "io.h"
#include "unistd.h" //usleep()

// #define DEBUG

int check_mm_if_busy(void)
{
    //Read control register of I2C-mm if
    int res = IORD(I2C_AVALON_MM_IF_0_BASE,CTRL_REG);
    //check if I2C_AVALON_MM_IF state machine is busy
  #ifdef DEBUG
    printf("CTRL: 0x%x\n",res);
  #endif
    if (check_bit(res,MM_IF_BUSY))
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

void write_to_i2c_device(alt_u8 i2c_device_addr, alt_u8 i2c_reg_addr,alt_u8 no_bytes,alt_u32 data)
{
    //write to address register of i2c mm if
    IOWR(I2C_AVALON_MM_IF_0_BASE,ADDR_REG, i2c_reg_addr << 8 | i2c_device_addr);
    //write to the data register of the i2c mm if
    IOWR(I2C_AVALON_MM_IF_0_BASE,WRITE_REG,data);
    //Set the corresponding bits of the ctrl register to enable the i2c communication
    IOWR(I2C_AVALON_MM_IF_0_BASE,CTRL_REG,no_bytes << 2 | CMD_ENA_WR);
    //Check for busy in the ctrl register (i2c busy or mm if busy), and continue when no longer busy
    while(check_mm_if_busy()) continue;
}

void read_from_i2c_device(alt_u8 i2c_device_addr,alt_u8 i2c_reg_addr,alt_u8 no_bytes, alt_u8* data)
{
    alt_u32 read_reg[2] = {0};
    alt_u8 data_temp[8] = {0};

    //write to address register of i2c mm if
    //6..0: 7-bits i2c device addres
    //15..8: 8 bits register address of i2c device
    IOWR(I2C_AVALON_MM_IF_0_BASE,ADDR_REG, i2c_reg_addr << 8 | i2c_device_addr);
    //Write to i2c mm if ctrl register to enable i2c command
    IOWR(I2C_AVALON_MM_IF_0_BASE,CTRL_REG, CMD_ENA_WR);
    //Check for busy in the ctrl register (i2c busy or mm if busy), and continue when no longer busy
    while(check_mm_if_busy()) continue;

    //no_bytes to be read from the i2c device

    IOWR(I2C_AVALON_MM_IF_0_BASE,CTRL_REG,no_bytes << 2 | CMD_ENA_RD);
    while(check_mm_if_busy()) continue;

    read_reg[0] = IORD(I2C_AVALON_MM_IF_0_BASE,READ_REG_LOW);
    read_reg[1] = IORD(I2C_AVALON_MM_IF_0_BASE,READ_REG_HIGH);

    //Move data in to byte array
    for(int i = 0; i<4; i++) {
        data_temp[i] = (read_reg[0] >> i*8) & 0xff;
        data_temp[i+4] = (read_reg[1] >> i*8) & 0xff;
    }

    //reverse byte array to have first received byte in the lowest array position
    for(int i = 0; i<no_bytes; i++) {
        data[i] = data_temp[(no_bytes-1)-i];
        //printf("i: %d, no_bytes: %d\n" ,i,(no_bytes-1)-i);
    }

}