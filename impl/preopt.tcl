set_multicycle_path 2 -from [get_pins */u_dram_ctl/u_buf/u_cmd_age/genblk1[*].u_matrix_r/q_reg[*]/C]
set_multicycle_path 2 -from [get_pins */u_dram_ctl/u_buf/u_buf_ent[*]/u_addr_r/q_reg[*]/C]
set_multicycle_path 2 -from [get_pins */u_dram_ctl/u_buf/u_buf_ent[*]/u_write_r/q_reg[*]/C]

# Valid primitive types:
# LUT
# FLOP_LATCH
# BMEM.*
# MULT.*
# CLK
# IO
# OTHERS
group_path -name ToRAM -to [get_pins -hier -filter {REF_NAME =~ RAMB* && DIRECTION == IN && IS_CLOCK == 0 && IS_CONNECTED == 1 && IS_TIED == 0}]
group_path -name FromRAM -from [get_pins -hier -filter {REF_NAME =~ RAMB* && DIRECTION == IN && IS_CLOCK == 1}]
group_path -name L2 -through [get_pins top/l2/*]
