import decode_pkg::*;
import pipeline_pkg::*;

module hazard_control (
    input logic [31:0]  rs1_id,
    input logic [31:0]  rs2_id,

    input logic [31:0]  rs1_ex,
    input logic [31:0]  rs2_ex,
    input logic [31:0]  rd_ex,
    input pc_src_e      pc_src_ex,
    input wb_src_e      wb_src_ex,

    input logic [31:0]  rd_mem,
    input logic         reg_write_mem,

    input logic         reg_write_wb,
    input logic         rd_wb
);

    
    
endmodule