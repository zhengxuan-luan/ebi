module m1_ebi
    import ebi_pkg::*;
    import rvh_l1d_pkg::*;
(
    input logic                 m1_clk,
    input logic                 bus_clk,
    input logic                 rst,
        // AR
    input  logic                l1d_l2_req_arvalid_i,
    output logic                l1d_l2_req_arready_o,
    input  cache_mem_if_ar_t    l1d_l2_req_ar_i,
        // AW   
    input  logic                l1d_l2_req_awvalid_i,
    output logic                l1d_l2_req_awready_o,
    input  cache_mem_if_aw_t    l1d_l2_req_aw_i,
        // W    
    input  logic                l1d_l2_req_wvalid_i,
    output logic                l1d_l2_req_wready_o,
    input  cache_mem_if_w_t     l1d_l2_req_w_i,
        // B    
    output logic                l2_l1d_resp_bvalid_o,
    input  logic                l2_l1d_resp_bready_i,
    output cache_mem_if_b_t     l2_l1d_resp_b_o,
        // R    
    output logic                l2_l1d_resp_rvalid_o,
    input  logic                l2_l1d_resp_rready_i,
    output cache_mem_if_r_t      l2_l1d_resp_r_o,
        // snoop addr   
    output logic                l2_snp_req_if_acvalid_o,
    input  logic                l2_snp_req_if_acready_i,
    output cache_mem_if_ac_t    l2_snp_req_if_ac_o,
        // snoop resp   
    input  logic                l2_snp_resp_if_crvalid_i,
    output logic                l2_snp_resp_if_crready_o,
    input  cache_mem_if_cr_t    l2_snp_resp_if_cr_i,
        // snoop data   
    input  logic                l2_snp_resp_if_cdvalid_i,
    output logic                l2_snp_resp_if_cdready_o,
    input  cache_mem_if_cd_t    l2_snp_resp_if_cd_i,

        //external interface
    output logic                m1_m2_bus_o,
    input  logic                m2_m1_credit_i,
    input  logic                m2_m1_bus_i,
    output logic                m1_m2_credit_o
);
// for tx
logic [M1_M2_CHANNEL_NUM-1:0][MAX_M1_M2_MESSAGE_LENGTH-1:0] m1_m2_channel_hs_entry;
logic [M1_M2_CHANNEL_NUM-1:0] m1_m2_channel_entry_valid, m1_m2_channel_push_ready;
// for rx
logic [M1_M2_CHANNEL_NUM-1:0] m2_m1_vc_valid, entry_if_recv_success;
logic [M1_M2_CHANNEL_NUM-1:0][MAX_M1_M2_MESSAGE_LENGTH-1:0] m2_m1_vc_entry_list;


// handshake module which control interface signal turning to unified signal
m1_ebi_if_handshake u_m1_ebi_if_handshake(
    .m1_clk_i(m1_clk),
    .rst_i(rst),
    // for tx
    .m1_m2_channel_entry_valid_o(m1_m2_channel_entry_valid), 
    .m1_m2_channel_push_ready_i(m1_m2_channel_push_ready),
    .m1_m2_channel_hs_entry_o(m1_m2_channel_hs_entry),
    // for rx
    .entry_if_recv_success_o(entry_if_recv_success), 
    .m2_m1_vc_valid_i(m2_m1_vc_valid),
    .m2_m1_vc_entry_list_i(m2_m1_vc_entry_list),

    .l1d_l2_req_arvalid_i(l1d_l2_req_arvalid_i),
    .l1d_l2_req_arready_o(l1d_l2_req_arready_o),
    .l1d_l2_req_ar_i(l1d_l2_req_ar_i),
    .l1d_l2_req_awvalid_i(l1d_l2_req_awvalid_i),
    .l1d_l2_req_awready_o(l1d_l2_req_awready_o),
    .l1d_l2_req_aw_i(l1d_l2_req_aw_i),
    .l1d_l2_req_wvalid_i(l1d_l2_req_wvalid_i),
    .l1d_l2_req_wready_o(l1d_l2_req_wready_o),
    .l1d_l2_req_w_i(l1d_l2_req_w_i),
    .l2_l1d_resp_bvalid_o(l2_l1d_resp_bvalid_o),
    .l2_l1d_resp_bready_i(l2_l1d_resp_bready_i),
    .l2_l1d_resp_b_o(l2_l1d_resp_b_o),
    .l2_l1d_resp_rvalid_o(l2_l1d_resp_rvalid_o),
    .l2_l1d_resp_rready_i(l2_l1d_resp_rready_i),
    .l2_l1d_resp_r_o(l2_l1d_resp_r_o),
    .l2_snp_req_if_acvalid_o(l2_snp_req_if_acvalid_o),
    .l2_snp_req_if_acready_i(l2_snp_req_if_acready_i),
    .l2_snp_req_if_ac_o(l2_snp_req_if_ac_o),
    .l2_snp_resp_if_crvalid_i(l2_snp_resp_if_crvalid_i),
    .l2_snp_resp_if_crready_o(l2_snp_resp_if_crready_o),
    .l2_snp_resp_if_cr_i(l2_snp_resp_if_cr_i),
    .l2_snp_resp_if_cdvalid_i(l2_snp_resp_if_cdvalid_i),
    .l2_snp_resp_if_cdready_o(l2_snp_resp_if_cdready_o),
    .l2_snp_resp_if_cd_i(l2_snp_resp_if_cd_i)
);

ebi_tx #(
    .CHANNEL_NUM(M1_M2_CHANNEL_NUM),
    .CHANNEL_NUM_WIDTH(M1_M2_CHANNEL_NUM_WIDTH),
    .MAX_MESSAGE_LENGTH(MAX_M1_M2_MESSAGE_LENGTH),
    .MAX_MESSAGE_WIDTH(MAX_M1_M2_MESSAGE_WIDTH),
    .CHANNEL_LENGTH_LIST(M1_M2_CHANNEL_LENGTH_LIST)
) u_m1_tx(
    .if_clk(m1_clk),
    .bus_clk(bus_clk),
    .rst(rst),
    .channel_hs_entry(m1_m2_channel_hs_entry),  // wire here
    .channel_entry_valid(m1_m2_channel_entry_valid),  
    .channel_push_ready(m1_m2_channel_push_ready),
    .bus_out(m1_m2_bus_o),
    .credit_in(m2_m1_credit_i)
);

ebi_rx #(
    .CHANNEL_NUM(M2_M1_CHANNEL_NUM),
    .CHANNEL_NUM_WIDTH(M2_M1_CHANNEL_NUM_WIDTH),
    .MAX_MESSAGE_LENGTH(MAX_M2_M1_MESSAGE_LENGTH),
    .MAX_MESSAGE_WIDTH(MAX_M2_M1_MESSAGE_WIDTH),
    .CHANNEL_LENGTH_LIST(M2_M1_CHANNEL_LENGTH_LIST)
) u_m1_rx (
    .if_clk(m1_clk),
    .bus_clk(bus_clk),
    .rst(rst),
    .vc_entry_list(m2_m1_vc_entry_list),  // wire here
    .vc_valid(m2_m1_vc_valid),  
    .entry_if_recv_success(entry_if_recv_success),
    .bus_in(m2_m1_bus_i),
    .credit_out(m1_m2_credit_o)
);

endmodule: m1_ebi