onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /archtest_tb/test_done
add wave -noupdate -radix hexadecimal /archtest_tb/clk
add wave -noupdate -radix hexadecimal /archtest_tb/rst_n
add wave -noupdate -radix hexadecimal /archtest_tb/dut/pc
add wave -noupdate -radix hexadecimal /archtest_tb/dut/if_inst/opcode_if
add wave -noupdate -label opcode_id -radix hexadecimal /archtest_tb/dut/id_inst/opcode
add wave -noupdate -radix hexadecimal /archtest_tb/dut/ex_inst/opcode_ex
add wave -noupdate -radix hexadecimal /archtest_tb/dut/mem_inst/opcode_mem
add wave -noupdate -radix hexadecimal /archtest_tb/dut/wb_inst/opcode_wb
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/flush_id_ex
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/flush_if_id
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/fwd_sel_a
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/fwd_sel_b
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/load_stall
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/pc_src_ex
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/rd_ex
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/rd_mem
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/rd_wb
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/reg_write_mem
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/reg_write_wb
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/rs1_ex
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/rs1_id
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/rs2_ex
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/rs2_id
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/stall_if_id
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/stall_pc_if
add wave -noupdate -group Hazard /archtest_tb/dut/hazard_inst/wb_src_ex
add wave -noupdate -group IF /archtest_tb/dut/if_inst/if_id
add wave -noupdate -group IF /archtest_tb/dut/if_inst/instruction
add wave -noupdate -group IF /archtest_tb/dut/if_inst/opcode_if
add wave -noupdate -group IF /archtest_tb/dut/if_inst/pc
add wave -noupdate -group IF /archtest_tb/dut/if_inst/pc_next
add wave -noupdate -group IF /archtest_tb/dut/if_inst/pc_plus4
add wave -noupdate -group IF /archtest_tb/dut/if_inst/pc_src
add wave -noupdate -group IF /archtest_tb/dut/if_inst/pc_target
add wave -noupdate -group ID /archtest_tb/dut/id_inst/funct3
add wave -noupdate -group ID /archtest_tb/dut/id_inst/funct7
add wave -noupdate -group ID /archtest_tb/dut/id_inst/id_ex
add wave -noupdate -group ID /archtest_tb/dut/id_inst/if_id
add wave -noupdate -group ID /archtest_tb/dut/id_inst/imm_B
add wave -noupdate -group ID /archtest_tb/dut/id_inst/imm_I
add wave -noupdate -group ID /archtest_tb/dut/id_inst/imm_J
add wave -noupdate -group ID /archtest_tb/dut/id_inst/imm_S
add wave -noupdate -group ID /archtest_tb/dut/id_inst/imm_U
add wave -noupdate -group ID /archtest_tb/dut/id_inst/opcode
add wave -noupdate -group ID /archtest_tb/dut/id_inst/rd_addr
add wave -noupdate -group ID /archtest_tb/dut/id_inst/rs1_addr
add wave -noupdate -group ID /archtest_tb/dut/id_inst/rs1_data
add wave -noupdate -group ID /archtest_tb/dut/id_inst/rs2_addr
add wave -noupdate -group ID /archtest_tb/dut/id_inst/rs2_data
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/alu_a
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/alu_b
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/alu_result
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/branch_taken
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/cmp_eq
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/cmp_lt
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/cmp_ltu
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/ex_mem
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/fwd_data_mem
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/fwd_data_wb
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/fwd_sel_a
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/fwd_sel_b
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/id_ex
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/opcode_ex
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/pc_src
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/pc_target
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/rs1_data
add wave -noupdate -group EX /archtest_tb/dut/ex_inst/rs2_data
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/alu_result
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/byte_en
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/ex_mem
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/ld_byte_ext
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/ld_byte_unsigned_ext
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/ld_half_ext
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/ld_half_unsigned_ext
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/mem_address
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/mem_data
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/mem_data_adjusted
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/mem_wb
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/mem_write
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/opcode_mem
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/selected_byte
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/selected_half
add wave -noupdate -group MEM /archtest_tb/dut/mem_inst/write_data
add wave -noupdate -group WB /archtest_tb/dut/wb_inst/mem_wb
add wave -noupdate -group WB /archtest_tb/dut/wb_inst/opcode_wb
add wave -noupdate -group WB /archtest_tb/dut/wb_inst/rd_addr
add wave -noupdate -group WB /archtest_tb/dut/wb_inst/reg_write
add wave -noupdate -group WB /archtest_tb/dut/wb_inst/wb_result
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {167105000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {166944657 ps} {167123966 ps}
