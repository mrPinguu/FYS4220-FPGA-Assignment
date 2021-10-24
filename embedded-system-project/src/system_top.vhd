library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity system_top is
    port(
        clk                 :   in std_logic; --system clock
        arst_n              :   in std_logic; --asynchronous active low reset(key0)
        ext_ena_n           :   in std_logic; --DE10-Lite push buttons (key1)
        sw                  :   in std_logic_vector(9 downto 0); --DE10-Lite slide switches
        led                 :   out std_logic_vector(9 downto 0); --DE1-SoC LEDs (output data)
        sda                 :   inout std_logic; --bidirectional serial i2c data
        scl                 :   inout std_logic; --bidirectional serial i2c clock
        adxl345_irq_n       :   in std_logic_vector(1 downto 0); --interrupt lines from adxl345
        adxl345_alt_addr    :   out std_logic; --Hardwire to '0' to set adxl345 i2c address to 0x53
        adxl345_cs_n        :   out std_logic --Hardwire to '0' to set adxl345 serial mode to i2c
    );
end entity system_top;

architecture behave of system_top is
    signal irq_n_r, irq_n_rr   : std_logic_vector (2 downto 0);

    component nios2_system is
		port (
			clk_clk                                  : in  std_logic                    := 'X';             -- clk
			reset_reset_n                            : in  std_logic                    := 'X';             -- reset_n
			led_pio_external_connection_export       : out std_logic_vector(9 downto 0);                    -- export
			sw_pio_external_connection_export        : in  std_logic_vector(9 downto 0) := (others => 'X'); -- export
            interrupt_pio_external_connection_export : in  std_logic_vector(2 downto 0) := (others => 'X');  -- export
            i2c_avalon_mm_if_conduit_end_sda_export  : inout std_logic                    := 'X';             -- export
			i2c_avalon_mm_if_conduit_end_scl_export  : inout std_logic                    := 'X'              -- export
		);
    end component nios2_system;

    begin

        --Set adxl345's i2c address to 0x53
        adxl345_alt_addr <= '0';
        --Set adxl345's mode to i2c
        adxl345_cs_n <= '1';


        p_sync : process(clk) is
            begin
                if rising_edge(clk) then
                    irq_n_r <= adxl345_irq_n & ext_ena_n;
                    irq_n_rr <= irq_n_r;
                end if;
        end process p_sync;

        u0 : component nios2_system
		port map (
			clk_clk                                  => clk,                                  --                               clk.clk
			reset_reset_n                            => arst_n,                            --                             reset.reset_n
			led_pio_external_connection_export       => led,       --       led_pio_external_connection.export
			sw_pio_external_connection_export        => sw,        --        sw_pio_external_connection.export
            interrupt_pio_external_connection_export => irq_n_rr,  -- interrupt_pio_external_connection.export
            i2c_avalon_mm_if_conduit_end_sda_export  => sda,  --  i2c_avalon_mm_if_conduit_end_sda.export
			i2c_avalon_mm_if_conduit_end_scl_export  => scl   --  i2c_avalon_mm_if_conduit_end_scl.export
            
		);

    end architecture behave;

