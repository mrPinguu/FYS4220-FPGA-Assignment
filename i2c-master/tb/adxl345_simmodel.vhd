
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

entity adxl345_simmodel is
  generic(
    i2c_clk : integer := 200_000);      --i2c bus frequency in Hz
  port(
    sda : inout std_logic := 'Z';       --serial data output of i2c bus
    scl : inout std_logic := 'Z');      --serial clock output of i2c bus
end adxl345_simmodel;

architecture logic of adxl345_simmodel is

  type     statetype is(sIDLE, sACK1, sACK2, sMACK, sREAD_ADDR, sREAD_POINTER, sREAD_DATA_FROM_MASTER, sWRITE_DATA_TO_MASTER);
  signal   state   : statetype;
  type     t_ctrl is (cSTART, cRESTART, cSTOP, cNONE);
  constant C_SCOPE : string := "adxl345 model";

  signal ctrl : t_ctrl := cNONE;


  signal addr                    : std_logic_vector(6 downto 0);
  signal rnw                     : std_logic;
  signal addr_rnw                : std_logic_vector(7 downto 0);
  signal pointer                 : std_logic_vector(7 downto 0);
  --signal dataFormat              : std_logic_vector(7 downto 0);
  signal deviceID                : std_logic_vector(7 downto 0) := "11100101";
  signal logdata                 : std_logic_vector(7 downto 0);
  signal sda_in, sda_out, scl_in : std_logic;
  signal reset_ctrl              : std_logic;

  signal datax0 : std_logic_vector(7 downto 0) := x"01";
  signal datax1 : std_logic_vector(7 downto 0) := x"02";
  signal datay0 : std_logic_vector(7 downto 0) := x"03";
  signal datay1 : std_logic_vector(7 downto 0) := x"04";
  signal dataz0 : std_logic_vector(7 downto 0) := x"05";
  signal dataz1 : std_logic_vector(7 downto 0) := x"06";


begin


  addr <= addr_rnw(7 downto 1);
  rnw  <= addr_rnw(0);

  scl <= 'Z';

  scl_in <= '1' when scl = 'Z' else '0';


  sda <= '0' when state = sACK1 else
         '0' when state = sACK2                                         else
         '0' when ((state = sWRITE_DATA_TO_MASTER) and (sda_out = '0')) else 'Z';

  sda_in <= '1' when sda = 'Z' else '0';


-------------------------------------------------------------------------------
-- Detect start and stop conditions
-------------------------------------------------------------------------------
  process(sda_in, scl_in, reset_ctrl)
  begin

    if sda_in'event and sda_in = '1' then
      if scl_in = '1' then
        ctrl <= cSTOP;
        log(ID_SEQUENCER_SUB, "STOP condition detected", C_SCOPE);
      end if;
    elsif sda_in'event and sda_in = '0' then
      if scl_in = '1' then
        if ctrl = cSTART or ctrl = cRESTART then
          ctrl <= cRESTART;
          log(ID_SEQUENCER_SUB, "RESTART condition detected", C_SCOPE);
        else
          ctrl <= cSTART;
          log(ID_SEQUENCER_SUB, "START condition detected", C_SCOPE);
        end if;
      end if;
    end if;
    if reset_ctrl = '1' then
      ctrl <= cNONE;
    end if;


  end process;

-------------------------------------------------------------------------------
-- Main control process
-------------------------------------------------------------------------------
  process(scl_in, ctrl)
    variable bit_count     : integer range 0 to 8 := 8;
    variable dataFormatReg : std_logic_vector(7 downto 0);

  begin

    --If stop detected return immediatly to sIDLE
    if ctrl = cSTOP then
      state     <= sIDLE;
      sda_out   <= '1';
      bit_count := 8;

    end if;
    -- if restart condition detected return immediately to sIDLE.
    if ctrl'event and ctrl = cRESTART then
      state     <= sIDLE;
      sda_out   <= '1';
      bit_count := 8;

    end if;

    --Do all the following operations on falling edge
    if falling_edge(scl_in) then
      case state is
-------------------------------------------------------------------------------
-- sIDLE
-------------------------------------------------------------------------------
        when sIDLE =>
          reset_ctrl <= '0';
          if ctrl = cSTART or ctrl = cRESTART then
            state <= sREAD_ADDR;
          end if;
          sda_out <= '1';
-------------------------------------------------------------------------------
-- sREAD_ADRR
-------------------------------------------------------------------------------
        when sREAD_ADDR =>
          sda_out             <= '1';
          bit_count           := bit_count - 1;
          addr_rnw(bit_count) <= sda_in;

          if bit_count = 0 then
            state   <= sACK1;
            sda_out <= '0';
          end if;
---------------------------------------
--sREAD_POINTER
---------------------------------------
        when sREAD_POINTER =>
          sda_out <= '1';

          bit_count          := bit_count - 1;
          pointer(bit_count) <= sda_in;

          if bit_count = 0 then
            state   <= sACK2;
            sda_out <= '0';
            log(ID_SEQUENCER_SUB, "Register address: " & to_string(pointer(7 downto 1) & sda_in) & " detected.", C_SCOPE);
          end if;

-------------------------------------------------------------------------------
-- sACK1
-------------------------------------------------------------------------------
        when sACK1 =>

          sda_out   <= '0';
          bit_count := 8;

          if rnw = '0' then                  --continued write cmd from master
            state <= sREAD_POINTER;
          else
            state <= sWRITE_DATA_TO_MASTER;  --put first bit on bus
          end if;

          if addr /= "1010001" then
            state      <= sIDLE;
            reset_ctrl <= '1';
            sda_out    <= '1';
          else
            log(ID_SEQUENCER_SUB, "Ack Address adxl345", C_SCOPE);
          end if;
