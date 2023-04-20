module m2_ebi
    import ebi_pkg::*;
    import rvh_l1d_pkg::*;
(
    input logic                 m2_clk,
    input logic                 bus_clk,
    input logic                 rst,
        // AR
    output logic                l1d_scu_req_arvalid_o,
    input  logic                l1d_scu_req_arready_i,
    output cache_mem_if_ar_t    l1d_scu_req_ar_o,
        // AW   
    output logic                l1d_scu_req_awvalid_o,
    input  logic                l1d_scu_req_awready_i,
    output cache_mem_if_aw_t    l1d_scu_req_aw_o,
        // W    
    output logic                l1d_scu_req_wvalid_o,
    input  logic                l1d_scu_req_wready_i,
    output cache_mem_if_w_t     l1d_scu_req_w_o,
        // B    
    input  logic                scu_l1d_resp_bvalid_i,
    output logic                scu_l1d_resp_bready_o,
    input  cache_mem_if_b_t     scu_l1d_resp_b_i,
        // R    
    input  logic                scu_l1d_resp_rvalid_i,
    output logic                scu_l1d_resp_rready_o,
    input cache_mem_if_r_t      scu_l1d_resp_r_i,
        // snoop addr   
    input  logic                l2_snp_req_if_acvalid_i,
    output logic                l2_snp_req_if_acready_o,
    input  cache_mem_if_ac_t    l2_snp_req_if_ac_i,
        // snoop resp   
    output logic                l2_snp_resp_if_crvalid_o,
    input  logic                l2_snp_resp_if_crready_i,
    output cache_mem_if_cr_t    l2_snp_resp_if_cr_o,
        // snoop data   
    output logic                l2_snp_resp_if_cdvalid_o,
    input  logic                l2_snp_resp_if_cdready_i,
    output cache_mem_if_cd_t    l2_snp_resp_if_cd_o,

        //external interface
    input  logic                m1_m2_bus_i,
    output logic                m2_m1_credit_o,
    output logic                m2_m1_bus_o,
    input  logic                m1_m2_credit_i
);
logic [M1_M2_CHANNEL_NUM-1:0] m1_m2_vc_valid, entry_if_recv_success;
logic [M1_M2_CHANNEL_NUM-1:0][MAX_M1_M2_MESSAGE_LENGTH-1:0] m1_m2_vc_entry_list; // they are wire here

logic [M2_M1_CHANNEL_NUM-1:0][MAX_M2_M1_MESSAGE_LENGTH-1:0] m2_m1_channel_hs_entry;
logic [M2_M1_CHANNEL_NUM-1:0] m2_m1_channel_entry_valid, m2_m1_channel_push_ready;

ebi_rx #(
    .CHANNEL_NUM(M1_M2_CHANNEL_NUM),
    .CHANNEL_NUM_WIDTH(M1_M2_CHANNEL_NUM_WIDTH),
    .MAX_MESSAGE_LENGTH(MAX_M1_M2_MESSAGE_LENGTH),
    .MAX_MESSAGE_WIDTH(MAX_M1_M2_MESSAGE_WIDTH),
    .CHANNEL_LENGTH_LIST(M1_M2_CHANNEL_LENGTH_LIST)
) u_m2_rx (
    .if_clk(m2_clk),
    .bus_clk(bus_clk),
    .rst(rst),
    .vc_entry_list(m1_m2_vc_entry_list),  // wire here
    .vc_valid(m1_m2_vc_valid),  
    .entry_if_recv_success(entry_if_recv_success),
    .bus_in(m1_m2_bus_i),
    .credit_out(m2_m1_credit_o)
);

ebi_tx #(
    .CHANNEL_NUM(M2_M1_CHANNEL_NUM),
    .CHANNEL_NUM_WIDTH(M2_M1_CHANNEL_NUM_WIDTH),
    .MAX_MESSAGE_LENGTH(MAX_M2_M1_MESSAGE_LENGTH),
    .MAX_MESSAGE_WIDTH(MAX_M2_M1_MESSAGE_WIDTH),
    .CHANNEL_LENGTH_LIST(M2_M1_CHANNEL_LENGTH_LIST)
) u_m2_tx(
    .if_clk(m2_clk),
    .bus_clk(bus_clk),
    .rst(rst),
    .channel_hs_entry(m2_m1_channel_hs_entry),  // wire here
    .channel_entry_valid(m2_m1_channel_entry_valid),  
    .channel_push_ready(m2_m1_channel_push_ready),
    .bus_out(m2_m1_bus_o),
    .credit_in(m1_m2_credit_i)
);

m2_ebi_if_handshake u_m2_ebi_if_handshake(
    .m2_clk_i(m2_clk),
    .rst_i(rst),

    .m2_m1_channel_entry_valid_o(m2_m1_channel_entry_valid), 
    .m2_m1_channel_push_ready_i(m2_m1_channel_push_ready),
    .m2_m1_channel_hs_entry_o(m2_m1_channel_hs_entry),

    .entry_if_recv_success_o(entry_if_recv_success), 
    .m1_m2_vc_valid_i(m1_m2_vc_valid),
    .m1_m2_vc_entry_list_i(m1_m2_vc_entry_list),

    .l1d_scu_req_arvalid_o(l1d_scu_req_arvalid_o),
    .l1d_scu_req_arready_i(l1d_scu_req_arready_i),
    .l1d_scu_req_ar_o(l1d_scu_req_ar_o),
    .l1d_scu_req_awvalid_o(l1d_scu_req_awvalid_o),
    .l1d_scu_req_awready_i(l1d_scu_req_awready_i),
    .l1d_scu_req_aw_o(l1d_scu_req_aw_o),
    .l1d_scu_req_wvalid_o(l1d_scu_req_wvalid_o),
    .l1d_scu_req_wready_i(l1d_scu_req_wready_i),
    .l1d_scu_req_w_o(l1d_scu_req_w_o),
    .scu_l1d_resp_bvalid_i(scu_l1d_resp_bvalid_i),
    .scu_l1d_resp_bready_o(scu_l1d_resp_bready_o),
    .scu_l1d_resp_b_i(scu_l1d_resp_b_i),
    .scu_l1d_resp_rvalid_i(scu_l1d_resp_rvalid_i),
    .scu_l1d_resp_rready_o(scu_l1d_resp_rready_o),
    .scu_l1d_resp_r_i(scu_l1d_resp_r_i),
    .l2_snp_req_if_acvalid_i(l2_snp_req_if_acvalid_i),
    .l2_snp_req_if_acready_o(l2_snp_req_if_acready_o),
    .l2_snp_req_if_ac_i(l2_snp_req_if_ac_i),
    .l2_snp_resp_if_crvalid_o(l2_snp_resp_if_crvalid_o),
    .l2_snp_resp_if_crready_i(l2_snp_resp_if_crready_i),
    .l2_snp_resp_if_cr_o(l2_snp_resp_if_cr_o),
    .l2_snp_resp_if_cdvalid_o(l2_snp_resp_if_cdvalid_o),
    .l2_snp_resp_if_cdready_i(l2_snp_resp_if_cdready_i),
    .l2_snp_resp_if_cd_o(l2_snp_resp_if_cd_o)
);

// wrapper port assignment

endmodule: m2_ebi