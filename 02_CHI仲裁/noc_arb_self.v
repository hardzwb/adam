// Per-channel NOC-side CHI port bundle.  IDX is the NOC port suffix, 0 or 1.
`define CHI_NOC_PORTS(CH, IDX) \
   ,output wire tx``CH``flitpend``IDX \
   ,output wire tx``CH``flitv``IDX \
   ,output wire tx``CH``flit``IDX \
   ,output wire tx``CH``flitpatag``IDX \
   ,input  wire tx``CH``lcrdv``IDX \
   ,output wire tx``CH``retlcrdv``IDX \
   ,output wire tx``CH``nocinfo``IDX \
   ,output wire tx``CH``push``IDX \
   ,input  wire rx``CH``flitpend``IDX \
   ,input  wire rx``CH``flitv``IDX \
   ,input  wire rx``CH``flit``IDX \
   ,input  wire rx``CH``flitpatag``IDX \
   ,output wire rx``CH``lcrdv``IDX \
   ,input  wire rx``CH``retlcrdv``IDX \
   ,input  wire rx``CH``hint``IDX

// Per-channel SLLC-side CHI port bundle.  SLLC ports keep the original names.
`define CHI_SLLC_PORTS(CH) \
   ,input  wire tx``CH``flitpend \
   ,input  wire tx``CH``flitv \
   ,input  wire tx``CH``flit \
   ,input  wire tx``CH``flitpatag \
   ,output wire tx``CH``lcrdv \
   ,input  wire tx``CH``retlcrdv \
   ,input  wire tx``CH``nocinfo \
   ,input  wire tx``CH``push \
   ,output wire rx``CH``flitpend \
   ,output wire rx``CH``flitv \
   ,output wire rx``CH``flit \
   ,output wire rx``CH``flitpatag \
   ,input  wire rx``CH``lcrdv \
   ,output wire rx``CH``retlcrdv \
   ,output wire rx``CH``hint

