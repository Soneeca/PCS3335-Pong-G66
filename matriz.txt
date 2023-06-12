library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity WS2812 is
	port (
		clk : in std_logic;
        data : in std_logic_vector(2 downto 0);
		serial : out std_logic;
	);
end entity WS2812;

architecture arch of WS2812 is

	constant T0H : integer := 17;
	constant T0L : integer := 38; 
	constant T1H : integer := 35;
	constant T1L : integer := 28; 
	constant RES : integer := 2500;
    
	
	type LED_matrix is array (0 to 255) of std_logic_vector(23 downto 0);
	type state_machine is (load, sending, send_bit, reset);

begin
	process
		variable state : state_machine := load;
		variable GRB : std_logic_vector(23 downto 0) := x"000000";
		variable delay_high_counter : integer := 0;
		variable delay_low_counter : integer := 0;
		variable index : integer := 0;
		variable bit_counter : integer := 0;
        variable ball : integer range -3 to 3 := 1;
    	variable ball_index : integer range 0 to 255 := 119;
    	variable p1_index : integer range 1 to 14 := 7;
    	variable p2_index : integer range 225 to 238 := 231;
		variable LED : LED_matrix := (
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"FFFF00", x"FFFF00", x"FFFF00", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"FFFFFF", x"000000", x"FFFFFF", x"000000", x"FFFFFF", x"000000", x"FFFFFF", x"FFFF00", x"FFFFFF", x"000000", x"FFFFFF", x"000000", x"FFFFFF", x"000000", x"FFFFFF", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"FFFF00", x"FFFF00", x"FFFF00", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000");
	begin
		wait until rising_edge(clk);

		case state is
			when load =>
			    GRB := LED(index);
				bit_counter := 24;
				state := sending;

			when sending =>
				if (bit_counter > 0) then
				    bit_counter := bit_counter - 1;
					if GRB(bit_counter) = '1' then
						delay_high_counter := T1H;
						delay_low_counter := T1L;
					else
						delay_high_counter := T0H;
						delay_low_counter := T0L;
					end if;
					state := send_bit;
				else
					if (index < 255) then
						index := index + 1;
						state := load;
					else
						delay_low_counter := RES;
						state := reset;
					end if;
				end if;

			when send_bit =>
				if (delay_high_counter > 0) then
					serial <= '1';
					delay_high_counter := delay_high_counter - 1;
				elsif (delay_low_counter > 0) then
					serial <= '0';
					delay_low_counter := delay_low_counter - 1;
				else
					state := sending;
				end if;

			when reset =>
				if (delay_low_counter > 0) then
					serial <= '0';
					delay_low_counter := delay_low_counter - 1;
				else
					index := 0;

                    case data is
                        when "001" => 
                            if (p1_index /= 14) then 
                                LED(p1_index - 1) := x"000000";
                                LED(p1_index + 2) := x"FFFF00";
                                p1_index := p1_index + 1;
                            end if;
                        when "010" =>
                            if (p1_index /= 1) then 
                                LED(p1_index + 1) := x"000000";
                                LED(p1_index - 2) := x"FFFF00";
                                p1_index := p1_index - 1;
                            end if;
                        when "101" =>
                            if (p2_index /= 238) then 
                                LED(p2_index - 1) := x"000000";
                                LED(p2_index + 2) := x"FFFF00";
                                p2_index := p2_index + 1;
                            end if;
                        when "110" =>
                            if (p2_index /= 225) then 
                                LED(p2_index + 1) := x"000000";
                                LED(p2_index - 2) := x"FFFF00";
                                p2_index := p2_index - 1;
                            end if;
                        when others => null;
                    end case;

    
                    LED(ball_index) := x"000000";
                    
                    case ball is 
                        when 1 =>
                            if((ball_index = 16 and p1_index /= 1) or ball_index = 32 or ball_index = 48 or ball_index = 64
                            or ball_index = 80 or ball_index = 96 or ball_index = 112 or ball_index = 128 or ball_index = 144
                            or ball_index = 160 or ball_index = 176 or ball_index = 192 or ball_index = 208) then
                                ball := 3;
                                ball_index := ball_index - 15;
                                state := load;
                            elsif (not(ball_index > 15 and ball_index < 32)) then
                                ball_index := ball_index - 17;
                                state := load;
                            elsif(ball_index - 17 = p1_index - 1) then
                                case p1_index is
                                    when 1 => 
                                        ball := -1;
                                        ball_index := ball_index + 17;
                                    when others =>
                                        ball := -3;
                                        ball_index := ball_index + 15;
                                end case;
                                state := load;
                            elsif(ball_index - 17 = p1_index) then
                                ball := -2;
                                ball_index := ball_index + 16;
                                state := load;
                            elsif(ball_index - 17 = p1_index + 1) then
                                ball := -1;
                                ball_index := ball_index + 17;
                                state := load;
                            else  
                                state := start;
                            end if;
                                
                        when 2 =>
                            if (not(ball_index > 15 and ball_index < 32)) then
                                ball_index := ball_index - 16;
                                state := load;
                            elsif(ball_index - 16 = p1_index - 1) then
                                case p1_index is
                                    when 1 => 
                                        ball := -1;
                                        ball_index := ball_index + 17;
                                    when others =>
                                        ball := -3;
                                        ball_index := ball_index + 15;
                                end case;
                                state := load;
                            elsif(ball_index - 16 = p1_index) then
                                ball := -2;
                                ball_index := ball_index + 16;
                                state := load;
                            elsif(ball_index - 16 = p1_index + 1) then
                                case p1_index is
                                    when 14 => 
                                        ball := -3;
                                        ball_index := ball_index + 15;
                                    when others =>
                                        ball := -1;
                                        ball_index := ball_index + 17;
                                end case;
                                state := load;
                            else  
                                state := start;
                            end if;

                        when 3 =>
                            if((ball_index = 31 and p1_index /= 14) or ball_index = 47 or ball_index = 63 or ball_index = 79
                            or ball_index = 95 or ball_index = 111 or ball_index = 127 or ball_index = 143 or ball_index = 159 
                            or ball_index = 175 or ball_index = 191 or ball_index = 207 or ball_index = 223) then
                                ball := 1;
                                ball_index := ball_index - 17;
                                state := load;
                            elsif (not(ball_index > 15 and ball_index < 32)) then
                                ball_index := ball_index - 15;
                                state := load;
                            elsif(ball_index - 15 = p1_index - 1) then
                                ball := -3;
                                ball_index := ball_index + 15;
                                state := load;
                            elsif(ball_index - 15 = p1_index) then
                                ball := -2;
                                ball_index := ball_index + 16;
                                state := load;
                            elsif(ball_index - 15 = p1_index + 1) then
                                case p1_index is
                                    when 14 => 
                                        ball := -3;
                                        ball_index := ball_index + 15;
                                    when others =>
                                        ball := -1;
                                        ball_index := ball_index + 17;
                                end case;
                                state := load;
                            else  
                                state := start;
                            end if;

                        when -1 => 
                            if(ball_index = 31 or ball_index = 47 or ball_index = 63 or ball_index = 79 or ball_index = 95 
                            or ball_index = 111 or ball_index = 127 or ball_index = 143 or ball_index = 159 or ball_index = 175 
                            or ball_index = 191 or ball_index = 207 or (ball_index = 223 and p2_index /= 238)) then
                                ball := -3;
                                ball_index := ball_index + 15;
                                state := load;
                            elsif (not(ball_index > 207 and ball_index < 224)) then
                                ball_index := ball_index + 17;
                                state := load;
                            elsif(ball_index + 17 = p2_index - 1) then
                                ball := 1;
                                ball_index := ball_index - 17;
                                state := load;
                            elsif(ball_index + 17 = p2_index) then
                                ball := 2;
                                ball_index := ball_index - 16;
                                state := load;
                            elsif(ball_index + 17 = p2_index + 1) then
                                case p2_index is
                                    when 238 => 
                                        ball := 1;
                                        ball_index := ball_index - 17;
                                    when others =>
                                        ball := 3;
                                        ball_index := ball_index - 15;
                                end case;
                                state := load;
                            else  
                                state := start;
                            end if;

                        when -2 =>
                            if (not(ball_index > 207 and ball_index < 224)) then
                                ball_index := ball_index + 16;
                                state := load;
                            elsif(ball_index + 16 = p2_index - 1) then
                                case p2_index is
                                    when 225 => 
                                        ball := 3;
                                        ball_index := ball_index - 15;
                                    when others =>
                                        ball := 1;
                                        ball_index := ball_index - 17;
                                end case;
                                state := load;
                            elsif(ball_index + 16 = p2_index) then
                                ball := 2;
                                ball_index := ball_index - 16;
                                state := load;
                            elsif(ball_index + 16 = p2_index + 1) then
                                case p2_index is
                                    when 238 => 
                                        ball := 1;
                                        ball_index := ball_index - 17;
                                    when others =>
                                        ball := 3;
                                        ball_index := ball_index - 15;
                                end case;
                                state := load;
                            else  
                                state := start;
                            end if;

                        when -3 =>
                            if(ball_index= 16 or ball_index = 32 or ball_index = 48 or ball_index = 64 or ball_index = 80 
                            or ball_index = 96 or ball_index = 112 or ball_index = 128 or ball_index = 144 or ball_index = 160 
                            or ball_index = 176 or ball_index = 192 or ball_index = 208 or ball_index = 224) then
                                ball := -1;
                                ball_index := ball_index + 17;
                                state := load;
                            elsif (not(ball_index > 207 and ball_index < 224)) then
                                ball_index := ball_index + 15;
                                state := load;
                            elsif(ball_index + 15 = p2_index - 1) then
                                case p2_index is
                                    when 225 => 
                                        ball := 3;
                                        ball_index := ball_index - 15;
                                    when others =>
                                        ball := 1;
                                        ball_index := ball_index - 17;
                                end case;
                                state := load;
                            elsif(ball_index + 15 = p2_index) then
                                ball := 2;
                                ball_index := ball_index - 16;
                                state := load;
                            elsif(ball_index + 15 = p2_index + 1) then
                                ball := 3;
                                ball_index := ball_index - 15;
                                state := load;
                            else  
                                state := start;
                            end if;

                        when others => null;
                    end case;
				end if;
			
                when start =>
                    ball := 1;
                    ball_index := 119;
                    p1_index := 7;
                    p2_index := 231;
                    state := load;

                    for i in 0 to 255 loop
                        if (i = 6 or i = 7 or i = 8 or i = 119 or i = 230 or i = 231 or i = 232) then
                            LED(i) := x"FFFF00";
                        elsif (i = 112 or i = 114 or i = 116 or i = 118 or i = 120 or i = 122 or i = 124 or i = 126) then
                            LED(i) := x"FFFFFF";
                        else
                        LED(i) := x"000000";
                        end if;
                    end loop;
                when others => null;
		end case;
        LED(ball_index) := x"FFFF00";
	end process;
end arch;

-- Quando entrar no estado start (= fazer um ponto) mostrar a pontuação dos dois jogadores
-- Criar a tela de start e game over
