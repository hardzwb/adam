module SLLC_TX_BUFFER(
    input clk
    input rst_n
    input dft_glb_gt_se

    input sllc_utl_sky_rx
    input sllc_phy_utl
    input cfg_sky_rx_cbusy_rsp_en

    input flitpend
    input flitv
    input [FLIT_V -1:0] flit

    output tx_vld
    output [PLD_W -1:0] tx_pld
    input sllc_tx_en //rdy
    input phy_tx_crd_exist
)
