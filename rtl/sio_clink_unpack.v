// -----------------------------------------------------------------------------
// SIO Clink -> NoC unpacker
// -----------------------------------------------------------------------------
// Port rule:
//   One accepted Clink frame may produce req, rsp, and one dat fragment update.
//   The frame is consumed only when all valid output channels can accept the
//   data that belongs to that frame.
//
// Frame layout, low address to high address:
//   [44:0]    clink_reserved, 45 bit
//   [71:45]   header_payload, 27 bit
//   [123:72]  segment[0], 52 bit
//   ...
//   [799:748] segment[13], 52 bit
//
// Fixed channel locations:
//   req : segment[0:2] + header_payload[19:18].
//   rsp : segment[3] + header_payload[17:0].
//   frame_type : header_payload[26:22] =
//                {req_valid, rsp_valid, dat_valid, dat_new_valid, dat_size_604}.
//   dat : extracted from the segment locations not occupied by req/rsp.
//
// dat metadata rule:
//   clink_reserved does not carry dat boundaries. frame_type[1] marks that a
//   new dat packet starts in the current accepted dat segment window, and
//   frame_type[0] gives the size of that new packet. The unpacker stores this
//   size and decides completion itself after collecting 12 segments for a 604b
//   packet or 13 segments for a 668b packet.
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

