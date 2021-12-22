----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:38:18 05/15/2014 
-- Design Name: 
-- Module Name:    UC_slave - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: la UC incluye un contador de 2 bits para llevar la cuenta de las transferencias de bloque y una máquina de estados
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

entity UC_MC is
    Port ( 	clk : in  STD_LOGIC;
			reset : in  STD_LOGIC;
			RE : in  STD_LOGIC; --RE y WE son las ordenes del MIPs
			WE : in  STD_LOGIC;
			hit : in  STD_LOGIC; --se activa si hay acierto
			bus_TRDY : in  STD_LOGIC; --indica que la memoria no puede realizar la operación solicitada en este ciclo
			Bus_DevSel: in  STD_LOGIC; --indica que la memoria ha reconocido que la dirección está dentro de su rango
			MC_RE : out  STD_LOGIC; --RE y WE de la MC
            MC_WE : out  STD_LOGIC;
            MC_bus_Rd_Wr : out  STD_LOGIC; --1 para escritura en Memoria y 0 para lectura
            MC_tags_WE : out  STD_LOGIC; -- para escribir la etiqueta en la memoria de etiquetas
            palabra : out  STD_LOGIC_VECTOR (1 downto 0);--indica la palabra actual dentro de una transferencia de bloque (1ª, 2ª...)
            mux_origen: out STD_LOGIC; -- Se utiliza para elegir si el origen de la dirección y el dato es el Mips (cuando vale 0) o la UC y el bus (cuando vale 1)
            ready : out  STD_LOGIC; -- indica si podemos procesar la orden actual del MIPS en este ciclo. En caso contrario habrá que detener el MIPs
            block_addr : out  STD_LOGIC; -- indica si la dirección a enviar es la de bloque (rm) o la de palabra (w)
			MC_send_addr : out  STD_LOGIC; --ordena que se envíen la dirección y las señales de control al bus
            MC_send_data : out  STD_LOGIC; --ordena que se envíen los datos
            Frame : out  STD_LOGIC; --indica que la operación no ha terminado
			Replace_block	: out  STD_LOGIC; -- indica que se ha reemplazado un bloque
			inc_rm : out STD_LOGIC; -- indica que ha habido un fallo de lectura
			inc_wm : out STD_LOGIC; -- indica que ha habido un fallo de escritura
			inc_wh : out STD_LOGIC; -- indica que ha habido un acierto de escritura
			Rload : out  STD_LOGIC;
			Rdir : out  STD_LOGIC
           );
end UC_MC;

architecture Behavioral of UC_MC is


component counter_2bits is
		    Port ( clk : in  STD_LOGIC;
		           reset : in  STD_LOGIC;
		           count_enable : in  STD_LOGIC;
		           count : out  STD_LOGIC_VECTOR (1 downto 0)
					  );
end component;		           
-------------------------------------------------------------------------------------------------
-- poner en el siguiente type el nombre de vuestros estados
type state_type is (Inicio,R_W,W_W,R_1,W_1,R_2,W_2); 
signal state, next_state : state_type; 
signal last_word: STD_LOGIC; --se activa cuando se está pidiendo la última palabra de un bloque
signal count_enable: STD_LOGIC; -- se activa si se ha recibido una palabra de un bloque para que se incremente el contador de palabras
signal palabra_UC : STD_LOGIC_VECTOR (1 downto 0);
begin
 
 
--el contador nos dice cuantas palabras hemos recibido. Se usa para saber cuando se termina la transferencia del bloque y para direccionar la palabra en la que se escribe el dato leido del bus en la MC
word_counter: counter_2bits port map (clk, reset, count_enable, palabra_UC); --indica la palabra actual dentro de una transferencia de bloque (1ª, 2ª...)

last_word <= '1' when palabra_UC="11" else '0';--se activa cuando estamos pidiendo la última palabra

