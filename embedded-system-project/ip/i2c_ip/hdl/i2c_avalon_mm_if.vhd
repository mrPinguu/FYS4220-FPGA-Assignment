library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_avalon_mm_if is
    port(
        clk         : in    std_logic; --system clock
        reset_n     : in    std_logic; --system reset
        read        : in    std_logic; --indicates read transaction on Avalon busy
        write       : in    std_logic; --indicates write transaction on Avlon busy
        chipselect  : in    std_logic; --Enable access to Avlon modules
        address      : in    std_logic_vector(2 downto 0); --Address of i2c_avlon_mm_if registers
        writedata   : in    std_logic_vector(31 downto 0); --Data to be witen to Avalon module
        readdata    : out    std_logic_vector(31 downto 0); --Data read back from Avalon module
        sda         : inout std_logic; --I2C data line to interface ADXL345 accelerometer
        scl         : inout std_logic --I2C clock lime to interface ADXL345 accelerometer
    );
end entity i2c_avalon_mm_if;

architecture behave of i2c_avalon_mm_if is

    --Signals from i2c_master component
    signal i2c_valid            : std_logic;
    signal i2c_addr             : std_logic_vector(6 downto 0);
    signal i2c_rnw              : std_logic;
    signal i2c_data_wr          : std_logic_vector(7 downto 0);
    signal i2c_data_rd          : std_logic_vector(7 downto 0);
    signal i2c_busy             : std_logic;
    signal i2c_ack_error        : std_logic;

    signal cmd_rst              : std_logic;

    --Register
    signal ctrl_reg             : std_logic_vector (31 downto 0); --Command and control register (RW)
    signal addr_reg             : std_logic_vector (31 downto 0); --I2c device and internal register addressable (RW)
    signal write_reg            : std_logic_vector (31 downto 0); --Data to be written to I2C device (RW)
    signal read_reg             : std_logic_vector (63 downto 0); --Data read from I2C device


    --alias for addr_reg
    alias i2c_int_addr          : std_logic_vector is addr_reg(15 downto 8);
    alias i2c_device_addr       : std_logic_vector is addr_reg(6 downto 0);

    --alias for ctrl_reg
    alias mm_if_busy            : std_logic is ctrl_reg(7);
    alias busy                  : std_logic is ctrl_reg(6);
    alias ack_error             : std_logic is ctrl_reg(5);
    alias no_bytes              : std_logic_vector is ctrl_reg(4 downto 2);
    alias rnw                   : std_logic is ctrl_reg(1);
    alias cmd                   : std_logic is ctrl_reg(0);

    --state machine signals
    type state_type is (sIDLE, sADDR, sWAIT_DATA, sWRITE_DATA, sWAIT_STOP);
    signal state       : state_type;
    signal mm_if_busy_state     : std_logic;

    begin
        I2C : entity work.i2c_master
            port map (
            clk => clk,
            arst_n => reset_n,
            valid => i2c_valid,
            addr => i2c_addr,
            rnw => i2c_rnw,
            data_wr => i2c_data_wr,
            data_rd => i2c_data_rd,
            busy => i2c_busy,
            ack_error => i2c_ack_error,
            sda => sda,
            scl => scl
            );


        p_mm_if : process(clk)
        begin
            
            if(rising_edge(clk)) then
                -- if reset_n = '0' then
                --     ctrl_reg(4 downto 0) <= (others => '0');
                --     addr_reg <= (others => '0');
                --     write_reg <= (others => '0');
                --     read_reg <= (others => '0');
                -- else
                    --write data from CPU interface
                    if chipselect = '1' and write = '1' then
                        case address is
                            when "000" =>
                                ctrl_reg(4 downto 0) <= writedata(4 downto 0);
                            when "001" =>
                                addr_reg <= writedata;
                            when "010" =>
                                write_reg <= writedata;
                            when others =>
                                null;
                        end case;
                    --read data from CPU interface
                    elsif chipselect = '1' and read = '1' then
                        case address is
                            when "000" =>
                                readdata <= ctrl_reg;
                            when "001" =>
                                readdata <= addr_reg;
                            when "010" =>
                                readdata <= write_reg;
                            when "011" =>
                                readdata <= read_reg(31 downto 0);
                            when "100" =>
                                readdata <= read_reg(63 downto 32);
                            when others =>
                                null;
                        end case;
                    end if;
                    ack_error <= i2c_ack_error;
                    busy <= i2c_busy;
                    mm_if_busy <= mm_if_busy_state;
                    
                    if(cmd_rst = '1') then
                        cmd <= '0';
                    end if;
                --end if;
            end if;
        end process p_mm_if;

        p_mm_if_state : process(clk, reset_n)
        
            variable byte_count : integer range 0 to 63;

        begin
                
            if rising_edge(clk) then
                cmd_rst <= '0';
                if reset_n = '0' then
                    state <= sIDLE;
                else

                    case state is
                    
                        when sIDLE =>
                            i2c_valid <= '0';
                            mm_if_busy_state <= '0';

                            if cmd = '1' then
                                byte_count := to_integer(unsigned(no_bytes));
                                cmd_rst <= '1';
                                state <= sADDR;
                            else
                                state <= sIDLE;
                            end if;

                        when sADDR =>
                            mm_if_busy_state <= '1';
                            i2c_data_wr <= i2c_int_addr;
                            i2c_addr <= i2c_device_addr;
                            i2c_rnw <= rnw;
                            i2c_valid <= '1';
                        
                            if( i2c_busy = '1' and busy = '0') then
                                state <= sWAIT_DATA;
                            else
                                state <= sADDR;
                            end if;
                        

                        when sWAIT_DATA =>
                            mm_if_busy_state <= '1';
                            if(i2c_busy = '0' and busy = '1') then
                                if(rnw = '1') then
                                    read_reg((8*byte_count)-1 downto 8*(byte_count - 1)) <= i2c_data_rd;
                                    byte_count := byte_count -1;

                                    if(byte_count = 0) then
                                        state <= sWAIT_STOP;
                                    else
                                        state <= sWAIT_DATA;
                                    end if;

                                elsif (rnw = '0') then
                                    if (byte_count = 0) then
                                        state <= sWAIT_STOP;
                                    else
                                        state <= sWRITE_DATA;
                                    end if;
                                end if;
                            else
                                state <= sWAIT_DATA;
                            end if;
                        
                        when sWRITE_DATA =>
                            mm_if_busy_state <= '1';
                            i2c_data_wr <= write_reg((8*byte_count)-1 downto 8*(byte_count-1));
                            if(i2c_busy = '1' and busy = '0') then
                                byte_count := byte_count -1;
                                state <= sWAIT_DATA;
                            else
                                state <= sWRITE_DATA;
                            end if;

                        when sWAIT_STOP =>
                            mm_if_busy_state <= '1';
                            i2c_valid <= '0';
                            if(i2c_busy = '0' and busy = '1') then
                                state <= sIDLE;
                            else
                                state <= sWAIT_STOP;
                            end if;
                    end case ;
                end if;
            end if;
        end process p_mm_if_state;
        

end architecture behave;