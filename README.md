# FYS4220 Project
This project was the FPGA project assignment in FYS4220. The goal of the project was to program the Intel DE10-lite FPGA to read acellerometer data over I2C-bus and print the data over jtag-uart.

# Assignment progress

## Introductory assignment
 - Problem 1: < not started | started | **completed** >
 - Problem 2: < not started | started | **completed** >
 - Problem 3: < not started | started | **completed** >
 - Problem 4: < not started | started | **completed** >

## Embedded system project
 - Problem 5: < not started | started | **completed** >
 - Problem 6: < not started | started | **completed** >
 - Problem 7: < not started | started | **completed** >
 - Problem 8: < not started | started | **completed** >


 # Answers to assignment questions

 ## Introductory assignment

 ### Exercise 1: Your first FPGA project

 **a)** What is the meaning of the warning messages in the compilation report and why can we choose to ignore them at this stage?

Warning (18236): Number of processors has not been specified which may cause overloading on shared machines.  Set the global assignment &NUM_PARALLEL_PROCESSORS in your QSF to an appropriate value for best performance. \
This warning occurs because haven't specified any processors. I can ignore this message at this stage because it's not necessary to specify any processors to speed up the compilation of my design.

Warning (292013): Feature LogicLock is only available with a valid subscription license. You can purchase a software subscription to gain full access to this feature. \
Licensing warning

Warning (15714): Some pins have incomplete I/O assignments. Refer to the I/O Assignment Warnings report for details. \
This warning is connected to timing, the pins declared in this project haven't been specified with setup and hold times, I can ignore this because I don't have any clocks in this design 

Critical Warning (332012): Synopsys Design Constraints File file not found: 'lab1.sdc'. A Synopsys Design Constraints File is required by the Timing Analyzer to get proper timing constraints. Without it, the Compiler will not properly optimize the design. \
This critical warning occurs because there is no Synopsys Design Constraint File in this project, this file is required to do timing analysis of the project design. I can ignore this message because I don't have any requirements for timing in this project.


Warning (332068): No clocks defined in design. \
This warning occurs because I haven't implemented any clocks in my design. In this project this isn't necessary because I have a direct connection between input and output.

**b)** What is the purpose of the entity and architecture description? \
The entity defines the interface to the FPGA, while the architecture describes the functionality of the FPGA

**c)** What is the purpose of the Tcl file used in this problem? \
The TCL file connects the I/O declared in the entity declaration to physical ports on the FPGA

**d)** Can you briefly explain what the following Tcl statement is doing:
```
set_location_assignment PIN_C10 -to sw[0]
```
The TCL statement connects the PIN_C10 port to the sw[0] entity name

**e)** Which VHDL statement is needed to connect the input ports to the output ports of your design?
```
led <= sw;
```
### Exercise 2: Seven segment display

**a)** How many values can a 4-bit binary number represent, and can all of these numbers be shown on the seven segment display? \
A 4 bit binary number can represent 4^2 = 16 values. All these numbers can be represented på a single 7 digit display, because the seven segment display displays numbers in a hexadecimal format. A single hexadecimal digit can represent 16^1 = 16 values.


**b)** The input port sw is a bundle / vector of 10 input while only 4 are needed to control the seven segment display. How can you address only parts of a std_logic_vector?
```
alias bin0 is sw(3 downto 0)
```


### Exercise 3: Synchronous logic and test benches

**a)** Which package is available in VHDL to arithmetic operations? \
ieee.numeric_std


**b)** What is the purpose of the process sensitivity list? \
The sensitivity list contains a list of signals a process is sensitive to. If there is a transition on any of the signals in the list, the process will be triggered.


**c)** Why should an asynchronous reset signal be listed in the sensitivity list and why should a synchronous reset signal not be listed? \
An asynchronus reset signal should be listed in the sensitivity list, in order for the process to be able read the reset signal even if the process haven't been trigered by the clock. An sychronus reset signal should however not be listed, because it should not trigger the process. It should only be read on a clock tick event.


