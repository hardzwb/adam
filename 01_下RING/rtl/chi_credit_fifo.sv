`timescale 1ns/1ps

module chi_credit_fifo #(
    parameter int DATA_W = 128,
    parameter int DEPTH  = 4,
    parameter int CREDIT_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH + 1)
) (
    input  logic                 clk,
    input  logic                 rst_n,

    input  logic                 in_vld_i,
    input  logic [DATA_W-1:0]    in_data_i,
    output logic [CREDIT_W-1:0]  credit_o,
    output logic                 overflow_o,

    output logic                 out_vld_o,
    output logic [DATA_W-1:0]    out_data_o,
    input  logic                 out_rdy_i
);

    localparam int PTR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
    localparam logic [CREDIT_W-1:0] DEPTH_VALUE = CREDIT_W'(DEPTH);
    localparam logic [PTR_W-1:0]    LAST_PTR    = PTR_W'(DEPTH - 1);

    logic [DATA_W-1:0] mem_q [0:DEPTH-1];
    logic [PTR_W-1:0]  rd_ptr_q;
    logic [PTR_W-1:0]  wr_ptr_q;
    logic [CREDIT_W-1:0] occ_q;

    logic fifo_empty;
    logic fifo_full;
    logic fifo_pop;
    logic fifo_push;
    logic bypass_pop;
    logic store_push;

    assign fifo_empty = (occ_q == '0);
    assign fifo_full  = (occ_q == DEPTH_VALUE);

    assign out_vld_o  = fifo_empty ? in_vld_i : 1'b1;
    assign out_data_o = fifo_empty ? in_data_i : mem_q[rd_ptr_q];

    assign bypass_pop = fifo_empty && in_vld_i && out_rdy_i;
    assign fifo_pop   = (!fifo_empty) && out_rdy_i;
    assign fifo_push  = in_vld_i && (!fifo_full || fifo_pop || bypass_pop);
    assign store_push = fifo_push && !bypass_pop;

    assign credit_o   = DEPTH_VALUE - occ_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_q   <= '0;
            wr_ptr_q   <= '0;
            occ_q      <= '0;
            overflow_o <= 1'b0;
        end else begin
            overflow_o <= in_vld_i && fifo_full && !fifo_pop && !bypass_pop;

            if (store_push) begin
                mem_q[wr_ptr_q] <= in_data_i;
                if (wr_ptr_q == LAST_PTR) begin
                    wr_ptr_q <= '0;
                end else begin
                    wr_ptr_q <= wr_ptr_q + 1'b1;
                end
            end

            if (fifo_pop) begin
                if (rd_ptr_q == LAST_PTR) begin
                    rd_ptr_q <= '0;
                end else begin
                    rd_ptr_q <= rd_ptr_q + 1'b1;
                end
            end

            unique case ({store_push, fifo_pop})
                2'b10: occ_q <= occ_q + 1'b1;
                2'b01: occ_q <= occ_q - 1'b1;
                default: occ_q <= occ_q;
            endcase
        end
    end

endmodule
