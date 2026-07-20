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

wire rxlcrdhold0;
wire txlcrdreturn0;
wire txlcrdreceive0;
wire txflitenable0;
wire rxlcrdhold1;
wire txlcrdreturn1;
wire txlcrdreceive1;
wire txflitenable1;
wire rxlcrdhold_sllc;
wire txlcrdreturn_sllc;
wire txlcrdreceive_sllc;
wire txflitenable_sllc;

wire rxbuf_vld0;
wire [2:0] rxbuf_pld0;
wire rxbuf_rdy0;
wire rxbuf_vld1;
wire [2:0] rxbuf_pld1;
wire rxbuf_rdy1;
wire rxbuf_vld_sllc;
wire [2:0] rxbuf_pld_sllc;
wire rxbuf_rdy_sllc;

wire txbuf_flitpend_sllc;
wire txbuf_flitv_sllc;
wire [2:0] txbuf_flit_sllc;
wire txbuf_rdy_sllc;
wire txbuf_flitpend0;
wire txbuf_flitv0;
wire [2:0] txbuf_flit0;
wire txbuf_rdy0;
wire txbuf_flitpend1;
wire txbuf_flitv1;
wire [2:0] txbuf_flit1;
wire txbuf_rdy1;
wire txbuf_sllc_fire;
wire txbuf_sllc_sel0;
wire txbuf_sllc_sel1;
wire rxbuf_sllc_fire;
wire rxbuf_sllc_sel0;
wire rxbuf_sllc_sel1;
wire [2:0] rxreqflit_pack0;
wire [2:0] rxreqflit_pack1;
wire [2:0] rxreqflit_pack;
wire [2:0] txreqflit_pack;
wire [2:0] txreqflit_pack0;
wire [2:0] txreqflit_pack1;
wire rxreqnocinfo_unused;

reg txbuf_sllc_arb_sel;
reg rxbuf_sllc_arb_sel;

