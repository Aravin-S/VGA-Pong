----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:22:37 11/22/2023 
-- Design Name: 
-- Module Name:    VGA - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
entity VGA is
	Port (
		clk 		: in STD_LOGIC;
		H 			: out std_logic;	-- H sync bit
		V 			: out std_logic;	-- V sync bit		
		DAC_CLK 	: out std_logic;	-- clk for digital to analog converter (freq. 25 MHz)

		SW0 	: in STD_LOGIC;	-- up player 1
		SW1 	: in STD_LOGIC;	-- down player 1
		SW2 	: in STD_LOGIC;	-- up player 2
		SW3 	: in STD_LOGIC;	-- down player 2
		
		Rout 		: out std_logic_vector (7 downto 0); -- RGB
		Gout 		: out std_logic_vector (7 downto 0);
		Bout 		: out std_logic_vector (7 downto 0));

end VGA;

architecture Behavioral of VGA is
	
	--vga
	signal H_ila, V_ila			: std_logic;			-- Hsync and Vsync
	signal xPos, yPos				: integer := 0;		-- horizontal and vertical position of drawn pixel
	signal trigger					: std_logic := '0';	-- trigger flag to capture Vsync change
	signal dac 						: std_logic := '0';	-- dac signal, same as dac_clk
	signal screenOn 				: std_logic := '0';	

	--ball
	signal ballOffsetX : integer := 367;		-- ball horizontal offset, default position is h = 367
	signal ballOffsetY : integer := 272;		-- ball vertical offset, default position is v = 272
	signal offsetX 		: integer := 367;		-- used to update ball horizontal postion
	signal offsetY 		: integer := 272;		-- used to update ball vertical position
	
	signal ballDirX 	: integer := 1;		-- current direction of ball, could be 1 or -1 dependin gon collision
	signal ballDirY 	: integer := 1;
	signal reset 		: std_logic := '0';	-- reset if ball goes out of bounds
	
	--paddle
	signal paddle1OffsetY 	: integer := 0;	-- paddle offset range is between -160 and 160
	signal paddle2OffsetY 	: integer := 0;
	signal offset1 				: integer := 0;	-- used to update paddle1 vertical position
	signal offset2 				: integer := 0;	-- used to update paddle2 vertical position
	signal delay 				: integer := 0;	-- used to wait clock cycles
	
	--ila
	signal control0 : std_logic_vector(35 downto 0);
	signal ila_data : std_logic_vector(63	downto 0);
	signal trig0 : std_logic_vector(0 to 0);

	component icon
		port (
			control0 : inout std_logic_vector(35 downto 0)
		);
	end component;
 
	component ila
		port (
			control : inout std_logic_vector(35 downto 0);
			clk : in std_logic;
			data : in std_logic_vector(63 downto 0);
			trig0 : in std_logic_vector(0 to 0)
		);
	end component;

