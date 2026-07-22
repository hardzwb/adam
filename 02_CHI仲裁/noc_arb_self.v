// One CHI traffic channel inside a port interface.
`define CHI_CHANNEL_SIGNALS(CH) \
logic tx``CH``flitpend; \
logic tx``CH``flitv; \
logic tx``CH``flit; \
logic tx``CH``flitpatag; \
logic tx``CH``lcrdv; \
logic tx``CH``retlcrdv; \
logic tx``CH``nocinfo; \
logic tx``CH``push; \
logic rx``CH``flitpend; \
logic rx``CH``flitv; \
logic rx``CH``flit; \
logic rx``CH``flitpatag; \
logic rx``CH``lcrdv; \
logic rx``CH``retlcrdv; \
logic rx``CH``hint;

// NOC-facing modport directions are from NOC_ARB's point of view.
`define CHI_NOC_MODPORT(CH) \
   ,output tx``CH``flitpend \
   ,output tx``CH``flitv \
   ,output tx``CH``flit \
   ,output tx``CH``flitpatag \
   ,input  tx``CH``lcrdv \
   ,output tx``CH``retlcrdv \
   ,output tx``CH``nocinfo \
   ,output tx``CH``push \
   ,input  rx``CH``flitpend \
   ,input  rx``CH``flitv \
   ,input  rx``CH``flit \
   ,input  rx``CH``flitpatag \
   ,output rx``CH``lcrdv \
   ,input  rx``CH``retlcrdv \
   ,input  rx``CH``hint

