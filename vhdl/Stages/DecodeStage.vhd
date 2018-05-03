library ieee;
use ieee.std_logic_1164.all;
library work;
use work.Commons.all;

entity DecodeStage is
    port (
        clk_c, reset_in : in std_logic;

        instruction_in : in std_logic_vector(15 downto 0);

        -- From writeback
        enable_r_src_in, enable_r_dst_in : in std_logic; 
        r_src_address_in, r_dst_address_in : in std_logic_vector(2 downto 0);
        r_src_data_in, r_dst_data_in : in std_logic_vector(15 downto 0);
        immediate_fetched_in : in std_logic; -- From Buffer After me


        r_dst_from_execute_in, r_dst_from_memory_in : in std_logic_vector(15 downto 0);
        call_pc_address_select_in : in std_logic_vector(1 downto 0);
        opcode_out : out  std_logic_vector(4 downto 0);
        r_src_address_out, r_dst_address_out : out std_logic_vector(2 downto 0);
        r_src_data_out, r_dst_data_out : out std_logic_vector(15 downto 0);
        pc_address_out : out  std_logic_vector(15 downto 0)
    ) ;
end DecodeStage;

architecture decode_stage_arch of DecodeStage is
    component nRegistersFile is
        generic (
            n : integer;
            num_selection_bits : integer;
            register_width : integer
        );
        port (
            clk_c, enable1_in, enable2_in, reset_in : in std_logic;
    
            r_src_write_address_in, r_dst_write_address_in : in std_logic_vector(num_selection_bits downto 0);
            r_src_read_address_in, r_dst_read_address_in : in std_logic_vector(num_selection_bits downto 0);
    
            r_src_data_in, r_dst_data_in : in std_logic_vector(register_width-1 downto 0);
    
            r_src_data_out, r_dst_data_out : out std_logic_vector(register_width-1 downto 0)
        );
    end component;

    signal r_src_read_address_s, r_dst_read_address_s : std_logic_vector(2 downto 0);
begin

    opcode_out <= instruction_in(OPCODE_HIGHER_LIMIT downto R_SRC_HIGHER_LIMIT+1) 
    when immediate_fetched_in = FETCHED else ALU_OP_NOP;
    r_src_read_address_s <= instruction_in(R_SRC_HIGHER_LIMIT downto R_DST_HIGHER_LIMIT+1);
    r_dst_read_address_s <= instruction_in(R_DST_HIGHER_LIMIT downto R_DST_LOWER_LIMIT);
    
    pc_address_out <= r_dst_from_execute_in when call_pc_address_select_in = DECODE_DST_EXECUTE
    else r_dst_from_memory_in when call_pc_address_select_in = DECODE_DST_MEMORY
    else r_dst_read_address_s when call_pc_address_select_in = DECODE_DST_NORMAL;

    r_src_address_out <= r_src_read_address_s;
    r_dst_address_out <= r_dst_read_address_s;

    Inner_Register_File : nRegistersFile generic map (n => 6, num_selection_bits => 3, register_width => 16) port map (
        clk_c => clk_c, enable1_in => enable_r_src_in, enable2_in => enable_r_dst_in, reset_in => reset_in,
        r_src_write_address_in => r_src_address_in, r_dst_write_address_in => r_dst_address_in,
        r_src_read_address_in => r_src_read_address_s, r_dst_read_address_in => r_dst_read_address_s,
        r_src_data_in => r_src_data_in, r_dst_data_in => r_dst_data_in,
        r_src_data_out => r_src_data_out, r_dst_data_out => r_dst_data_out
    );
end decode_stage_arch ; -- decode_stage_arch