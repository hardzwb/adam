module SKY_LINK_CTRL_ACTIVE (
    input  wire clk
   ,input  wire rst_n
   ,output  wire txsactive
   ,input  wire rxsactive
    ,output  wire txlinkactivereq
    ,input wire rxlinkactivereq
    ,output wire rxlinkactiveack
    ,input wire txlinkactiveack

    ,output wire rxlcrdhold
    ,output wire txlcrdreturn
    ,output wire txlcrdreceive
    ,output wire txflitenable
);

endmodule

module SKY_RXBUF (
    input  wire  clk
   ,input  wire  rst_n
   ,input  wire  flitpend
   ,input  wire  flitv
   ,input  wire [2:0] flit

   ,output wire  rxbuf_vld
   ,output wire [2:0] rxbuf_pld
   ,input  wire  rxbuf_rdy

   ,input  wire  rxretlcrdv
   ,output wire  rxlcrdv
   ,input  wire  rxlcrdhold
);

endmodule

module SKY_TXBUF (
    input  wire clk
   ,input  wire rst_n
   ,input  wire txbuf_flitv
   ,input  wire txbuf_flitpend
   ,input  wire [2:0] txbuf_flit
   ,output wire txbuf_rdy
   ,input  wire txlcrdreceive
   ,input  wire txflitenable
   ,input  wire txlcrdreturn

   ,output wire flitpend
   ,output wire flitv
   ,output wire [2:0] flit
   ,input txlcrdv
   ,output txretlcrdv
);

endmodule
