/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include <stdio.h> //accsess to printf
#include <system.h> //accsess to information about nios 2 hardware
#include <io.h> //IORD and IOWR
#include <altera_avalon_pio_regs.h> //functions that can read and write to the pio core
#include <sys/alt_irq.h> //irq routines
#include <i2c_avalon_mm_if.h>
#include <alt_types.h>


volatile int edge_capture;
const alt_u8 adxl_addr = 0x53;

//ISR that will be called when the system signals an interrupt.
static void handle_interrupts(void* context)
{
	//Cast context to edge_capture's type, volatile to avoid compiler optimization
	volatile int* edge_capture_ptr = (volatile int*) context;
	//read capture register on the pio and store the value
	*edge_capture_ptr = IORD_ALTERA_AVALON_PIO_EDGE_CAP(INTERRUPT_PIO_BASE);
	//Write to edge capture register and reset it
	IOWR_ALTERA_AVALON_PIO_EDGE_CAP(INTERRUPT_PIO_BASE,0);

}

//initializes and registers the interrupt handøer
static void init_interrupt_pio()
{
	//recast the edge_capture point to match the alt_irq_register() function
	void* edge_capture_ptr = (void*)&edge_capture;

	//Enable all 3 interrupt inputs
	IOWR_ALTERA_AVALON_PIO_IRQ_MASK(INTERRUPT_PIO_BASE,0x7);

	//Reset the edge capture register
	IOWR_ALTERA_AVALON_PIO_EDGE_CAP(INTERRUPT_PIO_BASE,0);

	//Register the interrupt handler
	alt_ic_isr_register(INTERRUPT_PIO_IRQ_INTERRUPT_CONTROLLER_ID, INTERRUPT_PIO_IRQ, handle_interrupts, edge_capture_ptr,0x0);
}

int main()
{
	char strx[40];
	char stry[40];
	char strz[40];
	alt_16 ax, ay,az;
	float axf, ayf, azf;
	float scale = 1.0/256; //1g/lsb
	alt_u8 data[6] = {0};


	//initialize the interrupts
	init_interrupt_pio();

	//verify connection to adxl345
	alt_u8 devid;
	read_from_i2c_device(adxl_addr,0x0,1,&devid);

	//wake up adxl345
	write_to_i2c_device(adxl_addr,0x2d,1,0x8);

	//configure adxl345 device
	alt_u8 set_accel_config = 0x20 | 0x8 | 0x1;
	write_to_i2c_device(adxl_addr,0x31,1,set_accel_config);



	int sw_data = 0;
	printf("Hello from Nios II!\n");
	while(1)
	{
		sw_data = IORD(SW_PIO_BASE,0);
		IOWR(LED_PIO_BASE,0,sw_data);

		read_from_i2c_device(adxl_addr,0x32,6,&data[0]);

		ax = (alt_16)(data[1]<<8|data[0]);
		ay = (alt_16)(data[1]<<8|data[2]);
		az = (alt_16)(data[1]<<8|data[4]);

		axf = ax*scale;
		ayf = ay*scale;
		azf = az*scale;

		sprintf(strx, "ax = %f, ",axf);
		sprintf(stry, "ay = %f, ",ayf);
		sprintf(strz, "az = %f\n",azf);


		printf(strx);
		printf(stry);
		printf(strz);


		if(edge_capture == 0x1)
		{
			printf("Interrupt, Key1 was pressed!\n");
			edge_capture = 0;
		}
		else if(edge_capture == 0x2)
		{
			printf("Interrupt, ADXL345 IRQ 0 activated! \n");
			edge_capture = 0;
		}
		else if(edge_capture == 0x4)
			printf("Interrupt, ADXL345 IRQ 1 activated! \n");
		edge_capture = 0;
	}
	return 0;
}
