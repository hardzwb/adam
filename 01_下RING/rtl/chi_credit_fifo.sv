`timescale 1ns/1ps

module CHI_CREDIT_FIFO #(
    parameter int DATA_W = 128,
    parameter int DEPTH  = 4
) (
    input  logic                 clk,
    input  logic                 rst_n,

    input  logic                 in_vld_i,
    input  logic [DATA_W-1:0]    in_data_i,
    output logic                 credit_o,
    output logic                 overflow_o,

    output logic                 out_vld_o,
    output logic [DATA_W-1:0]    out_data_o,
    input  logic                 out_rdy_i
);

    localparam int PTR_W   = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
    localparam int COUNT_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH + 1);
    localparam logic [COUNT_W-1:0] DEPTH_VALUE = COUNT_W'(DEPTH);
    localparam logic [PTR_W-1:0]   LAST_PTR    = PTR_W'(DEPTH - 1);

    function automatic logic [PTR_W-1:0] ptr_next(input logic [PTR_W-1:0] ptr);
        if (ptr == LAST_PTR) begin
            ptr_next = '0;
        end else begin
            ptr_next = ptr + 1'b1;
        end
    endfunction

    logic [DATA_W-1:0] mem_q [0:DEPTH-1];
    logic [PTR_W-1:0]  rd_ptr_q;
    logic [PTR_W-1:0]  wr_ptr_q;
    logic [COUNT_W-1:0] occ_q;
    logic [COUNT_W-1:0] credit_cnt_q;
    logic [COUNT_W-1:0] credit_cnt_d;

    logic fifo_empty_w;
    logic fifo_full_w;
    logic bypass_xfer_w;
    logic push_entry_w;
    logic pop_entry_w;
    logic accept_input_w;
    logic accept_output_w;
    logic issue_credit_w;

    assign fifo_empty_w = (occ_q == '0);
    assign fifo_full_w  = (occ_q == DEPTH_VALUE);

    assign out_vld_o  = fifo_empty_w ? in_vld_i : 1'b1;
    assign out_data_o = fifo_empty_w ? in_data_i : mem_q[rd_ptr_q];

    assign accept_output_w = out_vld_o && out_rdy_i;
    assign bypass_xfer_w   = fifo_empty_w && in_vld_i && out_rdy_i;
    assign pop_entry_w     = !fifo_empty_w && out_rdy_i;
    assign accept_input_w  = in_vld_i && (!fifo_full_w || pop_entry_w || bypass_xfer_w);
    assign push_entry_w    = accept_input_w && !bypass_xfer_w;
    assign issue_credit_w  = (credit_cnt_q != '0);

    always_comb begin
        credit_cnt_d = credit_cnt_q;

        if (issue_credit_w) begin
            credit_cnt_d = credit_cnt_q - 1'b1;
        end

        if (accept_output_w && (credit_cnt_d != DEPTH_VALUE)) begin
            credit_cnt_d = credit_cnt_d + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_q     <= '0;
            wr_ptr_q     <= '0;
            occ_q        <= '0;
            credit_cnt_q <= DEPTH_VALUE;
            credit_o     <= 1'b0;
            overflow_o   <= 1'b0;
        end else begin
            credit_cnt_q <= credit_cnt_d;
            credit_o     <= issue_credit_w;
            overflow_o   <= in_vld_i && fifo_full_w && !pop_entry_w && !bypass_xfer_w;

            if (push_entry_w) begin
                mem_q[wr_ptr_q] <= in_data_i;
                wr_ptr_q <= ptr_next(wr_ptr_q);
            end

            if (pop_entry_w) begin
                rd_ptr_q <= ptr_next(rd_ptr_q);
            end

            if (push_entry_w && !pop_entry_w) begin
                occ_q <= occ_q + 1'b1;
            end else if (!push_entry_w && pop_entry_w) begin
                occ_q <= occ_q - 1'b1;
            end
        end
    end

endmodule
