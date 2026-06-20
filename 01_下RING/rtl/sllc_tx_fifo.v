`timescale 1ns/1ps

module sllc_tx_fifo #(
    parameter integer WIDTH = 128,
    parameter integer DEPTH = 4
) (
    input                   clk,
    input                   rst_n,
    input                   push,
    input  [WIDTH-1:0]      din,
    input                   pop,
    output [WIDTH-1:0]      dout,
    output                  full,
    output                  empty
);

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1) begin
                value = value >> 1;
            end
            clog2 = (i == 0) ? 1 : i;
        end
    endfunction

    localparam integer ADDR_W  = clog2(DEPTH);
    localparam integer COUNT_W = clog2(DEPTH + 1);

    reg [WIDTH-1:0]      mem [0:DEPTH-1];
    reg [ADDR_W-1:0]     wr_ptr;
    reg [ADDR_W-1:0]     rd_ptr;
    reg [COUNT_W-1:0]    count;

    wire                 do_pop;
    wire                 do_push;

    assign empty   = (count == {COUNT_W{1'b0}});
    assign full    = (count == DEPTH);

    // A simultaneous pop frees one entry, so a push is still accepted when full.
    assign do_pop  = pop & ~empty;
    assign do_push = push & (~full | do_pop);
    assign dout    = mem[rd_ptr];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {ADDR_W{1'b0}};
            rd_ptr <= {ADDR_W{1'b0}};
            count  <= {COUNT_W{1'b0}};
        end else begin
            if (do_push) begin
                mem[wr_ptr] <= din;
                if (wr_ptr == (DEPTH - 1)) begin
                    wr_ptr <= {ADDR_W{1'b0}};
                end else begin
                    wr_ptr <= wr_ptr + 1'b1;
                end
            end

            if (do_pop) begin
                if (rd_ptr == (DEPTH - 1)) begin
                    rd_ptr <= {ADDR_W{1'b0}};
                end else begin
                    rd_ptr <= rd_ptr + 1'b1;
                end
            end

            case ({do_push, do_pop})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
