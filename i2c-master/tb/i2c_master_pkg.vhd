library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- UVVM Utility Library
-------------------------------------------------------------------------------
library STD;
use std.env.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

--library bitvis_vip_sbi;
--use bitvis_vip_sbi.sbi_bfm_pkg.all;
-------------------------------------------------------------------------------


package i2c_master_pkg is

  -- Signals for i2c master
  signal clk       : std_logic;
  signal arst_n    : std_logic;
  signal valid     : std_logic;
  signal addr      : std_logic_vector(6 downto 0);
  signal rnw       : std_logic;
  signal data_wr   : std_logic_vector(7 downto 0);
  signal data_rd   : std_logic_vector(7 downto 0);
  signal busy      : std_logic;
  signal ack_error : std_logic;
  signal sda       : std_logic;
  signal scl       : std_logic;


  signal clk_ena    : boolean := false;
  signal clk_period : time    := 20 ns;

  constant GC_SYSTEM_CLK : integer := 50_000_000;
  constant GC_I2C_CLK    : integer := 200_000;
  constant C_SCL_PERIOD  : time    := clk_period*(GC_SYSTEM_CLK/GC_I2C_CLK);


  --ADXL345 address values
  constant i2c_addr_adxl345        : std_logic_vector(6 downto 0) := "1010001";
  constant reg_addr_device_id      : std_logic_vector(7 downto 0) := "00000000";
  constant reg_addr_data_format    : std_logic_vector(7 downto 0) := "00110001";
  constant adxl345_device_id       : std_logic_vector(7 downto 0) := "11100101";
  constant adxl345_data_format_reg : std_logic_vector(7 downto 0)  := "00110001";
  constant adxl345_8g              : std_logic_vector(7 downto 0) := "00000010";

  constant adxl345_datax0_reg_addr : std_logic_vector(7 downto 0) := x"32";
  constant adxl345_datax1_reg_addr : std_logic_vector(7 downto 0) := x"33";
  constant adxl345_datay0_reg_addr : std_logic_vector(7 downto 0) := x"34";
  constant adxl345_datay1_reg_addr : std_logic_vector(7 downto 0) := x"35";
  constant adxl345_dataz0_reg_addr : std_logic_vector(7 downto 0) := x"36";
  constant adxl345_dataz1_reg_addr : std_logic_vector(7 downto 0) := x"37";

  constant adxl345_datax0_value : std_logic_vector(7 downto 0) := x"01";
  constant adxl345_datax1_value : std_logic_vector(7 downto 0) := x"02";
  constant adxl345_datay0_value : std_logic_vector(7 downto 0) := x"03";
  constant adxl345_datay1_value : std_logic_vector(7 downto 0) := x"04";
  constant adxl345_dataz0_value : std_logic_vector(7 downto 0) := x"05";
  constant adxl345_dataz1_value : std_logic_vector(7 downto 0) := x"06";


  -- constant system_clk : integer := 50_000_000;
  -- constant i2c_clk    : integer := 200_000;
  constant clk_ratio : integer := GC_SYSTEM_CLK/GC_I2C_CLK;







  type t_data_array is array (0 to 1) of std_logic_vector(7 downto 0);

  --write data to i2c device
  procedure write_i2c(
    -- input values
    constant i2c_addr : in  std_logic_vector;
    constant reg_addr : in  std_logic_vector;
    constant data     : in  t_data_array;
    constant no_bytes : in  integer;
    -- signals to check
    signal   clk      : in  std_logic;
    signal   busy     : in  std_logic;
    -- signals to set
    signal   valid    : out std_logic;
    signal   rnw      : out std_logic;
    signal   addr     : out std_logic_vector;
    signal   data_wr  : out std_logic_vector
    );


  --read data to i2c device
  procedure read_i2c(
    -- input/output values
    constant i2c_addr    : in  std_logic_vector;
    constant reg_addr    : in  std_logic_vector;
    signal   data        : out t_data_array;
    constant no_bytes    : in  integer;
    -- signals to check
    signal   clk         : in  std_logic;
    signal   busy        : in  std_logic;
    signal   data_rd     : in  std_logic_vector;
    -- signals to set
    signal   valid       : out std_logic;
    signal   rnw         : out std_logic;
    signal   addr        : out std_logic_vector;
    signal   data_wr     : out std_logic_vector;
    constant check_value : in  boolean := false
    );




