module m2_ebi_if_handshake
    import ebi_pkg::*;
    import rvh_l1d_pkg::*;
(
    input  logic                                 m2_clk_i,
    input  logic                                 rst_i,

    output logic [M2_M1_CHANNEL_NUM-1:0]         m2_m1_channel_entry_valid_o, 
    input  logic [M2_M1_CHANNEL_NUM-1:0]         m2_m1_channel_push_ready_i,
    output logic [M2_M1_CHANNEL_NUM-1:0][MAX_M2_M1_MESSAGE_LENGTH-1:0] m2_m1_channel_hs_entry_o, // there they are registers

    output logic [M1_M2_CHANNEL_NUM-1:0]         entry_if_recv_success_o, 
    input  logic [M1_M2_CHANNEL_NUM-1:0]         m1_m2_vc_valid_i,
    input  logic [M1_M2_CHANNEL_NUM-1:0][MAX_M1_M2_MESSAGE_LENGTH-1:0] m1_m2_vc_entry_list_i,

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
    output cache_mem_if_cd_t    l2_snp_resp_if_cd_o
);

logic [M1_M2_CHANNEL_NUM-1:0] m1_m2_entry_valid; 
logic [M1_M2_CHANNEL_NUM-1:0][MAX_M1_M2_MESSAGE_LENGTH-1:0] m1_m2_vc_entry_list; // registers here

logic [BURST_SIZE-1:0] w_count, r_count, cd_count;
logic en_w_count, en_r_count, en_cd_count;

assign en_w_count = l1d_scu_req_wvalid_o & l1d_scu_req_wready_i;
assign en_r_count = scu_l1d_resp_rvalid_i & scu_l1d_resp_rready_o;
assign en_cd_count = l2_snp_resp_if_cdvalid_o & l2_snp_resp_if_cdready_i;

