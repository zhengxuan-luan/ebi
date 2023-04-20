module m1_ebi_if_handshake
    import ebi_pkg::*;
    import rvh_l1d_pkg::*;
(
    input  logic                                    m1_clk_i,
    input  logic                                    rst_i,

    output logic [M1_M2_CHANNEL_NUM-1:0]            m1_m2_channel_entry_valid_o, 
    input  logic [M1_M2_CHANNEL_NUM-1:0]            m1_m2_channel_push_ready_i,
    output logic [M1_M2_CHANNEL_NUM-1:0][MAX_M1_M2_MESSAGE_LENGTH-1:0] m1_m2_channel_hs_entry_o, // there they are registers

    output logic [M2_M1_CHANNEL_NUM-1:0]            entry_if_recv_success_o, 
    input  logic [M2_M1_CHANNEL_NUM-1:0]            m2_m1_vc_valid_i,
    input  logic [M2_M1_CHANNEL_NUM-1:0][MAX_M2_M1_MESSAGE_LENGTH-1:0] m2_m1_vc_entry_list_i,

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
    input  cache_mem_if_cd_t    l2_snp_resp_if_cd_i
);

logic [M2_M1_CHANNEL_NUM-1:0] m2_m1_entry_valid; 
logic [M2_M1_CHANNEL_NUM-1:0][MAX_M2_M1_MESSAGE_LENGTH-1:0] m2_m1_vc_entry_list; // registers here

logic en_w_count, en_r_count, en_cd_count;
logic [BURST_SIZE-1:0] w_count, r_count, cd_count;
assign en_w_count = l1d_l2_req_wvalid_i & l1d_l2_req_wready_o;
assign en_r_count = l2_l1d_resp_rvalid_o & l2_l1d_resp_rready_i;
assign en_cd_count = l2_snp_resp_if_cdvalid_i & l2_snp_resp_if_cdready_o;

