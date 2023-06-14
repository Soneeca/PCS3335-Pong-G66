library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity musica is
  generic (
    S : natural := 113637;
    T : natural := 12500000;
    M : natural := 16;
    Z : natural := 32
  );
  port (
    ligar : in  std_logic;
    escolher : in  std_logic;
    clock_in : in  std_logic;
	 medida : out std_logic;
    clock_out : out std_logic
  );
end entity musica;

architecture Behavioral of musica is
  signal counterS : natural range 0 to S-1 := 0;
  signal counterT : natural range 0 to T-1 := 0; 
  signal counterM : natural range 0 to M-1 := 0;
  signal counterZ : natural range 0 to Z-1 := 0; 
  signal clockT : std_logic := '0';
  signal clockS : std_logic := '0';
  signal escolherP : std_logic := '0';
  signal escolherA : std_logic := '1';
  type tipo_estadoZ is (n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28, n29, n30, n31, n32, x);
  type tipo_estadoM is (n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, x);
  signal estadoZ : tipo_estadoZ := n1;
  signal estadoM : tipo_estadoM := n1;
begin


  process(clock_in, ligar, escolher)
  begin
    if (ligar = '1') then
	 
		if rising_edge(clock_in) then

			if ((escolher xor escolherP) = '1') then
            counterZ <= 0;
            counterM <= 0;
				estadoZ <= x;
				estadoM <= x;
			end if;
			
			
				if counterT = T-1 then
					counterT <= 0;
					clockT <= not clockT;
					if clockT = '1' then
						if counterZ = Z-1 then
							counterZ <= 0;
						elsif counterM = M-1 then
							counterM <= 0;
						elsif (escolher = '0') then
							counterZ <= counterZ + 1;
						elsif (escolher = '1') then
							counterM <= counterM + 1;
						end if;
					end if;
				else
					counterT <= counterT + 1;
				end if;
				
				
				if counterS = S-1 then
					counterS <= 0;
					clockS <= not clockS;
				else
					counterS <= counterS + 1;
				end if;

        if (escolher = '0') then
            case estadoZ is
                when n1 =>  


                                if counterS = 15943 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;

                            if counterZ = 1 then
                            counterS <= 0;
                            estadoZ <= n2;
                            else 
                            estadoZ <= n1;
                            end if;

                when n2 =>  
                
                                if counterS = 31887 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 2 then
                            counterS <= 0;
                            estadoZ <= n3;
                            else 
                            estadoZ <= n2;
                            end if;

                when n3 =>  
                
                                if counterS = 23877 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                            
                            if counterZ = 3 then 
                            counterS <= 0;
                            estadoZ <= n4;
                            else 
                            estadoZ <= n3;
                            end if;

                when n4 =>  
                
                                if counterS = 18953 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 4 then 
                            counterS <= 0;
                            estadoZ <= n5;
                            else 
                            estadoZ <= n4;
                            end if;

                when n5 =>  
                
                                if counterS = 20079 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;

                
                            if counterZ = 5 then 
                            counterS <= 0;
                            estadoZ <= n6;
                            else 
                            estadoZ <= n5;
                            end if;

                when n6 =>  
                
                                if counterS = 31887 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 6 then 
                            counterS <= 0;
                            estadoZ <= n7;
                            else 
                            estadoZ <= n6;
                            end if;

                when n7 =>  
                
             
                                if counterS = 12657 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;

                
                            if counterZ = 7 then 
                            counterS <= 0;
                            estadoZ <= n8;
                            else 
                            estadoZ <= n7;
                            end if;

                when n8 =>  
              
                                if counterS = 25303 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 8 then 
                            counterS <= 0;
                            estadoZ <= n9;
                            else 
                            estadoZ <= n8;
                            end if;

                when n9 =>  
                
                                if counterS = 14204 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 9 then 
                            counterS <= 0;
                            estadoZ <= n10;
                            else 
                            estadoZ <= n9;
                            end if;

                when n10 => 
                
                                if counterS = 23877 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 10 then 
                            counterS <= 0;
                            estadoZ <= n11;
                            else 
                            estadoZ <= n10;
                            end if;

                when n11 => 
                
                                if counterS = 18953 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 11 then 
                            counterS <= 0;
                            estadoZ <= n12;
                            else 
                            estadoZ <= n11;
                            end if;

                when n12 => 
                
                                if counterS = 14204 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 12 then 
                            counterS <= 0;
                            estadoZ <= n13;
                            else 
                            estadoZ <= n12;
                            end if;

                when n13 => 
                
                                if counterS = 15943 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 13 then 
                            counterS <= 0;
                            estadoZ <= n14;
                            else 
                            estadoZ <= n13;
                            end if;

                when n14 => 
                
                                if counterS = 23877 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 14 then 
                            counterS <= 0;
                            estadoZ <= n15;
                            else 
                            estadoZ <= n14;
                            end if;

                when n15 => 
                
                                if counterS = 21276 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 15 then 
                            counterS <= 0;
                            estadoZ <= n16;
                            else 
                            estadoZ <= n15;
                            end if;

                when n16 => 
                
                                if counterS = 18953 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 16 then 
                            counterS <= 0;
                            estadoZ <= n17;
                            else 
                            estadoZ <= n16;
                            end if;

                when n17 => 
                
                                if counterS = 14204 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 17 then 
                            counterS <= 0;
                            estadoZ <= n18;
                            else 
                            estadoZ <= n17;
                            end if;

                when n18 => 
                
                                if counterS = 23877 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 18 then 
                            counterS <= 0;
                            estadoZ <= n19;
                            else 
                            estadoZ <= n18;
                            end if;

                when n19 => 
                
                                if counterS = 17894 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 19 then 
                            counterS <= 0;
                            estadoZ <= n20;
                            else 
                            estadoZ <= n19;
                            end if;

                when n20 => 
                
                                if counterS = 14204 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 20 then 
                            counterS <= 0;
                            estadoZ <= n21;
                            else 
                            estadoZ <= n20;
                            end if;

                when n21 => 
                
                                if counterS = 15050 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 21 then 
                            counterS <= 0;
                            estadoZ <= n22;
                            else 
                            estadoZ <= n21;
                            end if;

                when n22 => 
                
                                if counterS = 23877 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 22 then 
                            counterS <= 0;
                            estadoZ <= n23;
                            else 
                            estadoZ <= n22;
                            end if;

                when n23 => 
                
                                if counterS = 21276 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 23 then 
                            counterS <= 0;
                            estadoZ <= n24;
                            else 
                            estadoZ <= n23;
                            end if;

                when n24 => 
                
                                if counterS = 17894 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 24 then 
                            counterS <= 0;
                            estadoZ <= n25;
                            else 
                            estadoZ <= n24;
                            end if;

                when n25 => 
                
                                if counterS = 18953 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 25 then 
                            counterS <= 0;
                            estadoZ <= n26;
                            else 
                            estadoZ <= n25;
                            end if;

                when n26 => 
                
                                if counterS = 31887 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 26 then 
                            counterS <= 0;
                            estadoZ <= n27;
                            else estadoZ <= n26;
                            end if;

                when n27 => 
                
                                if counterS = 23877 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 27 then 
                            counterS <= 0;
                            estadoZ <= n28;
                            else 
                            estadoZ <= n27;
                            end if;

                when n28 => 
                
                                if counterS = 18953 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 28 then 
                            counterS <= 0;
                            estadoZ <= n29;
                            else 
                            estadoZ <= n28;
                            end if;

                when n29 => 
                
                                if counterS = 21276 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 29 then 
                            counterS <= 0;
                            estadoZ <= n30;
                            else 
                            estadoZ <= n29;
                            end if;

                when n30 => 
                
                                if counterS = 28408 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 30 then 
                            counterS <= 0;
                            estadoZ <= n31;
                            else 
                            estadoZ <= n30;
                            end if;

                when n31 => 
                
                                if counterS = 25303 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 31 then 
                            counterS <= 0;
                            estadoZ <= n32;
                            else 
                            estadoZ <= n31;
                            end if;

                when n32 => 
                
                                if counterS = 21276 then
                                    counterS <= 0;
                                    clockS <= not clockS;
                                end if;
                
                            if counterZ = 0 then 
                            counterS <= 0;
                            estadoZ <= n1;
                            else 
                            estadoZ <= n32;
                            end if;
                when others => 
                clockS <= '0';
                counterS <= 0;
                estadoZ <= n1;
            end case;
        elsif (escolher = '1') then
            case estadoM is

                when n1 =>  

                    if counterS = 113636 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 1 then
                counterS <= 0;
                estadoM <= n2;
                else 
                estadoM <= n1;
                end if;

                when n2 =>  

                    if counterS = 90253 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 2 then
                counterS <= 0;
                estadoM <= n3;
                else 
                estadoM <= n2;
                end if;

                when n3 =>  

                    if counterS = 56817 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 3 then
                counterS <= 0;
                estadoM <= n4;
                else 
                estadoM <= n3;
                end if;

                when n4 =>  

                    if counterS = 50606 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 4 then
                counterS <= 0;
                estadoM <= n5;
                else 
                estadoM <= n4;
                end if;

                when n5 =>  

                    if counterS = 45125 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 5 then
                counterS <= 0;
                estadoM <= n6;
                else 
                estadoM <= n5;
                end if;

                when n6 =>  

                    if counterS = 50606 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 6 then
                counterS <= 0;
                estadoM <= n7;
                else 
                estadoM <= n6;
                end if;

                when n7 =>  

                    if counterS = 56817 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 7 then
                counterS <= 0;
                estadoM <= n8;
                else 
                estadoM <= n7;
                end if;

                when n8 =>  

                    if counterS = 75757 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 8 then
                counterS <= 0;
                estadoM <= n9;
                else 
                estadoM <= n8;
                end if;

                when n9 =>  

                    if counterS = 85033 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 9 then
                counterS <= 0;
                estadoM <= n10;
                else 
                estadoM <= n9;
                end if;

                when n10 =>  

                    if counterS = 67567 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 10 then
                counterS <= 0;
                estadoM <= n11;
                else 
                estadoM <= n10;
                end if;

                when n11 =>  

                    if counterS = 45125 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 11 then
                counterS <= 0;
                estadoM <= n12;
                else 
                estadoM <= n11;
                end if;

                when n12 =>  

                    if counterS = 37935 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 12 then
                counterS <= 0;
                estadoM <= n13;
                else 
                estadoM <= n12;
                end if;

                when n13 =>  

                    if counterS = 45125 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if counterM = 13 then
                counterS <= 0;
                estadoM <= n14;
                else 
                estadoM <= n13;
                end if;

                when n14 =>  

                    if counterS = 56817 then
                        counterS <= 0;
                        clockS <= not clockS;
                    end if;

                if (counterM = 0) then
                counterS <= 0;
                counterM <= 0;
                estadoM <= n1;
                else 
                estadoM <= n14;
                end if;
                

                when others => 
                estadoM <= n1; 
            end case;
        end if;
		escolherP <= escolher;
	 end if;
	 
    elsif (ligar = '0') then
        clockS <= '0';
        counterS <= 0;
		counterT <= 0;
		clockT <= '0';
        counterZ <= 0;
        counterM <= 0;
		  
    end if;
  end process;

  clock_out <= clockS; 
  medida <= clockT;

end architecture Behavioral;
