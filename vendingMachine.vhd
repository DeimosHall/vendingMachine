library ieee;
use ieee.std_logic_1164.all;

entity vendingMachine is

	port (clk, reset, enter, key: in std_logic;
			input: in std_logic_vector(3 downto 0);
			Q: out std_logic_vector(2 downto 0) := "000";
			display1: out std_logic_vector(6 downto 0);
			display2: out std_logic_vector(6 downto 0));

end vendingMachine;

architecture behavioral of vendingMachine is

	type status is (Start, Digit1, Digit2, Delivery, Error);
	signal currentStatus: status := Start;
--	signal nextStatus: status;
	
	-- Deboucing filter variables
	signal previousReset, resetOK: std_logic := '0';
	signal previousEnter, enterOK: std_logic := '0';
	signal previousKey, keyOK: std_logic := '0';
	
	signal statusCLK: std_logic := '0';
	signal number1, number2: std_logic_vector(3 downto 0);

begin
	
	-- Deboucing filters
	resetFilter: process(clk, reset)
		variable bouncingCounter: integer range 0 to 4000000 := 0;
	begin
		if(clk'event and clk = '1') then
			if(bouncingCounter < 4000000) then
				bouncingCounter := bouncingCounter + 1;
			else
				bouncingCounter := 0;
				if(previousReset = reset) then
					resetOK <= reset;
				end if;
				previousReset <= reset;
			end if;
		end if;
	end process;
	
	enterFilter: process(clk, reset)
		variable bouncingCounter: integer range 0 to 4000000 := 0;
	begin
		if(clk'event and clk = '1') then
			if(bouncingCounter < 4000000) then
				bouncingCounter := bouncingCounter + 1;
			else
				bouncingCounter := 0;
				if(previousEnter = enter) then
					enterOK <= enter;
				end if;
				previousEnter <= enter;
			end if;
		end if;
	end process;
	
	keyFilter: process(clk, reset)
		variable bouncingCounter: integer range 0 to 4000000 := 0;
	begin
		if(clk'event and clk = '1') then
			if(bouncingCounter < 4000000) then
				bouncingCounter := bouncingCounter + 1;
			else
				bouncingCounter := 0;
				if(previousKey = key) then
					keyOK <= key;
				end if;
				previousKey <= key;
			end if;
		end if;
	end process;
	
	statusCLK <= enterOK or keyOK;
	
	process(currentStatus, statusCLK, resetOK, enterOK, keyOK) begin
		if(resetOK = '1') then
			currentStatus <= Start;
		elsif(statusCLK'event and statusCLK = '1') then
			case currentStatus is
			
				when Start =>
					number1 <= "1010"; -- H
					number2 <= "1101"; -- I
					if(enterOK = '1') then
						currentStatus <= Error;
					elsif(keyOK = '1') then
						currentStatus <= Digit1;
					else
						currentStatus <= Start;
					end if;
					
				when Digit1 =>
					number1 <= "0000"; -- 0
					number2 <= input(3 downto 0);
					if(enterOK = '1') then
						currentStatus <= Error;
					elsif(keyOK = '1') then
						currentStatus <= Digit2;
					else
						currentStatus <= Digit1;
					end if;
					
				when Digit2 =>
					number1 <= number2;
					number2 <= input(3 downto 0);
					if(enterOK = '1') then
						currentStatus <= Error;
					elsif(keyOK = '1') then
						currentStatus <= Delivery;
					else
						currentStatus <= Digit2;
					end if;
					
				when Delivery =>
					number1 <= "1011"; -- C
					number2 <= "1011"; -- C
					if(keyOK = '1') then
						currentStatus <= Error;
					elsif(enterOK = '1') then
						currentStatus <= Start;
					else
						currentStatus <= Delivery;
					end if;
					
				when Error =>
					number1 <= "1100"; -- E
					number2 <= "1100"; -- E
					if(keyOK = '1') then
						currentStatus <= Error;
					elsif(enterOK = '1') then
						currentStatus <= Start;
					else
						currentStatus <= Error;
					end if;
					
			end case;
		end if;
	end process;
	
	with currentStatus select
		Q <=  "110" when Start,
				"001" when Digit1,
				"010" when Digit2,
				"011" when Delivery,
				"100" when Error,
				"000" when others;
	
	with number1 select
		display1 <=
			"0111111" when "0000", -- 0
			"0000110" when "0001", -- 1
			"1011011" when "0010", -- 2
			"1001111" when "0011", -- 3
			"1100110" when "0100", -- 4
			"1101101" when "0101", -- 5
			"1111101" when "0110", -- 6
			"0000111" when "0111", -- 7
			"1111111" when "1000", -- 8
			"1101111" when "1001", -- 9
			"0110111" when "1010", -- H
			"1001110" when "1011", -- C
			"1001111" when "1100", -- E
			"0110000" when "1101", -- I
			"0000000" when others;
					
	with number2 select
		display2 <=
			"0111111" when "0000", -- 0
			"0000110" when "0001", -- 1
			"1011011" when "0010", -- 2
			"1001111" when "0011", -- 3
			"1100110" when "0100", -- 4
			"1101101" when "0101", -- 5
			"1111101" when "0110", -- 6
			"0000111" when "0111", -- 7
			"1111111" when "1000", -- 8
			"1101111" when "1001", -- 9
			"0110111" when "1010", -- H
			"1001110" when "1011", -- C
			"1001111" when "1100", -- E
			"0110000" when "1101", -- I
			"0000000" when others;

end behavioral;