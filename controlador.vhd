----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:19:30 12/14/2018 
-- Design Name: 
-- Module Name:    controlador - casa_domotica 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controlador is
    Port ( clk : in  STD_LOGIC;
           min : in  STD_LOGIC;
           hor : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  habilitado: in STD_LOGIC;
           alarma : out  STD_LOGIC;
           aspersor : out  STD_LOGIC;
           luces : out  STD_LOGIC;
           minpres : out  STD_LOGIC;
           horpres : out  STD_LOGIC;
           resetpres : out  STD_LOGIC;
			  E: inout std_logic;
			  l: out std_logic_vector(3 downto 0);
			  RS,RW,SF_CE0 : out std_logic;
			  DB : out std_logic_vector(3 downto 0));
end controlador;

architecture casa_domotica of controlador is

	type estados is (FI1A,FI1B,FI2A,FI2B,FI3A,FI3B,BOR1,BOR2,CONT1,CONT2,
	                 MOD1,MOD2, pp1,pp2,ent1,ent2,
						  hd1, hd2, hu1, hu2, p1, p2, md1, md2, mu1, mu2, sd1, sd2, su1, su2,
						  f1, f2, u1, u2, n1, n2, c1, c2, i1, i2, o1, o2, n21, n22, p21, p22, sp1, sp2,
						  msg11, msg12, msg21, msg22, msg31, msg32, msg41, msg42, msg51, msg52,
						  borr1,borr2,ret1,ret2);	
	signal pr_estado,sig_estado: estados;
	
	type tiempos is (t0, t00, t01, t10, t11, t20, t21, t30, t31, t40, t41, t50, t51, t60, t61, t70, t71, t80, t81, t90, t91);
	signal pr_tiempo, sig_tiempo: tiempos;
	
	signal hora, minuto: std_logic;
	signal horasd, horasu, minutosd, minutosu, segundosd, segundosu: std_logic_vector (3 downto 0);
	signal horas, minutos, segundos : integer range 0 to 60;
	signal rel, rel2, alarm, asper, luc : std_logic;
	
	component eliminador is
    Port ( clk : in STD_LOGIC;
			  reset : in  STD_LOGIC;
			  pbsync : in STD_LOGIC;
           pulse : out  STD_LOGIC);
	end component;
	
	component div_frec_5hz is
    Port ( clock : in  STD_LOGIC;
           clkout : out  STD_LOGIC);
	end component;
	
	component div_frec_vhdl is
    Port ( clock : in  STD_LOGIC;
           clkout : out  STD_LOGIC);
	end component;

