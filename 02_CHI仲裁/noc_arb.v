module NOC_ARB #(
    parameter FIFO_DEPTH = 4
) (
    input wire clk
   ,input wire rst_n

    //noc0
   ,output wire txsactive0
   ,input  wire rxsactive0
   ,output wire txlinkactivereq0
   ,input  wire txlinkactiveack0
   ,input wire  rxlinkactivereq0
   ,output wire rxlinkactiveack0

   ,output wire txreqflitpend0
   ,output wire txreqflitv0
   ,output wire txreqflit0
   ,output wire txreqflitpatag0
   ,input wire txreqlcrdv0
   ,output wire txreqretlcrdv0
   ,output wire txreqnocinfo0
   ,output wire txreqpush0
   ,input wire rxreqflitpend0
   ,input wire rxreqflitv0
   ,input wire rxreqflit0
   ,input wire rxreqflitpatag0
   ,output wire rxreqlcrdv0
   ,input wire rxreqretlcrdv0
   ,input wire rxreqhint0

    //noc1
   ,output wire txsactive1
   ,input  wire rxsactive1
   ,output wire txlinkactivereq1
   ,input  wire txlinkactiveack1
   ,input wire  rxlinkactivereq1
   ,output wire rxlinkactiveack1

   ,output wire txreqflitpend1
   ,output wire txreqflitv1
   ,output wire txreqflit1
   ,output wire txreqflitpatag1
   ,input wire txreqlcrdv1
   ,output wire txreqretlcrdv1
   ,output wire txreqnocinfo1
   ,output wire txreqpush1
   ,input wire rxreqflitpend1
   ,input wire rxreqflitv1
   ,input wire rxreqflit1
   ,input wire rxreqflitpatag1
   ,output wire rxreqlcrdv1
   ,input wire rxreqretlcrdv1
   ,input wire rxreqhint1

   //sllc
   ,input wire txsactive
   ,output wire rxsactive
   ,input wire txlinkactivereq
   ,output wire txlinkactiveack
   ,output wire rxlinkactivereq
   ,input wire rxlinkactiveack

   ,input wire txreqflitpend
   ,input wire txreqflitv
   ,input wire txreqflit
   ,input wire txreqflitpatag
   ,output wire txreqlcrdv
   ,input wire txreqretlcrdv
   ,input wire txreqnocinfo
   ,input wire txreqpush
   ,output wire rxreqflitpend
   ,output wire rxreqflitv
   ,output wire rxreqflit
   ,output wire rxreqflitpatag
   ,input wire rxreqlcrdv
   ,output wire rxreqretlcrdv
   ,output wire rxreqhint

);

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1) begin
                value = value >> 1;
            end
            clog2 = i;
        end
    endfunction

    localparam FIFO_CNT_W = clog2(FIFO_DEPTH + 1);
    localparam [FIFO_CNT_W-1:0] FIFO_DEPTH_COUNT = FIFO_DEPTH;

    wire req_grant0;
    wire req_grant1;
    wire rx_link_active0;
    wire rx_link_active1;
    wire tx_link_active0;
    wire tx_link_active1;
    wire rx_down_link_active;
    wire link_rx_hold0;
    wire link_rx_hold1;
    wire link_rx_hold_sllc;
    wire link_tx_return0;
    wire link_tx_return1;
    wire link_tx_return_sllc;
    wire link_tx_receive0;
    wire link_tx_receive1;
    wire link_tx_receive_sllc;
    wire link_tx_enable0;
    wire link_tx_enable1;
    wire link_tx_enable_sllc;
    wire fifo0_empty;
    wire fifo1_empty;
    wire fifo0_full;
    wire fifo1_full;
    wire downstream_credit_avail;
    wire downstream_req_pop_enable;
    wire req_send0;
    wire req_send1;
    wire fifo0_flitpend;
    wire fifo0_flit;
    wire fifo0_flitpatag;
    wire fifo0_retlcrdv;
    wire fifo0_hint;
    wire fifo1_flitpend;
    wire fifo1_flit;
    wire fifo1_flitpatag;
    wire fifo1_retlcrdv;
    wire fifo1_hint;
    wire tx_fifo0_empty;
    wire tx_fifo1_empty;
    wire tx_fifo0_full;
    wire tx_fifo1_full;
    wire tx_fifo0_pop;
    wire tx_fifo1_pop;
    wire tx_fifo_push;
    wire tx_common_link_active;
    wire tx_credit_pulse;
    wire [FIFO_CNT_W-1:0] tx_fifo0_count;
    wire [FIFO_CNT_W-1:0] tx_fifo1_count;
    wire [FIFO_CNT_W-1:0] tx_max_fifo_count;
    wire [FIFO_CNT_W-1:0] tx_common_free_count;
    wire tx_fifo0_flitpend;
    wire tx_fifo0_flit;
    wire tx_fifo0_flitpatag;
    wire tx_fifo0_retlcrdv;
    wire tx_fifo0_nocinfo;
    wire tx_fifo0_push_sideband;
    wire tx_fifo1_flitpend;
    wire tx_fifo1_flit;
    wire tx_fifo1_flitpatag;
    wire tx_fifo1_retlcrdv;
    wire tx_fifo1_nocinfo;
    wire tx_fifo1_push_sideband;

    reg [FIFO_CNT_W:0] downstream_credit_count;
    reg [FIFO_CNT_W-1:0] tx_credit_balance;
    reg arb_sel;

    assign rx_link_active0 = rxlinkactivereq0 & rxlinkactiveack0;
    assign rx_link_active1 = rxlinkactivereq1 & rxlinkactiveack1;
    assign tx_link_active0 = link_tx_enable0;
    assign tx_link_active1 = link_tx_enable1;
    assign tx_common_link_active = tx_link_active0 & tx_link_active1 & link_tx_enable_sllc;
    assign rx_down_link_active = link_tx_enable_sllc;

    assign downstream_credit_avail = downstream_credit_count != {(FIFO_CNT_W+1){1'b0}};
    assign downstream_req_pop_enable = rx_down_link_active &
                                       link_tx_receive_sllc &
                                       downstream_credit_avail;

    assign req_grant0 = downstream_req_pop_enable & ~fifo0_empty &
                        ((arb_sel == 1'b0) | fifo1_empty);
    assign req_grant1 = downstream_req_pop_enable & ~fifo1_empty &
                        ((arb_sel == 1'b1) | fifo0_empty);
    assign req_send0 = req_grant0;
    assign req_send1 = req_grant1;

    assign tx_fifo0_pop    = tx_link_active0 & link_tx_receive0 & ~tx_fifo0_empty & txreqlcrdv0;
    assign tx_fifo1_pop    = tx_link_active1 & link_tx_receive1 & ~tx_fifo1_empty & txreqlcrdv1;
    assign tx_fifo_push    = tx_common_link_active & txreqflitv &
                             (tx_credit_balance != {FIFO_CNT_W{1'b0}}) &
                             ~tx_fifo0_full & ~tx_fifo1_full;
    assign tx_max_fifo_count = (tx_fifo0_count > tx_fifo1_count) ?
                               tx_fifo0_count : tx_fifo1_count;
    assign tx_common_free_count = FIFO_DEPTH_COUNT - tx_max_fifo_count;
    assign tx_credit_pulse = tx_common_link_active & ~link_rx_hold_sllc &
                             (tx_credit_balance < tx_common_free_count);
    assign txreqlcrdv      = tx_credit_pulse;

    assign txreqflitpend0  = tx_link_active0 & ~tx_fifo0_empty & tx_fifo0_flitpend;
    assign txreqflitpend1  = tx_link_active1 & ~tx_fifo1_empty & tx_fifo1_flitpend;
    assign txreqflitv0     = tx_link_active0 & ~tx_fifo0_empty;
    assign txreqflitv1     = tx_link_active1 & ~tx_fifo1_empty;
    assign txreqflit0      = tx_fifo0_flit;
    assign txreqflit1      = tx_fifo1_flit;
    assign txreqflitpatag0 = tx_fifo0_flitpatag;
    assign txreqflitpatag1 = tx_fifo1_flitpatag;
    assign txreqretlcrdv0  = tx_link_active0 & ~tx_fifo0_empty & tx_fifo0_retlcrdv;
    assign txreqretlcrdv1  = tx_link_active1 & ~tx_fifo1_empty & tx_fifo1_retlcrdv;
    assign txreqnocinfo0   = tx_fifo0_nocinfo;
    assign txreqnocinfo1   = tx_fifo1_nocinfo;
    assign txreqpush0      = tx_link_active0 & ~tx_fifo0_empty & tx_fifo0_push_sideband;
    assign txreqpush1      = tx_link_active1 & ~tx_fifo1_empty & tx_fifo1_push_sideband;

    assign rxreqflitpend   = req_grant0 ? fifo0_flitpend  :
                             req_grant1 ? fifo1_flitpend  : 1'b0;
    assign rxreqflitv      = req_grant0 | req_grant1;
    assign rxreqflit       = req_grant0 ? fifo0_flit      :
                             req_grant1 ? fifo1_flit      : 1'b0;
    assign rxreqflitpatag  = req_grant0 ? fifo0_flitpatag :
                             req_grant1 ? fifo1_flitpatag : 1'b0;
    assign rxreqretlcrdv   = req_grant0 ? fifo0_retlcrdv  :
                             req_grant1 ? fifo1_retlcrdv  : 1'b0;
    assign rxreqhint       = req_grant0 ? fifo0_hint      :
                             req_grant1 ? fifo1_hint      : 1'b0;

    SKY_LINK_CTRL_ACTIVE u_link_ctrl0 (
        .clk(clk),
        .rst_n(rst_n),
        .txsactive(txsactive0),
        .rxsactive(rxsactive0),
        .txlinkactivereq(txlinkactivereq0),
        .rxlinkactivereq(rxlinkactivereq0),
        .rxlinkactiveack(rxlinkactiveack0),
        .txlinkactiveack(txlinkactiveack0),
        .rxlcrdhold(link_rx_hold0),
        .txlcrdreturn(link_tx_return0),
        .txlcrdreceive(link_tx_receive0),
        .txflitenable(link_tx_enable0)
    );

    SKY_LINK_CTRL_ACTIVE u_link_ctrl1 (
        .clk(clk),
        .rst_n(rst_n),
        .txsactive(txsactive1),
        .rxsactive(rxsactive1),
        .txlinkactivereq(txlinkactivereq1),
        .rxlinkactivereq(rxlinkactivereq1),
        .rxlinkactiveack(rxlinkactiveack1),
        .txlinkactiveack(txlinkactiveack1),
        .rxlcrdhold(link_rx_hold1),
        .txlcrdreturn(link_tx_return1),
        .txlcrdreceive(link_tx_receive1),
        .txflitenable(link_tx_enable1)
    );

    SKY_LINK_CTRL_ACTIVE u_link_ctrl_sllc (
        .clk(clk),
        .rst_n(rst_n),
        .txsactive(rxsactive),
        .rxsactive(txsactive),
        .txlinkactivereq(rxlinkactivereq),
        .rxlinkactivereq(txlinkactivereq),
        .rxlinkactiveack(txlinkactiveack),
        .txlinkactiveack(rxlinkactiveack),
        .rxlcrdhold(link_rx_hold_sllc),
        .txlcrdreturn(link_tx_return_sllc),
        .txlcrdreceive(link_tx_receive_sllc),
        .txflitenable(link_tx_enable_sllc)
    );

    CHI_REQ_FIFO #(
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_req_fifo0 (
        .clk(clk),
        .rst_n(rst_n),
        .link_active(rx_link_active0),
        .rxreqflitpend(rxreqflitpend0),
        .rxreqflitv(rxreqflitv0),
        .rxreqflit(rxreqflit0),
        .rxreqflitpatag(rxreqflitpatag0),
        .rxreqretlcrdv(rxreqretlcrdv0),
        .rxreqhint(rxreqhint0),
        .rxlcrdhold(link_rx_hold0),
        .pop(req_send0),
        .empty(fifo0_empty),
        .full(fifo0_full),
        .flitpend_out(fifo0_flitpend),
        .flit_out(fifo0_flit),
        .flitpatag_out(fifo0_flitpatag),
        .retlcrdv_out(fifo0_retlcrdv),
        .hint_out(fifo0_hint),
        .rxreqlcrdv(rxreqlcrdv0)
    );

    CHI_REQ_FIFO #(
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_req_fifo1 (
        .clk(clk),
        .rst_n(rst_n),
        .link_active(rx_link_active1),
        .rxreqflitpend(rxreqflitpend1),
        .rxreqflitv(rxreqflitv1),
        .rxreqflit(rxreqflit1),
        .rxreqflitpatag(rxreqflitpatag1),
        .rxreqretlcrdv(rxreqretlcrdv1),
        .rxreqhint(rxreqhint1),
        .rxlcrdhold(link_rx_hold1),
        .pop(req_send1),
        .empty(fifo1_empty),
        .full(fifo1_full),
        .flitpend_out(fifo1_flitpend),
        .flit_out(fifo1_flit),
        .flitpatag_out(fifo1_flitpatag),
        .retlcrdv_out(fifo1_retlcrdv),
        .hint_out(fifo1_hint),
        .rxreqlcrdv(rxreqlcrdv1)
    );

    CHI_TX_FIFO #(
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_CNT_W(FIFO_CNT_W)
    ) u_tx_fifo0 (
        .clk(clk),
        .rst_n(rst_n),
        .link_active(tx_common_link_active),
        .push(tx_fifo_push),
        .txreqflitpend(txreqflitpend),
        .txreqflit(txreqflit),
        .txreqflitpatag(txreqflitpatag),
        .txreqretlcrdv(txreqretlcrdv),
        .txreqnocinfo(txreqnocinfo),
        .txreqpush(txreqpush),
        .pop(tx_fifo0_pop),
        .empty(tx_fifo0_empty),
        .full(tx_fifo0_full),
        .count(tx_fifo0_count),
        .flitpend_out(tx_fifo0_flitpend),
        .flit_out(tx_fifo0_flit),
        .flitpatag_out(tx_fifo0_flitpatag),
        .retlcrdv_out(tx_fifo0_retlcrdv),
        .nocinfo_out(tx_fifo0_nocinfo),
        .push_out(tx_fifo0_push_sideband)
    );

    CHI_TX_FIFO #(
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_CNT_W(FIFO_CNT_W)
    ) u_tx_fifo1 (
        .clk(clk),
        .rst_n(rst_n),
        .link_active(tx_common_link_active),
        .push(tx_fifo_push),
        .txreqflitpend(txreqflitpend),
        .txreqflit(txreqflit),
        .txreqflitpatag(txreqflitpatag),
        .txreqretlcrdv(txreqretlcrdv),
        .txreqnocinfo(txreqnocinfo),
        .txreqpush(txreqpush),
        .pop(tx_fifo1_pop),
        .empty(tx_fifo1_empty),
        .full(tx_fifo1_full),
        .count(tx_fifo1_count),
        .flitpend_out(tx_fifo1_flitpend),
        .flit_out(tx_fifo1_flit),
        .flitpatag_out(tx_fifo1_flitpatag),
        .retlcrdv_out(tx_fifo1_retlcrdv),
        .nocinfo_out(tx_fifo1_nocinfo),
        .push_out(tx_fifo1_push_sideband)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            downstream_credit_count <= {(FIFO_CNT_W+1){1'b0}};
            tx_credit_balance <= {FIFO_CNT_W{1'b0}};
            arb_sel <= 1'b0;
        end else begin
            if (!rx_down_link_active | link_tx_return_sllc) begin
                downstream_credit_count <= {(FIFO_CNT_W+1){1'b0}};
            end else begin
                case ({rxreqlcrdv & link_tx_receive_sllc, req_send0 | req_send1})
                    2'b10: downstream_credit_count <= downstream_credit_count + {{FIFO_CNT_W{1'b0}}, 1'b1};
                    2'b01: downstream_credit_count <= downstream_credit_count - {{FIFO_CNT_W{1'b0}}, 1'b1};
                    default: downstream_credit_count <= downstream_credit_count;
                endcase
            end

            if (!tx_common_link_active | link_tx_return_sllc) begin
                tx_credit_balance <= {FIFO_CNT_W{1'b0}};
            end else begin
                case ({tx_credit_pulse, tx_fifo_push})
                    2'b10: tx_credit_balance <= tx_credit_balance + {{(FIFO_CNT_W-1){1'b0}}, 1'b1};
                    2'b01: tx_credit_balance <= tx_credit_balance - {{(FIFO_CNT_W-1){1'b0}}, 1'b1};
                    default: tx_credit_balance <= tx_credit_balance;
                endcase
            end

            if (req_send0) begin
                arb_sel <= 1'b1;
            end else if (req_send1) begin
                arb_sel <= 1'b0;
            end
        end
    end

endmodule

module CHI_TX_FIFO #(
    parameter FIFO_DEPTH = 4,
    parameter FIFO_CNT_W = 3
) (
    input wire clk
   ,input wire rst_n
   ,input wire link_active

   ,input wire push
   ,input wire txreqflitpend
   ,input wire txreqflit
   ,input wire txreqflitpatag
   ,input wire txreqretlcrdv
   ,input wire txreqnocinfo
   ,input wire txreqpush

   ,input wire pop
   ,output wire empty
   ,output wire full
   ,output wire [FIFO_CNT_W-1:0] count
   ,output wire flitpend_out
   ,output wire flit_out
   ,output wire flitpatag_out
   ,output wire retlcrdv_out
   ,output wire nocinfo_out
   ,output wire push_out
);

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1) begin
                value = value >> 1;
            end
            clog2 = i;
        end
    endfunction

    localparam FIFO_PTR_W = (FIFO_DEPTH <= 2) ? 1 : clog2(FIFO_DEPTH);
    localparam [FIFO_PTR_W-1:0] FIFO_LAST_PTR = FIFO_DEPTH - 1;
    localparam [FIFO_CNT_W-1:0] FIFO_DEPTH_COUNT = FIFO_DEPTH;

    wire push_en;
    wire pop_en;

    reg [FIFO_PTR_W-1:0] rd_ptr;
    reg [FIFO_PTR_W-1:0] wr_ptr;
    reg [FIFO_CNT_W-1:0] count_r;
    reg [FIFO_DEPTH-1:0] flitpend_mem;
    reg [FIFO_DEPTH-1:0] flit_mem;
    reg [FIFO_DEPTH-1:0] flitpatag_mem;
    reg [FIFO_DEPTH-1:0] retlcrdv_mem;
    reg [FIFO_DEPTH-1:0] nocinfo_mem;
    reg [FIFO_DEPTH-1:0] push_mem;

    assign count = count_r;
    assign empty = count_r == {FIFO_CNT_W{1'b0}};
    assign full = count_r == FIFO_DEPTH_COUNT;
    assign push_en = link_active & push & ~full;
    assign pop_en = link_active & pop & ~empty;

    assign flitpend_out = flitpend_mem[rd_ptr];
    assign flit_out = flit_mem[rd_ptr];
    assign flitpatag_out = flitpatag_mem[rd_ptr];
    assign retlcrdv_out = retlcrdv_mem[rd_ptr];
    assign nocinfo_out = nocinfo_mem[rd_ptr];
    assign push_out = push_mem[rd_ptr];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= {FIFO_PTR_W{1'b0}};
            wr_ptr <= {FIFO_PTR_W{1'b0}};
            count_r <= {FIFO_CNT_W{1'b0}};
        end else if (!link_active) begin
            rd_ptr <= {FIFO_PTR_W{1'b0}};
            wr_ptr <= {FIFO_PTR_W{1'b0}};
            count_r <= {FIFO_CNT_W{1'b0}};
        end else begin
            if (push_en) begin
                flitpend_mem[wr_ptr] <= txreqflitpend;
                flit_mem[wr_ptr] <= txreqflit;
                flitpatag_mem[wr_ptr] <= txreqflitpatag;
                retlcrdv_mem[wr_ptr] <= txreqretlcrdv;
                nocinfo_mem[wr_ptr] <= txreqnocinfo;
                push_mem[wr_ptr] <= txreqpush;
                wr_ptr <= (wr_ptr == FIFO_LAST_PTR) ?
                          {FIFO_PTR_W{1'b0}} :
                          wr_ptr + 1'b1;
            end

            if (pop_en) begin
                rd_ptr <= (rd_ptr == FIFO_LAST_PTR) ?
                          {FIFO_PTR_W{1'b0}} :
                          rd_ptr + 1'b1;
            end

            case ({push_en, pop_en})
                2'b10: count_r <= count_r + {{(FIFO_CNT_W-1){1'b0}}, 1'b1};
                2'b01: count_r <= count_r - {{(FIFO_CNT_W-1){1'b0}}, 1'b1};
                default: count_r <= count_r;
            endcase
        end
    end

endmodule

module CHI_REQ_FIFO #(
    parameter FIFO_DEPTH = 4
) (
    input wire clk
   ,input wire rst_n
   ,input wire link_active

   ,input wire rxreqflitpend
   ,input wire rxreqflitv
   ,input wire rxreqflit
   ,input wire rxreqflitpatag
   ,input wire rxreqretlcrdv
   ,input wire rxreqhint
   ,input wire rxlcrdhold

   ,input wire pop
   ,output wire empty
   ,output wire full
   ,output wire flitpend_out
   ,output wire flit_out
   ,output wire flitpatag_out
   ,output wire retlcrdv_out
   ,output wire hint_out
   ,output wire rxreqlcrdv
);

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1) begin
                value = value >> 1;
            end
            clog2 = i;
        end
    endfunction

    localparam FIFO_PTR_W = (FIFO_DEPTH <= 2) ? 1 : clog2(FIFO_DEPTH);
    localparam FIFO_CNT_W = clog2(FIFO_DEPTH + 1);
    localparam [FIFO_PTR_W-1:0] FIFO_LAST_PTR = FIFO_DEPTH - 1;
    localparam [FIFO_CNT_W-1:0] FIFO_DEPTH_COUNT = FIFO_DEPTH;

    wire push;
    wire init_credit;
    wire init_credit_send;
    wire pop_credit_send;
    wire pop_credit_pending;

    reg [FIFO_PTR_W-1:0] rd_ptr;
    reg [FIFO_PTR_W-1:0] wr_ptr;
    reg [FIFO_CNT_W-1:0] count;
    reg [FIFO_CNT_W-1:0] init_credit_count;
    reg [FIFO_CNT_W-1:0] return_credit_count;
    reg [FIFO_DEPTH-1:0] flitpend_mem;
    reg [FIFO_DEPTH-1:0] flit_mem;
    reg [FIFO_DEPTH-1:0] flitpatag_mem;
    reg [FIFO_DEPTH-1:0] retlcrdv_mem;
    reg [FIFO_DEPTH-1:0] hint_mem;

    assign empty = count == {FIFO_CNT_W{1'b0}};
    assign full = count == FIFO_DEPTH_COUNT;
    assign push = link_active & rxreqflitv & ~full;

    assign init_credit = link_active & (init_credit_count != FIFO_DEPTH_COUNT);
    assign pop_credit_pending = return_credit_count != {FIFO_CNT_W{1'b0}};
    assign pop_credit_send = link_active & ~rxlcrdhold & pop_credit_pending;
    assign init_credit_send = init_credit & ~pop_credit_send & ~rxlcrdhold;
    assign rxreqlcrdv = pop_credit_send | init_credit_send;

    assign flitpend_out = flitpend_mem[rd_ptr];
    assign flit_out = flit_mem[rd_ptr];
    assign flitpatag_out = flitpatag_mem[rd_ptr];
    assign retlcrdv_out = retlcrdv_mem[rd_ptr];
    assign hint_out = hint_mem[rd_ptr];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= {FIFO_PTR_W{1'b0}};
            wr_ptr <= {FIFO_PTR_W{1'b0}};
            count <= {FIFO_CNT_W{1'b0}};
            init_credit_count <= {FIFO_CNT_W{1'b0}};
            return_credit_count <= {FIFO_CNT_W{1'b0}};
        end else if (!link_active) begin
            rd_ptr <= {FIFO_PTR_W{1'b0}};
            wr_ptr <= {FIFO_PTR_W{1'b0}};
            count <= {FIFO_CNT_W{1'b0}};
            init_credit_count <= {FIFO_CNT_W{1'b0}};
            return_credit_count <= {FIFO_CNT_W{1'b0}};
        end else begin
            if (init_credit_send) begin
                init_credit_count <= init_credit_count + {{(FIFO_CNT_W-1){1'b0}}, 1'b1};
            end

            case ({pop, pop_credit_send})
                2'b10: return_credit_count <= return_credit_count + {{(FIFO_CNT_W-1){1'b0}}, 1'b1};
                2'b01: return_credit_count <= return_credit_count - {{(FIFO_CNT_W-1){1'b0}}, 1'b1};
                default: return_credit_count <= return_credit_count;
            endcase

            if (push) begin
                flitpend_mem[wr_ptr] <= rxreqflitpend;
                flit_mem[wr_ptr] <= rxreqflit;
                flitpatag_mem[wr_ptr] <= rxreqflitpatag;
                retlcrdv_mem[wr_ptr] <= rxreqretlcrdv;
                hint_mem[wr_ptr] <= rxreqhint;
                wr_ptr <= (wr_ptr == FIFO_LAST_PTR) ?
                          {FIFO_PTR_W{1'b0}} :
                          wr_ptr + 1'b1;
            end

            if (pop) begin
                rd_ptr <= (rd_ptr == FIFO_LAST_PTR) ?
                          {FIFO_PTR_W{1'b0}} :
                          rd_ptr + 1'b1;
            end

            case ({push, pop})
                2'b10: count <= count + {{(FIFO_CNT_W-1){1'b0}}, 1'b1};
                2'b01: count <= count - {{(FIFO_CNT_W-1){1'b0}}, 1'b1};
                default: count <= count;
            endcase
        end
    end

endmodule
