// -----------------------------------------------------------------------------
// SIO NoC -> Clink packer
// -----------------------------------------------------------------------------
// Port rule:
//   Channel inputs are req/rsp/dat data, valid, and ready handshakes.
//   Channel outputs are clink_frame_o and its associated valid sidebands.
//
// Frame layout, low address to high address:
//   [44:0]    clink_reserved, 45 bit. No input port is provided, so this field
//             is driven to 0 in this module.
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
//   dat : fills the segment locations not occupied by req/rsp.
//
// dat length rule:
//   The dat input is 668 bit wide. A 604 bit dat packet must have
//   dat_i[667:604] driven to 0. With no explicit size sideband, this module
//   treats dat_i[667:604] == 0 as a 604 bit packet and otherwise as 668 bit.
//
// dat segment stream rule:
//   Accepted dat packets are concatenated into one ordered dat segment stream.
//   When the previous packet has only tail segments left, and a new dat packet
//   is accepted,
//   the current Clink frame may carry:
//
//       old_dat_tail_segments + new_dat_head_segments
//
//   in the same dat fragment area. A 668b packet occupies 13 segments and a
//   604b packet occupies 12 segments; padding inside the last segment belongs to
//   that packet and is not filled by the next packet. If RX needs to recover
//   original dat packet boundaries, dat_new_valid and dat_size_604 are carried
//   in frame_type.
//
// Timing note:
//   The internal dat segment stream buffer is organized as 16 lanes of 52 bit segment.
//   This is the minimum depth for the worst splice case: a 668b packet can leave
//   3 tail segments after a req+rsp+dat frame sends 10 segments, while the next
//   accepted 668b packet needs 13 segments. 3 + 13 = 16.
//   Dat never uses header_payload. Dat remaining length, capacity, and
//   ready are tracked in segment counts instead of bit counts to reduce control
//   width.
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

