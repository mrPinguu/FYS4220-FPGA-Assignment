library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

-- User-library with I2C package
-- Contains declaration of I2C/ADXL345 relevant signals and constants
use work.i2c_master_pkg.all;

-------------------------------------------------------------------------------
-- UVVM Utility Library
-------------------------------------------------------------------------------
library STD;
use std.env.all;

-- Include the UVVM utility library
library uvvm_util;
context uvvm_util.uvvm_util_context;

-- The UVVM library contains a bus functional model (BFM) for the Avalon memory mapped interface
-- This package provide access to procedures that can be used to write to and read from an Avalon Memory mapped interface.
use uvvm_util.avalon_mm_bfm_pkg.all;

-------------------------------------------------------------------------------

entity i2c_avalon_mm_if_tb is
end entity;


architecture tb of i2c_avalon_mm_if_tb is


  -- Setting up signals and  constants for the Avalon BFM

  -- The UVVM BFM package uses a record type to group the MM IF signals
  -- Create interface signal of record type t_avalon_mm_if;
  -- See avalon_mm_if_bfm_pkg.vhd for definition
  -- Records are similar to structures in C, and are often used to define a new VHDL type.  This new type contains a group of signals that the user desire to e.g. simplify an interface.
  -- The t_avalon_mm_if needs to be constrained as some of the record members are defined as std_logic_vector without specifying the length of the vector.
  signal avalon_mm_if : t_avalon_mm_if(address(2 downto 0),
                                       byte_enable(3 downto 0),
                                       writedata(31 downto 0),
                                       readdata(31 downto 0));

  -- The UVVM avalon bus functional model (BFM) has a certain set of default configuration parameters that needs to be updated in order to be used in this project. Use the following settings.
  constant C_AVALON_MM_BFM_CONFIG : t_avalon_mm_bfm_config := (
    max_wait_cycles          => 10,
    max_wait_cycles_severity => TB_FAILURE,
    clock_period             => clk_period,
    clock_period_margin      => 0 ns,
    clock_margin_severity    => TB_ERROR,
    setup_time               => clk_period/4,  -- recommended
    hold_time                => clk_period/4,  -- recommended
    bfm_sync                 => SYNC_ON_CLOCK_ONLY,
    match_strictness         => MATCH_STD_INCL_Z,
    num_wait_states_read     => 1,
    num_wait_states_write    => 0,
    use_waitrequest          => false,
    use_readdatavalid        => false,
    use_response_signal      => false,
    use_begintransfer        => false,
    id_for_bfm               => ID_BFM,
    id_for_bfm_wait          => ID_BFM_WAIT,
    id_for_bfm_poll          => ID_BFM_POLL
    );



  -- Some local constans and signals

  constant C_CTRL_REG_ADDR : unsigned(2 downto 0)          := "000";
  signal ctrl_reg_value    : std_logic_vector(31 downto 0) := (others => '0');
  alias cmd                : std_logic is ctrl_reg_value(0);
  alias rnw                : std_logic is ctrl_reg_value(1);
  alias no_bytes           : std_logic_vector(2 downto 0) is ctrl_reg_value(4 downto 2);

  constant C_ADDR_REG_ADDR : unsigned(2 downto 0)          := "001";
  signal addr_reg_value    : std_logic_vector(31 downto 0) := (others => '0');
  alias i2c_device_addr    : std_logic_vector is addr_reg_value(6 downto 0);
  alias internal_addr      : std_logic_vector is addr_reg_value(15 downto 8);

  constant C_WRITE_REG_ADDR     : unsigned(2 downto 0) := "010";
  constant C_READ_REG_ADDR_LOW  : unsigned(2 downto 0) := "011";
  constant C_READ_REG_ADDR_HIGH : unsigned(2 downto 0) := "100";

begin

  -- Instantiate the i2c_avalon_mm_if component
  -- Connect the internal signals to the test bench signals defined in then avalon_mm_if record
  i2c_avalon_mm_if_i : entity work.i2c_avalon_mm_if
    port map (
      clk        => clk,
      reset_n    => arst_n,             --
      read       => avalon_mm_if.read,
      write      => avalon_mm_if.write,
      chipselect => avalon_mm_if.chipselect,
      address    => avalon_mm_if.address,
      writedata  => avalon_mm_if.writedata,
      readdata   => avalon_mm_if.readdata,
      sda        => sda,
      scl        => scl
      );


  -- Include the ADXL345 simulation model and connect its sda and scl lines to the i2c_avalon_mm_if component
  adxl345 : entity work.adxl345_simmodel
    generic map (
      i2c_clk => GC_I2C_CLK)
    port map (
      sda => sda,
      scl => scl);

-- Generate the test bench clock using the UVVM utility library clock generator
  clock_generator(clk, clk_ena, clk_period, "TB clock");