always_ff @(posedge m2_clk_i) begin
    if(rst_i) begin
        m1_m2_entry_valid <= {M1_M2_CHANNEL_NUM{1'b0}};
        m1_m2_vc_entry_list <= {(MAX_M1_M2_MESSAGE_LENGTH * M1_M2_CHANNEL_NUM){1'b0}};
    end else begin
        for (int i = 0; i < M1_M2_CHANNEL_NUM; i++) begin
            if(entry_if_recv_success_o[i]) begin
                m1_m2_entry_valid[i] <= 1'b0;
            end else if((!m1_m2_entry_valid[i]) & m1_m2_vc_valid_i[i]) begin
                m1_m2_entry_valid[i] <= 1'b1;
                m1_m2_vc_entry_list[i] <= m1_m2_vc_entry_list_i[i];
            end
        end
    end
end

always_ff @(posedge m2_clk_i) begin
    if(rst_i) begin
        w_count  <= {BURST_SIZE{1'b0}};
        r_count  <= {BURST_SIZE{1'b0}};
        cd_count <= {BURST_SIZE{1'b0}};
    end else begin
        if(entry_if_recv_success_o[ID_W]) begin
            w_count <= {BURST_SIZE{1'b0}};
        end else if(en_w_count) begin
            w_count <= w_count + 1'b1;
        end

        if(entry_if_recv_success_o[ID_CD]) begin
            cd_count <= {BURST_SIZE{1'b0}};
        end else if(en_cd_count) begin
            cd_count <= cd_count + 1'b1;
        end
        if(m2_m1_channel_entry_valid_o[ID_R] & m2_m1_channel_push_ready_i[ID_R]) begin
            r_count <= {BURST_SIZE{1'b0}};
        end else if(en_r_count) begin
            r_count <= r_count + 1'b1;
        end
    end
end

assign l1d_scu_req_ar_o = m1_m2_vc_entry_list[ID_AR][AR_MESSAGE_LENGTH-1:0];
assign l1d_scu_req_aw_o = m1_m2_vc_entry_list[ID_AW][AW_MESSAGE_LENGTH-1:0];
assign l1d_scu_req_w_o = m1_m2_vc_entry_list[ID_W][w_count * W_BEAT_LENGTH +: W_BEAT_LENGTH];
assign l2_snp_resp_if_cr_o = m1_m2_vc_entry_list[ID_CR][AW_MESSAGE_LENGTH-1:0];
assign l2_snp_resp_if_cd_o = m1_m2_vc_entry_list[ID_CD][cd_count * CD_BEAT_LENGTH +: CD_BEAT_LENGTH];

assign entry_if_recv_success_o[ID_AR] = l1d_scu_req_arvalid_o & l1d_scu_req_arready_i;
assign entry_if_recv_success_o[ID_AW] = l1d_scu_req_awvalid_o & l1d_scu_req_awready_i;
assign entry_if_recv_success_o[ID_W] = l1d_scu_req_wvalid_o & l1d_scu_req_wready_i & l1d_scu_req_w_o.wlast;
assign entry_if_recv_success_o[ID_CR] = l2_snp_resp_if_crvalid_o & l2_snp_resp_if_crready_i;
assign entry_if_recv_success_o[ID_CD] = l2_snp_resp_if_cdvalid_o & l2_snp_resp_if_cdready_i & l2_snp_resp_if_cd_o.cdlast;

assign l1d_scu_req_arvalid_o = m1_m2_entry_valid[ID_AR];
assign l1d_scu_req_awvalid_o = m1_m2_entry_valid[ID_AW];
assign l1d_scu_req_wvalid_o = m1_m2_entry_valid[ID_W];
assign l2_snp_resp_if_crvalid_o = m1_m2_entry_valid[ID_CR];
assign l2_snp_resp_if_cdvalid_o = m1_m2_entry_valid[ID_CD];

always_ff @(posedge m2_clk_i) begin
    if(rst_i) begin
        m2_m1_channel_entry_valid_o <= {M2_M1_CHANNEL_NUM{1'b0}};
        m2_m1_channel_hs_entry_o <= {(M2_M1_CHANNEL_NUM*MAX_M2_M1_MESSAGE_LENGTH){1'b0}};
    end else begin
        // B
        if(scu_l1d_resp_bvalid_i & scu_l1d_resp_bready_o) begin
            m2_m1_channel_hs_entry_o[ID_B] <= scu_l1d_resp_b_i; // TODO: packed struct can assign other variable in this way? 
            m2_m1_channel_entry_valid_o[ID_B] <= 1'b1;
        end else begin 
            if(m2_m1_channel_entry_valid_o[ID_B] & m2_m1_channel_push_ready_i[ID_B]) begin
                m2_m1_channel_entry_valid_o[ID_B] <= 1'b0;
            end
        end
        // AC
        if(l2_snp_req_if_acvalid_i & l2_snp_req_if_acready_o) begin
            m2_m1_channel_hs_entry_o[ID_AC] <= l2_snp_req_if_ac_i; // TODO: packed struct can assign other variable in this way? 
            m2_m1_channel_entry_valid_o[ID_AC] <= 1'b1;
        end else begin 
            if(m2_m1_channel_entry_valid_o[ID_AC] & m2_m1_channel_push_ready_i[ID_AC]) begin
                m2_m1_channel_entry_valid_o[ID_AC] <= 1'b0;
            end
        end
        // R
        if(scu_l1d_resp_rvalid_i & scu_l1d_resp_rready_o) begin
            m2_m1_channel_hs_entry_o[ID_R][r_count*R_BEAT_LENGTH +: R_BEAT_LENGTH] <= scu_l1d_resp_r_i; // TODO: packed struct can assign other variable in this way? 
            if(scu_l1d_resp_r_i.rlast) begin
                m2_m1_channel_entry_valid_o[ID_R] <= 1'b1;
            end
        end else begin 
            if(m2_m1_channel_entry_valid_o[ID_R] & m2_m1_channel_push_ready_i[ID_R]) begin
                m2_m1_channel_entry_valid_o[ID_R] <= 1'b0;
            end
        end
    end
end

assign scu_l1d_resp_rready_o = ~m2_m1_channel_entry_valid_o[ID_R];
assign l2_snp_req_if_acready_o = ~m2_m1_channel_entry_valid_o[ID_AC];
assign scu_l1d_resp_bready_o = ~m2_m1_channel_entry_valid_o[ID_B];

endmodule: m2_ebi_if_handshake