module sio_clink_pack (
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

    output var clink_frame_t clink_frame_o,
    output wire         clink_frame_vld_o,
    output wire         clink_req_vld_o,
    output wire         clink_rsp_vld_o,
    output wire         clink_dat_vld_o
);

    localparam integer SEGMENT_WIDTH   = 52;
    localparam integer DAT_BUF_SEG_NUM = 16;
    localparam integer DAT_BUF_WIDTH   = DAT_BUF_SEG_NUM * SEGMENT_WIDTH;
    localparam integer DAT_APPEND_PAD  = DAT_BUF_WIDTH - 668;
    localparam integer DAT_SHIFT_RQ_RS = 10 * SEGMENT_WIDTH;
    localparam integer DAT_SHIFT_RQ    = 11 * SEGMENT_WIDTH;
    localparam integer DAT_SHIFT_RS    = 13 * SEGMENT_WIDTH;
    localparam integer DAT_SHIFT_ONLY  = 14 * SEGMENT_WIDTH;

    localparam [5:0] DAT_SEG_604     = 6'd12;
    localparam [5:0] DAT_SEG_668     = 6'd13;
    localparam [5:0] DAT_CAP_RQ_RS   = 6'd10;
    localparam [5:0] DAT_CAP_RQ      = 6'd11;
    localparam [5:0] DAT_CAP_RS      = 6'd13;
    localparam [5:0] DAT_CAP_ONLY    = 6'd14;
    localparam [5:0] DAT_READY_LEVEL = DAT_BUF_SEG_NUM - 13; // 16 - 13

    reg  [DAT_BUF_WIDTH-1:0]     dat_stream_q;
    reg  [DAT_BUF_SEG_NUM-1:0]   dat_new_vld_q;
    reg  [DAT_BUF_SEG_NUM-1:0]   dat_size_604_q;
    reg  [5:0]                   dat_stream_seg_cnt_q;

    wire [5:0]                   dat_seg_i_w;
    wire                         dat_accept_w;
    wire [11:0]                  dat_append_shift_w;
    wire [DAT_BUF_WIDTH-1:0]     dat_append_w;
    wire [DAT_BUF_WIDTH-1:0]     dat_stream_pre_w;
    wire [DAT_BUF_SEG_NUM-1:0]   dat_new_vld_append_w;
    wire [DAT_BUF_SEG_NUM-1:0]   dat_size_604_append_w;
    wire [DAT_BUF_SEG_NUM-1:0]   dat_new_vld_pre_w;
    wire [DAT_BUF_SEG_NUM-1:0]   dat_size_604_pre_w;
    wire [5:0]                   dat_stream_pre_seg_cnt_w;
    wire [5:0]                   dat_cap_seg_w;
    wire                         dat_active_w;
    wire                         dat_new_vld_w;
    wire                         dat_size_604_w;
    wire [4:0]                   frame_type_w;
    wire                     dat_stream_remain_w;
    wire [5:0]               dat_stream_next_seg_cnt_w;
    reg  [DAT_BUF_WIDTH-1:0] dat_stream_shift_r;
    reg  [DAT_BUF_SEG_NUM-1:0] dat_new_vld_shift_r;
    reg  [DAT_BUF_SEG_NUM-1:0] dat_size_604_shift_r;
    reg  [13:0][SEGMENT_WIDTH-1:0] dat_window_r;
    reg                            dat_new_vld_r;
    reg                            dat_size_604_r;
    integer                  dat_seg_idx;

    // req/rsp have fixed one-frame locations and no internal buffering here.
    assign req_ready_o = 1'b1;
    assign rsp_ready_o = 1'b1;

    // See dat length rule above. Exact 668b packets whose high 64 bits are all
    // zero need an explicit size sideband outside this module.
    assign dat_seg_i_w = (dat_i[667:604] == 64'b0) ? DAT_SEG_604 : DAT_SEG_668;

    // Conservative ready: the buffer must have room for the largest dat packet
    // before accepting. The buffer itself is segment-organized: 16 * 52 bit.
    assign dat_ready_o  = (dat_stream_seg_cnt_q <= DAT_READY_LEVEL);
    assign dat_accept_w = dat_vld_i & dat_ready_o;

    assign dat_cap_seg_w =
        (req_vld_i && rsp_vld_i) ? DAT_CAP_RQ_RS :
        (req_vld_i)              ? DAT_CAP_RQ    :
        (rsp_vld_i)              ? DAT_CAP_RS    :
                                    DAT_CAP_ONLY;

    // Multiply segment count by 52 for the bit insertion position.
    // 52 = 32 + 16 + 4, keeping this as a narrow 6b-count expression.
    assign dat_append_shift_w =
        {1'b0, dat_stream_seg_cnt_q, 5'b0} +
        {2'b0, dat_stream_seg_cnt_q, 4'b0} +
        {4'b0, dat_stream_seg_cnt_q, 2'b0};
    assign dat_append_w = ({ {DAT_APPEND_PAD{1'b0}}, dat_i } << dat_append_shift_w);
    assign dat_stream_pre_w =
        dat_accept_w ? (dat_stream_q | dat_append_w) : dat_stream_q;
    assign dat_new_vld_append_w =
        dat_accept_w ? ({{(DAT_BUF_SEG_NUM-1){1'b0}}, 1'b1} << dat_stream_seg_cnt_q) :
                       {DAT_BUF_SEG_NUM{1'b0}};
    assign dat_size_604_append_w =
        (dat_accept_w && (dat_seg_i_w == DAT_SEG_604)) ?
        ({{(DAT_BUF_SEG_NUM-1){1'b0}}, 1'b1} << dat_stream_seg_cnt_q) :
        {DAT_BUF_SEG_NUM{1'b0}};
    assign dat_new_vld_pre_w =
        dat_accept_w ? (dat_new_vld_q | dat_new_vld_append_w) : dat_new_vld_q;
    assign dat_size_604_pre_w =
        dat_accept_w ? (dat_size_604_q | dat_size_604_append_w) : dat_size_604_q;
    assign dat_stream_pre_seg_cnt_w =
        dat_stream_seg_cnt_q + (dat_accept_w ? dat_seg_i_w : 6'd0);

    assign dat_active_w = (dat_stream_pre_seg_cnt_w != 6'd0);
    assign dat_stream_remain_w = dat_active_w && (dat_stream_pre_seg_cnt_w > dat_cap_seg_w);
    assign dat_stream_next_seg_cnt_w =
        dat_stream_remain_w ? (dat_stream_pre_seg_cnt_w - dat_cap_seg_w) : 6'd0;

    assign dat_new_vld_w     = dat_active_w & dat_new_vld_r;
    assign dat_size_604_w    = dat_new_vld_w & dat_size_604_r;

    // frame_type is also written into header_payload[26:22] below.
    assign frame_type_w      = {req_vld_i, rsp_vld_i, dat_active_w,
                                dat_new_vld_w, dat_size_604_w};
    assign clink_req_vld_o   = frame_type_w[4];
    assign clink_rsp_vld_o   = frame_type_w[3];
    assign clink_dat_vld_o   = frame_type_w[2];
    assign clink_frame_vld_o = req_vld_i | rsp_vld_i | dat_active_w;

    always @* begin
        case (dat_cap_seg_w)
            DAT_CAP_RQ_RS: begin
                dat_stream_shift_r = dat_stream_pre_w >> DAT_SHIFT_RQ_RS;
                dat_new_vld_shift_r = dat_new_vld_pre_w >> DAT_CAP_RQ_RS;
                dat_size_604_shift_r = dat_size_604_pre_w >> DAT_CAP_RQ_RS;
            end
            DAT_CAP_RQ: begin
                dat_stream_shift_r = dat_stream_pre_w >> DAT_SHIFT_RQ;
                dat_new_vld_shift_r = dat_new_vld_pre_w >> DAT_CAP_RQ;
                dat_size_604_shift_r = dat_size_604_pre_w >> DAT_CAP_RQ;
            end
            DAT_CAP_RS: begin
                dat_stream_shift_r = dat_stream_pre_w >> DAT_SHIFT_RS;
                dat_new_vld_shift_r = dat_new_vld_pre_w >> DAT_CAP_RS;
                dat_size_604_shift_r = dat_size_604_pre_w >> DAT_CAP_RS;
            end
            default: begin
                dat_stream_shift_r = dat_stream_pre_w >> DAT_SHIFT_ONLY;
                dat_new_vld_shift_r = dat_new_vld_pre_w >> DAT_CAP_ONLY;
                dat_size_604_shift_r = dat_size_604_pre_w >> DAT_CAP_ONLY;
            end
        endcase
    end

    always @* begin
        // dat_window_r is the next contiguous dat fragment window, organized
        // directly as 14 segment lanes.
        for (dat_seg_idx = 0; dat_seg_idx < 14; dat_seg_idx = dat_seg_idx + 1) begin
            dat_window_r[dat_seg_idx] =
                dat_stream_pre_w[dat_seg_idx*SEGMENT_WIDTH +: SEGMENT_WIDTH];
        end

        dat_new_vld_r  = 1'b0;
        dat_size_604_r = 1'b0;
        for (dat_seg_idx = 0; dat_seg_idx < 14; dat_seg_idx = dat_seg_idx + 1) begin
            if ((dat_seg_idx < dat_cap_seg_w) && dat_new_vld_pre_w[dat_seg_idx]) begin
                dat_new_vld_r  = 1'b1;
                dat_size_604_r = dat_size_604_pre_w[dat_seg_idx];
            end
        end
    end

    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            dat_stream_q           <= {DAT_BUF_WIDTH{1'b0}};
            dat_new_vld_q          <= {DAT_BUF_SEG_NUM{1'b0}};
            dat_size_604_q         <= {DAT_BUF_SEG_NUM{1'b0}};
            dat_stream_seg_cnt_q   <= 6'd0;
        end else if (dat_stream_remain_w) begin
            dat_stream_q           <= dat_stream_shift_r;
            dat_new_vld_q          <= dat_new_vld_shift_r;
            dat_size_604_q         <= dat_size_604_shift_r;
            dat_stream_seg_cnt_q   <= dat_stream_next_seg_cnt_w;
        end else begin
            dat_stream_q           <= {DAT_BUF_WIDTH{1'b0}};
            dat_new_vld_q          <= {DAT_BUF_SEG_NUM{1'b0}};
            dat_size_604_q         <= {DAT_BUF_SEG_NUM{1'b0}};
            dat_stream_seg_cnt_q   <= 6'd0;
        end
    end

    always @* begin
        // Default unused frame bits to zero, including clink_reserved[44:0].
        clink_frame_o = '0;

        // Explicit in-frame format marker. header_payload[21:20] remains free
        // for future metadata or is zero when unused.
        clink_frame_o.header_payload[26:22] = frame_type_w;

        // ---------------------------------------------------------------------
        // req fixed at segment[0:2] + header_payload[19:18].
        // This uses the shared header to avoid segment-local req padding.
        // ---------------------------------------------------------------------
        if (req_vld_i) begin
            clink_frame_o.segment[0] = req_i[51:0];
            clink_frame_o.segment[1] = req_i[103:52];
            clink_frame_o.segment[2] = req_i[155:104];
            clink_frame_o.header_payload[19:18] = req_i[157:156];
        end

        // ---------------------------------------------------------------------
        // rsp fixed at segment[3] + header_payload[17:0].
        // Fill segment[3] first, then use 18 bits of header_payload.
        // header_payload[21:20] is left for other use; here it remains 0.
        // ---------------------------------------------------------------------
        if (rsp_vld_i) begin
            clink_frame_o.segment[3]             = rsp_i[51:0];
            clink_frame_o.header_payload[17:0]   = rsp_i[69:52];
        end

        // ---------------------------------------------------------------------
        // dat fragment placement. dat_window_r[0] is the next unsent dat
        // segment lane. If one packet tail and the next packet head both fit,
        // they are packed back-to-back at segment granularity.
        // ---------------------------------------------------------------------
        if (dat_active_w) begin
            if (req_vld_i && rsp_vld_i) begin
                // req + rsp + dat:
                // dat uses segment[4:13], max 520 bit in this frame.
                clink_frame_o.segment[4]  = dat_window_r[0];
                clink_frame_o.segment[5]  = dat_window_r[1];
                clink_frame_o.segment[6]  = dat_window_r[2];
                clink_frame_o.segment[7]  = dat_window_r[3];
                clink_frame_o.segment[8]  = dat_window_r[4];
                clink_frame_o.segment[9]  = dat_window_r[5];
                clink_frame_o.segment[10] = dat_window_r[6];
                clink_frame_o.segment[11] = dat_window_r[7];
                clink_frame_o.segment[12] = dat_window_r[8];
                clink_frame_o.segment[13] = dat_window_r[9];
            end else if (req_vld_i) begin
                // req + dat:
                // dat uses segment[3:13], max 572 bit in this frame.
                clink_frame_o.segment[3]  = dat_window_r[0];
                clink_frame_o.segment[4]  = dat_window_r[1];
                clink_frame_o.segment[5]  = dat_window_r[2];
                clink_frame_o.segment[6]  = dat_window_r[3];
                clink_frame_o.segment[7]  = dat_window_r[4];
                clink_frame_o.segment[8]  = dat_window_r[5];
                clink_frame_o.segment[9]  = dat_window_r[6];
                clink_frame_o.segment[10] = dat_window_r[7];
                clink_frame_o.segment[11] = dat_window_r[8];
                clink_frame_o.segment[12] = dat_window_r[9];
                clink_frame_o.segment[13] = dat_window_r[10];
            end else if (rsp_vld_i) begin
                // rsp + dat:
                // dat uses segment[0:2] and segment[4:13], max 676 bit.
                clink_frame_o.segment[0]  = dat_window_r[0];
                clink_frame_o.segment[1]  = dat_window_r[1];
                clink_frame_o.segment[2]  = dat_window_r[2];
                clink_frame_o.segment[4]  = dat_window_r[3];
                clink_frame_o.segment[5]  = dat_window_r[4];
                clink_frame_o.segment[6]  = dat_window_r[5];
                clink_frame_o.segment[7]  = dat_window_r[6];
                clink_frame_o.segment[8]  = dat_window_r[7];
                clink_frame_o.segment[9]  = dat_window_r[8];
                clink_frame_o.segment[10] = dat_window_r[9];
                clink_frame_o.segment[11] = dat_window_r[10];
                clink_frame_o.segment[12] = dat_window_r[11];
                clink_frame_o.segment[13] = dat_window_r[12];
            end else begin
                // dat only:
                // dat uses segment[0:13], max 728 bit in this frame.
                clink_frame_o.segment[0]  = dat_window_r[0];
                clink_frame_o.segment[1]  = dat_window_r[1];
                clink_frame_o.segment[2]  = dat_window_r[2];
                clink_frame_o.segment[3]  = dat_window_r[3];
                clink_frame_o.segment[4]  = dat_window_r[4];
                clink_frame_o.segment[5]  = dat_window_r[5];
                clink_frame_o.segment[6]  = dat_window_r[6];
                clink_frame_o.segment[7]  = dat_window_r[7];
                clink_frame_o.segment[8]  = dat_window_r[8];
                clink_frame_o.segment[9]  = dat_window_r[9];
                clink_frame_o.segment[10] = dat_window_r[10];
                clink_frame_o.segment[11] = dat_window_r[11];
                clink_frame_o.segment[12] = dat_window_r[12];
                clink_frame_o.segment[13] = dat_window_r[13];
            end
        end
    end

endmodule
