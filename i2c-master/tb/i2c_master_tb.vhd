library ieee;
use ieee.std_logic_1164.all;

entity i2c_master_tb is
end entity;

architecture tb of i2c_master_tb is
    --signals from main
    signal clk     :   std_logic;
    signal arst_n  :   std_logic;
    signal valid   :   std_logic;
    signal addr    :   std_logic_vector(6 downto 0);
    signal rnw     :   std_logic;
    signal data_wr :   std_logic_vector(7 downto 0);
    signal data_rd :   std_logic_vector(7 downto 0);
    signal busy    :   std_logic;
    signal ack_error : std_logic;
    signal sda     :   std_logic;
    signal scl     :   std_logic;

    --signals to generate clock
    signal clk_ena  :   boolean := false;
    signal clk_period : time := 20 ns;

    constant GC_SYSTEM_CLK : integer := 50_000_000;
    constant GC_I2C_CLK : integer := 200_000;
    constant C_SCL_PERIOD : time := clk_period*(GC_SYSTEM_CLK/GC_I2C_CLK);--clk_period * 250
begin
    UUT : entity work.i2c_master
        generic map(
            GC_SYSTEM_CLK => GC_SYSTEM_CLK,
            GC_I2C_CLK => GC_I2C_CLK
        )
        port map (
            clk => clk,
            arst_n => arst_n,
            valid => valid,
            addr => addr,
            rnw => rnw,
            data_wr => data_wr,
            data_rd => data_rd,
            busy => busy,
            ack_error => ack_error,
            sda => sda,
            scl => scl
        );
    
    --generate clock
    clk <= not clk after clk_period/2 when clk_ena else '0';

    -- sequencer
  p_seq : process
  begin
    -- set default values
    addr <= (others => '0');
    rnw <= '0';
    data_wr <= (others => '0');

    valid <= '0';
    arst_n <= '1';

    -- Start clk
    clk_ena <= true;
    -- Reset circuit
    wait until clk = '1';
    arst_n <= '0';
    wait for clk_period*5;
    arst_n <= '1';


    ---------------------------------------------------
    -- Write data to register
    ---------------------------------------------------
    addr    <= "1010011";               -- i2c address
    rnw     <= '0';
    data_wr <= "00110001";  -- address of internal register.
    valid   <= '1';

    wait until busy = '1';  -- wait for busy to make sure command is received
    wait until rising_edge(clk);

    -- keep valid active
    wait until busy = '0';              -- wait for ack2
    data_wr <= "00000011";              -- provide data to be written to register

    wait until busy = '1';  -- wait for busy to make sure command is received
    valid <= '0';                       -- wait for busy ack2 and then stop
    wait until busy = '0';
    wait until busy = '1';              --busy in stop
    wait until busy = '0';              --returned to idle

    wait for clk_period*10;

    ---------------------------------------------------
    -- Read data from register
    ---------------------------------------------------
    addr    <= "1010011";               -- i2c address
    rnw     <= '0';
    data_wr <= "00110001";  -- address of internal register.
    valid   <= '1';
    wait until busy = '1';  -- wait for busy to make sure command is received

    wait until busy = '0';              -- wait for ack2
    rnw   <= '1';                       -- prepare for read
    valid <= '1';                       -- keep valid high --> restart
    addr  <= "1010011";
    wait until busy = '1';  -- wait for busy to make sure command is received
    wait until busy = '0';              -- wait for sMACK
    valid <= '0';                       -- prepare for stop
    wait until busy = '1';  -- wait for busy to make sure command is recieved

    wait for C_SCL_PERIOD*10;
    clk_ena <= false;
    wait;                  --end simulation
  end process;
end architecture tb;
