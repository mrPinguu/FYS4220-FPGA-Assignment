library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab1_tb is
end;

architecture testbench of lab1_tb is

  -- Signal declarations
  -- The clk related signals is provided as an example
  signal clk          : std_logic;
  signal clk_ena      : boolean;
  constant clk_period : time := 20 ns;  -- 50 MHz
  -- Declare all the remaining required top level signals.
  signal Reset_tb : std_logic := '1';
  signal cnt_enable_tb : std_logic := '1';
  signal hex0_tb : std_logic_vector(6 downto 0);
  signal sw_tb : std_logic_vector(9 downto 0);
  signal led_tb : std_logic_vector(9 downto 0);



  -- Component declarations
  -- Declare the component to be tested.
  component lab1
    port(
      sw : in std_logic_vector(9 downto 0);
      led : out std_logic_vector(9 downto 0);
      Clock, Reset, cnt_enable: in std_logic;
      hex0 : out std_logic_vector(6 downto 0)
    );
  end component;

begin

  -- Instantiate the port map for the unit under test.
  -- Keep the label name UUT
  UUT : lab1 port map ( 
                        Reset => Reset_tb,
                        cnt_enable => cnt_enable_tb,
                        hex0 => hex0_tb,
                        Clock => clk,
                        sw => sw_tb,
                        led => led_tb
                      );
  -- create a 50 MHz clock
  -- The clk signal can be disabled or enabled by the clk_ena signal
  clk <= not clk after clk_period/2 when clk_ena else '0';


  -- Write the stimuli process

  stimuli_process : process
  begin
    -- set default values

    -- enable clk and wait for 3 clk periods
    clk_ena <= true; wait for 3*clk_period;
    report "clock enabled" severity NOTE;
    -- assert arst_n for 3 clk periods
    reset_tb <= '0'; wait for 3*clk_period;
    report "reset activated" severity NOTE;
    -- deassert arst_n for 3 clk periods
    reset_tb <= '1'; wait for 3*clk_period;
    report "reset deactivated" severity NOTE;
    -- enable counter and wait for 20 clk_periods
    cnt_enable_tb <= '0'; wait for 20*clk_period;
    report "counter enabled" severity NOTE;
    -- disable counter and wait for 5 clk_periods
    cnt_enable_tb <= '1'; wait for 5*clk_period;
    report "counter disabled" severity NOTE;
    -- assert arst_n for 3 clk periods
    reset_tb <= '0'; wait for 3*clk_period;
    report "reset activated" severity NOTE;
    -- deassert arst_n for 10 clk periods
    reset_tb <= '1'; wait for 10*clk_period;
    report "reset deactivated" severity NOTE;
    -- disable clk
    clk_ena <= false;
    report "clock disabled" severity NOTE;
    -- end of simulation
    report "end of simulation" severity NOTE;
    wait;
  end process stimuli_process;
end architecture testbench;