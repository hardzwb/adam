`timescale 1ns/1ps

`ifndef CHI_REQ_W
`define CHI_REQ_W 128
`endif

`ifndef CHI_RSP_W
`define CHI_RSP_W 64
`endif

`ifndef CHI_DAT_W
`define CHI_DAT_W 512
`endif

`ifndef CHI_SNP_W
`define CHI_SNP_W 128
`endif

`ifndef CHI_REQ_FIFO_DEPTH
`define CHI_REQ_FIFO_DEPTH 4
`endif

`ifndef CHI_RSP_FIFO_DEPTH
`define CHI_RSP_FIFO_DEPTH 4
`endif

`ifndef CHI_DAT_FIFO_DEPTH
`define CHI_DAT_FIFO_DEPTH 4
`endif

`ifndef CHI_SNP_FIFO_DEPTH
`define CHI_SNP_FIFO_DEPTH 4
`endif

module CHI_DOWN_RING #(
    parameter int REQ_W = `CHI_REQ_W,
    parameter int RSP_W = `CHI_RSP_W,
    parameter int DAT_W = `CHI_DAT_W,
    parameter int SNP_W = `CHI_SNP_W,

    parameter int REQ_FIFO_DEPTH = `CHI_REQ_FIFO_DEPTH,
    parameter int RSP_FIFO_DEPTH = `CHI_RSP_FIFO_DEPTH,
    parameter int DAT_FIFO_DEPTH = `CHI_DAT_FIFO_DEPTH,
    parameter int SNP_FIFO_DEPTH = `CHI_SNP_FIFO_DEPTH
) (
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    req_in_vld_i,
    input  logic [REQ_W-1:0]        req_in_i,
    output logic                    req_in_credit_o,

    input  logic                    rsp_in_vld_i,
    input  logic [RSP_W-1:0]        rsp_in_i,
    output logic                    rsp_in_credit_o,

    input  logic                    dat_in_vld_i,
    input  logic [DAT_W-1:0]        dat_in_i,
    output logic                    dat_in_credit_o,

    input  logic                    snp_in_vld_i,
    input  logic [SNP_W-1:0]        snp_in_i,
    output logic                    snp_in_credit_o,

    output logic                    req_out_vld_o,
    output logic [REQ_W-1:0]        req_out_o,
    input  logic                    req_out_rdy_i,

    output logic                    rsp_out_vld_o,
    output logic [RSP_W-1:0]        rsp_out_o,
    input  logic                    rsp_out_rdy_i,

    output logic                    dat_out_vld_o,
    output logic [DAT_W-1:0]        dat_out_o,
    input  logic                    dat_out_rdy_i,

    output logic                    snp_out_vld_o,
    output logic [SNP_W-1:0]        snp_out_o,
    input  logic                    snp_out_rdy_i,

    output logic                    req_overflow_o,
    output logic                    rsp_overflow_o,
    output logic                    dat_overflow_o,
    output logic                    snp_overflow_o
);

    // Request channel
    CHI_CREDIT_FIFO #(
        .DATA_W(REQ_W),
        .DEPTH (REQ_FIFO_DEPTH)
    ) U_REQ_FIFO (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_vld_i   (req_in_vld_i),
        .in_data_i  (req_in_i),
        .credit_o   (req_in_credit_o),
        .overflow_o (req_overflow_o),
        .out_vld_o  (req_out_vld_o),
        .out_data_o (req_out_o),
        .out_rdy_i  (req_out_rdy_i)
    );

    // Response channel
    CHI_CREDIT_FIFO #(
        .DATA_W(RSP_W),
        .DEPTH (RSP_FIFO_DEPTH)
    ) U_RSP_FIFO (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_vld_i   (rsp_in_vld_i),
        .in_data_i  (rsp_in_i),
        .credit_o   (rsp_in_credit_o),
        .overflow_o (rsp_overflow_o),
        .out_vld_o  (rsp_out_vld_o),
        .out_data_o (rsp_out_o),
        .out_rdy_i  (rsp_out_rdy_i)
    );

    // Data channel
    CHI_CREDIT_FIFO #(
        .DATA_W(DAT_W),
        .DEPTH (DAT_FIFO_DEPTH)
    ) U_DAT_FIFO (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_vld_i   (dat_in_vld_i),
        .in_data_i  (dat_in_i),
        .credit_o   (dat_in_credit_o),
        .overflow_o (dat_overflow_o),
        .out_vld_o  (dat_out_vld_o),
        .out_data_o (dat_out_o),
        .out_rdy_i  (dat_out_rdy_i)
    );

    // Snoop channel
    CHI_CREDIT_FIFO #(
        .DATA_W(SNP_W),
        .DEPTH (SNP_FIFO_DEPTH)
    ) U_SNP_FIFO (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_vld_i   (snp_in_vld_i),
        .in_data_i  (snp_in_i),
        .credit_o   (snp_in_credit_o),
        .overflow_o (snp_overflow_o),
        .out_vld_o  (snp_out_vld_o),
        .out_data_o (snp_out_o),
        .out_rdy_i  (snp_out_rdy_i)
    );

endmodule
