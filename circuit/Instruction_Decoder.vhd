library ieee;
use ieee.std_logic_1164.all;

-- Instruction_Decoder: purely combinational decode of OP/FUNCT.
-- CLASS    : instruction class (selects the control sequence downstream); "11111" = illegal
-- ALU_OP   : 000 add, 001 sub, 010 and, 011 or, 100 slt, 101 sll, 110 srl
-- EXT_MODE : immediate extension: 00 none, 01 sign, 10 zero, 11 upper (lui: imm << 16)
entity Instruction_Decoder is
  port (
    OP       : in  std_logic_vector(5 downto 0);
    FUNCT    : in  std_logic_vector(5 downto 0);
    CLASS    : out std_logic_vector(4 downto 0);
    ALU_OP   : out std_logic_vector(2 downto 0);
    EXT_MODE : out std_logic_vector(1 downto 0);
    ILLEGAL  : out std_logic
  );
end entity Instruction_Decoder;

architecture combinational of Instruction_Decoder is
begin
  process (OP, FUNCT)
  begin
    -- Safe defaults: any unlisted encoding is flagged illegal (also prevents latches)
    CLASS    <= "11111";
    ALU_OP   <= "000";
    EXT_MODE <= "00";
    ILLEGAL  <= '1';

    if OP = "000000" then
      -- R-type: the operation is selected by FUNCT
      case FUNCT is
        when "100000" =>  -- add
          CLASS <= "00000"; ALU_OP <= "000"; EXT_MODE <= "00"; ILLEGAL <= '0';
        when "100001" =>  -- addu
          CLASS <= "00000"; ALU_OP <= "000"; EXT_MODE <= "00"; ILLEGAL <= '0';
        when "100010" =>  -- sub
          CLASS <= "00000"; ALU_OP <= "001"; EXT_MODE <= "00"; ILLEGAL <= '0';
        when "100100" =>  -- and
          CLASS <= "00000"; ALU_OP <= "010"; EXT_MODE <= "00"; ILLEGAL <= '0';
        when "100101" =>  -- or
          CLASS <= "00000"; ALU_OP <= "011"; EXT_MODE <= "00"; ILLEGAL <= '0';
        when "101010" =>  -- slt
          CLASS <= "00000"; ALU_OP <= "100"; EXT_MODE <= "00"; ILLEGAL <= '0';
        when "000000" =>  -- sll (all-zero word = nop = sll $0,$0,0)
          CLASS <= "00000"; ALU_OP <= "101"; EXT_MODE <= "00"; ILLEGAL <= '0';
        when "000010" =>  -- srl
          CLASS <= "00000"; ALU_OP <= "110"; EXT_MODE <= "00"; ILLEGAL <= '0';
        when "001000" =>  -- jr (own class: PC <- rs)
          CLASS <= "01111"; ALU_OP <= "000"; EXT_MODE <= "00"; ILLEGAL <= '0';
        when "001100" =>  -- syscall
          CLASS <= "10000"; ALU_OP <= "000"; EXT_MODE <= "00"; ILLEGAL <= '0';
        when others =>    -- unknown FUNCT: keep the illegal defaults
          null;
      end case;
    else
      -- I-type / J-type: the operation is selected by OP
      case OP is
        when "001000" =>  -- addi  (sign-extended imm)
          CLASS <= "00001"; ALU_OP <= "000"; EXT_MODE <= "01"; ILLEGAL <= '0';
        when "001001" =>  -- addiu (sign-extended imm)
          CLASS <= "00001"; ALU_OP <= "000"; EXT_MODE <= "01"; ILLEGAL <= '0';
        when "001010" =>  -- slti  (sign-extended imm, ALU does slt)
          CLASS <= "00010"; ALU_OP <= "100"; EXT_MODE <= "01"; ILLEGAL <= '0';
        when "001100" =>  -- andi  (zero-extended imm)
          CLASS <= "00011"; ALU_OP <= "010"; EXT_MODE <= "10"; ILLEGAL <= '0';
        when "001101" =>  -- ori   (zero-extended imm)
          CLASS <= "00100"; ALU_OP <= "011"; EXT_MODE <= "10"; ILLEGAL <= '0';
        when "001111" =>  -- lui   (imm << 16)
          CLASS <= "00101"; ALU_OP <= "000"; EXT_MODE <= "11"; ILLEGAL <= '0';
        when "100011" =>  -- lw    (address = rs + sign-ext imm)
          CLASS <= "00110"; ALU_OP <= "000"; EXT_MODE <= "01"; ILLEGAL <= '0';
        when "101011" =>  -- sw
          CLASS <= "00111"; ALU_OP <= "000"; EXT_MODE <= "01"; ILLEGAL <= '0';
        when "100000" =>  -- lb
          CLASS <= "01000"; ALU_OP <= "000"; EXT_MODE <= "01"; ILLEGAL <= '0';
        when "100100" =>  -- lbu
          CLASS <= "01001"; ALU_OP <= "000"; EXT_MODE <= "01"; ILLEGAL <= '0';
        when "101000" =>  -- sb
          CLASS <= "01010"; ALU_OP <= "000"; EXT_MODE <= "01"; ILLEGAL <= '0';
        when "000100" =>  -- beq   (ALU subtracts to compare; offset sign-extended)
          CLASS <= "01011"; ALU_OP <= "001"; EXT_MODE <= "01"; ILLEGAL <= '0';
        when "000101" =>  -- bne
          CLASS <= "01100"; ALU_OP <= "001"; EXT_MODE <= "01"; ILLEGAL <= '0';
        when "000010" =>  -- j     (26-bit target, no immediate extension)
          CLASS <= "01101"; ALU_OP <= "000"; EXT_MODE <= "00"; ILLEGAL <= '0';
        when "000011" =>  -- jal
          CLASS <= "01110"; ALU_OP <= "000"; EXT_MODE <= "00"; ILLEGAL <= '0';
        when others =>    -- unknown OP: keep the illegal defaults
          null;
      end case;
    end if;
  end process;
end architecture combinational;
