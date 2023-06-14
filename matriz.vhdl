library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity WS2812 is
	port (
		clk : in std_logic;
        data1 : in std_logic_vector(1 downto 0);
        data2 : in std_logic_vector(1 downto 0);
		serial : out std_logic
	);
end entity WS2812;

architecture arch of WS2812 is

	constant T0H : integer := 20; -- quantidade
	constant T0L : integer := 43; 
	constant T1H : integer := 40;
	constant T1L : integer := 23; 
	constant RES : integer := 50_000_000;
    
	
	type LED_matrix is array (0 to 255) of std_logic_vector(23 downto 0);
	type state_machine is (load, sending, send_bit, reset, player, ball, start, up_right, right, down_right, up_left, left, down_left);

begin
	process(clk)
		variable state : state_machine := load;
		variable GRB : std_logic_vector(23 downto 0) := x"000000";
		variable delay_high_counter : integer := 0;
		variable delay_low_counter : integer := 0;
		variable index : integer := 0;
		variable bit_counter : integer := 0;
        variable ball_desloc : integer range -3 to 3 := 1;  
        variable aux0, aux1 : integer := 0;
        variable ball_row : integer range 0 to 15 := 7; 
        variable ball_col : integer range 0 to 15 := 7;
    	variable p1_index : integer range 1 to 14 := 7; -- posição do jogador 1
    	variable p2_index : integer range 225 to 238 := 231; -- posição do jogador 2
		variable LED : LED_matrix := (
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"F000F0", x"F000F0", x"F000F0", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"F0F0F0", x"000000", x"F0F0F0", x"000000", x"F0F0F0", x"F0F000", x"F0F0F0", x"000000", x"F0F0F0", x"000000", x"F0F0F0", x"000000", x"F0F0F0", x"000000", x"F0F0F0",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"00F000", x"00F000", x"00F000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000",
        x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000", x"000000"
        );
	begin
		if rising_edge(clk) then

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
                        state := player;
                    end if;

                when player =>
                
                    case data1 is
                        when "01" => 
                            if (p1_index /= 14) then 
                                LED(p1_index - 1) := x"000000";
                                LED(p1_index + 2) := x"F000F0";
                                p1_index := p1_index + 1;
                            end if;
                        when "10" =>
                            if (p1_index /= 1) then 
                                LED(p1_index + 1) := x"000000";
                                LED(p1_index - 2) := x"F000F0";
                                p1_index := p1_index - 1;
                            end if;
                        when others => null;
                    end case;

                    case data2 is
                        when "01" =>
                            if (p2_index /= 238) then 
                                LED(p2_index - 1) := x"000000";
                                LED(p2_index + 2) := x"00F000";
                                p2_index := p2_index + 1;
                            end if;
                        when "10" =>
                            if (p2_index /= 225) then 
                                LED(p2_index + 1) := x"000000";
                                LED(p2_index - 2) := x"00F000";
                                p2_index := p2_index - 1;
                            end if;
                        when others => null;
                    end case;

                    aux0 := 16 * ball_col + (15 * (1 - ball_col mod 2) - ball_row * (1 - 2 * (ball_col mod 2)));
                    aux1 := 16 * ball_col + ball_row;
                
                    state := ball;

                when ball =>
                      
					LED(aux1 + 15 * (ball_col mod 2) - 2 * ball_row * (ball_col mod 2)) := x"000000";
                            
                    case ball_desloc is 
                        
                        when 1 =>
                            if ball_row = 15 and ball_col /= 14 then
                                state := up_right;

                            elsif ball_col /= 14 then 
                                state := down_right;

                            elsif aux1 + 17 = p2_index - 1 then  
                                state := up_left;

                            elsif aux1 + 17 = p2_index then
                                state := left;

                            elsif aux1 + 17 = p2_index + 1 then
                                case p2_index is
                                    when 238 => 
                                        state := up_left; 
                                    when others =>
                                        state := down_left;
                                end case;

                            else
                                state := start;
                            end if;


                        when 2 =>
                            if ball_col /= 14 then 
                                state := right;

                            elsif aux1 + 16 = p2_index - 1 then
                                case p2_index is
                                    when 225 => 
                                        state := down_left; 
                                    when others =>
                                        state := up_left;       
                                end case;
        
                            elsif aux1 + 16 = p2_index then
                                state := left;

                            elsif aux1 + 16 = p2_index + 1 then
                                case p2_index is
                                    when 238 => 
                                        state := up_left;
                                    when others =>
                                        state := down_left; 
                                    end case;
        
                            else
                                state := start;
                            end if;
                            
                        when 3 =>
                            if ball_row = 0 and ball_col /= 14 then
                                state := down_right;

                            elsif ball_col /= 14 then 
                                state := up_right;

                            elsif aux1 + 15 = p2_index - 1 then
                                 case p2_index is
                                    when 225 => 
                                        state := down_left; 
                                    when others =>
                                        state := up_left;
                                end case;
        
                            elsif aux1 + 15 = p2_index then
                                state := left;
        
                            elsif aux1 + 15 = p2_index + 1 then
                                state := down_left;
        
                            else
                                state := start;
                            end if;
                            

                        when -1 =>
                            if ball_row = 15 and ball_col /= 1 then
                                state := up_left;

                            elsif ball_col /= 1 then 
                                state := down_left;

                            elsif aux1 - 15 = p1_index - 1 then
                                state := up_right;

                            elsif aux1 - 15 = p1_index then
                                state := right;

                            elsif aux1 - 15 = p1_index + 1 then
                                case p1_index is
                                    when 14 => 
                                        state := up_right; 
                                    when others =>
                                        state := down_right;
                                end case;

                            else
                                state := start;
                            end if;

                        when -2 =>
                            if ball_col /= 1 then 
                                state := left;

                            elsif aux1 - 16 = p1_index - 1 then
                                case p1_index is
                                    when 1 => 
                                        state := down_right;
                                    when others =>
                                        state := up_right;
                                end case;

                            elsif aux1 - 16 = p1_index then
                                state := right;

                            elsif aux1 - 16 = p1_index + 1 then
                                case p1_index is
                                    when 14 => 
                                        state := up_right;
                                    when others =>
                                        state := down_right; 
                                end case;

                            else
                                state := start;
                            end if;
                        
                        when -3 =>
                            if ball_row = 0 and ball_col /= 1 then
                                state := down_left;

                            elsif ball_col /= 1 then 
                                state := up_left;
                                        
                            elsif aux1 - 17 = p1_index - 1 then
                                case p1_index is
                                    when 1 => 
                                        state := down_right; 
                                    when others =>
                                        state := up_right; 
                                end case;

                            elsif aux1 - 17 = p1_index then
                                state := right;

                            elsif aux1 - 17 = p1_index + 1 then
                                state := down_right;

                            else
                                state := start;
                            end if;

                        when others => null;
                    end case;
                    
                when up_right =>
                    ball_desloc := 3;
                    ball_col := ball_col + 1;
                    ball_row := ball_row - 1;
                    LED(aux0 + 15 + 2 * (ball_col mod 2)) := x"F0F000";
                    state := load;

                when right =>
                    ball_desloc := 2;
                    ball_col := ball_col + 1;
                    LED(aux0 + 16) := x"F0F000";
                    state := load;
                    
                when down_right =>
                    ball_desloc := 1;
                    ball_col := ball_col + 1;
                    ball_row := ball_row + 1;
                    LED(aux0 + 17 - 2 * (ball_col mod 2)) := x"F0F000";
                    state := load;
                    
                when up_left =>
                    ball_desloc := -3;
                    ball_col := ball_col - 1;
                    ball_row := ball_row - 1;
                    LED(aux0 + 15 + 2 * (ball_col mod 2)) := x"F0F000";
                    state := load;
                    
                when left =>
                    ball_desloc := -2;
                    ball_col := ball_col - 1;
                    LED(aux0 + 16) := x"F0F000";
                    state := load;
                    
                when down_left =>
                    ball_desloc := -1;
                    ball_col := ball_col - 1;
                    ball_row := ball_row + 1;
                    LED(aux0 + 17 - 2 * (ball_col mod 2)) := x"F0F000";
                    state := load;
                    

                when start =>
                    ball_desloc := 2;
                    ball_col := 7;
                    ball_row := 7;
                    p1_index := 7;
                    p2_index := 231;
                    state := load;

                    for i in 0 to 255 loop
                        if (i = 6 or i = 7 or i = 8) then
                            LED(i) := x"F000F0";
                        elsif (i = 230 or i = 231 or i = 232) then
                            LED(i) := x"00F000";
                        elsif (i = 119) then
                            LED(i) := x"F0F000";
                        elsif (i = 113 or i = 115 or i = 117 or i = 119 or i = 121 or i = 123 or i = 125 or i = 127) then
                            LED(i) := x"F0F0F0";
                        else
                            LED(i) := x"000000";
                        end if;
                    end loop;
                when others => null;
            end case;
            
        end if; 
	end process;
end arch;
