-------------------------------------------------------------------------------
--
--   FileName:         i2c_master.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 64-bit Version 13.1 Build 162 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 11/01/2012 Scott Larson
--     Initial Public Release
--   Version 2.0 06/20/2014 Scott Larson
--     Added ability to interface with different slaves in the same transaction
--     Corrected ack_error bug where ack_error went 'Z' instead of '1' on error
--     Corrected timing of when ack_error signal clears
--   Version 2.1 10/21/2014 Scott Larson
--     Replaced gated clock with clock enable
--     Adjusted timing of SCL during start and stop conditions
--   Version 2.2 02/05/2015 Scott Larson
--     Corrected small SDA glitch introduced in version 2.1
-- 
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master is
  GENERIC(
    input_clk : INTEGER := 50000000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 400000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    finish    : out std_logic; 
    data_rd   : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC
	 );
end entity i2c_master;

ARCHITECTURE logic OF i2c_master IS
  CONSTANT divider  :  INTEGER := (input_clk/bus_clk)/4; --number of clocks in 1/4 cycle of scl
  TYPE machine IS(ready, start, command, slv_ack1, wr, rd, slv_ack2, mstr_ack, stop); --needed states
  SIGNAL state         : machine;                        --state machine
  SIGNAL data_clk      : STD_LOGIC;                      --data clock for sda
  SIGNAL data_clk_prev : STD_LOGIC;                      --data clock during previous system clock
  SIGNAL scl_clk       : STD_LOGIC;                      --constantly running internal scl
  SIGNAL scl_ena       : STD_LOGIC := '0';               --enables internal scl to output
  SIGNAL sda_int       : STD_LOGIC := '1';               --internal sda
  SIGNAL sda_ena_n     : STD_LOGIC;                      --enables internal sda to output
  SIGNAL addr_rw       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --latched in address and read/write
  SIGNAL data_tx       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --latched in data to write to slave
  SIGNAL data_rx       : STD_LOGIC_VECTOR(15 DOWNTO 0);   --data received from slave
  SIGNAL bit_cnt       : INTEGER RANGE 0 TO 16 := 7;      --tracks bit number in transaction
  SIGNAL stretch       : STD_LOGIC := '0';               --identifies if slave is stretching scl