**d)** What is the standard method to check the behaviour of an HDL description? \
The standart method to check the behaviour of an HDL description, is to simulate it using a test bench.


**e)** Why is the entity description of a test bench empty? \
The entity description of a test bench is empty because a test bench doesn't have any imputs or outputs. Therefore there are no ports to be declared in the entity.


**f)** How can you model a 10 MHz clock signal in a VHDL test bench?
```
signal clk          : std_logic;
signal clk_ena      : boolean;
constant clk_period : time := 100 ns;  -- 10 MHz

begin

clk <= not clk after clk_period/2 when clk_ena else '0';
```


**g)** Why does the stimuli process of a basic test bench not have a sensitivity list? \
Within the stimuli process, wait statements are used to control the execution of the signal assignment, because each possible input is generated within the process. Thus the process doesn't have a sensitivity list.


**h)** Why do you need to disable a the clock at the end of the stimuli process in the test bench? \
I need to disable the clock at the end of the stimuli process in the test bench in order to not keep trigering the counter process after the stimuli process is done.


**i)** Why can the wait for and wait statements not be synthesized? \
Wait for and wait can't be synthesized since FPGAs have no internall timers.


**j)** Can you think of a reason why for the first part of the simulation the value of the counter signal in figure 25 is 'U'? Was this the case for your simulation results? \
The reason is that before the counter is reset, the counters value is undefined, and a value added to undefined is still undefined. This was also the case for my simulation, but i later fixed it.


**k)** What does this 'U' mean and how could you avoid it? \
The 'U' means undefined, this means that it hasn't been given a value, to avoid this i assigned an initial value to the counter like so:
```
signal counter : unsigned(3 downto 0) := "0000";
```

**l)** What happens when you press the push button KEY1 to start the counter, and can you explain why this happens? \
When i press and hold down the KEY1 button the counter is enabled and starts incrementing the counter at a blazing speed (50Mhz), when i release KEY1 the last value of the counter remains visable on the display. This is because the counter is incremented with the rising edge of the clock, while KEY1 is pressed.


### Exercise 4: Synchronization and edge-detection
**a)** What is the purpose of synchronization registers and when do you need to use them? \
Synchronization registers purpouse is to sychronize an asynchronous signal with the rising or falling edge of a clock. When recieving an asychronous signal it is required to synchronise the signal to avoid a metastable condition.



## Embedded system project
### Problem 5: I2C-master module
**a** Can you identify any limitations with the simulation approach used in this problem? That is, is there any functionality you are not able to fully verify, and do you have any suggestions for how these limitations can be overcome? \
Usimg this simulation aproach, the only way to verify the design is to look at the wave diagram and see if the design works as intended. Seeing as in this project there is a lot to keep track of and it is not so simple to see if all the signals transition at the correct time. To overcome this problem i sugest that we use a more complex testbench, that reads the outputs from the i2c master and checks if the signals have the expected values after a signal was supposed to transition. And represents this analasys in a more readable fasion than having to inspect wave diagrams.



**b** What is the purpose of the busy signal? \ 
The purpuse of the busy signal is to have an indicator to show when the i2c-master is ready to enter the sSTART state. It is used to ensure that the i2c module has recieved a command sucessfuly, and when it is ready to recieve a new command.


### Problem 6: Advanced test benches
**a)** Which function is available in the UVVM utility library to write log messages to a file? \
The log() function from the UVVM utility library can be used to write log messages to a file

b) Which function is available in the UVVM utility library to generate a clock signal to be used in the test bench? \
The clock_generator() function from the UVVM utility libarary can be used to generate a clock signal


**c)** Why is the wait for 0 ns statement included in VHDL code below?
```
reg_addr_use <= reg_addr_device_id;
wait for 0 ns;
read_i2c(i2c_addr_adxl345, reg_addr_use, data_array_rd, 1);
```
Because a process doesn't assign signals before at the end of the process or when there is a wait expresion. So here the 'wait for 0 ns;' is used to assign the 'reg_adr_device_id' to 'reg_addr_use'