end package;


package body i2c_master_pkg is




  --write data to i2c device
  procedure write_i2c(
    -- input values
    constant i2c_addr : in  std_logic_vector;
    constant reg_addr : in  std_logic_vector;
    constant data     : in  t_data_array;
    constant no_bytes : in  integer;
    -- signals to check
    signal   clk      : in  std_logic;
    signal   busy     : in  std_logic;
    -- signals to set
    signal   valid    : out std_logic;
    signal   rnw      : out std_logic;
    signal   addr     : out std_logic_vector;
    signal   data_wr  : out std_logic_vector
    ) is
    constant C_SCOPE : string := "i2c pkg write";
  begin
    -- Wait until i2c master is ready
    await_value(busy, '0', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy low", C_SCOPE);
    addr    <= i2c_addr;                -- i2c address
    rnw     <= '0';
    data_wr <= reg_addr;  -- address of configuration register to pointer reg.
    valid   <= '1';
    -- wait for command to be received and then to reach sACK2
    await_value(busy, '1', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy high", C_SCOPE);
    await_value(busy, '0', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy low2", C_SCOPE);
    for byte_pos in 0 to no_bytes-1
    loop
      data_wr <= data(byte_pos);        -- update data_wr
      --wait for command to be received and then to reach sACK2
      await_value(busy, '1', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy high2", C_SCOPE);
      await_value(busy, '0', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy low3", C_SCOPE);
    end loop;

    valid <= '0';                       -- prepare to stop
    --wait for valid to be received and then for sSTOP
    await_value(busy, '1', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy high3", C_SCOPE);
    --wait for idle state
    await_value(busy, '0', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy low4", C_SCOPE);
-- wait for stop state

  end procedure;




  --read data to i2c device
  procedure read_i2c(
    -- input/output values
    constant i2c_addr    : in  std_logic_vector;
    constant reg_addr    : in  std_logic_vector;
    signal   data        : out t_data_array;
    constant no_bytes    : in  integer;
    -- signals to check
    signal   clk         : in  std_logic;
    signal   busy        : in  std_logic;
    signal   data_rd     : in  std_logic_vector;
    -- signals to set
    signal   valid       : out std_logic;
    signal   rnw         : out std_logic;
    signal   addr        : out std_logic_vector;
    signal   data_wr     : out std_logic_vector;
    constant check_value : in  boolean := false
    ) is
    constant C_SCOPE : string := "i2c pkg read";
  begin
    await_value(busy, '0', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy low", C_SCOPE);

    addr    <= i2c_addr;
    rnw     <= '0';
    data_wr <= reg_addr;  -- write addr. of temperature register to pointer reg.
    valid   <= '1';
    -- Wait until command is received and then for sMACK
    await_value(busy, '1', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy high", C_SCOPE);
    await_value(busy, '0', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy low2", C_SCOPE);

    addr  <= i2c_addr;                  --Prepare for read (restart)
    rnw   <= '1';
    valid <= '1';


    for byte_pos in 0 to no_bytes-1     -- repeat for number of bytes to read
    loop
      --wait for command to be received and then for sMACK
      await_value(busy, '1', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy high2", C_SCOPE);
      await_value(busy, '0', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy low3", C_SCOPE);
      for bit_pos in 0 to data_rd'length-1
      loop
        if (data_rd(bit_pos) = 'Z') or (data_rd(bit_pos) = '1') then
          data(byte_pos)(bit_pos) <= '1';
        else
          data(byte_pos)(bit_pos) <= '0';
        end if;
      end loop;
    end loop;
    valid <= '0';                       -- prepare for stop
    --wait for valid to be received and then for sSTOP
    await_value(busy, '1', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy high3", C_SCOPE);
    --wait for idle state
    await_value(busy, '0', 0 ns, clk_ratio*100*clk_period, error, "Waiting for busy low4", C_SCOPE);
  end procedure;


end package body;