-- Test sequencer
  p_seq : process

    constant C_SCOPE    : string                        := "TB seq.";
    variable read_value : std_logic_vector(31 downto 0) := (others => '0');


  begin
    ----------------------------------------------------------------------------------
    -- Set and report init conditions
    ----------------------------------------------------------------------------------
    -- Increment alert counter as one warning is expected when testing writing
    -- to ID register which is read only
    increment_expected_alerts(warning, 0);
    -- Print the configuration to the log: report/enable logging/alert conditions
    report_global_ctrl(VOID);
    report_msg_id_panel(VOID);
    enable_log_msg(ALL_MESSAGES);
    disable_log_msg(ID_POS_ACK);        --make output a bit cleaner


    -- Begin simulation
    log(ID_LOG_HDR, "Start Simulation of TB for I2C Avalon MM IF", C_SCOPE);
    log(ID_SEQUENCER, "Set default values for I/O and enable clock and reset system", C_SCOPE);
    -- default values
    arst_n                  <= '1';
    avalon_mm_if.writedata  <= (others => '0');
    avalon_mm_if.chipselect <= '0';
    avalon_mm_if.write      <= '0';
    avalon_mm_if.read       <= '0';
    avalon_mm_if.address    <= (others => '0');
    scl                     <= 'Z';
    sda                     <= 'Z';
    clk_ena                 <= true;    --Enable the system clk
    wait for 5*clk_period;
    log(ID_SEQUENCER, "Activate async. reset", C_SCOPE);
    arst_n                  <= '0', '1' after 5*clk_period;
    wait for clk_period*10;
    wait until falling_edge(clk);



    -- =============================== Perform read of device ID register, 1 byte =============================
    log(ID_LOG_HDR, "Verify communication with MM IF", C_SCOPE);
    log(ID_SEQUENCER, "Write I2C address and device ID address to MM IF addr_reg", C_SCOPE);
    -- The address register of the mm_if module shares both the internal register address (31 downto 16) and the i2c device address (15 downto 0).
    -- Data format register is no
    i2c_device_addr <= i2c_addr_adxl345;
    internal_addr   <= reg_addr_device_id;
    -- A process have sequential statements where signals assignments are updated when the process goes into a wait state. This happens either at the end of the process, typical for clocked process which are synthesisable, or when calling a wait statement. Thus, for the signal to be updated before it is used in the next line, we need to call a wait statement.
    wait for 0 ns;                      -- make sure signals are updated.
    avalon_mm_write(C_ADDR_REG_ADDR, addr_reg_value, "MM IF Write transaction to addr_reg", clk, avalon_mm_if, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);
    wait for 20*clk_period;

    -- This method reads back and verifies that the data is as expected.
    avalon_mm_check(C_ADDR_REG_ADDR, addr_reg_value, "MM IF transaction to verify correct value in addr_reg", clk, avalon_mm_if, warning, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);


    log(ID_LOG_HDR, "Read ADXL345 Device ID Register", C_SCOPE);
    -- Read back Device ID
    -- We first need to update the internal register address pointer of the ADXL345
    -- The I2C and internal register addresses has already been written to the MM IF addr_reg_value
    -- We can therefore request the MM IF state machine to start an I2C transactions
    -- As we will only update the internal register pointer no data bytes will be written.
    cmd      <= '1';    -- Request start transaction by setting cmd-bit high
    no_bytes <= "000";                  -- No data bytes
    rnw      <= '0';                    -- Request write
    wait for 0 ns;
    avalon_mm_write(C_CTRL_REG_ADDR, ctrl_reg_value, "MM IF transaction to request I2C write transaction", clk, avalon_mm_if, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);

    wait for clk_period*(GC_SYSTEM_CLK/GC_I2C_CLK)*50;

    -- The internal register address pointer has now been updated and we can request a I2C read transaction
    cmd      <= '1';    -- Request start transaction by setting cmd-bit high
    no_bytes <= "001";  -- One byte will be read from device ID register
    rnw      <= '1';                    -- Request read
    wait for 0 ns;
    avalon_mm_write(C_CTRL_REG_ADDR, ctrl_reg_value, "MM IF transaction to request I2C read transaction", clk, avalon_mm_if, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);


    wait for clk_period*(GC_SYSTEM_CLK/GC_I2C_CLK)*50;
    -- Check that read device ID is as expected
    log(ID_SEQUENCER, "Check correct device ID", C_SCOPE);
    avalon_mm_check(C_READ_REG_ADDR_LOW, X"------" & "ZZZ00Z0Z", "MM IF transaction to verify correct reveived value in read_reg", clk, avalon_mm_if, warning, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);



    -- =============================== Set ADXL345 resolution to 4g ==========================================
    log(ID_LOG_HDR, "Set the ADXL345 resolution to 4g", C_SCOPE);
    -- Write to MM IF address registers
    log(ID_SEQUENCER, "Write I2C address and address of Data Fromat register to MM IF addr_reg", C_SCOPE);
    i2c_device_addr <= i2c_addr_adxl345;
    internal_addr   <= adxl345_data_format_reg;
    wait for 0 ns;
    avalon_mm_write(C_ADDR_REG_ADDR, addr_reg_value, "MM IF Write transaction to addr_reg", clk, avalon_mm_if, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);

    wait for 5*clk_period;
    log(ID_SEQUENCER, "Write the value to be written to the Data Format register to the MM IF write_reg", C_SCOPE);
    -- Writing to MM IF write data registers.
    -- 4g resolution is set by writing 1 to the Data Format register
    avalon_mm_write(C_WRITE_REG_ADDR, x"00000001", "MM IF Write transaction to write_reg", clk, avalon_mm_if, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);

    wait for 5*clk_period;

    -- Writing to control register to start I2C transaction
    cmd      <= '1';    -- Request start transaction by setting cmd-bit high
    no_bytes <= "001";                  -- Write one byte
    rnw      <= '0';                    -- Request write
    wait for 0 ns;
    avalon_mm_write(C_CTRL_REG_ADDR, ctrl_reg_value, "MM IF transaction to request I2C write transaction", clk, avalon_mm_if, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);

    wait for clk_period*(GC_SYSTEM_CLK/GC_I2C_CLK)*50;


    -- =============================== Read back accel. data regs ============================================
    log(ID_LOG_HDR, "Reading back ADXL345 accelerometer data registers", C_SCOPE);


    -- Write to MM IF address registers
    -- We first need to update the ADXL345 device with the information about which register to read
    log(ID_SEQUENCER, "Write I2C address and address of Accel. DATAX0 register to MM IF addr_reg", C_SCOPE);
    i2c_device_addr <= i2c_addr_adxl345;
    internal_addr   <= adxl345_datax0_reg_addr;
    wait for 0 ns;
    avalon_mm_write(C_ADDR_REG_ADDR, addr_reg_value, "MM IF Write transaction to addr_reg", clk, avalon_mm_if, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);


    -- Writing to ctrl register to start I2C write transactions
    -- As we will only update the internal register pointer no data bytes will be written.
    cmd      <= '1';    -- Request start transaction by setting cmd-bit high
    no_bytes <= "000";  -- No bytes to write as only internal register address pointer will be updated
    rnw      <= '0';                    -- Request write
    wait for 0 ns;
    avalon_mm_write(C_CTRL_REG_ADDR, ctrl_reg_value, "MM IF transaction to request I2C write transaction", clk, avalon_mm_if, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);

    wait for clk_period*(GC_SYSTEM_CLK/GC_I2C_CLK)*50;

    -- Read back the 6 data registers
    -- The correct I2C and internal register values are already in the MM IF addr_reg from the previous transaction
    -- To read back all the data registers we can request the read of 6 bytes. The internal address pointer of the ADXL345 device will be incremented with one for each byte read.
    cmd      <= '1';    -- Request start transaction by setting cmd-bit high
    no_bytes <= "110";  -- We will read back 6 bytes (DATAX0,DATAX1,DATAY0,DATAY1,DATAZ0,DATAZ1)
    rnw      <= '1';                    -- Request read
    wait for 0 ns;
    avalon_mm_write(C_CTRL_REG_ADDR, ctrl_reg_value, "MM IF transaction to request I2C read transaction", clk, avalon_mm_if, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);

    wait for clk_period*(GC_SYSTEM_CLK/GC_I2C_CLK)*50*6;




    -- This method reads back and verifies that the data is as expected.
    -- The i2c_avalon_mm_if module returns the data in big endian format. Most significant value is stored in the lowest address. That is, DATAZ0 is stored in read_reg(7 downto 0) and DATAX0 is stored in read_reg(47 downto 32)
    -- Since the simulation model of the ADXL345 returns 'Z' for high values, we need to also compare the result using 'Z'.
    avalon_mm_check(C_READ_REG_ADDR_LOW, "000000ZZ00000Z0000000Z0Z00000ZZ0", "MM IF transaction to verify correct reveived value in read_reg(31 downto 0)", clk, avalon_mm_if, warning, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);

    -- This method reads back and verifies that the data is as expected.
    avalon_mm_check(C_READ_REG_ADDR_HIGH, "----------------0000000Z000000Z0", "MM IF transaction to verify correct reveived value in read_reg(63 downto 32)", clk, avalon_mm_if, warning, C_SCOPE, shared_msg_id_panel, C_AVALON_MM_BFM_CONFIG);


    --==================================================================================================
    -- Ending the simulation
    --------------------------------------------------------------------------------------
    wait for 1000 ns;                   -- to allow some time for completion
    report_alert_counters(FINAL);  -- Report final counters and print conclusion for simulation (Success/Fail)
    log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);
    clk_ena <= false;  -- to gracefully stop the simulation - if possible

    wait;                               -- to stop completely


    wait;                               --end simulation
  end process;
end architecture tb;
