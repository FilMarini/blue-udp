`timescale 1ps / 1ps


module UdpIpArpEthCmacRxTxWrapper#(
    parameter GT_LANE_WIDTH = 4,
    parameter XDMA_AXIS_TDATA_WIDTH = 512,
    parameter XDMA_AXIS_TKEEP_WIDTH = 64,
    parameter XDMA_AXIS_TUSER_WIDTH = 1
)(
    input xdma_clk,
    input xdma_reset,

    input udp_clk,
    input udp_reset,

    input gt_ref_clk_p,
    input gt_ref_clk_n,
    input gt_init_clk,
    input gt_sys_reset,

    input  xdma_rx_axis_tready,
    output xdma_rx_axis_tvalid,
    output xdma_rx_axis_tlast,
    output [XDMA_AXIS_TDATA_WIDTH - 1 : 0] xdma_rx_axis_tdata,
    output [XDMA_AXIS_TKEEP_WIDTH - 1 : 0] xdma_rx_axis_tkeep,
    output [XDMA_AXIS_TUSER_WIDTH - 1 : 0] xdma_rx_axis_tuser,

    input  xdma_tx_axis_tvalid,
    output xdma_tx_axis_tready,
    input  xdma_tx_axis_tlast,
    input [XDMA_AXIS_TDATA_WIDTH - 1 : 0] xdma_tx_axis_tdata,
    input [XDMA_AXIS_TKEEP_WIDTH - 1 : 0] xdma_tx_axis_tkeep,
    input [XDMA_AXIS_TUSER_WIDTH - 1 : 0] xdma_tx_axis_tuser,

    // Serdes
    input  [GT_LANE_WIDTH - 1 : 0] gt_rxn_in,
    input  [GT_LANE_WIDTH - 1 : 0] gt_rxp_in,
    output [GT_LANE_WIDTH - 1 : 0] gt_txn_out,
    output [GT_LANE_WIDTH - 1 : 0] gt_txp_out
);
    localparam CMAC_AXIS_TDATA_WIDTH = 512;
    localparam CMAC_AXIS_TKEEP_WIDTH = 64;
    localparam CMAC_AXIS_TUSER_WIDTH = 1;

    wire [(GT_LANE_WIDTH * 3)-1 :0]    gt_loopback_in;
    //// For other GT loopback options please change the value appropriately
    //// For example, for Near End PMA loopback for 4 Lanes update the gt_loopback_in = {4{3'b010}};
    //// For more information and settings on loopback, refer GT Transceivers user guide
    assign gt_loopback_in  = {GT_LANE_WIDTH{3'b000}};

    wire            gtwiz_reset_tx_datapath;
    wire            gtwiz_reset_rx_datapath;
    assign gtwiz_reset_tx_datapath    = 1'b0;
    assign gtwiz_reset_rx_datapath    = 1'b0;


    // GT Signals
    wire            gt_txusrclk2;
    wire            gt_usr_tx_reset;
    wire            gt_usr_rx_reset;

    wire            gt_rx_axis_tvalid;
    wire            gt_rx_axis_tlast;
    wire [CMAC_AXIS_TDATA_WIDTH - 1 : 0] gt_rx_axis_tdata;
    wire [CMAC_AXIS_TKEEP_WIDTH - 1 : 0] gt_rx_axis_tkeep;
    wire [CMAC_AXIS_TUSER_WIDTH - 1 : 0] gt_rx_axis_tuser;

    wire            gt_stat_rx_aligned;
    wire [8:0]      gt_stat_rx_pause_req;
    wire            gt_ctl_rx_enable;
    wire            gt_ctl_rx_force_resync;
    wire            gt_ctl_rx_test_pattern;
    wire            gt_ctl_rx_check_etype_gcp;
    wire            gt_ctl_rx_check_etype_gpp;
    wire            gt_ctl_rx_check_etype_pcp;
    wire            gt_ctl_rx_check_etype_ppp;
    wire            gt_ctl_rx_check_mcast_gcp;
    wire            gt_ctl_rx_check_mcast_gpp;
    wire            gt_ctl_rx_check_mcast_pcp;
    wire            gt_ctl_rx_check_mcast_ppp;
    wire            gt_ctl_rx_check_opcode_gcp;
    wire            gt_ctl_rx_check_opcode_gpp;
    wire            gt_ctl_rx_check_opcode_pcp;
    wire            gt_ctl_rx_check_opcode_ppp;
    wire            gt_ctl_rx_check_sa_gcp;
    wire            gt_ctl_rx_check_sa_gpp;
    wire            gt_ctl_rx_check_sa_pcp;
    wire            gt_ctl_rx_check_sa_ppp;
    wire            gt_ctl_rx_check_ucast_gcp;
    wire            gt_ctl_rx_check_ucast_gpp;
    wire            gt_ctl_rx_check_ucast_pcp;
    wire            gt_ctl_rx_check_ucast_ppp;
    wire            gt_ctl_rx_enable_gcp;
    wire            gt_ctl_rx_enable_gpp;
    wire            gt_ctl_rx_enable_pcp;
    wire            gt_ctl_rx_enable_ppp;
    wire [8:0]      gt_ctl_rx_pause_ack;
    wire [8:0]      gt_ctl_rx_pause_enable;

    wire            gt_tx_axis_tready;
    wire            gt_tx_axis_tvalid;
    wire            gt_tx_axis_tlast;
    wire [CMAC_AXIS_TDATA_WIDTH - 1 : 0] gt_tx_axis_tdata;
    wire [CMAC_AXIS_TKEEP_WIDTH - 1 : 0] gt_tx_axis_tkeep;
    wire [CMAC_AXIS_TUSER_WIDTH - 1 : 0] gt_tx_axis_tuser;

    wire            gt_tx_ovfout;
    wire            gt_tx_unfout;
    wire            gt_ctl_tx_enable;
    wire            gt_ctl_tx_test_pattern;
    wire            gt_ctl_tx_send_idle;
    wire            gt_ctl_tx_send_rfi;
    wire            gt_ctl_tx_send_lfi;
    wire [8:0]      gt_ctl_tx_pause_enable;
    wire [15:0]     gt_ctl_tx_pause_quanta0;
    wire [15:0]     gt_ctl_tx_pause_quanta1;
    wire [15:0]     gt_ctl_tx_pause_quanta2;
    wire [15:0]     gt_ctl_tx_pause_quanta3;
    wire [15:0]     gt_ctl_tx_pause_quanta4;
    wire [15:0]     gt_ctl_tx_pause_quanta5;
    wire [15:0]     gt_ctl_tx_pause_quanta6;
    wire [15:0]     gt_ctl_tx_pause_quanta7;
    wire [15:0]     gt_ctl_tx_pause_quanta8;
    wire [8:0]      gt_ctl_tx_pause_req;
    wire            gt_ctl_tx_resend_pause;

    mkXdmaUdpIpArpEthCmacRxTx udp_inst1 (
        .xdma_clk               (xdma_clk        ),
        .xdma_reset             (xdma_reset      ),
        .cmac_rxtx_clk          (gt_txusrclk2    ),
        .cmac_rx_reset          (~gt_usr_rx_reset),
        .cmac_tx_reset          (~gt_usr_tx_reset),
        .udp_clk                (udp_clk         ),
        .udp_reset              (udp_reset       ),

        .cmac_tx_axis_tvalid    (gt_tx_axis_tvalid),
        .cmac_tx_axis_tdata     (gt_tx_axis_tdata ),
        .cmac_tx_axis_tkeep     (gt_tx_axis_tkeep ),
        .cmac_tx_axis_tlast     (gt_tx_axis_tlast ),
        .cmac_tx_axis_tuser     (gt_tx_axis_tuser ),
        .cmac_tx_axis_tready    (gt_tx_axis_tready),

        .tx_stat_ovfout         (gt_tx_ovfout),
        .tx_stat_unfout         (gt_tx_unfout),
        .tx_stat_rx_aligned     (gt_stat_rx_aligned),

        .tx_ctl_enable          (gt_ctl_tx_enable      ),
        .tx_ctl_test_pattern    (gt_ctl_tx_test_pattern),
        .tx_ctl_send_idle       (gt_ctl_tx_send_idle   ),
        .tx_ctl_send_lfi        (gt_ctl_tx_send_lfi    ),
        .tx_ctl_send_rfi        (gt_ctl_tx_send_rfi    ),
        .tx_ctl_reset           (),

        .tx_ctl_pause_enable    (gt_ctl_tx_pause_enable ),
        .tx_ctl_pause_req       (gt_ctl_tx_pause_req    ),
        .tx_ctl_pause_quanta0   (gt_ctl_tx_pause_quanta0),
        .tx_ctl_pause_quanta1   (gt_ctl_tx_pause_quanta1),
        .tx_ctl_pause_quanta2   (gt_ctl_tx_pause_quanta2),
        .tx_ctl_pause_quanta3   (gt_ctl_tx_pause_quanta3),
        .tx_ctl_pause_quanta4   (gt_ctl_tx_pause_quanta4),
        .tx_ctl_pause_quanta5   (gt_ctl_tx_pause_quanta5),
        .tx_ctl_pause_quanta6   (gt_ctl_tx_pause_quanta6),
        .tx_ctl_pause_quanta7   (gt_ctl_tx_pause_quanta7),
        .tx_ctl_pause_quanta8   (gt_ctl_tx_pause_quanta8),

        .cmac_rx_axis_tvalid    (gt_rx_axis_tvalid),
        .cmac_rx_axis_tdata     (gt_rx_axis_tdata ),
        .cmac_rx_axis_tkeep     (gt_rx_axis_tkeep ),
        .cmac_rx_axis_tlast     (gt_rx_axis_tlast ),
        .cmac_rx_axis_tuser     (gt_rx_axis_tuser ),
        .cmac_rx_axis_tready    (),

        .rx_stat_aligned        (gt_stat_rx_aligned    ),
        .rx_stat_pause_req      (gt_stat_rx_pause_req  ),
        .rx_ctl_enable          (gt_ctl_rx_enable      ),
        .rx_ctl_force_resync    (gt_ctl_rx_force_resync),
        .rx_ctl_test_pattern    (gt_ctl_rx_test_pattern),
        .rx_ctl_reset           (),
        .rx_ctl_pause_enable    (gt_ctl_rx_pause_enable),
        .rx_ctl_pause_ack       (gt_ctl_rx_pause_ack   ),

        .rx_ctl_enable_gcp      (gt_ctl_rx_enable_gcp),
        .rx_ctl_check_mcast_gcp (gt_ctl_rx_check_mcast_gcp),
        .rx_ctl_check_ucast_gcp (gt_ctl_rx_check_ucast_gcp),
        .rx_ctl_check_sa_gcp    (gt_ctl_rx_check_sa_gcp),
        .rx_ctl_check_etype_gcp (gt_ctl_rx_check_etype_gcp),
        .rx_ctl_check_opcode_gcp(gt_ctl_rx_check_opcode_gcp),
		
        .rx_ctl_enable_pcp      (gt_ctl_rx_enable_pcp),
        .rx_ctl_check_mcast_pcp (gt_ctl_rx_check_mcast_pcp),
        .rx_ctl_check_ucast_pcp (gt_ctl_rx_check_ucast_pcp),
        .rx_ctl_check_sa_pcp    (gt_ctl_rx_check_sa_pcp),
        .rx_ctl_check_etype_pcp (gt_ctl_rx_check_etype_pcp),
        .rx_ctl_check_opcode_pcp(gt_ctl_rx_check_opcode_pcp),
		
        .rx_ctl_enable_gpp      (gt_ctl_rx_enable_gpp),
        .rx_ctl_check_mcast_gpp (gt_ctl_rx_check_mcast_gpp),
        .rx_ctl_check_ucast_gpp (gt_ctl_rx_check_ucast_gpp),
        .rx_ctl_check_sa_gpp    (gt_ctl_rx_check_sa_gpp),
        .rx_ctl_check_etype_gpp (gt_ctl_rx_check_etype_gpp),
        .rx_ctl_check_opcode_gpp(gt_ctl_rx_check_opcode_gpp),
		
        .rx_ctl_enable_ppp      (gt_ctl_rx_enable_ppp),
        .rx_ctl_check_mcast_ppp (gt_ctl_rx_check_mcast_ppp),
        .rx_ctl_check_ucast_ppp (gt_ctl_rx_check_ucast_ppp),
        .rx_ctl_check_sa_ppp    (gt_ctl_rx_check_sa_ppp),
        .rx_ctl_check_etype_ppp (gt_ctl_rx_check_etype_ppp),
        .rx_ctl_check_opcode_ppp(gt_ctl_rx_check_opcode_ppp),

        .xdma_rx_axis_tvalid    (xdma_rx_axis_tvalid),
        .xdma_rx_axis_tdata     (xdma_rx_axis_tdata ),
        .xdma_rx_axis_tkeep     (xdma_rx_axis_tkeep ),
        .xdma_rx_axis_tlast     (xdma_rx_axis_tlast ),
        .xdma_rx_axis_tuser     (xdma_rx_axis_tuser ),
        .xdma_rx_axis_tready    (xdma_rx_axis_tready),

        .xdma_tx_axis_tvalid    (xdma_tx_axis_tvalid),
        .xdma_tx_axis_tdata     (xdma_tx_axis_tdata ),
        .xdma_tx_axis_tkeep     (xdma_tx_axis_tkeep ),
        .xdma_tx_axis_tlast     (xdma_tx_axis_tlast ),
        .xdma_tx_axis_tuser     (xdma_tx_axis_tuser ),
        .xdma_tx_axis_tready    (xdma_tx_axis_tready)
    );


    cmac_usplus_0 cmac_inst1(
        .gt_rxp_in                            (gt_rxp_in     ),
        .gt_rxn_in                            (gt_rxn_in     ),
        .gt_txp_out                           (gt_txp_out    ),
        .gt_txn_out                           (gt_txn_out    ),
        .gt_loopback_in                       (gt_loopback_in),
        
        .gtwiz_reset_tx_datapath              (gtwiz_reset_tx_datapath),
        .gtwiz_reset_rx_datapath              (gtwiz_reset_rx_datapath),
        .sys_reset                            (gt_sys_reset),
        .gt_ref_clk_p                         (gt_ref_clk_p),
        .gt_ref_clk_n                         (gt_ref_clk_n),
        .init_clk                             (gt_init_clk),

        .gt_txusrclk2                         (gt_txusrclk2),
        .usr_rx_reset                         (gt_usr_rx_reset),
        .usr_tx_reset                         (gt_usr_tx_reset),

        // RX
        .rx_axis_tvalid                       (gt_rx_axis_tvalid),
        .rx_axis_tdata                        (gt_rx_axis_tdata),
        .rx_axis_tkeep                        (gt_rx_axis_tkeep),
        .rx_axis_tlast                        (gt_rx_axis_tlast),
        .rx_axis_tuser                        (gt_rx_axis_tuser),
        
        .stat_rx_aligned                      (gt_stat_rx_aligned),
        .stat_rx_pause_req                    (gt_stat_rx_pause_req),
        .ctl_rx_enable                        (gt_ctl_rx_enable),
        .ctl_rx_force_resync                  (gt_ctl_rx_force_resync),
        .ctl_rx_test_pattern                  (gt_ctl_rx_test_pattern),
        .ctl_rx_check_etype_gcp               (gt_ctl_rx_check_etype_gcp),
        .ctl_rx_check_etype_gpp               (gt_ctl_rx_check_etype_gpp),
        .ctl_rx_check_etype_pcp               (gt_ctl_rx_check_etype_pcp),
        .ctl_rx_check_etype_ppp               (gt_ctl_rx_check_etype_ppp),
        .ctl_rx_check_mcast_gcp               (gt_ctl_rx_check_mcast_gcp),
        .ctl_rx_check_mcast_gpp               (gt_ctl_rx_check_mcast_gpp),
        .ctl_rx_check_mcast_pcp               (gt_ctl_rx_check_mcast_pcp),
        .ctl_rx_check_mcast_ppp               (gt_ctl_rx_check_mcast_ppp),
        .ctl_rx_check_opcode_gcp              (gt_ctl_rx_check_opcode_gcp),
        .ctl_rx_check_opcode_gpp              (gt_ctl_rx_check_opcode_gpp),
        .ctl_rx_check_opcode_pcp              (gt_ctl_rx_check_opcode_pcp),
        .ctl_rx_check_opcode_ppp              (gt_ctl_rx_check_opcode_ppp),
        .ctl_rx_check_sa_gcp                  (gt_ctl_rx_check_sa_gcp),
        .ctl_rx_check_sa_gpp                  (gt_ctl_rx_check_sa_gpp),
        .ctl_rx_check_sa_pcp                  (gt_ctl_rx_check_sa_pcp),
        .ctl_rx_check_sa_ppp                  (gt_ctl_rx_check_sa_ppp),
        .ctl_rx_check_ucast_gcp               (gt_ctl_rx_check_ucast_gcp),
        .ctl_rx_check_ucast_gpp               (gt_ctl_rx_check_ucast_gpp),
        .ctl_rx_check_ucast_pcp               (gt_ctl_rx_check_ucast_pcp),
        .ctl_rx_check_ucast_ppp               (gt_ctl_rx_check_ucast_ppp),
        .ctl_rx_enable_gcp                    (gt_ctl_rx_enable_gcp),
        .ctl_rx_enable_gpp                    (gt_ctl_rx_enable_gpp),
        .ctl_rx_enable_pcp                    (gt_ctl_rx_enable_pcp),
        .ctl_rx_enable_ppp                    (gt_ctl_rx_enable_ppp),
        .ctl_rx_pause_ack                     (gt_ctl_rx_pause_ack),
        .ctl_rx_pause_enable                  (gt_ctl_rx_pause_enable),
    

        // TX
        .tx_axis_tready                       (gt_tx_axis_tready),
        .tx_axis_tvalid                       (gt_tx_axis_tvalid),
        .tx_axis_tdata                        (gt_tx_axis_tdata),
        .tx_axis_tkeep                        (gt_tx_axis_tkeep),
        .tx_axis_tlast                        (gt_tx_axis_tlast),
        .tx_axis_tuser                        (gt_tx_axis_tuser),
        
        .tx_ovfout                            (gt_tx_ovfout),
        .tx_unfout                            (gt_tx_unfout),
        .ctl_tx_enable                        (gt_ctl_tx_enable),
        .ctl_tx_test_pattern                  (gt_ctl_tx_test_pattern),
        .ctl_tx_send_idle                     (gt_ctl_tx_send_idle),
        .ctl_tx_send_rfi                      (gt_ctl_tx_send_rfi),
        .ctl_tx_send_lfi                      (gt_ctl_tx_send_lfi),
        .ctl_tx_pause_enable                  (gt_ctl_tx_pause_enable),
        .ctl_tx_pause_req                     (gt_ctl_tx_pause_req),
        .ctl_tx_pause_quanta0                 (gt_ctl_tx_pause_quanta0),
        .ctl_tx_pause_quanta1                 (gt_ctl_tx_pause_quanta1),
        .ctl_tx_pause_quanta2                 (gt_ctl_tx_pause_quanta2),
        .ctl_tx_pause_quanta3                 (gt_ctl_tx_pause_quanta3),
        .ctl_tx_pause_quanta4                 (gt_ctl_tx_pause_quanta4),
        .ctl_tx_pause_quanta5                 (gt_ctl_tx_pause_quanta5),
        .ctl_tx_pause_quanta6                 (gt_ctl_tx_pause_quanta6),
        .ctl_tx_pause_quanta7                 (gt_ctl_tx_pause_quanta7),
        .ctl_tx_pause_quanta8                 (gt_ctl_tx_pause_quanta8),

        .ctl_tx_pause_refresh_timer0          (16'd0),
        .ctl_tx_pause_refresh_timer1          (16'd0),
        .ctl_tx_pause_refresh_timer2          (16'd0),
        .ctl_tx_pause_refresh_timer3          (16'd0),
        .ctl_tx_pause_refresh_timer4          (16'd0),
        .ctl_tx_pause_refresh_timer5          (16'd0),
        .ctl_tx_pause_refresh_timer6          (16'd0),
        .ctl_tx_pause_refresh_timer7          (16'd0),
        .ctl_tx_pause_refresh_timer8          (16'd0),
        .ctl_tx_resend_pause                  (1'b0 ),
        .tx_preamblein                        (56'd0),
        .core_rx_reset                        (1'b0 ),
        .core_tx_reset                        (1'b0 ),
        .rx_clk                               (gt_txusrclk2),
        .core_drp_reset                       (1'b0 ),
        .drp_clk                              (1'b0 ),
        .drp_addr                             (10'b0),
        .drp_di                               (16'b0),
        .drp_en                               (1'b0 ),
        .drp_do                               (),
        .drp_rdy                              (),
        .drp_we                               (1'b0 )
    );

endmodule