BEGIN
  
  --generate the timing for the bus clock (scl_clk) and the data clock (data_clk)
  PROCESS(clk, reset_n)
    VARIABLE count  :  INTEGER RANGE 0 TO divider*4;  --timing for clock generation
  BEGIN
    IF(reset_n = '0') THEN                --reset asserted
      stretch <= '0';
      count := 0;
    ELSIF(clk'EVENT AND clk = '1') THEN
      data_clk_prev <= data_clk;          --store previous value of data clock
      IF(count = divider*4-1) THEN        --end of timing cycle
        count := 0;                       --reset timer
      ELSIF(stretch = '0') THEN           --clock stretching from slave not detected
        count := count + 1;               --continue clock generation timing
      END IF;
      CASE count IS
        WHEN 0 TO divider-1 =>            --first 1/4 cycle of clocking
          scl_clk <= '0';
          data_clk <= '0';
        WHEN divider TO divider*2-1 =>    --second 1/4 cycle of clocking
          scl_clk <= '0';
          data_clk <= '1';
        WHEN divider*2 TO divider*3-1 =>  --third 1/4 cycle of clocking
          scl_clk <= '1';                 --release scl
          IF(scl = '0') THEN              --detect if slave is stretching clock
            stretch <= '1';
          ELSE
            stretch <= '0';
          END IF;
          data_clk <= '1';
        WHEN OTHERS =>                    --last 1/4 cycle of clocking
          scl_clk <= '1';
          data_clk <= '0';
      END CASE;
    END IF;
  END PROCESS;

  --state machine and writing to sda during scl low (data_clk rising edge)
  PROCESS(clk, reset_n)
  BEGIN
    IF(reset_n = '0') THEN                 --reset asserted
      state <= ready;                      --return to initial state
      busy <= '1';                         --indicate not available
      scl_ena <= '0';                      --sets scl high impedance
      sda_int <= '1';                      --sets sda high impedance
      ack_error <= '0';                    --clear acknowledge error flag
      bit_cnt <= 7;                        --restarts data bit counter
      finish <= '0';
      data_rd <= "0000000000000000";      --clear data read port
    ELSIF(clk'EVENT AND clk = '1') THEN
      IF(data_clk = '1' AND data_clk_prev = '0') THEN  --data clock rising edge
        CASE state IS
          WHEN ready =>                      --idle state
          finish <= '0';
            IF(ena = '1') THEN               --transaction requested
              busy <= '1';                   --flag busy
              addr_rw <= addr & rw;          --collect requested slave address and command
              data_tx <= data_wr;            --collect requested data to write
              state <= start;                --go to start bit
				  bit_cnt <= 7;
            ELSE                             --remain idle
              busy <= '0';                   --unflag busy
              state <= ready;                --remain idle
            END IF;
          WHEN start =>                      --start bit of transaction
          finish <= '0';
			   bit_cnt <= 7;
			   addr_rw <= addr & rw;            --collect requested slave address and command
            data_tx <= data_wr;              --collect requested data to write
            busy <= '1';                     --resume busy if continuous mode
            sda_int <= addr_rw(bit_cnt);     --set first address bit to bus
            state <= command;                --go to command
          WHEN command =>                    --address and command byte of transaction
          finish <= '0';
            IF(bit_cnt = 0) THEN             --command transmit finished
              sda_int <= '1';                --release sda for slave acknowledge
              bit_cnt <= 7;                  --reset bit counter for "byte" states
              state <= slv_ack1;             --go to slave acknowledge (command)
            ELSE                             --next clock cycle of command state
              bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
              sda_int <= addr_rw(bit_cnt-1); --write address/command bit to bus
              state <= command;              --continue with command
            END IF;
          WHEN slv_ack1 =>                   --slave acknowledge bit (command)
          finish <= '0';
            IF(addr_rw(0) = '0') THEN        --write command
              sda_int <= data_tx(bit_cnt);   --write first bit of data
              state <= wr;                   --go to write byte
            ELSE                             --read command
              sda_int <= '1';                --release sda from incoming data
              state <= rd;                   --go to read byte
				  bit_cnt <= 15;
            END IF;
          WHEN wr =>                         --write byte of transaction
          finish <= '0';
            busy <= '1';                     --resume busy if continuous mode
            IF(bit_cnt = 0) THEN             --write byte transmit finished
              sda_int <= '1';                --release sda for slave acknowledge
              bit_cnt <= 7;                  --reset bit counter for "byte" states
              finish <= '1';
              state <= slv_ack2;             --go to slave acknowledge (write)
            ELSE                             --next clock cycle of write state
              bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
              sda_int <= data_tx(bit_cnt-1); --write next bit to bus
              state <= wr;                   --continue writing
            END IF;
          WHEN rd =>                         --read byte of transaction
          finish <= '0';
            busy <= '1';                     --resume busy if continuous mode
            IF(bit_cnt = 0) THEN             --read byte receive finished
              IF(ena = '1' AND addr_rw = addr & rw) THEN  --continuing with another read at same address
                sda_int <= '0';              --acknowledge the byte has been received
              ELSE                           --stopping or continuing with a write
                sda_int <= '1';              --send a no-acknowledge (before stop or repeated start)
              END IF;
              --bit_cnt <= 15;                  --reset bit counter for "byte" states
              finish <= '1';
              data_rd <= data_rx;            --output received data
              state <= mstr_ack;             --go to master acknowledge
            ELSE                             --next clock cycle of read state
              bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
              state <= rd;                   --continue reading
            END IF;
          WHEN slv_ack2 =>                   --slave acknowledge bit (write)
          finish <= '1';
            IF(ena = '1') THEN               --continue transaction
              busy <= '0';                   --continue is accepted
              addr_rw <= addr & rw;          --collect requested slave address and command
              data_tx <= data_wr;            --collect requested data to write
              IF(addr_rw = addr & rw) THEN   --continue transaction with another write
                sda_int <= data_wr(bit_cnt); --write first bit of data
                state <= wr;                 --go to write byte
                bit_cnt <= 7;   
				  ELSE                           --continue transaction with a read or new slave
                state <= start;              --go to repeated start
              END IF;
            ELSE                             --complete transaction
              state <= stop;                 --go to stop bit
            END IF;
          WHEN mstr_ack =>                   --master acknowledge bit after a read
            IF(ena = '1') THEN               --continue transaction
            finish <= '1';
              busy <= '0';                   --continue is accepted and data received is available on bus
              addr_rw <= addr & rw;          --collect requested slave address and command
              data_tx <= data_wr;            --collect requested data to write
              IF(addr_rw = addr & rw) THEN   --continue transaction with another read
               sda_int <= '1';              --release sda from incoming data
               state <= rd;                 --go to read byte
              ELSE                           --continue transaction with a write or new slave
               state <= start;              --repeated start
              END IF;    
            ELSE                             --complete transaction
              state <= stop;                 --go to stop bit
            END IF;
          WHEN stop =>                       --stop bit of transaction
          finish <= '0';
			   bit_cnt <= 7;
            busy <= '0';                     --unflag busy
            state <= ready;                  --go to idle state
        END CASE;    
		  
      ELSIF(data_clk = '0' AND data_clk_prev = '1') THEN  --data clock falling edge
        CASE state IS
          WHEN start =>                  
            IF(scl_ena = '0') THEN                  --starting new transaction
              scl_ena <= '1';                       --enable scl output
              ack_error <= '0';                     --reset acknowledge error output
            END IF;
          WHEN slv_ack1 =>                          --receiving slave acknowledge (command)
            IF(sda /= '0' OR ack_error = '1') THEN  --no-acknowledge or previous no-acknowledge
              ack_error <= '1';                     --set error output if no-acknowledge
            END IF;
          WHEN rd =>                                --receiving slave data
            data_rx(bit_cnt) <= sda;                --receive current slave data bit
          WHEN slv_ack2 =>                          --receiving slave acknowledge (write)
            IF(sda /= '0' OR ack_error = '1') THEN  --no-acknowledge or previous no-acknowledge
              ack_error <= '1';                     --set error output if no-acknowledge
            END IF;
          WHEN stop =>
            scl_ena <= '0';                         --disable scl
          WHEN OTHERS =>
            NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS;  

  --set sda output
  WITH state SELECT
    sda_ena_n <= data_clk_prev WHEN start,     --generate start condition
                 NOT data_clk_prev WHEN stop,  --generate stop condition
                 sda_int WHEN OTHERS;          --set to internal sda signal    
      
  --set scl and sda outputs
  scl <= '0' WHEN (scl_ena = '1' AND scl_clk = '0') ELSE 'Z';
  sda <= '0' WHEN sda_ena_n = '0' ELSE 'Z';
  
END logic;








LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY Controle IS
  PORT(
    clk_in       : IN     STD_LOGIC;
    reset_in   : IN     STD_LOGIC;
    en      : IN     STD_LOGIC;
	 posicao1: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
	 posicao2: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
	 mandarps: IN     STD_LOGIC;
	 tst1    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	 sd      : INOUT STD_LOGIC;
	 sc      : INOUT STD_LOGIC;
	 tst2    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	 );
END ENTITY Controle;

ARCHITECTURE arch OF Controle IS

	SIGNAL bsy      : STD_LOGIC;
	SIGNAL dado   	 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL fim      : STD_LOGIC;
	SIGNAL d1   	 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL d2   	 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL ps1		 : STD_LOGIC_VECTOR(3 DOWNTO 0):= "0111";
	SIGNAL ps2		 : STD_LOGIC_VECTOR(3 DOWNTO 0):= "0111";
	SIGNAL p1   	 : STD_LOGIC_VECTOR(3 DOWNTO 0):= "0111";
	SIGNAL p2   	 : STD_LOGIC_VECTOR(3 DOWNTO 0):= "0111";
	SIGNAL counterp : natural range 0 to 399 := 0;
	SIGNAL dir1     : STD_LOGIC_VECTOR(1 DOWNTO 0):= "00";
	SIGNAL dir2     : STD_LOGIC_VECTOR(1 DOWNTO 0):= "00";
	SIGNAL adr      : STD_LOGIC_VECTOR(6 DOWNTO 0);

	COMPONENT i2c_master IS
		GENERIC (
			input_clk : INTEGER := 50000000;
			bus_clk : INTEGER := 400000); 
		PORT (
			clk : IN STD_LOGIC;
			reset_n : IN STD_LOGIC;
			ena : IN STD_LOGIC;
			addr : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
			rw : IN STD_LOGIC;
			data_wr : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			busy : OUT STD_LOGIC;
			finish : OUT std_logic;
			data_rd : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			ack_error : BUFFER STD_LOGIC;
			sda : INOUT STD_LOGIC;
			scl : INOUT STD_LOGIC
			);
	END COMPONENT;
	
BEGIN

		i2c : i2c_master
		GENERIC MAP(
		input_clk => 50000000,
		bus_clk => 400000)
		PORT MAP(
			clk => clk_in, 
			reset_n => reset_in, 
			ena => en, 
			addr => adr, 
			rw => '1', 
			data_wr => "00000000", 
			busy => bsy, 
			finish => fim,
			data_rd => dado, 
			ack_error => open, 
			sda => sd, 
			scl => sc
		);
		
		process(sc, en, adr, reset_in)
		begin
		if rising_edge(sc) then
			if (en = '1' and reset_in = '1') then 
				counterP <= counterP+1;
				if (counterP < 100) then
					adr <= "1001000";
				elsif (counterP < 200) then
					d1 <= dado;
				elsif (counterP < 300) then
					adr <= "1001001";
				elsif (counterP < 390) then
					d2 <= dado;
					counterP <= 0;
				elsif (counterP > 390) then
					counterP <= 0;
				end if;
			end if;
		end if;
		end process;

		process(sc, d1, d2)
		begin
		
		p1 <= d1(15 downto 12);
		p2 <= d2(15 downto 12);
		
		if (p1 = "0000") then
			p1 <= "0001";
		elsif (p1 = "1111") then
			p2 <= "1110";
		end if;
		
		if (p2 = "0000") then
			p2 <= "0001";
		elsif (p2 = "1111") then
			p2 <= "1110";
		end if;
		
		if (p1 > ps1) then
			dir1 <= "11";
		elsif (p1 < ps1) then
			dir1 <= "01";
		elsif (p1 = ps1) then
			dir1 <= "00";
		end if;
		
		if (p2 > ps2) then
			dir2 <= "11";
		elsif (p2 < ps2) then
			dir2 <= "01";
		elsif (p2 = ps2) then
			dir2 <= "00";
		end if;
		
		if rising_edge(sc) then
			if (dir1 = "11") then
				ps1 <= (ps1 + "0001");
				posicao1 <= ps1;
			elsif (dir1 = "01") then
				ps1 <= (ps1 - "0001");
				posicao1 <= ps1;
			else
				posicao1 <= ps1;
			end if;
			
			if (dir2 = "11") then
				ps2 <= (ps2 + "0001");
				posicao2 <= ps2;
			elsif (dir2 = "01") then
				ps2 <= (ps2 - "0001");
				posicao2 <= ps2;
			else
				posicao2 <= ps2;
			end if;
		end if;
		end process;
		
		process(clk_in, ps1)
		begin
			if ps1 = "1111" then
				tst1 <= not"0000110";
				tst2 <= not"1101101";
			elsif ps1 = "0000" then
				tst1 <= not"0111111";
				tst2 <= not"0111111";
			elsif ps1 = "0001" then
				tst1 <= not"0111111";
				tst2 <= not"0000110";
			elsif ps1 = "0010" then
				tst1 <= not"0111111";
				tst2 <= not"1011011";
			elsif ps1 = "0011" then
				tst1 <= not"0111111";
				tst2 <= not"1001111";
			elsif ps1 = "0100" then
				tst1 <= not"0111111";
				tst2 <= not"1100110";
			elsif ps1 = "0101" then
				tst1 <= not"0111111";
				tst2 <= not"1101101";
			elsif ps1 = "0110" then
				tst1 <= not"0111111";
				tst2 <= not"1111101";
			elsif ps1 = "0111" then
				tst1 <= not"0111111";
				tst2 <= not"0000111";
			elsif ps1 = "1000" then
				tst1 <= not"0111111";
				tst2 <= not"1111111";
			elsif ps1 = "1001" then
				tst1 <= not"0111111";
				tst2 <= not"1101111";
			elsif ps1 = "1010" then
				tst1 <= not"0111111";
				tst2 <= not"1101101";
			elsif ps1 = "1011" then
				tst1 <= not"0000110";
				tst2 <= not"0000110";
			elsif ps1 = "1100" then
				tst1 <= not"0000110";
				tst2 <= not"1011011";
			elsif ps1 = "1101" then
				tst1 <= not"0000110";
				tst2 <= not"1001111";
			elsif ps1 = "1110" then
				tst1 <= not"0000110";
				tst2 <= not"1100110";
			end if;
		end process;
END arch;