begin

	sys_icon : icon
	port map(
		control0
	);
	sys_ila : ila
	port map(
		control0, 
      clk, 
      ila_data, 
      trig0
	);

	makeDacClk : process(clk)
	begin
			if(clk'event and clk = '1') then		-- if clock rising edge
				dac <= not dac;						-- toggle dac
				DAC_CLK <= not dac;					-- toggle DAC_CLK so DAC_CLK is double the period/half freq.
			end if;.
	end process;
	
	hSync : process (dac, xPos)
	begin
		if (dac'event and dac = '1') then		-- if dac rising edge
			if (xPos < 703) then						-- if x position less than 703 after active pixels during horizontal front porch
				H <= '1';								-- set Hsync
				H_ila <= '1';
			else											
				H <= '0';								-- else Hsync=0
				H_ila <= '0';
			end if;
		end if;
	end process;
	
	vSync : process (dac, yPos)
	begin
		if (dac'event and dac = '1') then		-- if dac rising edge
			if (yPos < 522) then						-- if y position less than 522 after active pixels during vertical front porch
				V_ila <= '1';							
				V <= '1';								-- set Vsync
			else											
				V_ila <= '0';
				V <= '0';								-- else Vsync=0
			end if;
			
			if (yPos > 520 AND xPos > 700) then	-- check if at the end of the screen bottom right
				trigger <= '1';						-- set trigger
			else
				trigger <= '0';						-- reset trigger
			end if;
		end if;
	end process;
	
	screen_on : process (dac)
	begin
		if (dac'event and dac = '1') then		-- if dac rising edge
			if ((xPos <= 687 and xPos > 47) and (yPos <= 512 and yPos > 32)) then	-- if x range between 47 and 687 and y range between 32 and 512
				screenOn <= '1';																		-- set screenOn to draw
			else																							-- 640x480p
				screenOn <= '0';																		-- else screen off
			end if;
		end if;
	end process;
	
	horizontalPosition : process (dac)
	begin
			if (dac'event and dac = '1') then	-- if dac rising edge
				if (xPos = 799) then					-- if at end of screen horizontally
					xPos <= 0;							-- go back to left side of screen
				else										
					xPos <= xPos + 1;					-- else increment by 1
				end if;
			end if;
	end process;
	
	verticalPosition : process (dac,xPos,yPos)
	begin
		if (dac'event and dac = '1') then		-- if dac rising edge
			if (xPos = 799) then						-- if at end of screen horizontally
				if (yPos = 524) then					-- check if vertical position also at the end (bottom of screen)
					yPos <= 0;							-- reset from botom of screen to top
				else
					yPos <= yPos + 1;					-- else increment vertical position by 1
				end if;
			end if;
		end if;
	end process;

	draw : process (dac)
	begin
		if (dac'event and dac = '1') then
			if (screenOn = '1') then
				if((xPos > 57 and xPos < 677) and ((yPos > 42 and yPos < 52) or (yPos > 492 and yPos < 502 ))) then -- upper and lower walls
					Rout <= "11111111";
					Bout <= "11111111";
					Gout <= "11111111";
				
				elsif (((xPos > 57 and xPos < 67) or (xPos < 677 and xPos > 667)) and
				((yPos > 51 and yPos < 150) or (yPos < 493 and yPos > 394))) then		-- walls on left and right side
					Rout <= "11111111";
					Bout <= "11111111";
					Gout <= "11111111";
				
				elsif ((xPos > 87 and xPos < 107) and (yPos > (paddle1OffsetY + 232) and
				yPos < (paddle1OffsetY + 312))) then			-- left paddle 1 with blue color
					Rout <= "00000000";
					Bout <= "11111111";
					Gout <= "00000000";

				elsif ((xPos > 627 and xPos < 647) and (yPos > (paddle2OffsetY + 232)
				and yPos < (paddle2OffsetY + 312))) then		-- right paddle 2 with pink
					Bout <= "10010011";
					Gout <= "00010100";
					Rout <= "11111111";
				
				-- ball
				elsif ((xPos < (ballOffsetX + 5) and xPos > (ballOffsetX - 5)) and (yPos
				< (ballOffsetY + 5) and yPos > (ballOffsetY - 5))) then
					if(ballOffsetX + 5 < 677 AND ballOffsetX - 5 > 57) then	-- if ball in bounds, yellow
						Bout <= "00000000";
						Gout <= "11111111";
						Rout <= "11111111";
					else										-- else ball turns red before going out of bounds
						Bout <= "00000000";
						Gout <= "00000000";
						Rout <= "11111111";
					end if;
					
				elsif ((xPos < (367+2) and xPos > (367 - 2))and ((yPos > 70 and yPos <
				90) or (yPos > 110 and yPos < 130) or (yPos > 150 and yPos < 170) or (yPos > 190 and yPos <
				210) or (yPos > 230 and yPos < 250) or (yPos > 270 and yPos < 290) or (yPos > 310 and yPos
				< 330) or (yPos > 350 and yPos < 370) or (yPos > 390 and yPos < 410) or (yPos > 430 and
				yPos < 450) or (yPos > 470 and yPos < 490))) then 	-- dashed black lines in center
					Bout <= "00000000";
					Gout <= "00000000";
					Rout <= "00000000";
				else								-- else green background
					Bout <= "00000000";
					Gout <= "11111111";
					Rout <= "00000000";
				end if;

			else									-- else screen off so display black
				Bout <= "00000000";
				Gout <= "00000000";
				Rout <= "00000000";
			end if;
		end if;
	end process;
	
	ball : process (clk,reset)
	begin
		if (clk'event and clk = '1') then
			if (delay < 500000) then
				delay <= delay + 1;
			else
				if (reset = '1') then
					offsetX <= 367;
					offsetY <= 272;
				else
					offsetX <= offsetX + ballDirX;
					ballOffsetX <= offsetX + ballDirX; -- move Ball xPosition
					offsetY <= offsetY + ballDirY;
					ballOffsetY <= offsetY + ballDirY; -- move Ball yPosition
					delay <= 0; 							-- reset delay
				end if;
			end if;
		end if;
	end process;

	verticalCollisionDetection : process (clk, offsetY, offsetX, paddle1OffsetY, paddle2OffsetY)
	begin
	if (clk'event and clk = '1') then
		if (delay < 500000) then
			
		else
			if (((offsetY + (5)*(ballDirY)) > 492) or ((offsetY + (5)*(ballDirY)) < 52)) then -- if 
				ballDirY <= -1 * ballDirY;
			end if;
		end if;
	end if;
	end process;
	
	horizontalCollisionDetection : process (clk, offsetY, offsetX, paddle1OffsetY, paddle2OffsetY)
	begin
		if (clk'event and clk = '1') then
			if (delay < 500000) then
			
			else
				if ((((offsetX + (5)*(ballDirX)) > 667) or ((offsetX + (5)*(ballDirX)) < 67))
					and (offsetY + (5)*(ballDirY) < 150 or offsetY + (5)*(ballDirY) > 394)) then	-- wall collision detection
					ballDirX <= -1 * ballDirX;	
	
				elsif ((((offsetX + (5)*(ballDirX)) > 87) and ((offsetX + (5)*(ballDirX)) <
					107)) and (offsetY + (5)*(ballDirY) < (paddle1OffsetY + 312) and offsetY + (5)*(ballDirY) >
				(paddle1OffsetY + 232))) then	-- paddle1 collision detection
					ballDirX <= -1 * ballDirX;
	
				elsif ((((offsetX + (5)*(ballDirX)) > 627) and ((offsetX + (5)*(ballDirX)) <
					647)) and (offsetY + (5)*(ballDirY) < (paddle2OffsetY + 312) and offsetY + (5)*(ballDirY) >
					(paddle2OffsetY + 232))) then	-- paddle2 collision detection
					ballDirX <= -1 * ballDirX;
				
				end if;
			end if;
		end if;
	end process;
	
	boundary : process (clk)
	begin
		if (clk'event and clk = '1') then
			if (delay < 500000) then
			
			else
				if (offsetX + 5 > 687 or offsetX - 5 < 47) then
					reset <= '1';
				else
					reset <= '0';
				end if;
			end if;
		end if;
	end process;
	
	Paddle1 : process(clk)
			begin
				if (clk'event and clk = '1') then
					if (delay < 500000) then
			
					else
						if (SW0 = '1' and SW1 = '0') then
							if (offset1 < 160) then
								offset1 <= offset1 + 1;
								paddle1OffsetY <= offset1 + 1;
							end if;
					
						elsif (SW0 = '0' and SW1 = '1') then
							if (offset1 > -160) then
								offset1 <= offset1 - 1;
								paddle1OffsetY <= offset1 - 1;
							end if;
						end if;
					end if;
				end if;
			end process;
	
	Paddle2 : process(clk)
			begin
				if (clk'event and clk = '1') then
					if (delay < 500000) then
			
					else
						if (SW2 = '1' and SW3 = '0') then
							if (offset2 < 160) then
								offset2 <= offset2 + 1;
								paddle2OffsetY <= offset2 + 1;
							end if;
					
						elsif (SW2 = '0' and SW3 = '1') then
							if (offset2 > -160) then
								offset2 <= offset2 - 1;
								paddle2OffsetY <= offset2 - 1;
							end if;
						end if;
					end if;
				end if;
	end process;
	
	--mapping ila ports
	ila_data(0) 			<= H_ila;
	ila_data(1) 			<= V_ila;
	ila_data(2) 			<= clk;
	ila_data(3)			 	<= dac;
	trig0(0)					<= trigger;
	
end Behavioral;