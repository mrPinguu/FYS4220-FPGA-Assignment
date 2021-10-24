library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master is
    generic(
        GC_SYSTEM_CLK   : integer := 50_000_000; --system clock in Hz
        GC_I2C_CLK      : integer := 200_000 --I2C bus clock in Hz
    );

    port(
        clk     :   in std_logic; --system clk
        arst_n  :   in std_logic; --asynchronous active low reset
        valid   :   in std_logic; --module enable - valid data on input --> start tramsaction
        addr    :   in std_logic_vector(6 downto 0); --I2C adress of target slave
        rnw     :   in std_logic; --Read/nWrite command ('0' = write)
        data_wr :   in std_logic_vector(7 downto 0); --data to be written to slave
        data_rd :   out std_logic_vector(7 downto 0); --data read from slave
        busy    :   out std_logic; --indicates transaction in progress
        ack_error : out std_logic; --flagged if no acknowledge from slave
        sda     :   inout std_logic; --bidirectional serial i2c data
        scl     :   inout std_logic --bidirectional serial i2c clock
    );
end entity i2c_master;

architecture i2c of i2c_master is
    --timing signals
    signal state_ena    : std_logic := '0'; --enables state transition (duration 1 system clk cycle)
    signal scl_high_ena : std_logic := '0'; --enable signal used for start and stop conditions,data sample and acnowledge (duration 1 system clk cycle)
    signal scl_clk      : std_logic := '0'; --internal coninious running i2c clk signal

    --state machine signals
    type state_type is (sIDLE, sSTART, sADDR, sACK1, sACK2, sWRITE, sREAD, sMACK, sSTOP);
    signal state        : state_type; --state machine signal
    signal ack_error_i  : std_logic; --internal ack. error flag
    signal sda_i        : std_logic; -- internal sda signal
    signal addr_rnw_i   : std_logic_vector(7 downto 0); --internally stored value of ardess and Read/nWrite bit
    signal data_tx      : std_logic_vector(7 downto 0); --internally stored data to be sent to slave
    signal data_rx      : std_logic_vector(7 downto 0); --internally stored data from slave
    signal bit_cnt      : integer RANGE 0 to 7 := 0; --counter to keep track of databit
    signal scl_oe       : std_logic; --output enavle for scl

    alias rnw_i         : std_logic is addr_rnw_i(0); --lsb of internal signal addr_rnw_i


    --timing event constants
    constant C_SCL_PERIOD   : integer := GC_SYSTEM_CLK/GC_I2C_CLK; --transition point from 1->0 of the SCL signal
    constant C_SCL_HALF_PERIOD   : integer := C_SCL_PERIOD / 2; --transition point from 0->1 of the SCL signal
    constant C_STATE_TRIGGER   : integer := C_SCL_PERIOD / 4; --transition point of the main state machine
    constant C_SCL_TRIGGER   : integer := C_SCL_PERIOD * 3/4; -- Used to indicate the timing of a START and STOP condition and when to sample the SDA