// SLLC-facing modport directions are from NOC_ARB's point of view.
`define CHI_SLLC_MODPORT(CH) \
   ,input  tx``CH``flitpend \
   ,input  tx``CH``flitv \
   ,input  tx``CH``flit \
   ,input  tx``CH``flitpatag \
   ,output tx``CH``lcrdv \
   ,input  tx``CH``retlcrdv \
   ,input  tx``CH``nocinfo \
   ,input  tx``CH``push \
   ,output rx``CH``flitpend \
   ,output rx``CH``flitv \
   ,output rx``CH``flit \
   ,output rx``CH``flitpatag \
   ,input  rx``CH``lcrdv \
   ,output rx``CH``retlcrdv \
   ,output rx``CH``hint

interface CHI_NOC_ARB_IF;
logic txsactive;
logic rxsactive;
logic txlinkactivereq;
logic txlinkactiveack;
logic rxlinkactivereq;
logic rxlinkactiveack;

`CHI_CHANNEL_SIGNALS(req)
`CHI_CHANNEL_SIGNALS(dat)
`CHI_CHANNEL_SIGNALS(rsp)
`CHI_CHANNEL_SIGNALS(reqext)
`CHI_CHANNEL_SIGNALS(datext)
`CHI_CHANNEL_SIGNALS(rspext)

modport noc_side (
    output txsactive
   ,input  rxsactive
   ,output txlinkactivereq
   ,input  txlinkactiveack
   ,input  rxlinkactivereq
   ,output rxlinkactiveack
   `CHI_NOC_MODPORT(req)
   `CHI_NOC_MODPORT(dat)
   `CHI_NOC_MODPORT(rsp)
   `CHI_NOC_MODPORT(reqext)
   `CHI_NOC_MODPORT(datext)
   `CHI_NOC_MODPORT(rspext)
);

modport sllc_side (
    input  txsactive
   ,output rxsactive
   ,input  txlinkactivereq
   ,output txlinkactiveack
   ,output rxlinkactivereq
   ,input  rxlinkactiveack
   `CHI_SLLC_MODPORT(req)
   `CHI_SLLC_MODPORT(dat)
   `CHI_SLLC_MODPORT(rsp)
   `CHI_SLLC_MODPORT(reqext)
   `CHI_SLLC_MODPORT(datext)
   `CHI_SLLC_MODPORT(rspext)
);

endinterface

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
    .tx_flitpend0       (noc0.tx``CH``flitpend ), \
    .tx_flitv0          (noc0.tx``CH``flitv    ), \
    .tx_flit0           (noc0.tx``CH``flit     ), \
    .tx_flitpatag0      (noc0.tx``CH``flitpatag), \
    .tx_lcrdv0          (noc0.tx``CH``lcrdv    ), \
    .tx_retlcrdv0       (noc0.tx``CH``retlcrdv ), \
    .tx_nocinfo0        (noc0.tx``CH``nocinfo  ), \
    .tx_push0           (noc0.tx``CH``push     ), \
    .rx_flitpend0       (noc0.rx``CH``flitpend ), \
    .rx_flitv0          (noc0.rx``CH``flitv    ), \
    .rx_flit0           (noc0.rx``CH``flit     ), \
    .rx_flitpatag0      (noc0.rx``CH``flitpatag), \
    .rx_lcrdv0          (noc0.rx``CH``lcrdv    ), \
    .rx_retlcrdv0       (noc0.rx``CH``retlcrdv ), \
    .rx_hint0           (noc0.rx``CH``hint     ), \
    .tx_flitpend1       (noc1.tx``CH``flitpend ), \
    .tx_flitv1          (noc1.tx``CH``flitv    ), \
    .tx_flit1           (noc1.tx``CH``flit     ), \
    .tx_flitpatag1      (noc1.tx``CH``flitpatag), \
    .tx_lcrdv1          (noc1.tx``CH``lcrdv    ), \
    .tx_retlcrdv1       (noc1.tx``CH``retlcrdv ), \
    .tx_nocinfo1        (noc1.tx``CH``nocinfo  ), \
    .tx_push1           (noc1.tx``CH``push     ), \
    .rx_flitpend1       (noc1.rx``CH``flitpend ), \
    .rx_flitv1          (noc1.rx``CH``flitv    ), \
    .rx_flit1           (noc1.rx``CH``flit     ), \
    .rx_flitpatag1      (noc1.rx``CH``flitpatag), \
    .rx_lcrdv1          (noc1.rx``CH``lcrdv    ), \
    .rx_retlcrdv1       (noc1.rx``CH``retlcrdv ), \
    .rx_hint1           (noc1.rx``CH``hint     ), \
    .tx_flitpend        (sllc.tx``CH``flitpend ), \
    .tx_flitv           (sllc.tx``CH``flitv    ), \
    .tx_flit            (sllc.tx``CH``flit     ), \
    .tx_flitpatag       (sllc.tx``CH``flitpatag), \
    .tx_lcrdv           (sllc.tx``CH``lcrdv    ), \
    .tx_retlcrdv        (sllc.tx``CH``retlcrdv ), \
    .tx_nocinfo         (sllc.tx``CH``nocinfo  ), \
    .tx_push            (sllc.tx``CH``push     ), \
    .rx_flitpend        (sllc.rx``CH``flitpend ), \
    .rx_flitv           (sllc.rx``CH``flitv    ), \
    .rx_flit            (sllc.rx``CH``flit     ), \
    .rx_flitpatag       (sllc.rx``CH``flitpatag), \
    .rx_lcrdv           (sllc.rx``CH``lcrdv    ), \
    .rx_retlcrdv        (sllc.rx``CH``retlcrdv ), \
    .rx_hint            (sllc.rx``CH``hint     )  \
);

module NOC_ARB #(
    parameter FIFO_DEPTH = 4
) (
    input wire clk
   ,input wire rst_n
   ,CHI_NOC_ARB_IF.noc_side  noc0
   ,CHI_NOC_ARB_IF.noc_side  noc1
   ,CHI_NOC_ARB_IF.sllc_side sllc
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
    .txsactive       (noc0.txsactive      ),
    .rxsactive       (noc0.rxsactive      ),
    .txlinkactivereq (noc0.txlinkactivereq),
    .rxlinkactivereq (noc0.rxlinkactivereq),
    .rxlinkactiveack (noc0.rxlinkactiveack),
    .txlinkactiveack (noc0.txlinkactiveack),
    .rxlcrdhold      (rxlcrdhold0         ),
    .txlcrdreturn    (txlcrdreturn0       ),
    .txlcrdreceive   (txlcrdreceive0      ),
    .txflitenable    (txflitenable0       )
);

SKY_LINK_CTRL_ACTIVE u_link_ctrl_noc1 (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .txsactive       (noc1.txsactive      ),
    .rxsactive       (noc1.rxsactive      ),
    .txlinkactivereq (noc1.txlinkactivereq),
    .rxlinkactivereq (noc1.rxlinkactivereq),
    .rxlinkactiveack (noc1.rxlinkactiveack),
    .txlinkactiveack (noc1.txlinkactiveack),
    .rxlcrdhold      (rxlcrdhold1         ),
    .txlcrdreturn    (txlcrdreturn1       ),
    .txlcrdreceive   (txlcrdreceive1      ),
    .txflitenable    (txflitenable1       )
);

SKY_LINK_CTRL_ACTIVE u_link_ctrl_sllc (
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .txsactive       (sllc.rxsactive      ),
    .rxsactive       (sllc.txsactive      ),
    .txlinkactivereq (sllc.rxlinkactivereq),
    .rxlinkactivereq (sllc.txlinkactivereq),
    .rxlinkactiveack (sllc.txlinkactiveack),
    .txlinkactiveack (sllc.rxlinkactiveack),
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

`undef CHI_CHANNEL_SIGNALS
`undef CHI_NOC_MODPORT
`undef CHI_SLLC_MODPORT
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
