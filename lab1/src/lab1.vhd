--library and package part
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



--entity description
entity lab1 is
    port(
    sw : in std_logic_vector(9 downto 0);
    led : out std_logic_vector(9 downto 0);
    hex0 : out std_logic_vector(6 downto 0);
    Clock, Reset, cnt_enable : in std_logic
    );

end entity lab1;

--arcitecture

architecture func of lab1 is
    --decleration area
    alias bin0 is sw(3 downto 0);
    signal counter : unsigned(3 downto 0) := "0000";
    signal r0_input : std_logic := '0';
    signal r1_input : std_logic := '0';
    signal s_cnt_ena : std_logic := '0';
begin

    led <= sw;

    p_rising_edge_detection: process(Clock, Reset)
    begin
        if(Reset = '0') then
            r0_input <= '0';
            r1_input <= '0';
        elsif(Clock'event and Clock = '1') then
            r0_input <= cnt_enable;
            r1_input <= r0_input;
        end if;

    end process p_rising_edge_detection;

    s_cnt_ena <= not r0_input and r1_input;

    CNT : process (Clock, Reset)
    begin
            if (Reset = '0') then
                counter <= "0000";
            elsif (Clock'event and Clock = '1') then
                if (s_cnt_ena = '1') then
                    counter <= counter + 1;
                end if;
                
            end if;

                    
    end process CNT;
    
    with counter select
        hex0 <= "1000000" when "0000", --0
                "1111001" when "0001", --1
                "0100100" when "0010", --2
                "0110000" when "0011", --3
                "0011001" when "0100", --4
                "0010010" when "0101", --5
                "0000010" when "0110", --6
                "1111000" when "0111", --7
                "0000000" when "1000", --8
                "0010000" when "1001", --9
                "0001000" when "1010", --A 
                "0000011" when "1011", --b
                "1000110" when "1100", --C
                "0100001" when "1101", --d
                "0000110" when "1110", --E
                "0001110" when "1111", --F
                "0111111" when others;
        


end architecture; 