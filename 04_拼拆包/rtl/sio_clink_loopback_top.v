// -----------------------------------------------------------------------------
// SIO NoC -> Clink -> NoC loopback top
// -----------------------------------------------------------------------------
// This wrapper connects the packer directly to the unpacker for integration
// checks. The packer has no Clink-side ready input, so this top assumes the
// unpacker side can accept every generated Clink frame.
// -----------------------------------------------------------------------------

`timescale 1ns/1ps

`ifndef SIO_CLINK_FRAME_T_DEFINED
`define SIO_CLINK_FRAME_T_DEFINED
typedef struct packed {
    logic [13:0][51:0] segment;
    logic [26:0]       header_payload;
    logic [44:0]       clink_reserved;
} clink_frame_t;
`endif

module sio_clink_loopback_top (
    input  wire         clk_i,
    input  wire         rst_n_i,

    input  wire [157:0] req_i,
    input  wire         req_vld_i,
    output wire         req_ready_o,

    input  wire [69:0]  rsp_i,
    input  wire         rsp_vld_i,
    output wire         rsp_ready_o,

    input  wire [667:0] dat_i,
    input  wire         dat_vld_i,
    output wire         dat_ready_o,

    output wire [157:0] req_o,
    output wire         req_vld_o,
    input  wire         req_ready_i,

    output wire [69:0]  rsp_o,
    output wire         rsp_vld_o,
    input  wire         rsp_ready_i,

    output wire [667:0] dat_o,
    output wire         dat_vld_o,
    input  wire         dat_ready_i,
    output wire         dat_size_604_o,

    output wire [4:0]   frame_type_o,
    output wire [44:0]  clink_reserved_o,
    output wire         dat_meta_err_o,
    output wire         dat_overflow_err_o,

    output wire         clink_frame_vld_o,
    output wire         clink_frame_ready_o
);

    clink_frame_t clink_frame_w;
    wire          clink_req_vld_w;
    wire          clink_rsp_vld_w;
    wire          clink_dat_vld_w;

    sio_clink_pack u_pack (
        .clk_i             (clk_i),
        .rst_n_i           (rst_n_i),

        .req_i             (req_i),
        .req_vld_i         (req_vld_i),
        .req_ready_o       (req_ready_o),

        .rsp_i             (rsp_i),
        .rsp_vld_i         (rsp_vld_i),
        .rsp_ready_o       (rsp_ready_o),

        .dat_i             (dat_i),
        .dat_vld_i         (dat_vld_i),
        .dat_ready_o       (dat_ready_o),

        .clink_frame_o     (clink_frame_w),
        .clink_frame_vld_o (clink_frame_vld_o),
        .clink_req_vld_o   (clink_req_vld_w),
        .clink_rsp_vld_o   (clink_rsp_vld_w),
        .clink_dat_vld_o   (clink_dat_vld_w)
    );

    sio_clink_unpack u_unpack (
        .clk_i               (clk_i),
        .rst_n_i             (rst_n_i),

        .clink_frame_vld_i   (clink_frame_vld_o),
        .clink_frame_ready_o (clink_frame_ready_o),
        .clink_frame_i       (clink_frame_w),

        .req_o               (req_o),
        .req_vld_o           (req_vld_o),
        .req_ready_i         (req_ready_i),

        .rsp_o               (rsp_o),
        .rsp_vld_o           (rsp_vld_o),
        .rsp_ready_i         (rsp_ready_i),

        .dat_o               (dat_o),
        .dat_vld_o           (dat_vld_o),
        .dat_ready_i         (dat_ready_i),
        .dat_size_604_o      (dat_size_604_o),

        .frame_type_o        (frame_type_o),
        .clink_reserved_o    (clink_reserved_o),
        .dat_meta_err_o      (dat_meta_err_o),
        .dat_overflow_err_o  (dat_overflow_err_o)
    );

endmodule