// Instantiate one complete channel datapath.  All six CHI channels share the
// same buffering, credit isolation, and round-robin arbitration structure.
`define CHI_CHANNEL_INSTANCE(CH) \
SKY_CHI_CHANNEL_ARB u_``CH``_channel ( \
    .clk                (clk                   ), \
    .rst_n              (rst_n                 ), \
    .rxlcrdhold0        (rxlcrdhold0           ), \
    .txlcrdreturn0      (txlcrdreturn0         ), \
    .txlcrdreceive0     (txlcrdreceive0        ), \
    .txflitenable0      (txflitenable0         ), \
    .rxlcrdhold1        (rxlcrdhold1           ), \
    .txlcrdreturn1      (txlcrdreturn1         ), \
    .txlcrdreceive1     (txlcrdreceive1        ), \
    .txflitenable1      (txflitenable1         ), \
    .rxlcrdhold_sllc    (rxlcrdhold_sllc       ), \
    .txlcrdreturn_sllc  (txlcrdreturn_sllc     ), \
    .txlcrdreceive_sllc (txlcrdreceive_sllc    ), \
    .txflitenable_sllc  (txflitenable_sllc     ), \
    .tx_flitpend0       (tx``CH``flitpend0     ), \
    .tx_flitv0          (tx``CH``flitv0        ), \
    .tx_flit0           (tx``CH``flit0         ), \
    .tx_flitpatag0      (tx``CH``flitpatag0    ), \
    .tx_lcrdv0          (tx``CH``lcrdv0        ), \
    .tx_retlcrdv0       (tx``CH``retlcrdv0     ), \
    .tx_nocinfo0        (tx``CH``nocinfo0      ), \
    .tx_push0           (tx``CH``push0         ), \
    .rx_flitpend0       (rx``CH``flitpend0     ), \
    .rx_flitv0          (rx``CH``flitv0        ), \
    .rx_flit0           (rx``CH``flit0         ), \
    .rx_flitpatag0      (rx``CH``flitpatag0    ), \
    .rx_lcrdv0          (rx``CH``lcrdv0        ), \
    .rx_retlcrdv0       (rx``CH``retlcrdv0     ), \
    .rx_hint0           (rx``CH``hint0         ), \
    .tx_flitpend1       (tx``CH``flitpend1     ), \
    .tx_flitv1          (tx``CH``flitv1        ), \
    .tx_flit1           (tx``CH``flit1         ), \
    .tx_flitpatag1      (tx``CH``flitpatag1    ), \
    .tx_lcrdv1          (tx``CH``lcrdv1        ), \
    .tx_retlcrdv1       (tx``CH``retlcrdv1     ), \
    .tx_nocinfo1        (tx``CH``nocinfo1      ), \
    .tx_push1           (tx``CH``push1         ), \
    .rx_flitpend1       (rx``CH``flitpend1     ), \
    .rx_flitv1          (rx``CH``flitv1        ), \
    .rx_flit1           (rx``CH``flit1         ), \
    .rx_flitpatag1      (rx``CH``flitpatag1    ), \
    .rx_lcrdv1          (rx``CH``lcrdv1        ), \
    .rx_retlcrdv1       (rx``CH``retlcrdv1     ), \
    .rx_hint1           (rx``CH``hint1         ), \
    .tx_flitpend        (tx``CH``flitpend      ), \
    .tx_flitv           (tx``CH``flitv         ), \
    .tx_flit            (tx``CH``flit          ), \
    .tx_flitpatag       (tx``CH``flitpatag     ), \
    .tx_lcrdv           (tx``CH``lcrdv         ), \
    .tx_retlcrdv        (tx``CH``retlcrdv      ), \
    .tx_nocinfo         (tx``CH``nocinfo       ), \
    .tx_push            (tx``CH``push          ), \
    .rx_flitpend        (rx``CH``flitpend      ), \
    .rx_flitv           (rx``CH``flitv         ), \
    .rx_flit            (rx``CH``flit          ), \
    .rx_flitpatag       (rx``CH``flitpatag     ), \
    .rx_lcrdv           (rx``CH``lcrdv         ), \
    .rx_retlcrdv        (rx``CH``retlcrdv      ), \
    .rx_hint            (rx``CH``hint          )  \
);

module NOC_ARB #(
    parameter FIFO_DEPTH = 4
) (
    input wire clk
   ,input wire rst_n

    //--------------------------------------------------------------------------
    // NOC0 port
    //--------------------------------------------------------------------------
   ,output wire txsactive0
   ,input  wire rxsactive0
   ,output wire txlinkactivereq0
   ,input  wire txlinkactiveack0
   ,input  wire rxlinkactivereq0
   ,output wire rxlinkactiveack0

   `CHI_NOC_PORTS(req,    0)
   `CHI_NOC_PORTS(dat,    0)
   `CHI_NOC_PORTS(rsp,    0)
   `CHI_NOC_PORTS(reqext, 0)
   `CHI_NOC_PORTS(datext, 0)
   `CHI_NOC_PORTS(rspext, 0)

    //--------------------------------------------------------------------------
    // NOC1 port
    //--------------------------------------------------------------------------
   ,output wire txsactive1
   ,input  wire rxsactive1
   ,output wire txlinkactivereq1
   ,input  wire txlinkactiveack1
   ,input  wire rxlinkactivereq1
   ,output wire rxlinkactiveack1

   `CHI_NOC_PORTS(req,    1)
   `CHI_NOC_PORTS(dat,    1)
   `CHI_NOC_PORTS(rsp,    1)
   `CHI_NOC_PORTS(reqext, 1)
   `CHI_NOC_PORTS(datext, 1)
   `CHI_NOC_PORTS(rspext, 1)

    //--------------------------------------------------------------------------
    // SLLC port
    //--------------------------------------------------------------------------
   ,input  wire txsactive
   ,output wire rxsactive
   ,input  wire txlinkactivereq
   ,output wire txlinkactiveack
   ,output wire rxlinkactivereq
   ,input  wire rxlinkactiveack

   `CHI_SLLC_PORTS(req)
   `CHI_SLLC_PORTS(dat)
   `CHI_SLLC_PORTS(rsp)
   `CHI_SLLC_PORTS(reqext)
   `CHI_SLLC_PORTS(datext)
   `CHI_SLLC_PORTS(rspext)
);

// The link-control wrapper is shared by all traffic channels on the same CHI
// port.  Each channel datapath consumes these controls when driving RXBUF/TXBUF.
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

// Link control for the three CHI-facing ports.  The SLLC instance is wired with
// the port direction reversed because it faces the downstream CHI endpoint.
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

//------------------------------------------------------------------------------
// REQ channel
//------------------------------------------------------------------------------
`CHI_CHANNEL_INSTANCE(req)