-------------------------------------------------------------------------------
-- sACK2
-------------------------------------------------------------------------------
        when sACK2 =>

          log(ID_SEQUENCER_SUB, "Ack Data adxl345", C_SCOPE);
          sda_out   <= '0';
          state     <= sREAD_DATA_FROM_MASTER;  --continue to read data from master
          bit_count := 8;


-------------------------------------------------------------------------------
-- sREAD_DATA_FROM_MASTER
-------------------------------------------------------------------------------
        when sREAD_DATA_FROM_MASTER =>
          sda_out   <= '1';
          bit_count := bit_count - 1;
          if pointer = "00110001" then
            dataFormatReg(bit_count) := sda_in;


          end if;

          if bit_count = 0 then
            state   <= sACK2;
            sda_out <= '0';
            if pointer = "00000000" then
              alert(warning, "Device ID reg is read only!", C_SCOPE);
            elsif pointer = "00110001" then
              log(ID_SEQUENCER_SUB, "Updated Data Format .reg. to: " & to_string(dataFormatReg(7 downto 1) & sda_in), C_SCOPE);
              case dataFormatReg(1 downto 0) is
                when "00" =>
                  log(ID_SEQUENCER_SUB, "Setting accel. range to 2g", C_SCOPE);
                when "01" =>
                  log(ID_SEQUENCER_SUB, "Setting accel. range to 4g", C_SCOPE);
                when "10" =>
                  log(ID_SEQUENCER_SUB, "Setting accel. range to 8g", C_SCOPE);
                when "11" =>
                  log(ID_SEQUENCER_SUB, "Setting accel. range to 16g", C_SCOPE);
                when others =>
                  log(ID_SEQUENCER_SUB, "tes", C_SCOPE);
              end case;
              --if dataFormatReg(6) = '1' then
              -- log(ID_SEQUENCER_SUB, "SPI set to 3-wire inferface", C_SCOPE);
              --else
              --  log(ID_SEQUENCER_SUB, "SPI set to 4-wire inferface", C_SCOPE);
              --end if;
            end if;
          end if;

-------------------------------------------------------------------------------
-- sWRITE_DATA_TO_MASTER
-------------------------------------------------------------------------------
        when sWRITE_DATA_TO_MASTER =>
          null;
-------------------------------------------------------------------------------
-- sMACK
-------------------------------------------------------------------------------
        when sMACK =>

          if sda_in /= '0' then
            log(ID_SEQUENCER_SUB, "Master NACK detected", C_SCOPE);
            state <= sIDLE;
          else
            state   <= sWRITE_DATA_TO_MASTER;
            log(ID_SEQUENCER_SUB, "Master ACK detected", C_SCOPE);
            pointer <= std_logic_vector(unsigned(pointer) + 1);
          end if;
          bit_count := 8;
-------------------------------------------------------------------------------
-- others
-------------------------------------------------------------------------------
        when others =>
          sda_out <= '1';
      end case;
    end if;

    --The following code takes care of writing data to the I2C master.
    --The following code takes care of writing data to the I2C master.
    if falling_edge(scl_in) then

      if state = sWRITE_DATA_TO_MASTER or ((state = sACK1 or state = sMACK) and rnw = '1') then
        if bit_count = 0 then
          state <= sMACK;
          --logging
          if pointer = "00000000" then
            log(ID_SEQUENCER_SUB, "Read Device ID reg. of value: " & to_string(deviceID(7 downto 0)), C_SCOPE);
          elsif pointer = "00110001" then
            log(ID_SEQUENCER_SUB, "Read Data Format .reg. of value: " & to_string(dataFormatReg(7 downto 0)), C_SCOPE);
          elsif pointer = x"32" then
            log(ID_SEQUENCER_SUB, "Read accel. data x0:  " & to_string(datax0(7 downto 0)), C_SCOPE);
          elsif pointer = x"33" then
            log(ID_SEQUENCER_SUB, "Read accel. data x1:  " & to_string(datax1(7 downto 0)), C_SCOPE);
          elsif pointer = x"34" then
            log(ID_SEQUENCER_SUB, "Read accel. data y0:  " & to_string(datay0(7 downto 0)), C_SCOPE);
          elsif pointer = x"35" then
            log(ID_SEQUENCER_SUB, "Read accel. data y1:  " & to_string(datay1(7 downto 0)), C_SCOPE);
          elsif pointer = x"36" then
            log(ID_SEQUENCER_SUB, "Read accel. data z0:  " & to_string(dataz0(7 downto 0)), C_SCOPE);
          elsif pointer = x"37" then
            log(ID_SEQUENCER_SUB, "Read accel. data z1:  " & to_string(dataz1(7 downto 0)), C_SCOPE);


          end if;
        else
          if pointer = x"00" then
            sda_out <= deviceID(bit_count-1);
          elsif pointer = "00110001" then
            sda_out <= dataFormatReg(bit_count-1);

          elsif pointer = x"32" then
            sda_out <= datax0(bit_count-1);
          elsif pointer = x"33" then
            sda_out <= datax1(bit_count-1);
          elsif pointer = x"34" then
            sda_out <= datay0(bit_count-1);
          elsif pointer = x"35" then
            sda_out <= datay1(bit_count-1);
          elsif pointer = x"36" then
            sda_out <= dataz0(bit_count-1);
          elsif pointer = x"37" then
            sda_out <= dataz1(bit_count-1);


          end if;
          bit_count := bit_count - 1;
        end if;
      end if;
    end if;

  end process;

end logic;
