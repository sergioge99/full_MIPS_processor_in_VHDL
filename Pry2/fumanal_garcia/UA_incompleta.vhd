library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- Unidad de anticipación incompleta. Ahora mismo selecciona siempre la entrada 0
-- Entradas: 
-- Reg_Rs_EX
-- Reg_Rt_EX
-- RegWrite_MEM
-- RW_MEM
-- RegWrite_WB
-- RW_WB
-- Salidas:
-- MUX_ctrl_A
-- MUX_ctrl_B
entity UA is
	Port(
			Reg_Rs_EX: IN  std_logic_vector(4 downto 0); 
			Reg_Rt_EX: IN  std_logic_vector(4 downto 0);
			RegWrite_MEM: IN std_logic;
			RW_MEM: IN  std_logic_vector(4 downto 0);
			RegWrite_WB: IN std_logic;
			RW_WB: IN  std_logic_vector(4 downto 0);
			MUX_ctrl_A: out std_logic_vector(1 downto 0);
			MUX_ctrl_B: out std_logic_vector(1 downto 0)
		);
	end UA;

Architecture Behavioral of UA is
signal Corto_A_Mem, Corto_B_Mem, Corto_A_WB, Corto_B_WB: std_logic;
begin
-- Debéis diseñarla vosotros, ahora mismo elije siempre la entrada 0. Es decir sin ningún tipo de anticipación
-- entrada 00: se corresponde al dato original
-- entrada 01: dato de la etapa Mem
-- entrada 10: dato de la etapa WB
--original
--MUX_ctrl_A <= "00";
--MUX_ctrl_B <= "00";	
-- Solucion
Corto_A_Mem <= '1' when (Reg_Rs_EX=RW_MEM) AND (RegWrite_MEM='1') else '0';
Corto_B_Mem <= '1' when (Reg_Rt_EX=RW_MEM) AND (RegWrite_MEM='1') else '0';
Corto_A_WB	<= '1' when (Reg_Rs_EX=RW_WB) AND (RegWrite_WB='1') else '0';
Corto_B_WB	<= '1' when (Reg_Rt_EX=RW_WB) AND (RegWrite_WB='1') else '0';
MUX_ctrl_A <= 	"01" when Corto_A_Mem='1' else
				"10" when Corto_A_WB='1' else
				"00";
MUX_ctrl_B <= 	"01" when Corto_B_Mem='1' else
				"10" when Corto_B_WB='1' else
				"00";	
end Behavioral;