//------------------------------------------------------------------------------
// DAT channel
//------------------------------------------------------------------------------
`CHI_CHANNEL_INSTANCE(dat)

//------------------------------------------------------------------------------
// RSP channel
//------------------------------------------------------------------------------
`CHI_CHANNEL_INSTANCE(rsp)

//------------------------------------------------------------------------------
// REQEXT channel
//------------------------------------------------------------------------------
`CHI_CHANNEL_INSTANCE(reqext)

//------------------------------------------------------------------------------
// DATEXT channel
//------------------------------------------------------------------------------
`CHI_CHANNEL_INSTANCE(datext)

//------------------------------------------------------------------------------
// RSPEXT channel
//------------------------------------------------------------------------------
`CHI_CHANNEL_INSTANCE(rspext)

endmodule

`undef CHI_NOC_PORTS
`undef CHI_SLLC_PORTS
`undef CHI_CHANNEL_INSTANCE

module SKY_CHI_CHANNEL_ARB (
    input  wire clk
   ,input  wire rst_n

    // Link-control sideband.
   ,input  wire rxlcrdhold0
   ,input  wire txlcrdreturn0
   ,input  wire txlcrdreceive0
   ,input  wire txflitenable0
   ,input  wire rxlcrdhold1
   ,input  wire txlcrdreturn1
   ,input  wire txlcrdreceive1
   ,input  wire txflitenable1
   ,input  wire rxlcrdhold_sllc
   ,input  wire txlcrdreturn_sllc
   ,input  wire txlcrdreceive_sllc
   ,input  wire txflitenable_sllc

    // NOC0 side.
   ,output wire tx_flitpend0
   ,output wire tx_flitv0
   ,output wire tx_flit0
   ,output wire tx_flitpatag0
   ,input  wire tx_lcrdv0
   ,output wire tx_retlcrdv0
   ,output wire tx_nocinfo0
   ,output wire tx_push0
   ,input  wire rx_flitpend0
   ,input  wire rx_flitv0
   ,input  wire rx_flit0
   ,input  wire rx_flitpatag0
   ,output wire rx_lcrdv0
   ,input  wire rx_retlcrdv0
   ,input  wire rx_hint0

    // NOC1 side.
   ,output wire tx_flitpend1
   ,output wire tx_flitv1
   ,output wire tx_flit1
   ,output wire tx_flitpatag1
   ,input  wire tx_lcrdv1
   ,output wire tx_retlcrdv1
   ,output wire tx_nocinfo1
   ,output wire tx_push1
   ,input  wire rx_flitpend1
   ,input  wire rx_flitv1
   ,input  wire rx_flit1
   ,input  wire rx_flitpatag1
   ,output wire rx_lcrdv1
   ,input  wire rx_retlcrdv1
   ,input  wire rx_hint1

    // SLLC side.
   ,input  wire tx_flitpend
   ,input  wire tx_flitv
   ,input  wire tx_flit
   ,input  wire tx_flitpatag
   ,output wire tx_lcrdv
   ,input  wire tx_retlcrdv
   ,input  wire tx_nocinfo
   ,input  wire tx_push
   ,output wire rx_flitpend
   ,output wire rx_flitv
   ,output wire rx_flit
   ,output wire rx_flitpatag
   ,input  wire rx_lcrdv
   ,output wire rx_retlcrdv
   ,output wire rx_hint
);