palabra <= palabra_UC;

   SYNC_PROC: process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            state <= Inicio;
         else
            state <= next_state;
         end if;        
      end if;
   end process;
 

   -- Poned aquí el código de vuestra máquina de estados
	OUTPUT_DECODE: process (state, hit, last_word, bus_TRDY, RE, WE, Bus_DevSel)
	begin
		-- Se comienza dando los valores por defecto, si no se asigna otro valor en un estado valdrán lo que se asigna aquí
		-- Así no hay que asignar valor a todas las señales en cada caso
		MC_WE <= '0';
		MC_bus_Rd_Wr <= '0';
		MC_tags_WE <= '0';
        MC_RE <= RE;
        ready <= '0';
        mux_origen <= '0';
        MC_send_addr <= '0';
        MC_send_data <= '0';
        next_state <= state;  
		count_enable <= '0';
		Frame <= '0';
		Replace_block <= '0';	
		block_addr <= '0';
		inc_rm <= '0';
		inc_wm <= '0';
		inc_wh <= '0';
		Rload <= '0';
		Rdir<='0';
        -- Estado Inicio          
        if (state = Inicio and ((RE='0' and WE='0') or (RE='1' and hit='1'))) then -- si no piden nada no hacemos nada
				next_state <= Inicio;
				ready <= '1';
		elsif (state = Inicio and RE='1' and hit='0' and Bus_DevSel='0') then
				next_state <= R_W;
				Frame<='1';
				MC_send_addr<='1';
				inc_rm<='1';
				block_addr<='1';
		elsif (state = Inicio and RE='1' and hit='0' and Bus_DevSel='1') then
				next_state <= R_1;
				Frame<='1';
				MC_send_addr<='1';
				inc_rm<='1';
				block_addr<='1';
		elsif (state = R_W and Bus_DevSel='0') then
				next_state <= R_W;
				Frame<='1';
				MC_send_addr<='1';
				block_addr<='1';
		elsif (state = R_W and Bus_DevSel='1') then
				next_state <= R_1;
				Frame<='1';
		elsif (state = R_1 and ((Bus_DevSel='1' and last_word='0') or (bus_TRDY='0' and last_word='1'))) then
				next_state <= R_1;
				Frame<='1';
				mux_origen<='1';
				MC_WE<=bus_TRDY;
				count_enable<=bus_TRDY;
		elsif (state = R_1 and bus_TRDY='1' and last_word='1') then
				next_state <= R_2;
				Frame<='1';
				mux_origen<='1';
				MC_WE<='1';
				MC_tags_WE<='1';
				count_enable<='1';
		elsif (state = R_2 and bus_TRDY='1') then
				next_state <= R_2;
				Frame<='1';
		elsif (state = R_2 and bus_TRDY='0') then
				next_state <= Inicio;
				ready<='1';
-----------------------------------------------------------------------------
		elsif (state = Inicio and WE='1' and Bus_DevSel='0') then
				next_state <= W_W;
				Frame<='1';
				ready<='1';
				Rload<='1';
				MC_send_addr<='1';
				if (hit='1') then
					inc_wh<='1';
					MC_WE<='1';
				else
					inc_wm<='1';
				end if;
		elsif (state = Inicio and WE='1' and Bus_DevSel='1') then
				next_state <= W_1;
				Frame<='1';
				ready<='1';
				Rload<='1';
				MC_send_addr<='1';
				if (hit='1') then
					inc_wh<='1';
					MC_WE<='1';
				else
					inc_wm<='1';
				end if;
		elsif (state = W_W and Bus_DevSel='0') then
				next_state <= W_W;
				Frame<='1';
				Rdir<='1';
				MC_send_addr<='1';
				if ((RE='0' and WE='0') or (RE='1' and hit='1')) then
					ready<='1';
				end if;
		elsif (state = W_W and Bus_DevSel='1') then
				next_state <= W_1;
				Frame<='1';
				if ((RE='0' and WE='0') or (RE='1' and hit='1')) then
					ready<='1';
				end if;
		elsif (state = W_1 and bus_TRDY='0') then
				next_state <= W_1;
				Frame<='1';
				MC_send_data<='1';
				MC_bus_Rd_Wr<='1';
				if ((RE='0' and WE='0') or (RE='1' and hit='1')) then
					ready<='1';
				end if;
		elsif (state = W_1 and bus_TRDY='1') then
				next_state <= W_2;
				Frame<='1';
				MC_send_data<='1';
				MC_bus_Rd_Wr<='1';
				if ((RE='0' and WE='0') or (RE='1' and hit='1')) then
					ready<='1';
				end if;
		elsif (state = W_2 and bus_TRDY='1') then
				next_state <= W_2;
				Frame<='1';
				if ((RE='0' and WE='0') or (RE='1' and hit='1')) then
					ready<='1';
				end if;
		elsif (state = W_2 and bus_TRDY='0') then
				next_state <= Inicio;
				if ((RE='0' and WE='0') or (RE='1' and hit='1')) then
					ready<='1';
				end if;
		end if;
	end process;
 
   
end Behavioral;