begin

	SF_CE0 <='1';
		reloj: process (clk)   -- DIVISOR DE FRECUENCIA DE 50 MHz a 500 Hz
		       variable cuenta:integer range 0 to 100000:=0;
               begin
             		if(clk'event and clk='1') then
						  if (cuenta < 100000) then
                      cuenta:=cuenta + 1;
						  else 
							 cuenta := 0;
						  end if;	 
							if (cuenta < 50000) then
							 E <= '0';
							else
							 E <= '1';
							end if;	
						end if;
				 end process reloj;
		SEC_maquina: process(E, reset)  --- PARTE SECUENCIAL DE LA MAQUINA DE ESTADOS
				begin
					if(E'event and E='1') then
					 if(reset='1') then
					   pr_estado <= FI1A;
					 else	
						pr_estado <= sig_estado;
					 end if;
					end if; 
				end process SEC_maquina;
		m0: div_frec_5hz port map (clk, rel);
		resetpres <= reset;
		m1: eliminador port map (E, reset, min, minuto);
		m2: eliminador port map (E, reset, hor, hora);
		horpres <= hora;
		minpres <= minuto;
		m3: div_frec_vhdl port map (clk, rel2);
		
		temporizador: process (rel, minuto, hora, reset, rel2, habilitado) 
			variable mind, minu : integer range 0 to 10 := 0;
			variable hrsd, hrsu : integer range 0 to 10 := 0;
			variable segd, segu : integer range 0 to 10 := 0;
		begin
			if (reset = '1') then
				mind := 0;
				minu := 0;
				hrsd := 0;
				hrsu := 0;
				segd := 0;
				segu := 0;
				horas <= 0;
				minutos <= 0;
				segundos <= 0;
			elsif (rel'event and rel = '0' and (minuto = '1' or hora = '1' or rel2 = '1')) then
				if (rel2 = '1' and habilitado = '1') then
					segu := segu + 1;
					segundos <= segundos + 1;
					if segu = 10 then
						segd := segd + 1;
						segu := 0;
					end if;
					if segundos >= 59 then
						minu := minu + 1;
						minutos <= minutos + 1;
						segd := 0;
						segu := 0;
						segundos <= 0;
					end if;
					if minu = 10 then
						mind := mind + 1;
						minu := 0;
					end if;
					if minutos >= 59 and segundos >= 59 then
						 hrsu := hrsu + 1;
						 mind := 0;
						 minu := 0;
						 minutos <= 0;
						 segd := 0;
						 segu := 0;
						 segundos <= 0;
						 horas <= horas + 1;
					end if;
					if hrsu = 10 then
						hrsd := hrsd + 1;
						hrsu := 0;
					end if;
					if horas >= 23 and minutos >= 59 and segundos >= 59 then
						hrsd := 0;
						hrsu := 0;
						mind := 0;
						minu := 0;
						segd := 0;
						segu := 0;
						horas <= 0;
						minutos <= 0;
						segundos <= 0;
					end if;
				end if;
				if minuto = '1' then
					minu := minu + 1;
					minutos <= minutos + 1;
					if minu = 10 then 
						mind := mind + 1;
						minu := 0;
					end if;
					if minutos >= 59 then
						 hrsu := hrsu + 1;
						 mind := 0;
						 minu := 0;
						 minutos <= 0;
						 horas <= horas + 1;
					end if;
					if hrsu = 10 then
						hrsd := hrsd + 1;
						hrsu := 0;
					end if;
					if horas >= 23 and minutos >= 59 then
						hrsd := 0;
						hrsu := 0;
						mind := 0;
						minu := 0;
						horas <= 0;
						minutos <= 0;
					end if;
				end if;
				if hora = '1' then
					hrsu := hrsu + 1;
					horas <= horas + 1;
					
					if hrsu = 10 then
						hrsd := hrsd + 1;
						hrsu := 0;
					end if;
					if horas >= 23 then
						hrsd := 0;
						hrsu := 0;
						horas <= 0;
					end if;
				end if;
			end if;
			
			minutosd <= std_logic_vector(to_unsigned(mind, 4));
			minutosu <= std_logic_vector(to_unsigned(minu, 4));
			horasd <= std_logic_vector(to_unsigned(hrsd, 4));
			horasu <= std_logic_vector(to_unsigned(hrsu, 4));
			segundosu <= std_logic_vector(to_unsigned(segu, 4));
			segundosd <= std_logic_vector(to_unsigned(segd, 4));
			
		end process temporizador;
		
		seq_tiempo: process(rel2, reset) begin
			if(reset='1') then
				pr_tiempo <= t0;
			elsif(rel2'event and rel2='1') then	
				pr_tiempo <= sig_tiempo;
			end if; 
		end process seq_tiempo;
		
		funcionalidades: process (horas, minutos, segundos, pr_tiempo) begin
			alarm <= '0';
			asper <= '0';
			luc <= '0';
			if horas = 6 and minutos >= 30 and segundos >= 0 then
				case pr_tiempo is
					when t0 => 
						alarm <= '0';
						sig_tiempo <= t00;
					when t00 =>
						alarm <= '1';
						sig_tiempo <= t01;
					when t01 =>
						alarm <= '0';
						sig_tiempo <= t10;
						
					when t10 =>
						alarm <= '1';
						sig_tiempo <= t11;
					when t11 =>
						alarm <= '0';
						sig_tiempo <= t20;
						
					when t20 =>
						alarm <= '1';
						sig_tiempo <= t21;
					when t21 =>
						alarm <= '0';
						sig_tiempo <= t30;
						
					when t30 =>
						alarm <= '1';
						sig_tiempo <= t31;
					when t31 =>
						alarm <= '0';
						sig_tiempo <= t40;
						
					when t40 =>
						alarm <= '1';
						sig_tiempo <= t41;
					when t41 =>
						alarm <= '0';
						sig_tiempo <= t50;
						
					when t50 =>
						alarm <= '1';
						sig_tiempo <= t51;
					when t51 =>
						alarm <= '0';
						sig_tiempo <= t60;
						
					when t60 =>
						alarm <= '1';
						sig_tiempo <= t61;
					when t61 =>
						alarm <= '0';
						sig_tiempo <= t70;
						
					when t70 =>
						alarm <= '1';
						sig_tiempo <= t71;
					when t71 =>
						alarm <= '0';
						sig_tiempo <= t80;
						
					when t80 =>
						alarm <= '1';
						sig_tiempo <= t81;
					when t81 =>
						alarm <= '0';
						sig_tiempo <= t90;
						
					when t90 =>
						alarm <= '1';
						sig_tiempo <= t91;
					when t91 =>
						alarm <= '0';
						sig_tiempo <= t91;
				end case;
			end if;
			if horas >= 19 then
				if horas < 23 then 
					luc <= '1';
				else
					luc <= '0';
				end if;
			end if;
			if horas >= 4 then
				if horas < 6 then
					asper <= '1';
				else 
					asper <= '0';
				end if;
			end if;
			alarma <= alarm;
			aspersor <= asper;
			luces <= luc;
		end process funcionalidades;
		
		COMB_maquina: process (horasd, horasu, minutosd, minutosu, pr_estado) --- PARTE COMBINATORIA DE LA MAQUINA DE ESTADOS
			  
           begin
            
				case pr_estado is
				  when FI1A =>      ----- INICIO código $28 SELECCIÓM DEL BUS DE 4 BITS 
					RS <='0'; RW<='0';
					DB <="0010";
					sig_estado <= FI1B;
				  when FI1B =>
					RS <='0'; RW<='0';
					DB <="1000";
					sig_estado <= FI2A;
				  when FI2A =>
					RS <='0'; RW<='0';
					DB <="0010";
					sig_estado <= FI2B;
				  when FI2B =>
					RS <='0'; RW<='0';
					DB <="1000";
					sig_estado <= FI3A;
				  when FI3A =>
					RS <='0'; RW<='0';
					DB <="0010";
					sig_estado <= FI3B;
				  when FI3B =>
					RS <='0'; RW<='0';
					DB <="1000";       ----- FIN código $28 SELECCIÓM DEL BUS DE 4 BITS
					sig_estado <= BOR1;
					when BOR1 =>       ----- INICIO código $01 BORRA LA PANTALLA Y CURSOR A CASA
					RS <='0'; RW<='0';
					DB <="0000";
					sig_estado <= BOR2;
					when BOR2 =>
					RS <='0'; RW<='0';
					DB <="0001";       ----- FIN código $01 BORRA LA PANTALLA Y CURSOR A CASA 
					sig_estado <= CONT1;
					when CONT1 =>      ----- INICIO código $0C ACTIVA LA PANTALLA
					RS <='0'; RW<='0';
					DB <="0000";
					sig_estado <= CONT2;
					when CONT2 =>
					RS <='0'; RW<='0';
					DB <="1100";       ----- FIN código $0C ACTIVA LA PANTALLA
					sig_estado <= MOD1;
					when MOD1 =>       ----- INICIO código $06 INCREMENTA CURSOR EN LA PANTALLA 
					RS <='0'; RW<='0';
					DB <="0000";
					sig_estado <= MOD2;
					when MOD2 =>
					RS <='0'; RW<='0';
					DB <="0110";       ----- FIN código $06 INCREMENTA CURSOR EN LA PANTALLA 
					sig_estado <= hd1;
					
					when hd1 =>
						RS <= '1'; RW <= '0';
						DB <= "0011";
						sig_estado <= hd2;
					when hd2 =>
						RS <= '1'; RW <= '0';
						DB <= horasd;
						sig_estado <= hu1;
					
					when hu1 =>
						RS <= '1'; RW <= '0';
						DB <= "0011";
						sig_estado <= hu2;
					when hu2 =>
						RS <= '1'; RW <= '0';
						DB <= horasu;
						sig_estado <= p1;
					
					when p1 =>         
					RS <='1'; RW<='0';
					DB <="0011";
					sig_estado <= p2;
					when p2 =>
					RS <='1'; RW<='0';
					DB <="1010";      
					sig_estado <= md1;
					
					when md1 =>
						RS <= '1'; RW <= '0';
						DB <= "0011";
						sig_estado <= md2;
					when md2 =>
						RS <= '1'; RW <= '0';
						DB <= minutosd;
						sig_estado <= mu1;
					
					when mu1 =>
						RS <= '1'; RW <= '0';
						DB <= "0011";
						sig_estado <= mu2;
					when mu2 =>
						RS <= '1'; RW <= '0';
						DB <= minutosu;
						sig_estado <= pp1;
					
					when pp1 =>         
					RS <='1'; RW<='0';
					DB <="0011";
					sig_estado <= pp2;
					when pp2 =>
					RS <='1'; RW<='0';
					DB <="1010";      
					sig_estado <= sd1;
					
					when sd1 =>
						RS <= '1'; RW <= '0';
						DB <= "0011";
						sig_estado <= sd2;
					when sd2 =>
						RS <= '1'; RW <= '0';
						DB <= segundosd;
						sig_estado <= su1;
					
					when su1 =>
						RS <= '1'; RW <= '0';
						DB <= "0011";
						sig_estado <= su2;
					when su2 =>
						RS <= '1'; RW <= '0';
						DB <= segundosu;
						sig_estado <= ent1;
					
					when ent1 =>         
					RS <='0'; RW<='0';
					DB <="1100";
					sig_estado <= ent2;
					when ent2 =>
					RS <='0'; RW<='0';
					DB <="0000";      
					sig_estado <= f1;
						
					when f1 =>
						RS <= '1'; RW <= '0';
						DB <= x"4";
						sig_estado <= f2;
					when f2 =>
						RS <= '1'; RW <= '0';
						DB <= x"6";
						sig_estado <= u1;
						
					when u1 =>
						RS <= '1'; RW <= '0';
						DB <= x"5";
						sig_estado <= u2;
					when u2 =>
						RS <= '1'; RW <= '0';
						DB <= x"5";
						sig_estado <= n1;
					
					when n1 =>
						RS <= '1'; RW <= '0';
						DB <= x"4";
						sig_estado <= n2;
					when n2 =>
						RS <= '1'; RW <= '0';
						DB <= x"E";
						sig_estado <= c1;
						
					when c1 =>
						RS <= '1'; RW <= '0';
						DB <= x"4";
						sig_estado <= c2;
					when c2 =>
						RS <= '1'; RW <= '0';
						DB <= x"3";
						sig_estado <= i1;
						
					when i1 =>
						RS <= '1'; RW <= '0';
						DB <= x"4";
						sig_estado <= i2;
					when i2 =>
						RS <= '1'; RW <= '0';
						DB <= x"9";
						sig_estado <= o1;
					
					when o1 =>
						RS <= '1'; RW <= '0';
						DB <= x"4";
						sig_estado <= o2;
					when o2 =>
						RS <= '1'; RW <= '0';
						DB <= x"F";
						sig_estado <= n21;
						
					when n21 =>
						RS <= '1'; RW <= '0';
						DB <= x"4";
						sig_estado <= n22;
					when n22 =>
						RS <= '1'; RW <= '0';
						DB <= x"E";
						sig_estado <= p21;
					
					when p21 =>
						RS <= '1'; RW <= '0';
						DB <= x"3";
						sig_estado <= p22;
					when p22 =>
						RS <= '1'; RW <= '0';
						DB <= x"A";
						sig_estado <= sp1;
					
					when sp1 =>         
						RS <='1'; RW<='0';
						DB <= x"2";
						sig_estado <= sp2;
					when sp2 =>
						RS <='1'; RW<='0';
						DB <= x"0";  
						sig_estado <= msg11;
						
					when msg11 =>
						RS <= '1'; RW <= '0';
						if alarm = '1' then DB <= x"4";
						elsif asper = '1' then DB <= x"4";
						elsif luc = '1' then DB <= x"4";
						else DB <= x"2";
						end if;
						sig_estado <= msg12;
					when msg12 =>
						RS <= '1'; RW <= '0';
						if alarm = '1' then DB <= x"1";
						elsif asper = '1' then DB <= x"1";
						elsif luc = '1' then DB <= x"C";
						else DB <= x"0";
						end if;
						sig_estado <= msg21;
					
					when msg21 =>
						RS <= '1'; RW <= '0';
						if alarm = '1' then DB <= x"4";
						elsif asper = '1' then DB <= x"5";
						elsif luc = '1' then DB <= x"5";
						else DB <= x"2";
						end if;
						sig_estado <= msg22;
					when msg22 =>
						RS <= '1'; RW <= '0';
						if alarm = '1' then DB <= x"C";
						elsif asper = '1' then DB <= x"3";
						elsif luc = '1' then DB <= x"5";
						else DB <= x"0";
						end if;
						sig_estado <= msg31;
					
					when msg31 =>
						RS <= '1'; RW <= '0';
						if alarm = '1' then DB <= x"4";
						elsif asper = '1' then DB <= x"5";
						elsif luc = '1' then DB <= x"4";
						else DB <= x"2";
						end if;
						sig_estado <= msg32;
					when msg32 =>
						RS <= '1'; RW <= '0';
						if alarm = '1' then DB <= x"1";
						elsif asper = '1' then DB <= x"0";
						elsif luc = '1' then DB <= x"3";
						else DB <= x"0";
						end if;
						sig_estado <= msg41;
						
					when msg41 =>
						RS <= '1'; RW <= '0';
						if alarm = '1' then DB <= x"5";
						elsif asper = '1' then DB <= x"4";
						elsif luc = '1' then DB <= x"4";
						else DB <= x"2";
						end if;
						sig_estado <= msg42;
					when msg42 =>
						RS <= '1'; RW <= '0';
						if alarm = '1' then DB <= x"2";
						elsif asper = '1' then DB <= x"5";
						elsif luc = '1' then DB <= x"5";
						else DB <= x"0";
						end if;
						sig_estado <= msg51;
						
					when msg51 =>
						RS <= '1'; RW <= '0';
						if alarm = '1' then DB <= x"4";
						elsif asper = '1' then DB <= x"5";
						elsif luc = '1' then DB <= x"5";
						else DB <= x"2";
						end if;
						sig_estado <= msg52;
					when msg52 =>
						RS <= '1'; RW <= '0';
						if alarm = '1' then DB <= x"D";
						elsif asper = '1' then DB <= x"2";
						elsif luc = '1' then DB <= x"3";
						else DB <= x"0";
						end if;
						sig_estado <= borr1;
					
					when borr1 =>
						RS <='1'; RW<='0';
						DB <="0010";
						sig_estado <= borr2;
					when borr2 =>
						RS <='1'; RW<='0';
						DB <="0000";
						sig_estado <= ret1;
					when ret1 =>        ----- INICIO código $80 RETORNO
					RS <='0'; RW<='0';
					DB <="1000";
					sig_estado <= ret2;
					when ret2 =>
					RS <='0'; RW<='0';
					DB <="0000";      
					sig_estado <= hd1; ----- FIN código $80 RETORNO
		end case;
	end process COMB_maquina;

end casa_domotica;

