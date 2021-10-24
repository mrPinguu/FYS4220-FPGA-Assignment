/*************************************************************************
* Copyright (c) 2004 Altera Corporation, San Jose, California, USA.      *
* All rights reserved. All use of this software and documentation is     *
* subject to the License Agreement located at the end of this file below.*
**************************************************************************
* Description:                                                           *
* The following is a simple hello world program running MicroC/OS-II.The * 
* purpose of the design is to be a very simple application that just     *
* demonstrates MicroC/OS-II running on NIOS II.The design doesn't account*
* for issues such as checking system call return codes. etc.             *
*                                                                        *
* Requirements:                                                          *
*   -Supported Example Hardware Platforms                                *
*     Standard                                                           *
*     Full Featured                                                      *
*     Low Cost                                                           *
*   -Supported Development Boards                                        *
*     Nios II Development Board, Stratix II Edition                      *
*     Nios Development Board, Stratix Professional Edition               *
*     Nios Development Board, Stratix Edition                            *
*     Nios Development Board, Cyclone Edition                            *
*   -System Library Settings                                             *
*     RTOS Type - MicroC/OS-II                                           *
*     Periodic System Timer                                              *
*   -Know Issues                                                         *
*     If this design is run on the ISS, terminal output will take several*
*     minutes per iteration.                                             *
**************************************************************************/


#include <stdio.h>
#include <system.h>
#include <string.h>
#include "includes.h"

#include <io.h> //IORD and IOWR
#include <altera_avalon_pio_regs.h> //functions that can read and write to the pio core
#include <sys/alt_irq.h> //irq routines
#include <i2c_avalon_mm_if.h>
#include <alt_types.h>

/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    task_interrupt_stk[TASK_STACKSIZE];
OS_STK    task_accel_stk[TASK_STACKSIZE];

//Declaration of semaphore structure
OS_EVENT *shared_jtag_sem;
OS_EVENT *key1_sem;
//Decleration of messagebox structure
OS_EVENT *msg_box;


/* Definition of Task Priorities */

#define TASK_INTERRUPT_PRIORITY      2
#define TASK_ACCEL_PRIORITY      3

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

	//Post interrupt semaphore
	OSSemPost(key1_sem);

}

//initializes and registers the interrupt handler
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

//task for interrupt handeling
void task_interrupt(void* pdata)
{
	INT8U error_code = OS_NO_ERR;
	INT16U timeout;

	int sw_data = 0;
	while (1)
	{
		OSSemPend(key1_sem,0,&error_code);
		//read position of slide switches and calculate new timeout value
		sw_data = IORD(SW_PIO_BASE,0);
		IOWR(LED_PIO_BASE,0,sw_data);
		timeout = sw_data*50;
		OSMboxPost(msg_box, (void*)&timeout);



		OSSemPend(shared_jtag_sem,0,&error_code);

		printf("Interrupt value %d\n",edge_capture);

		OSSemPost(shared_jtag_sem);



	}
}

//Task for reading adxl345 values
void task_accel(void* pdata)
{
	INT16U timeout = 100;
	INT16U *msg_rx;
	INT8U error_code = OS_NO_ERR;

	alt_16 ax, ay,az;
	float axf, ayf, azf;
	float scale = 1.0/256; //1g/lsb
	alt_u8 data[6] = {0};

	//wake up adxl345
	write_to_i2c_device(adxl_addr,0x2d,1,0x8);

	//configure adxl345 device
	alt_u8 set_accel_config = 0x20 | 0x8 | 0x1;
	write_to_i2c_device(adxl_addr,0x31,1,set_accel_config);

	while (1)
	{

		read_from_i2c_device(adxl_addr,0x32,6,&data[0]);

		ax = (alt_16)(data[1]<<8|data[0]);
		ay = (alt_16)(data[1]<<8|data[2]);
		az = (alt_16)(data[1]<<8|data[4]);

		axf = ax*scale;
		ayf = ay*scale;
		azf = az*scale;

		msg_rx = (INT16U*)OSMboxPend(msg_box,timeout,&error_code);
		if(error_code == OS_NO_ERR)
		{
			timeout = *msg_rx;


		}
		OSSemPend(shared_jtag_sem,0,&error_code);
		printf("ax = %.2f, ",axf);
		printf("ay = %.2f, ",azf);
		printf("az = %.2f\n, ",ayf);
		OSSemPost(shared_jtag_sem);
	}
}
/* The main function creates two task and starts multi-tasking */
int main(void)
{
	//create semaphores and initialize them
	shared_jtag_sem = OSSemCreate(1);
	key1_sem = OSSemCreate(0);
	//create an empty mailbox
	msg_box = OSMboxCreate((void*)NULL);

	init_interrupt_pio();
	//initialize the interrupts



	OSTaskCreateExt(task_interrupt,
				  NULL,
				  (void *)&task_interrupt_stk[TASK_STACKSIZE-1],
				  TASK_INTERRUPT_PRIORITY,
				  TASK_INTERRUPT_PRIORITY,
				  task_interrupt_stk,
				  TASK_STACKSIZE,
				  NULL,
				  0);


	OSTaskCreateExt(task_accel,
				  NULL,
				  (void *)&task_accel_stk[TASK_STACKSIZE-1],
				  TASK_ACCEL_PRIORITY,
				  TASK_ACCEL_PRIORITY,
				  task_accel_stk,
				  TASK_STACKSIZE,
				  NULL,
				  0);
	OSStart();
	return 0;
}

/******************************************************************************
*                                                                             *
* License Agreement                                                           *
*                                                                             *
* Copyright (c) 2004 Altera Corporation, San Jose, California, USA.           *
* All rights reserved.                                                        *
*                                                                             *
* Permission is hereby granted, free of charge, to any person obtaining a     *
* copy of this software and associated documentation files (the "Software"),  *
* to deal in the Software without restriction, including without limitation   *
* the rights to use, copy, modify, merge, publish, distribute, sublicense,    *
* and/or sell copies of the Software, and to permit persons to whom the       *
* Software is furnished to do so, subject to the following conditions:        *
*                                                                             *
* The above copyright notice and this permission notice shall be included in  *
* all copies or substantial portions of the Software.                         *
*                                                                             *
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  *
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    *
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE *
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      *
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     *
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER         *
* DEALINGS IN THE SOFTWARE.                                                   *
*                                                                             *
* This agreement shall be governed in all respects by the laws of the State   *
* of California and by the laws of the United States of America.              *
* Altera does not recommend, suggest or require that this reference design    *
* file be used in conjunction or combination with any other product.          *
******************************************************************************/