**d)** What is the main purpose or advantage of adding the overloaded functions write_i2c and read_i2c in the i2c_master_adv_tb.vhd file? \
The original write_i2c and read_i2c procedures had many parameters, however not all of these signals are necessary to controll the testbench. So in order to reduce the amount of parameters required to use the read_i2c and write_i2c procedures, the overloaded procedures where added.

**e)** What is the VHDL conditional statement that can be used to detect a rising edge on the busy signal from the I2C master module?
```
if(i2c_busy = '1' and busy = '0')
```


### Problem 7: A Nios-II embedded system
**a)** Why do the CPU have both a data master and data instruction interface?\
The data instruction interface is just read, whilst data master is both read and write

**b)** In what ways are the Nios II PIO module utilized in this problem?\
The pio modules are utilized to allow the external pushbuttons, switches and leds to interact with the vhdl code

**c)** What is the purpose of the JTAG UART module?\
The purpouse of the JTAG UART module is to allow for implementing software on the cpu, it is also used to troubleshoot through sending serial messages over usb

**d)** Why is it recommended to minimize the application code inside an interrupt service routine (ISR)?\
It is recomended to minimize the application code inside an interrupt service routine, in order to keep the impact of interrupts on the execution on the main programm to a minimum.

**e)** What is the I2C address of the ADXL345 when the ALT ADDRESS pin is grounded?\
When the ALT ADDRESS pin is grounded, the I2C address of the ADXL345 is 0x53

**f)** How do you setup the ADXL345 to run in a I2C mode?\
To set up the ADXL345 to run in a I2C mode, the CS_n pin on the ADXL345 must be pulled high.

**g)** What is the device ID of the ADXL345 and in which register of the ADXL345 is this value stored?\
The device is of the ADXL345 is 0xE5, this value is stored in the DEVID register of the ADXL345. The addres of this register is 0x00

**h)** What is the purpose of writing the driver functions read_from_i2c_device and write_to_i2c_device?\
The purpuse of these functions is to simplify writing and reading data from the i2c device.

**i)** Can you explain what operation the following statement results in?
```
IOWR(I2C_AVALON_MM_IF_0_BASE,ADDR_REG, i2c_reg_addr << 8 | i2c_device_addr);
```
The statement provides the memory mapped interface with the i2c register adress and the i2c device address.



### Problem 7: A Nios-II embedded system
**a)** What is the purpose of using the putchar command in the first part of this problem?\
The purpuse of using the putchar command in the first part of the problem is to demonstrate that without a semaphore to protect the JTAG UART we risk that both tasks will use it at the same time. The execution time of the printf function is however a few houndred microsecconds. Thus the chance of both tasks using the JTAG UART at the same time is very low. So in order to increase the time it takes to write to the JTAG UART i loop through each character of the string and write a single character to the JTAG UART using the putchar command

**b)** Using the putchar command for the first part of this problem should result in a result similar to what is shown below. Can you explain this behaviour?
```
Hello from Task1
Hello from Task2
Hello fromHello from Task1
 Task2
Hello from Task2
Hello from Task1
```
The reason behind this behavour is that Task 1 has a higher priority than Task2, meaning that during the concatination of the "Hello World from Task2" string the task was interupted by Task1 due to its higher priority. Resulting in the message from task1 being printed in the middle of the task 2 message.

**c)** What is the purpose of the semaphore used in the first part of this problem?\
The purpouse of the semaphore ysed in the first part of this problem is to protect the JTAG UART resource. Resulting in that only one task can access the JTAG UART at a time.

**d)** What is the purpose of the semaphore used the interrupt routine of the second part of this problem, and how is it different from the use in the first part of the problem?\
The key1_sem semaphore used in the second part of the project, was used as a synchronization semaphore. The semaphore used in the first part of the problem was used as a key to protect a resource, whilst the key1_sem was used for synchronization. A synchronization semaphore is initialized to 0 while a semaphore used as a key is initialized to 1. 

**e)** What is the purpose of the message box used in the second part of this problem?\
The message box used in the second part of the problem was used to allow the code to change the sampling time of task_accel through an interrupt. Doing so by sending the timeout data from one task to another.