always_ff @(posedge m1_clk_i) begin
    if(rst_i) begin
        w_count  <= {BURST_SIZE{1'b0}};
        r_count  <= {BURST_SIZE{1'b0}};
        cd_count <= {BURST_SIZE{1'b0}};
    end else begin
        if(entry_if_recv_success_o[ID_R]) begin
            r_count <= {BURST_SIZE{1'b0}};
        end else if(en_r_count) begin
            r_count <= r_count + 1'b1;
        end

        if(m1_m2_channel_entry_valid_o[ID_W] & m1_m2_channel_push_ready_i[ID_W]) begin
            w_count <= {BURST_SIZE{1'b0}};
        end else if(en_w_count) begin
            w_count <= w_count + 1'b1;
        end

        if(m1_m2_channel_entry_valid_o[ID_CD] & m1_m2_channel_push_ready_i[ID_CD]) begin
            cd_count <= {BURST_SIZE{1'b0}};
        end else if(en_cd_count) begin
            cd_count <= cd_count + 1'b1;
        end
    end
end

assign entry_if_recv_success_o[ID_R] = l2_l1d_resp_rvalid_o & l2_l1d_resp_rready_i & l2_l1d_resp_r_o.rlast;
assign entry_if_recv_success_o[ID_B] = l2_l1d_resp_bvalid_o & l2_l1d_resp_bready_i;
assign entry_if_recv_success_o[ID_CR] = l2_snp_resp_if_crvalid_i & l2_snp_resp_if_crready_o;

always_ff @(posedge m1_clk_i) begin
    if(rst_i) begin
        m1_m2_channel_entry_valid_o <= {M1_M2_CHANNEL_NUM{1'b0}};
        m1_m2_channel_hs_entry_o <= {(M1_M2_CHANNEL_NUM*MAX_M1_M2_MESSAGE_LENGTH){1'b0}};
    end else begin
        // AR
        if(l1d_l2_req_arready_o & l1d_l2_req_arvalid_i) begin
            m1_m2_channel_hs_entry_o[ID_AR] <= l1d_l2_req_ar_i; // TODO: packed struct can assign other variable in this way? 
            m1_m2_channel_entry_valid_o[ID_AR] <= 1'b1;
        end else begin 
            if(m1_m2_channel_entry_valid_o[ID_AR] & m1_m2_channel_push_ready_i[ID_AR]) begin
                m1_m2_channel_entry_valid_o[ID_AR] <= 1'b0;
            end
        end

        //AW
        if(l1d_l2_req_awvalid_i & l1d_l2_req_awready_o) begin
            m1_m2_channel_hs_entry_o[ID_AW] <= l1d_l2_req_aw_i; // TODO: packed struct can assign other variable in this way? 
            m1_m2_channel_entry_valid_o[ID_AW] <= 1'b1;
        end else begin 
            if(m1_m2_channel_entry_valid_o[ID_AW] & m1_m2_channel_push_ready_i[ID_AW]) begin
                m1_m2_channel_entry_valid_o[ID_AW] <= 1'b0;
            end
        end

        //W
        if(l1d_l2_req_wvalid_i & l1d_l2_req_wready_o) begin
            m1_m2_channel_hs_entry_o[ID_W][w_count*W_BEAT_LENGTH +: W_BEAT_LENGTH] <= l1d_l2_req_aw_i; // TODO: packed struct can assign other variable in this way? 
                if(l1d_l2_req_w_i.wlast) begin
                    m1_m2_channel_entry_valid_o[ID_W] <= 1'b1;
                end
        end else begin 
            if(m1_m2_channel_entry_valid_o[ID_W] & m1_m2_channel_push_ready_i[ID_W]) begin
                m1_m2_channel_entry_valid_o[ID_W] <= 1'b0;
            end
        end

        // CR
        if(l2_snp_resp_if_crvalid_i & l2_snp_resp_if_crready_o) begin
            m1_m2_channel_hs_entry_o[ID_CR] <= l2_snp_resp_if_cr_i; // TODO: packed struct can assign other variable in this way? 
            m1_m2_channel_entry_valid_o[ID_CR] <= 1'b1;
        end else begin 
            if(m1_m2_channel_entry_valid_o[ID_CR] & m1_m2_channel_push_ready_i[ID_CR]) begin
                m1_m2_channel_entry_valid_o[ID_CR] <= 1'b0;
            end
        end

        //CD
        if(l2_snp_resp_if_cdvalid_i & l2_snp_resp_if_cdready_o) begin
            m1_m2_channel_hs_entry_o[ID_CD][cd_count*CD_BEAT_LENGTH +: CD_BEAT_LENGTH] <= l2_snp_resp_if_cd_i; // TODO: packed struct can assign other variable in this way? 
                if(l2_snp_resp_if_cd_i.cdlast) begin
                    m1_m2_channel_entry_valid_o[ID_CD] <= 1'b1;
                end
        end else begin 
            if(m1_m2_channel_entry_valid_o[ID_CD] & m1_m2_channel_push_ready_i[ID_CD]) begin
                m1_m2_channel_entry_valid_o[ID_CD] <= 1'b0;
            end
        end
    end
end


always_ff @(posedge m1_clk_i) begin
    if(rst_i) begin
        m2_m1_entry_valid <= {M2_M1_CHANNEL_NUM{1'b0}};
        m2_m1_vc_entry_list <= {(MAX_M2_M1_MESSAGE_LENGTH * M2_M1_CHANNEL_NUM){1'b0}};
    end else begin
        for (int i = 0; i < M2_M1_CHANNEL_NUM; i++) begin
            if(entry_if_recv_success_o[i]) begin
                m2_m1_entry_valid[i] <= 1'b0;
            end else if((!m2_m1_entry_valid[i]) & m2_m1_vc_valid_i[i]) begin
                m2_m1_entry_valid[i] <= 1'b1;
                m2_m1_vc_entry_list[i] <= m2_m1_vc_entry_list_i[i];
            end
        end
    end
end

assign l1d_l2_req_arready_o = ~m1_m2_channel_entry_valid_o[ID_AR];
assign l1d_l2_req_awready_o = ~m1_m2_channel_entry_valid_o[ID_AW];

assign l2_snp_req_if_acvalid_o = m2_m1_entry_valid[ID_AC];
assign l2_l1d_resp_rvalid_o = m2_m1_entry_valid[ID_R];
assign l2_l1d_resp_bvalid_o = m2_m1_entry_valid[ID_B];

assign l2_l1d_resp_b_o = m2_m1_vc_entry_list[ID_B];
assign l2_snp_req_if_ac_o = m2_m1_vc_entry_list[ID_AC];
assign l2_l1d_resp_r_o = m2_m1_vc_entry_list[ID_R][r_count*R_BEAT_LENGTH +: R_BEAT_LENGTH];
endmodule: m1_ebi_if_handshake