begin

    p_sclk: process(clk, arst_n) is --process that generates 200 kHz clock
        variable cnt : integer RANGE 0 to C_SCL_PERIOD := 0;
    begin
        if(arst_n = '0') then --asynchronous active low reset
            cnt := 0;
            scl_clk <= '0';
        elsif (rising_edge(clk)) then
            cnt := cnt + 1;
            if(cnt = C_SCL_PERIOD) then
                cnt:=0;
            end if;

            if(cnt < C_SCL_HALF_PERIOD) then
                scl_clk <= '0';
            
            elsif (cnt < C_SCL_PERIOD) then
                scl_clk <= '1';
            end if;
        end if;
    end process p_sclk;

    p_ctrl: process (clk, arst_n) is --process that create the internal trigger signals
    variable cnt : integer RANGE 0 to C_SCL_PERIOD :=0;
    begin
        if(arst_n = '0') then
            cnt:=0;
            state_ena <= '0';
            scl_high_ena <='0';
        elsif(rising_edge(clk)) then
            cnt := cnt + 1;
            state_ena <= '0';
            scl_high_ena <='0';
            if(cnt = C_SCL_PERIOD) then
                cnt := 0;
            end if;

            if(cnt = C_STATE_TRIGGER) then
                state_ena <= '1';
            elsif(cnt = C_SCL_TRIGGER) then
                scl_high_ena <= '1';
            end if;
        end if;
    end process p_ctrl;

    p_state: process (arst_n,clk) is
    begin
        if arst_n = '0' then
            state <= sIDLE;
        elsif rising_edge(clk) then
            case state is
                when sIDLE =>
                    --state code
                    sda_i <= '1';
                    bit_cnt <= 7;

                    --change state
                    if (state_ena = '1') and (valid = '1') then
                        data_tx <= data_wr;
                        addr_rnw_i <= addr & rnw;
                        ack_error_i <= '0';
                        state <= sSTART;
                    end if;

                when sSTART =>
                    --state code
                    if scl_high_ena = '1' then
                        sda_i <= '0';
                    end if;

                    --change state
                    if state_ena = '1' then
                        state <= sADDR;
                    end if;

                when sADDR =>
                    --state code
                    sda_i <= addr_rnw_i(bit_cnt);
                    
                    --change state
                    if bit_cnt /= 0 then
                        if(state_ena = '1') then
                            bit_cnt <= bit_cnt -1;
                        end if;
                        state <= sADDR;
                    elsif (state_ena = '1') and (bit_cnt = 0) then
                        bit_cnt <= 7;
                        state <= sACK1;
                    end if;

                when sACK1 =>
                    --state code
                    sda_i <= '1';
                    if scl_high_ena = '1' then
                        if(sda /= '0') then
                            ack_error_i <= '1';
                        end if;
                    end if;

                    --change state
                    if (state_ena = '1') and (rnw_i = '0') then
                        state <= sWRITE;
                    elsif (state_ena = '1') and (rnw_i = '1') then
                        state <= sREAD;
                    end if;

                when sWRITE =>
                    --state code
                    sda_i <= data_tx(bit_cnt);

                    --change state
                    if bit_cnt /= 0 then
                        if state_ena = '1' then
                            bit_cnt <= bit_cnt - 1;
                        end if;
                        state <= sWRITE;
                    elsif (state_ena = '1') and (bit_cnt = 0) then
                        bit_cnt <= 7;
                        state <= sACK2;
                    end if;

                when sREAD =>
                    --state code
                    sda_i <= '1';

                    if scl_high_ena = '1' then
                        data_rx(bit_cnt) <= sda;
                    end if;

                    --change state
                    if bit_cnt /= 0 then
                        if state_ena = '1' then
                            bit_cnt <= bit_cnt -1;
                        end if;
                        state <= sREAD;
                    elsif (state_ena = '1') and (bit_cnt = 0) then
                        bit_cnt <= 7;
                        data_rd <= data_rx;
                        state <= sMACK;
                    end if;

                when sACK2 =>
                    --state code
                    sda_i <= '1';
                    busy <= '0';
                    if(scl_high_ena = '1') and (sda/= '0') then
                        ack_error_i <= '1';
                    end if;

                    --change state
                    if (state_ena = '1') and (valid = '1') and (rnw = '1') then
                        addr_rnw_i <= addr & rnw;
                        state <= sSTART;
                    elsif (state_ena = '1') and (valid = '1') and (rnw = '0') then
                        data_tx <= data_wr;
                        state <= sWRITE;
                    elsif (state_ena = '1') and (valid = '0') then
                        sda_i <= '0';
                        state <= sSTOP;
                    end if;

                
                when sMACK =>
                    --state code
                    sda_i <= '1';
                    if valid = '1' then
                        sda_i <= '0';
                    end if;

                    --change state
                    if (state_ena = '1') and (valid = '1') and (rnw = '0') then
                        addr_rnw_i <= addr & rnw;
                        data_tx <= data_wr;
                        state <= sSTART;
                    elsif (state_ena = '1') and (valid = '1') and (rnw = '1') then
                        state <= sREAD;
                    elsif (state_ena = '1') and (valid = '0') then
                        sda_i <= '0';
                        state <= sSTOP;
                    end if;

                when sSTOP =>
                    --state code
                    if scl_high_ena = '1' then
                        sda_i <= '1';
                    end if;

                    --change state
                    if state_ena = '1' then
                        state <= sIDLE;
                    end if;

            end case;
            if state /= sIDLE then
                scl_oe <= '1';
            else
                scl_oe <= '0';

            end if;
            if (state /= sIDLE) and (state /= sACK2) and (state /= sMACK) then
                busy <= '1';
            else
                busy <= '0';
            end if;
            

        end if;
    end process p_state;

    --combinational assignment of sda, scl and ack_error outputs
    ack_error <= ack_error_i;
    scl <= '0' when ((scl_clk = '0') and (scl_oe = '1')) else ('Z');
    sda <= '0' when sda_i = '0' else ('Z');    


end architecture i2c;