// RXBUF outputs are the arbitration sources.  TXBUF ready signals are the
// arbitration sinks and also gate RXBUF pop/credit-return timing.
wire        rxbuf_vld0;
wire [2:0]  rxbuf_pld0;
wire        rxbuf_rdy0;
wire        rxbuf_vld1;
wire [2:0]  rxbuf_pld1;
wire        rxbuf_rdy1;
wire        rxbuf_vld_sllc;
wire [2:0]  rxbuf_pld_sllc;
wire        rxbuf_rdy_sllc;

wire        txbuf_flitpend_sllc;
wire        txbuf_flitv_sllc;
wire [2:0]  txbuf_flit_sllc;
wire        txbuf_rdy_sllc;
wire        txbuf_flitpend0;
wire        txbuf_flitv0;
wire [2:0]  txbuf_flit0;
wire        txbuf_rdy0;
wire        txbuf_flitpend1;
wire        txbuf_flitv1;
wire [2:0]  txbuf_flit1;
wire        txbuf_rdy1;

wire        to_sllc_fire;
wire        to_sllc_sel0;
wire        to_sllc_sel1;
wire        from_sllc_fire;
wire        from_sllc_sel0;
wire        from_sllc_sel1;

wire [2:0]  rx_flit_pack0;
wire [2:0]  rx_flit_pack1;
wire [2:0]  rx_flit_pack;
wire [2:0]  tx_flit_pack;
wire [2:0]  tx_flit_pack0;
wire [2:0]  tx_flit_pack1;
wire        rx_nocinfo_unused;

reg         to_sllc_arb_sel;
reg         from_sllc_arb_sel;