assign rxreqflit_pack0 = {rxreqflitpatag0, 1'b0, rxreqflit0};
assign rxreqflit_pack1 = {rxreqflitpatag1, 1'b0, rxreqflit1};
assign {rxreqflitpatag, rxreqnocinfo_unused, rxreqflit} = rxreqflit_pack;

assign txreqflit_pack = {txreqflitpatag, txreqnocinfo, txreqflit};
assign {txreqflitpatag0, txreqnocinfo0, txreqflit0} = txreqflit_pack0;
assign {txreqflitpatag1, txreqnocinfo1, txreqflit1} = txreqflit_pack1;

// Link control for the three CHI-facing ports.
SKY_LINK_CTRL_ACTIVE u_link_ctrl_noc0 (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .txsactive       (txsactive0          ),
    .rxsactive       (rxsactive0          ),
    .txlinkactivereq (txlinkactivereq0    ),
    .rxlinkactivereq (rxlinkactivereq0    ),
    .rxlinkactiveack (rxlinkactiveack0    ),
    .txlinkactiveack (txlinkactiveack0    ),
    .rxlcrdhold      (rxlcrdhold0         ),
    .txlcrdreturn    (txlcrdreturn0       ),
    .txlcrdreceive   (txlcrdreceive0      ),
    .txflitenable    (txflitenable0       )
);

SKY_LINK_CTRL_ACTIVE u_link_ctrl_noc1 (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .txsactive       (txsactive1          ),
    .rxsactive       (rxsactive1          ),
    .txlinkactivereq (txlinkactivereq1    ),
    .rxlinkactivereq (rxlinkactivereq1    ),
    .rxlinkactiveack (rxlinkactiveack1    ),
    .txlinkactiveack (txlinkactiveack1    ),
    .rxlcrdhold      (rxlcrdhold1         ),
    .txlcrdreturn    (txlcrdreturn1       ),
    .txlcrdreceive   (txlcrdreceive1      ),
    .txflitenable    (txflitenable1       )
);

SKY_LINK_CTRL_ACTIVE u_link_ctrl_sllc (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .txsactive       (rxsactive           ),
    .rxsactive       (txsactive           ),
    .txlinkactivereq (rxlinkactivereq     ),
    .rxlinkactivereq (txlinkactivereq     ),
    .rxlinkactiveack (txlinkactiveack     ),
    .txlinkactiveack (rxlinkactiveack     ),
    .rxlcrdhold      (rxlcrdhold_sllc     ),
    .txlcrdreturn    (txlcrdreturn_sllc   ),
    .txlcrdreceive   (txlcrdreceive_sllc  ),
    .txflitenable    (txflitenable_sllc   )
);

// NOC0/NOC1 -> SLLC direction.
SKY_RXBUF u_rxbuf_noc0 (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .flitpend        (rxreqflitpend0      ),
    .flitv           (rxreqflitv0         ),
    .flit            (rxreqflit_pack0     ),
    .rxbuf_vld       (rxbuf_vld0          ),
    .rxbuf_pld       (rxbuf_pld0          ),
    .rxbuf_rdy       (rxbuf_rdy0          ),
    .rxretlcrdv      (rxreqretlcrdv0      ),
    .rxlcrdv         (rxreqlcrdv0         ),
    .rxlcrdhold      (rxlcrdhold0         )
);

SKY_RXBUF u_rxbuf_noc1 (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .flitpend        (rxreqflitpend1      ),
    .flitv           (rxreqflitv1         ),
    .flit            (rxreqflit_pack1     ),
    .rxbuf_vld       (rxbuf_vld1          ),
    .rxbuf_pld       (rxbuf_pld1          ),
    .rxbuf_rdy       (rxbuf_rdy1          ),
    .rxretlcrdv      (rxreqretlcrdv1      ),
    .rxlcrdv         (rxreqlcrdv1         ),
    .rxlcrdhold      (rxlcrdhold1         )
);

// tx begin
assign txbuf_sllc_sel0     = rxbuf_vld0 & (~rxbuf_vld1 | ~txbuf_sllc_arb_sel);
assign txbuf_sllc_sel1     = rxbuf_vld1 & (~rxbuf_vld0 |  txbuf_sllc_arb_sel);
assign txbuf_sllc_fire     = txbuf_rdy_sllc & (txbuf_sllc_sel0 | txbuf_sllc_sel1);

assign txbuf_flitv_sllc    = txbuf_sllc_sel0 | txbuf_sllc_sel1;
assign txbuf_flitpend_sllc = txbuf_flitv_sllc;
assign txbuf_flit_sllc     = txbuf_sllc_sel0 ? rxbuf_pld0 :
                              txbuf_sllc_sel1 ? rxbuf_pld1 : 3'b000;

assign rxbuf_rdy0          = txbuf_rdy_sllc & txbuf_sllc_sel0;
assign rxbuf_rdy1          = txbuf_rdy_sllc & txbuf_sllc_sel1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        txbuf_sllc_arb_sel <= 1'b0;
    end else if (txbuf_sllc_fire) begin
        txbuf_sllc_arb_sel <= txbuf_sllc_sel0;
    end
end

// tx end

SKY_TXBUF u_txbuf_sllc (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .txbuf_flitv     (txbuf_flitv_sllc    ),
    .txbuf_flitpend  (txbuf_flitpend_sllc ),
    .txbuf_flit      (txbuf_flit_sllc     ),
    .txbuf_rdy       (txbuf_rdy_sllc      ),
    .txlcrdreceive   (txlcrdreceive_sllc  ),
    .txflitenable    (txflitenable_sllc   ),
    .txlcrdreturn    (txlcrdreturn_sllc   ),
    .flitpend        (rxreqflitpend       ),
    .flitv           (rxreqflitv          ),
    .flit            (rxreqflit_pack      ),
    .txlcrdv         (rxreqlcrdv          ),
    .txretlcrdv      (rxreqretlcrdv       )
);

// SLLC -> NOC0/NOC1 direction.
SKY_RXBUF u_rxbuf_sllc (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .flitpend        (txreqflitpend       ),
    .flitv           (txreqflitv          ),
    .flit            (txreqflit_pack      ),
    .rxbuf_vld       (rxbuf_vld_sllc      ),
    .rxbuf_pld       (rxbuf_pld_sllc      ),
    .rxbuf_rdy       (rxbuf_rdy_sllc      ),
    .rxretlcrdv      (txreqretlcrdv       ),
    .rxlcrdv         (txreqlcrdv          ),
    .rxlcrdhold      (rxlcrdhold_sllc     )
);

// rx begin
assign rxbuf_sllc_sel0     = rxbuf_vld_sllc & (~rxbuf_sllc_arb_sel);
assign rxbuf_sllc_sel1     = rxbuf_vld_sllc &   rxbuf_sllc_arb_sel;
assign rxbuf_sllc_fire     = (rxbuf_sllc_sel0 & txbuf_rdy0) |
                              (rxbuf_sllc_sel1 & txbuf_rdy1);

assign txbuf_flitv0        = rxbuf_sllc_sel0;
assign txbuf_flitpend0     = rxbuf_sllc_sel0;
assign txbuf_flit0         = rxbuf_pld_sllc;

assign txbuf_flitv1        = rxbuf_sllc_sel1;
assign txbuf_flitpend1     = rxbuf_sllc_sel1;
assign txbuf_flit1         = rxbuf_pld_sllc;

assign rxbuf_rdy_sllc      = rxbuf_sllc_fire;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxbuf_sllc_arb_sel <= 1'b0;
    end else if (rxbuf_sllc_fire) begin
        rxbuf_sllc_arb_sel <= ~rxbuf_sllc_arb_sel;
    end
end

// rx end

SKY_TXBUF u_txbuf_noc0 (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .txbuf_flitv     (txbuf_flitv0        ),
    .txbuf_flitpend  (txbuf_flitpend0     ),
    .txbuf_flit      (txbuf_flit0         ),
    .txbuf_rdy       (txbuf_rdy0          ),
    .txlcrdreceive   (txlcrdreceive0      ),
    .txflitenable    (txflitenable0       ),
    .txlcrdreturn    (txlcrdreturn0       ),
    .flitpend        (txreqflitpend0      ),
    .flitv           (txreqflitv0         ),
    .flit            (txreqflit_pack0     ),
    .txlcrdv         (txreqlcrdv0         ),
    .txretlcrdv      (txreqretlcrdv0      )
);

SKY_TXBUF u_txbuf_noc1 (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .txbuf_flitv     (txbuf_flitv1        ),
    .txbuf_flitpend  (txbuf_flitpend1     ),
    .txbuf_flit      (txbuf_flit1         ),
    .txbuf_rdy       (txbuf_rdy1          ),
    .txlcrdreceive   (txlcrdreceive1      ),
    .txflitenable    (txflitenable1       ),
    .txlcrdreturn    (txlcrdreturn1       ),
    .flitpend        (txreqflitpend1      ),
    .flitv           (txreqflitv1         ),
    .flit            (txreqflit_pack1     ),
    .txlcrdv         (txreqlcrdv1         ),
    .txretlcrdv      (txreqretlcrdv1      )
);

endmodule