module sio_clink_unpack (
    input  wire         clk_i,
    input  wire         rst_n_i,

    input  wire         clink_frame_vld_i,
    output wire         clink_frame_ready_o,
    input  clink_frame_t      clink_frame_i,

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
    output wire         dat_overflow_err_o
);

    localparam integer SEGMENT_WIDTH   = 52;
    localparam integer SEGMENT_NUM     = 14;
    localparam integer DAT_BUF_SEG_NUM = 13;

    localparam [3:0] DAT_SEG_604   = 4'd12;
    localparam [3:0] DAT_SEG_668   = 4'd13;
    localparam [3:0] DAT_CAP_RQ_RS = 4'd10;
    localparam [3:0] DAT_CAP_RQ    = 4'd11;
    localparam [3:0] DAT_CAP_RS    = 4'd13;
    localparam [3:0] DAT_CAP_ONLY  = 4'd14;

    wire [4:0] frame_type_w;
    wire       frame_req_vld_w;
    wire       frame_rsp_vld_w;
    wire       frame_dat_vld_w;
    wire       frame_dat_new_vld_w;
    wire       frame_dat_size_604_w;
    wire       req_can_accept_w;
    wire       rsp_can_accept_w;
    wire       dat_can_accept_w;
    wire       frame_accept_w;
    wire       dat_out_busy_w;
    wire [3:0] dat_cap_seg_w;
    wire [3:0] dat_new_packet_seg_num_w;
    wire [3:0] dat_active_packet_seg_num_w;

    reg  [SEGMENT_NUM-1:0][SEGMENT_WIDTH-1:0]     dat_window_r;
    reg  [DAT_BUF_SEG_NUM-1:0][SEGMENT_WIDTH-1:0] dat_asm_q;
    reg  [DAT_BUF_SEG_NUM-1:0][SEGMENT_WIDTH-1:0] dat_asm_next_r;
    reg  [DAT_BUF_SEG_NUM-1:0][SEGMENT_WIDTH-1:0] dat_out_segment_q;
    reg  [4:0]                                    dat_asm_seg_cnt_q;
    reg  [4:0]                                    dat_asm_seg_cnt_next_r;
    reg                                           dat_pkt_active_q;
    reg                                           dat_pkt_active_next_r;
    reg                                           dat_pkt_size_604_q;
    reg                                           dat_pkt_size_604_next_r;
    reg                                           dat_out_vld_q;
    reg                                           dat_out_size_604_q;
    reg                                           dat_complete_next_r;
    reg                                           dat_complete_size_604_next_r;
    reg  [DAT_BUF_SEG_NUM-1:0][SEGMENT_WIDTH-1:0] dat_complete_segment_next_r;

    integer dat_seg_idx;
    integer dat_copy_idx;
    integer dat_current_remaining_i;
    integer dat_take_i;
    integer dat_leftover_i;
    integer dat_new_packet_seg_num_i;

    assign frame_type_w           = clink_frame_i.header_payload[26:22];
    assign frame_req_vld_w        = frame_type_w[4];
    assign frame_rsp_vld_w        = frame_type_w[3];
    assign frame_dat_vld_w        = frame_type_w[2];
    assign frame_dat_new_vld_w    = frame_type_w[1];
    assign frame_dat_size_604_w   = frame_type_w[0];
    assign frame_type_o       = frame_type_w;
    assign clink_reserved_o   = clink_frame_i.clink_reserved;

    assign req_o = {
        clink_frame_i.header_payload[19:18],
        clink_frame_i.segment[2],
        clink_frame_i.segment[1],
        clink_frame_i.segment[0]
    };
    assign rsp_o = {
        clink_frame_i.header_payload[17:0],
        clink_frame_i.segment[3]
    };

    assign req_vld_o = clink_frame_vld_i & frame_req_vld_w;
    assign rsp_vld_o = clink_frame_vld_i & frame_rsp_vld_w;

    assign req_can_accept_w = !frame_req_vld_w || req_ready_i;
    assign rsp_can_accept_w = !frame_rsp_vld_w || rsp_ready_i;

    assign dat_cap_seg_w =
        (frame_req_vld_w && frame_rsp_vld_w) ? DAT_CAP_RQ_RS :
        (frame_req_vld_w)                    ? DAT_CAP_RQ    :
        (frame_rsp_vld_w)                    ? DAT_CAP_RS    :
                                                DAT_CAP_ONLY;

    assign dat_new_packet_seg_num_w =
        frame_dat_size_604_w ? DAT_SEG_604 : DAT_SEG_668;
    assign dat_active_packet_seg_num_w =
        dat_pkt_size_604_q ? DAT_SEG_604 : DAT_SEG_668;
    assign dat_out_busy_w = dat_out_vld_q && !dat_ready_i;

    assign dat_can_accept_w = !frame_dat_vld_w || !dat_out_busy_w;
    assign clink_frame_ready_o =
        req_can_accept_w &&
        rsp_can_accept_w &&
        dat_can_accept_w;
    assign frame_accept_w = clink_frame_vld_i & clink_frame_ready_o;

    assign dat_o = {
        dat_out_segment_q[12][43:0],
        dat_out_segment_q[11],
        dat_out_segment_q[10],
        dat_out_segment_q[9],
        dat_out_segment_q[8],
        dat_out_segment_q[7],
        dat_out_segment_q[6],
        dat_out_segment_q[5],
        dat_out_segment_q[4],
        dat_out_segment_q[3],
        dat_out_segment_q[2],
        dat_out_segment_q[1],
        dat_out_segment_q[0]
    };
    assign dat_vld_o       = dat_out_vld_q;
    assign dat_size_604_o  = dat_out_size_604_q;
    assign dat_meta_err_o  = 1'b0;
    assign dat_overflow_err_o = 1'b0;

    always @* begin
        for (dat_seg_idx = 0; dat_seg_idx < SEGMENT_NUM; dat_seg_idx = dat_seg_idx + 1) begin
            dat_window_r[dat_seg_idx] = {SEGMENT_WIDTH{1'b0}};
        end

        case (frame_type_w[4:2])
            3'b001: begin
                dat_window_r[0]  = clink_frame_i.segment[0];
                dat_window_r[1]  = clink_frame_i.segment[1];
                dat_window_r[2]  = clink_frame_i.segment[2];
                dat_window_r[3]  = clink_frame_i.segment[3];
                dat_window_r[4]  = clink_frame_i.segment[4];
                dat_window_r[5]  = clink_frame_i.segment[5];
                dat_window_r[6]  = clink_frame_i.segment[6];
                dat_window_r[7]  = clink_frame_i.segment[7];
                dat_window_r[8]  = clink_frame_i.segment[8];
                dat_window_r[9]  = clink_frame_i.segment[9];
                dat_window_r[10] = clink_frame_i.segment[10];
                dat_window_r[11] = clink_frame_i.segment[11];
                dat_window_r[12] = clink_frame_i.segment[12];
                dat_window_r[13] = clink_frame_i.segment[13];
            end
            3'b011: begin
                dat_window_r[0]  = clink_frame_i.segment[0];
                dat_window_r[1]  = clink_frame_i.segment[1];
                dat_window_r[2]  = clink_frame_i.segment[2];
                dat_window_r[3]  = clink_frame_i.segment[4];
                dat_window_r[4]  = clink_frame_i.segment[5];
                dat_window_r[5]  = clink_frame_i.segment[6];
                dat_window_r[6]  = clink_frame_i.segment[7];
                dat_window_r[7]  = clink_frame_i.segment[8];
                dat_window_r[8]  = clink_frame_i.segment[9];
                dat_window_r[9]  = clink_frame_i.segment[10];
                dat_window_r[10] = clink_frame_i.segment[11];
                dat_window_r[11] = clink_frame_i.segment[12];
                dat_window_r[12] = clink_frame_i.segment[13];
            end
            3'b101: begin
                dat_window_r[0]  = clink_frame_i.segment[3];
                dat_window_r[1]  = clink_frame_i.segment[4];
                dat_window_r[2]  = clink_frame_i.segment[5];
                dat_window_r[3]  = clink_frame_i.segment[6];
                dat_window_r[4]  = clink_frame_i.segment[7];
                dat_window_r[5]  = clink_frame_i.segment[8];
                dat_window_r[6]  = clink_frame_i.segment[9];
                dat_window_r[7]  = clink_frame_i.segment[10];
                dat_window_r[8]  = clink_frame_i.segment[11];
                dat_window_r[9]  = clink_frame_i.segment[12];
                dat_window_r[10] = clink_frame_i.segment[13];
            end
            3'b111: begin
                dat_window_r[0]  = clink_frame_i.segment[4];
                dat_window_r[1]  = clink_frame_i.segment[5];
                dat_window_r[2]  = clink_frame_i.segment[6];
                dat_window_r[3]  = clink_frame_i.segment[7];
                dat_window_r[4]  = clink_frame_i.segment[8];
                dat_window_r[5]  = clink_frame_i.segment[9];
                dat_window_r[6]  = clink_frame_i.segment[10];
                dat_window_r[7]  = clink_frame_i.segment[11];
                dat_window_r[8]  = clink_frame_i.segment[12];
                dat_window_r[9]  = clink_frame_i.segment[13];
            end
            default: begin
                // No dat fragment for this frame_type.
            end
        endcase
    end

    always @* begin
        dat_asm_next_r                = dat_asm_q;
        dat_asm_seg_cnt_next_r        = dat_asm_seg_cnt_q;
        dat_pkt_active_next_r         = dat_pkt_active_q;
        dat_pkt_size_604_next_r       = dat_pkt_size_604_q;
        dat_complete_next_r           = 1'b0;
        dat_complete_size_604_next_r  = dat_pkt_size_604_q;
        dat_complete_segment_next_r   = dat_asm_q;

        dat_current_remaining_i = 0;
        dat_take_i              = 0;
        dat_leftover_i          = 0;
        dat_new_packet_seg_num_i = dat_new_packet_seg_num_w;

        if (frame_dat_vld_w) begin
            if (dat_pkt_active_q) begin
                dat_current_remaining_i =
                    dat_active_packet_seg_num_w - dat_asm_seg_cnt_q;
                dat_take_i = (dat_cap_seg_w < dat_current_remaining_i) ?
                             dat_cap_seg_w : dat_current_remaining_i;

                for (dat_copy_idx = 0; dat_copy_idx < DAT_BUF_SEG_NUM; dat_copy_idx = dat_copy_idx + 1) begin
                    if (dat_copy_idx < dat_take_i) begin
                        dat_asm_next_r[dat_asm_seg_cnt_q + dat_copy_idx] =
                            dat_window_r[dat_copy_idx];
                    end
                end
                dat_asm_seg_cnt_next_r = dat_asm_seg_cnt_q + dat_take_i;

                if (dat_take_i == dat_current_remaining_i) begin
                    dat_complete_next_r          = 1'b1;
                    dat_complete_size_604_next_r = dat_pkt_size_604_q;
                    dat_complete_segment_next_r  = dat_asm_next_r;

                    for (dat_copy_idx = 0; dat_copy_idx < DAT_BUF_SEG_NUM; dat_copy_idx = dat_copy_idx + 1) begin
                        dat_asm_next_r[dat_copy_idx] = {SEGMENT_WIDTH{1'b0}};
                    end
                    dat_asm_seg_cnt_next_r  = 5'd0;
                    dat_pkt_active_next_r   = 1'b0;
                    dat_leftover_i          = dat_cap_seg_w - dat_current_remaining_i;

                    if (dat_leftover_i != 0 && frame_dat_new_vld_w) begin
                        for (dat_copy_idx = 0; dat_copy_idx < DAT_BUF_SEG_NUM; dat_copy_idx = dat_copy_idx + 1) begin
                            if (dat_copy_idx < dat_leftover_i) begin
                                dat_asm_next_r[dat_copy_idx] =
                                    dat_window_r[dat_current_remaining_i + dat_copy_idx];
                            end
                        end
                        dat_asm_seg_cnt_next_r  = dat_leftover_i;
                        dat_pkt_active_next_r   = 1'b1;
                        dat_pkt_size_604_next_r = frame_dat_size_604_w;
                    end
                end
            end else begin
                dat_take_i = (dat_cap_seg_w < dat_new_packet_seg_num_i) ?
                             dat_cap_seg_w : dat_new_packet_seg_num_i;

                for (dat_copy_idx = 0; dat_copy_idx < DAT_BUF_SEG_NUM; dat_copy_idx = dat_copy_idx + 1) begin
                    dat_asm_next_r[dat_copy_idx] = {SEGMENT_WIDTH{1'b0}};
                    if (dat_copy_idx < dat_take_i) begin
                        dat_asm_next_r[dat_copy_idx] = dat_window_r[dat_copy_idx];
                    end
                end
                dat_asm_seg_cnt_next_r  = dat_take_i;
                dat_pkt_active_next_r   = 1'b1;
                dat_pkt_size_604_next_r = frame_dat_size_604_w;

                if (dat_take_i == dat_new_packet_seg_num_i) begin
                    dat_complete_next_r          = 1'b1;
                    dat_complete_size_604_next_r = frame_dat_size_604_w;
                    dat_complete_segment_next_r  = dat_asm_next_r;

                    for (dat_copy_idx = 0; dat_copy_idx < DAT_BUF_SEG_NUM; dat_copy_idx = dat_copy_idx + 1) begin
                        dat_asm_next_r[dat_copy_idx] = {SEGMENT_WIDTH{1'b0}};
                    end
                    dat_asm_seg_cnt_next_r = 5'd0;
                    dat_pkt_active_next_r  = 1'b0;
                end
            end
        end
    end

    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            dat_asm_q             <= '0;
            dat_asm_seg_cnt_q     <= 5'd0;
            dat_pkt_active_q      <= 1'b0;
            dat_pkt_size_604_q    <= 1'b0;
            dat_out_segment_q     <= '0;
            dat_out_vld_q         <= 1'b0;
            dat_out_size_604_q    <= 1'b0;
        end else begin
            if (dat_out_vld_q && dat_ready_i) begin
                dat_out_vld_q <= 1'b0;
            end

            if (frame_accept_w && frame_dat_vld_w) begin
                dat_asm_q          <= dat_asm_next_r;
                dat_asm_seg_cnt_q  <= dat_asm_seg_cnt_next_r;
                dat_pkt_active_q   <= dat_pkt_active_next_r;
                dat_pkt_size_604_q <= dat_pkt_size_604_next_r;

                if (dat_complete_next_r) begin
                    dat_out_segment_q    <= dat_complete_segment_next_r;
                    dat_out_vld_q        <= 1'b1;
                    dat_out_size_604_q   <= dat_complete_size_604_next_r;
                end
            end
        end
    end

endmodule