// RX direction has no nocinfo on the upstream input, so the local packed flit
// inserts a zero in the middle bit: {patag, nocinfo, flit}.
assign rx_flit_pack0 = {rx_flitpatag0, 1'b0, rx_flit0};
assign rx_flit_pack1 = {rx_flitpatag1, 1'b0, rx_flit1};
assign {rx_flitpatag, rx_nocinfo_unused, rx_flit} = rx_flit_pack;
assign rx_hint = 1'b0;

// TX direction carries nocinfo from SLLC to each NOC port.  The TXBUF flit bus
// transports {patag, nocinfo, flit} as one compact payload.
assign tx_flit_pack = {tx_flitpatag, tx_nocinfo, tx_flit};
assign {tx_flitpatag0, tx_nocinfo0, tx_flit0} = tx_flit_pack0;
assign {tx_flitpatag1, tx_nocinfo1, tx_flit1} = tx_flit_pack1;
assign tx_push0 = 1'b0;
assign tx_push1 = 1'b0;

//------------------------------------------------------------------------------
// NOC0/NOC1 -> SLLC direction
//------------------------------------------------------------------------------
SKY_RXBUF u_rxbuf_noc0 (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .flitpend        (rx_flitpend0        ),
    .flitv           (rx_flitv0           ),
    .flit            (rx_flit_pack0       ),
    .rxbuf_vld       (rxbuf_vld0          ),
    .rxbuf_pld       (rxbuf_pld0          ),
    .rxbuf_rdy       (rxbuf_rdy0          ),
    .rxretlcrdv      (rx_retlcrdv0        ),
    .rxlcrdv         (rx_lcrdv0           ),
    .rxlcrdhold      (rxlcrdhold0         )
);

SKY_RXBUF u_rxbuf_noc1 (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .flitpend        (rx_flitpend1        ),
    .flitv           (rx_flitv1           ),
    .flit            (rx_flit_pack1       ),
    .rxbuf_vld       (rxbuf_vld1          ),
    .rxbuf_pld       (rxbuf_pld1          ),
    .rxbuf_rdy       (rxbuf_rdy1          ),
    .rxretlcrdv      (rx_retlcrdv1        ),
    .rxlcrdv         (rx_lcrdv1           ),
    .rxlcrdhold      (rxlcrdhold1         )
);

// tx begin: fair arbitration from two NOC RX buffers into the SLLC TX buffer.
// RXBUF pop happens only when the selected entry can enter the downstream
// TXBUF, so credit returns to exactly one upstream port.
assign to_sllc_sel0          = rxbuf_vld0 & (~rxbuf_vld1 | ~to_sllc_arb_sel);
assign to_sllc_sel1          = rxbuf_vld1 & (~rxbuf_vld0 |  to_sllc_arb_sel);
assign to_sllc_fire          = txbuf_rdy_sllc & (to_sllc_sel0 | to_sllc_sel1);

assign txbuf_flitv_sllc      = to_sllc_sel0 | to_sllc_sel1;
assign txbuf_flitpend_sllc   = txbuf_flitv_sllc;
assign txbuf_flit_sllc       = to_sllc_sel0 ? rxbuf_pld0 :
                                to_sllc_sel1 ? rxbuf_pld1 : 3'b000;

assign rxbuf_rdy0            = txbuf_rdy_sllc & to_sllc_sel0;
assign rxbuf_rdy1            = txbuf_rdy_sllc & to_sllc_sel1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        to_sllc_arb_sel <= 1'b0;
    end else if (to_sllc_fire) begin
        to_sllc_arb_sel <= to_sllc_sel0;
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
    .flitpend        (rx_flitpend         ),
    .flitv           (rx_flitv            ),
    .flit            (rx_flit_pack        ),
    .txlcrdv         (rx_lcrdv            ),
    .txretlcrdv      (rx_retlcrdv         )
);

//------------------------------------------------------------------------------
// SLLC -> NOC0/NOC1 direction
//------------------------------------------------------------------------------
SKY_RXBUF u_rxbuf_sllc (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .flitpend        (tx_flitpend         ),
    .flitv           (tx_flitv            ),
    .flit            (tx_flit_pack        ),
    .rxbuf_vld       (rxbuf_vld_sllc      ),
    .rxbuf_pld       (rxbuf_pld_sllc      ),
    .rxbuf_rdy       (rxbuf_rdy_sllc      ),
    .rxretlcrdv      (tx_retlcrdv         ),
    .rxlcrdv         (tx_lcrdv            ),
    .rxlcrdhold      (rxlcrdhold_sllc     )
);

// rx begin: fair distribution from the SLLC RX buffer into two NOC TX buffers.
// If only one NOC TXBUF is ready, send to that side.  If both are ready, toggle
// priority after each accepted flit to avoid long-term bias.
assign from_sllc_sel0        = rxbuf_vld_sllc & txbuf_rdy0 &
                               (~txbuf_rdy1 | ~from_sllc_arb_sel);
assign from_sllc_sel1        = rxbuf_vld_sllc & txbuf_rdy1 &
                               (~txbuf_rdy0 |  from_sllc_arb_sel);
assign from_sllc_fire        = from_sllc_sel0 | from_sllc_sel1;

assign txbuf_flitv0          = from_sllc_sel0;
assign txbuf_flitpend0       = from_sllc_sel0;
assign txbuf_flit0           = rxbuf_pld_sllc;

assign txbuf_flitv1          = from_sllc_sel1;
assign txbuf_flitpend1       = from_sllc_sel1;
assign txbuf_flit1           = rxbuf_pld_sllc;

assign rxbuf_rdy_sllc        = from_sllc_fire;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        from_sllc_arb_sel <= 1'b0;
    end else if (from_sllc_fire) begin
        from_sllc_arb_sel <= from_sllc_sel0;
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
    .flitpend        (tx_flitpend0        ),
    .flitv           (tx_flitv0           ),
    .flit            (tx_flit_pack0       ),
    .txlcrdv         (tx_lcrdv0           ),
    .txretlcrdv      (tx_retlcrdv0        )
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
    .flitpend        (tx_flitpend1        ),
    .flitv           (tx_flitv1           ),
    .flit            (tx_flit_pack1       ),
    .txlcrdv         (tx_lcrdv1           ),
    .txretlcrdv      (tx_retlcrdv1        )
);

endmodule
