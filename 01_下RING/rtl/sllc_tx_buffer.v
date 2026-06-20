`timescale 1ns/1ps

module SLLC_TX_BUFFER #(
    // CHANNEL: 0=req, 1=rsp, 2=snp, 3=dat.
    parameter [1:0]   CHANNEL = 2'd1,
    parameter integer FLIT_W  = 128,
    parameter integer PLD_W   = FLIT_W
) (
    input                   clk,
    input                   rst_n,
    input                   dft_glb_gt_se,

    input                   sllc_utl_sky_rx,
    input                   sllc_phy_utl,
    input                   cfg_sky_rx_cbusy_rsp_en,

    input                   flitpend,
    input                   flitv,
    input  [FLIT_W -1:0]    flit,

    output                  tx_vld,
    output [PLD_W -1:0]     tx_pld,
    input                   sllc_tx_en,
    input                   phy_tx_crd_exist
);

    localparam integer FIFO_DEPTH = 4;
    localparam integer CBUSY_W    = 1;
    localparam integer CBUSY_LSB  = 0;

    wire                  fifo_push;
    wire                  fifo_pop;
    wire                  fifo_full;
    wire                  fifo_empty;
    wire [PLD_W -1:0]     fifo_dout;
    wire [PLD_W -1:0]     rx_pld;
    wire [PLD_W -1:0]     rx_pld_cbusy;
    wire                  downstream_fire;
    wire                  bypass_fire;

    // Normalize the incoming CHI flit width to the downstream payload width.
    generate
        if (PLD_W > FLIT_W) begin : gen_flit_extend
            assign rx_pld = {{(PLD_W-FLIT_W){1'b0}}, flit};
        end else if (PLD_W == FLIT_W) begin : gen_flit_equal
            assign rx_pld = flit;
        end else begin : gen_flit_truncate
            assign rx_pld = flit[PLD_W-1:0];
        end
    endgenerate

    // Downstream can see valid data only when credit exists.
    assign tx_vld          = phy_tx_crd_exist & (~fifo_empty | flitv);
    assign downstream_fire = tx_vld & sllc_tx_en;

    // Empty FIFO plus an accepting downstream forms the bypass path.
    assign bypass_fire     = fifo_empty & flitv & downstream_fire;

    assign fifo_push       = flitv & ~bypass_fire;
    assign fifo_pop        = ~fifo_empty & downstream_fire;

    // Replace cbusy before entering FIFO, so stored data and bypass data match.
    assign rx_pld_cbusy    = replace_cbusy(rx_pld);
    assign tx_pld          = fifo_empty ? rx_pld_cbusy : fifo_dout;

    sllc_tx_fifo #(
        .WIDTH (PLD_W),
        .DEPTH (FIFO_DEPTH)
    ) u_sllc_tx_fifo (
        .clk    (clk),
        .rst_n  (rst_n),
        .push   (fifo_push),
        .din    (rx_pld_cbusy),
        .pop    (fifo_pop),
        .dout   (fifo_dout),
        .full   (fifo_full),
        .empty  (fifo_empty)
    );

    function [PLD_W-1:0] replace_cbusy;
        input [PLD_W-1:0] in_pld;
        reg   [PLD_W-1:0] out_pld;
        reg   [CBUSY_W-1:0] flit_cbusy;
        reg   [CBUSY_W-1:0] sllc_cbusy;
        begin
            out_pld    = in_pld;
            flit_cbusy = in_pld[CBUSY_LSB +: CBUSY_W];
            sllc_cbusy = sllc_utl_sky_rx;

            if (cfg_sky_rx_cbusy_rsp_en) begin
                if (sllc_cbusy > flit_cbusy) begin
                    out_pld[CBUSY_LSB +: CBUSY_W] = sllc_cbusy;
                end
            end

            replace_cbusy = out_pld;
        end
    endfunction

    wire unused_inputs;
    assign unused_inputs = dft_glb_gt_se | sllc_phy_utl | flitpend | fifo_full |
                           CHANNEL[0] | CHANNEL[1];

endmodule
