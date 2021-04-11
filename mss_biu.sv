`define SVA_CLK posedge clk
`define SVA_DIS !csysreset_n
`include "sva_macros.svh"

`ifdef ARM_FCOV_ON
`ifndef ARM_L1_COV_TESTS
`define ARM_L1_COV_TESTS 1
`endif
`endif


module yamin_biu import yamin_pkg::*, yamin_biu_pkg::*;
#(
  `include "yamin_decl.sv"
  //, parameter HAS_WRBF = 1
  , localparam HAS_WRBF = DCACHE
)
(
  //Clock and Reset
  //================
  input  wire logic               clk,
  input  wire logic               bclk,
  input  wire logic               csysreset_n,
  input  wire logic               ext_dft_cgen_i,
  input  wire logic               ext_biu_aclk_en_i,

  input  wire logic               cpc_outputs_to_reset_i,
  output wire logic               biu_cpc_adclk_en_o,

  //ICU Interface
  //=============
  input  wire logic               icu_biu_set_awakeup_i,
  input  wire logic               icu_biu_req_ic2_i,
  input  wire logic [31:2]        icu_biu_addr_ic2_i,
  input  wire logic               icu_biu_single_ic2_i,
  input  wire logic               icu_biu_ns_attr_ic2_i,
  input  wire attr_t              icu_biu_attrs_ic2_i,
  input  wire logic               icu_biu_priv_ic2_i,
  input  wire logic               icu_biu_vf_ic2_i,

  output wire logic               biu_icu_ack_o,
  output wire logic               biu_icu_data_valid_o,
  output wire logic               biu_icu_data_last_o,
  output wire logic [31:0]        biu_icu_data_o,
  output wire axi_fresp_t         biu_icu_data_resp_o,

  //LSU Interface
  //=============
  //Loads in ls2
  input  wire logic               lsu_biu_load_ls2_i,
  input  wire logic               lsu_biu_pld_ls2_i,

  //Load requests
  input  wire logic               lsu_biu_req_ls2_i,
  input  wire logic               lsu_biu_lf_req_ls2_i,
  input  wire logic               lsu_biu_nc_req_ls2_i,
  input  wire logic               lsu_biu_leaving_ls2_i,
  output wire logic               biu_lsu_stall_ls2_o,
  input  wire logic [31:0]        lsu_biu_addr_ls2_i,
  input  wire attr_t              lsu_biu_attrs_ls2_i,
  input  wire battr_t             lsu_biu_battrs_ls2_i,
  input  wire logic               lsu_biu_ns_attr_ls2_i,
  input  wire logic [1:0]         lsu_biu_size_ls2_i,
  input  wire logic               lsu_biu_dbg_ls2_i,
  input  wire logic [2:0]         lsu_biu_length_ls2_i,
  input  wire logic [1:0]         lsu_biu_lf_way_ls2_i,
  input  wire logic               lsu_biu_ns_req_ls2_i,
  input  wire logic               lsu_biu_priv_ls2_i,
  input  wire logic               lsu_biu_negpri_ls2_i,
  input  wire logic               lsu_biu_sh_excl_ls2_i,
  input  wire logic               lsu_biu_sh_excl_est_ls2_i,

  output wire logic               biu_lsu_lf_ready_ls2_o, //PLD can claim a LFB
  output wire logic               biu_lsu_dev_on_axi_ls2_o,
  output wire logic               biu_lsu_no_kill_ls2_o,  //share LDREX or STREX on axi

  //Returning load data
//  output wire [1:0]           biu_lsu_data_valid_ls2_o,
  output wire logic [3:0]         biu_lsu_axi_hit_ls2_o,
  output wire logic [3:0]         biu_lsu_lfb_hit_ls2_o,
  output wire logic [3:0]         biu_lsu_lfb_axi_hit_ls2_o,
  output wire logic [31:0]        biu_lsu_axi_data_ls2_o,
  output wire logic [31:0]        biu_lsu_lfb_data_ls2_o,
  output wire axi_fresp_t         biu_lsu_resp_ls2_o,

  // Aborts
  output wire logic               biu_lsu_lfb_imp_bus_fault_o,
  output wire axi_fresp_t         biu_lsu_lfb_imp_bus_fault_type_o,
  output wire logic               biu_lsu_axi_imp_bus_fault_o,
  output wire axi_fresp_t         biu_lsu_axi_imp_bus_fault_type_o,

  //Misc
  output wire logic [3:0]         biu_lsu_valid_wids_o,
  output wire logic               biu_lsu_any_stores_on_axi_o,
  input  wire logic               lsu_biu_kill_ls1_i,
  input  wire logic               lsu_biu_kill_ls2_i,
  input  wire logic               lsu_biu_cancel_ls2_i,
  input  wire logic               lsu_biu_ecc_err_ls2p1_i,
  input  wire logic               lsu_biu_store_ls2_i,
  output wire logic               biu_lsu_strex_bresp_valid_o,
  output wire axi_fresp_t         biu_lsu_strex_bresp_o,
  output wire logic               biu_lsu_lf_in_progress_o,
  input  wire logic               lsu_biu_drain_writes_i,
  input  wire logic               lsu_watchcat_fire_i,
  output wire logic               biu_lsu_watchcat_two_o,
  output wire logic               biu_lsu_watchcat_three_o,
  output wire logic               biu_lsu_watchcat_triple_o,
  input  wire logic               lsu_biu_set_awakeup_i,
  input  wire logic               lsu_biu_stop_pf_i,
  output wire logic               biu_lsu_quiescent_o,
  input  wire logic               lsu_biu_mask_hit_i,

  //PMU Events
  output wire logic               biu_lsu_axi_write_access_o,
  output wire logic               biu_lsu_axi_read_access_o,
  output wire logic [1:0]         biu_lsu_bus_access_o,
  output wire logic               biu_lsu_bus_cycles_o,
  output wire logic               biu_lsu_l1d_cache_miss_rd_o,
  output wire logic               biu_lsu_l1d_cache_refill_o,
  output wire logic               biu_lsu_l1d_cache_wb_o,
  output wire logic               biu_lsu_pf_linefill_o,
  output wire logic               biu_lsu_pf_cancel_o,
  output wire logic               biu_lsu_pf_drop_linefill_o,
  output wire logic               biu_lsu_nwamode_enter_o,

  //DCU Interface
  //=============
  //Linefill allocation handshaking
  output wire logic               biu_dcu_alloc_tag_req_m0_o,
  output wire logic               biu_dcu_alloc_data_req_m0_o,
  output wire logic               biu_dcu_alloc_mbistall_m0_o,
  input  wire logic               dcu_biu_alloc_has_priority_m0_i,
  input  wire logic               dcu_biu_alloc_ack_m1_i,

  output wire logic [311:0]       biu_dcu_alloc_data_m1_o,
  output wire logic [39:0]        biu_dcu_alloc_enables_m1_o,
  output wire logic [33:0]        biu_dcu_alloc_tag_m1_o,

  //Eviction signals into the cache RAMs
  output wire logic               biu_dcu_ev_tag_req_m0_o,
  input  wire logic               dcu_biu_ev_tag_has_priority_m0_i,
  input  wire logic               dcu_biu_ev_tag_ack_m1_i,

  output wire logic               biu_dcu_ev_data_req_m0_o,
  input  wire logic               dcu_biu_ev_data_has_priority_m0_i,
  input  wire logic               dcu_biu_ev_data_ack_m1_i,

  // MBIST state
  output wire logic               biu_dcu_mbistall_tag_wen_m0_o,
  output wire logic               biu_dcu_mbist_req_o,
  output wire logic               biu_dcu_mbist_active_o,
  output wire logic               biu_dcu_mbist_active_mb1_o,
  output wire logic               biu_dcu_mbist_tag_write_psel_gen_mb0_o,
  output wire logic               biu_mbist_data_write_psel_gen_mb0_o,
  output wire logic [1:0]         biu_dcu_mbist_tag_way_mb0_o,
  output wire logic               biu_dcu_mbist_read_data_pren_mb1_o,
  output wire logic               biu_dcu_mbist_read_data_psel_mb2_o,
  output wire logic               biu_dcu_mbist_read_tag_psel_mb2_o,
  output wire logic               biu_dcu_mbist_pren_mb2_o,
  output wire logic               biu_dcu_mbist_read_data_psel_mb3_o,
  output wire logic               biu_dcu_mbist_read_tag_psel_mb3_o,
  output wire logic               biu_dcu_mbist_pren_mb3_o,
  output wire logic [1:0]         biu_dcu_mbist_banksel_mb3_o,
  input  wire logic               dcu_biu_mbist_func_access_i,
  input  wire logic               dcu_dc_inaccessible_i,
  input  wire logic               dcu_auto_inval_in_prog_i,
  input  wire logic [27:0]        dcu_biu_mbist_ldst_tag_syndr_m3_i,
  input  wire logic [23:0]        dcu_biu_mbist_ldst_tag_chk_m3_i,
  input  wire logic [25:0]        dcu_biu_mbist_maint_ev_tag_corrctn_m3_i,
  input  wire logic [23:0]        dcu_biu_mbist_maint_ev_tag_chk_m3_i,
  input  wire logic [23:0]        dcu_biu_mbist_ldst_data_chk_m3_i,
  input  wire logic               dcu_biu_ecc_ls_in_prog_i,
  input  wire logic               dcu_misc_in_prog_i,

  //Signals shared between allocation and evictions
  output wire logic [7:0]         biu_dcu_data_en_m0_o,

  output wire logic [13:5]        biu_dcu_tag_addr_m0_o,
  output wire logic [3:0]         biu_dcu_tag_way_m0_o,

  output wire logic [13:5]        biu_dcu_data_addr_m0_o,
  output wire logic [3:0]         biu_dcu_data_way_m0_o,

  // The Eviction Tag and Data directly from the RAMs
  // Note: the Raw Tag is only used for MBIST reads
  input  wire logic [33:0]        dcu_biu_tag_data_m2_i,  //include ns_attr
  input  wire logic [127:0]       dcu_biu_line_data_m2_i,
  input  wire logic [27:0]        dcu_biu_line_syndrome_m2_i,
  input  wire logic [27:0]        dcu_biu_line_ecc_m2_i,
  output wire logic [7:0]         biu_dcu_line_err_m3_o,
  output wire logic [7:0]         biu_dcu_line_fatal_m3_o,
  output wire logic [13:5]        biu_dcu_line_addr_m3_o,

  // Corrected Tag data for natural evictions
  input  wire logic [31:10]       dcu_biu_ev_tag_addr_m3_i,
  input  wire half_attr_t         dcu_biu_ev_tag_attrs_m3_i,
  input  wire                     dcu_biu_ev_tag_ns_attr_m3_i,
  input  wire logic               dcu_biu_ev_tag_valid_m3_i,
  input  wire logic               dcu_biu_ev_tag_dirty_m3_i,
  input  wire logic               dcu_biu_ev_tag_fatal_m3_i,

  output wire logic               biu_dcu_lf_in_progress_o,

  //Cache maintenance signals
  input  wire logic               dcu_biu_ecc_pend_i,

  input  wire logic               dcu_biu_maint_ecc_ev_req_i,
  input  wire logic [26:0]        dcu_biu_maint_ecc_ev_tag_i,
  input  wire logic [3:0]         dcu_biu_maint_ecc_ev_way_i,
  input  wire logic [13:5]        dcu_biu_maint_ecc_ev_addr_i,
  output wire logic               biu_dcu_maint_ecc_ev_ack_o,

  // Prefetch lookup
  output wire logic               biu_dcu_pf_lu_req_m0_o,
  output wire logic [31:0]        biu_dcu_pf_lu_addr_m0_o,
  input  wire logic               dcu_biu_pf_lu_has_priority_m0_i,
  input  wire logic               dcu_biu_pf_lu_ack_m1_i,
  input  wire logic               dcu_biu_pf_lu_hit_m2_i,
  input  wire logic [1:0]         dcu_biu_pf_lu_way_m2_i,
  input  wire logic               dcu_biu_pf_lu_ecc_err_m3_i,

  //EBRs
  input  wire logic               dcu_biu_debr0_val_i,
  input  wire logic               dcu_biu_debr1_val_i,
  input  wire logic [1:0]         dcu_biu_debr0_way_i,
  input  wire logic [1:0]         dcu_biu_debr1_way_i,
  input  wire logic [13:5]        dcu_biu_debr0_addr_i,
  input  wire logic [13:5]        dcu_biu_debr1_addr_i,

  //STB Interface
  //=============
  input  wire logic [3:0]         stb_biu_slots_valid_i,
  input  wire logic [31:0]        stb_biu_slot0_addr_i,
  input  wire logic [31:0]        stb_biu_slot1_addr_i,
  input  wire logic [31:0]        stb_biu_slot2_addr_i,
  input  wire logic [31:0]        stb_biu_slot3_addr_i,
  input  wire logic [1:0]         stb_biu_slot0_way_i,
  input  wire logic [1:0]         stb_biu_slot1_way_i,
  input  wire logic [1:0]         stb_biu_slot2_way_i,
  input  wire logic [1:0]         stb_biu_slot3_way_i,
  input  wire attr_t              stb_biu_slot0_attrs_i,
  input  wire attr_t              stb_biu_slot1_attrs_i,
  input  wire attr_t              stb_biu_slot2_attrs_i,
  input  wire attr_t              stb_biu_slot3_attrs_i,
  input  wire logic               stb_biu_slot0_ns_attr_i,
  input  wire logic               stb_biu_slot1_ns_attr_i,
  input  wire logic               stb_biu_slot2_ns_attr_i,
  input  wire logic               stb_biu_slot3_ns_attr_i,
  output wire logic [3:0]         biu_stb_lf_hazard_o,
  output wire logic [3:0]         biu_stb_lf_hazard_abort_o,
  output wire logic [3:0]         biu_stb_lf_hazard_alloc_o,
  output wire logic [1:0]         biu_stb_lf_hazard_way_o,
  output wire logic [3:0]         biu_stb_lf_can_merge_o,
  output wire logic [3:0]         biu_stb_ev_hazard_o,
  input  wire logic [3:0]         stb_biu_lf_req_i,
  input  wire logic [1:0]         stb_biu_lf_earliest_slot_i,
  input  wire logic [3:0]         stb_biu_lf_merge_req_i,
  input  wire logic [31:0]        stb_biu_lf_merge_data_i,
  input  wire logic [3:0]         stb_biu_lf_merge_wstrb_i,
  input  wire logic               stb_biu_lf_merge_update_dirty_i,
  input  wire logic               stb_biu_slot_in_m1_i,

  input  wire logic               stb_biu_write_req_i,
  input  wire logic [31:0]        stb_biu_write_data_i,
  input  wire logic [3:0]         stb_biu_write_wstrb_i,
  input  wire logic [3:0]         stb_biu_write_slot_i,
  input  wire logic               stb_biu_write_priv_i,
  input  wire logic               stb_biu_write_dbg_i,
  input  wire attr_t              stb_biu_write_attrs_i,
  input  wire logic               stb_biu_write_ns_attr_i,
  input  wire size_t              stb_biu_write_size_i,
  input  wire logic               stb_biu_write_strex_i,
  input  wire logic               stb_biu_write_sameline_i,
  output wire logic               biu_stb_write_ack_o,
  output wire logic [3:0]         biu_stb_valid_wids_o,

  //Read allocate mode
  output wire logic               biu_stb_no_write_alloc_mode_o,
  input  wire logic               stb_biu_cancel_no_write_alloc_i,
  output wire logic               biu_stb_waw_hazard_ls2_o,
  input  wire logic               stb_biu_stl_wait_wids_i,

  //SCB Interface
  //=============
  input  wire actlr_t             scb_actlr_s_i,
  input  wire actlr_t             scb_actlr_ns_i,
  input  wire mscr_t              scb_mscr_i,
  input  wire pfcr_t              scb_pfcr_i,
  input  wire logic               scb_ecc_en_i,

  //MIU Interface
  //=============
  input  wire logic               miu_biu_lock_req_i,
  output wire logic               biu_miu_lock_ack_o,
  output wire mbist_ol_err_t      biu_miu_err_o,
  input  wire logic               miu_array_0_i, // 1 = data, 0 = tag
  input  wire logic [1:0]         miu_array_4_3_i, // ECC unit encoding
  input  wire logic               miu_biu_mbistall_en_i,
  input  wire logic               miu_rd_en_i,
  input  wire logic               miu_wr_en_i,
  input  wire mbist_ol_psel_t     miu_psel_i,
  input  wire logic               miu_pren_i,
  input  wire logic [21:0]        miu_addr_i,
  input  wire logic [4:0]         miu_be_i,
  input  wire logic [38:0]        miu_wdata_i,
  output wire logic [38:0]        biu_miu_rdata_o,
  input  wire logic               miu_prod_mbist_en_i,

  //External AXI interface
  //======================

  output wire logic               biu_ext_awakeup_o,
  //AXI Address read channel
  input  wire logic               ext_biu_ar_ready_i,
  output wire logic               biu_ext_ar_valid_o,

  output wire axi_rid_t           biu_ext_ar_id_o,
  output wire logic [31:0]        biu_ext_ar_addr_o,
  output wire axi_burst_t         biu_ext_ar_burst_o,
  output wire logic [7:0]         biu_ext_ar_len_o,
  output wire size_t              biu_ext_ar_size_o,
  output wire logic               biu_ext_ar_lock_o,
  output wire logic [3:0]         biu_ext_ar_cache_o,
  output wire logic [2:0]         biu_ext_ar_prot_o,
  output wire logic               biu_ext_ar_master_o,
  output wire logic [3:0]         biu_ext_ar_inner_o,
  output wire axi_domain_t        biu_ext_ar_domain_o,

  //AXI Read Data Channel
  output wire logic               biu_ext_dr_ready_o,
  input  wire logic               ext_biu_dr_valid_i,

  input  wire axi_rid_t           ext_biu_dr_id_i,
  input  wire logic [31:0]        ext_biu_dr_data_i,
  input  wire logic               ext_biu_dr_last_i,
  input  wire axi_resp_t          ext_biu_dr_resp_i,
  input  wire logic               ext_biu_dr_poison_i,

  //Write address channel
  input  wire logic               ext_biu_aw_ready_i,
  output wire logic               biu_ext_aw_valid_o,
  output wire axi_wid_t           biu_ext_aw_id_o,
  output wire logic [31:0]        biu_ext_aw_addr_o,
  output wire axi_burst_t         biu_ext_aw_burst_o,
  output wire logic [7:0]         biu_ext_aw_len_o,
  output wire size_t              biu_ext_aw_size_o,

  output wire logic               biu_ext_aw_lock_o,
  output wire logic [3:0]         biu_ext_aw_cache_o,
  output wire logic [2:0]         biu_ext_aw_prot_o,
  output wire logic               biu_ext_aw_master_o,
  output wire logic [3:0]         biu_ext_aw_inner_o,
  output wire axi_domain_t        biu_ext_aw_domain_o,
  output wire logic               biu_ext_aw_sparse_o,

  //Write data channel
  input  wire logic               ext_biu_dw_ready_i,
  output wire logic               biu_ext_dw_valid_o,
  output wire axi_wid_t           biu_ext_dw_id_o,
  output wire logic [31:0]        biu_ext_dw_data_o,
  output wire logic [3:0]         biu_ext_dw_strb_o,
  output wire logic               biu_ext_dw_poison_o,
  output wire logic               biu_ext_dw_last_o,
  //Write response channel
  output wire logic               biu_ext_db_ready_o,
  input  wire logic               ext_biu_db_valid_i,
  input  wire axi_wid_t           ext_biu_db_id_i,
  input  wire axi_resp_t          ext_biu_db_resp_i,
  //Interface protection signals
  input  wire logic               ext_biu_aclk_enchk_i,
  input  wire logic               ext_biu_ar_readychk_i,
  input  wire logic               ext_biu_aw_readychk_i,
  input  wire logic               ext_biu_dr_validchk_i,
  input  wire logic               ext_biu_dr_idchk_i,
  input  wire logic [3:0]         ext_biu_dr_datachk_i,
  input  wire logic               ext_biu_dr_lastchk_i,
  input  wire logic               ext_biu_dr_respchk_i,
  input  wire logic               ext_biu_dr_poisonchk_i,
  input  wire logic               ext_biu_dw_readychk_i,
  input  wire logic               ext_biu_db_validchk_i,
  input  wire logic               ext_biu_db_idchk_i,
  input  wire logic               ext_biu_db_respchk_i,
  output wire logic               biu_ext_ar_validchk_o,
  output wire logic  [3:0]        biu_ext_ar_addrchk_o,
  output wire logic               biu_ext_ar_idchk_o,
  output wire logic               biu_ext_ar_lenchk_o,
  output wire logic               biu_ext_ar_userchk_o,
  output wire logic               biu_ext_ar_ctlchk0_o,
  output wire logic               biu_ext_ar_ctlchk1_o,
  output wire logic               biu_ext_ar_ctlchk2_o,
  output wire logic               biu_ext_aw_validchk_o,
  output wire logic  [3:0]        biu_ext_aw_addrchk_o,
  output wire logic               biu_ext_aw_idchk_o,
  output wire logic               biu_ext_aw_lenchk_o,
  output wire logic               biu_ext_aw_userchk_o,
  output wire logic               biu_ext_aw_ctlchk0_o,
  output wire logic               biu_ext_aw_ctlchk1_o,
  output wire logic               biu_ext_aw_ctlchk2_o,
  output wire logic               biu_ext_dr_readychk_o,
  output wire logic               biu_ext_dw_validchk_o,
  output wire logic  [3:0]        biu_ext_dw_datachk_o,
  output wire logic               biu_ext_dw_strbchk_o,
  output wire logic               biu_ext_dw_idchk_o,
  output wire logic               biu_ext_dw_lastchk_o,
  output wire logic               biu_ext_dw_poisonchk_o,
  output wire logic               biu_ext_db_readychk_o,
  output wire logic               biu_lsu_dbe_o,

  // C-AHB
  output wire [31:0]              biu_ext_c_haddr_o,        // C-AHB address
  output wire                     biu_ext_c_hmaster_o,      // C-AHB master (core=0, debug=1)
  output wire  [1:0]              biu_ext_c_htrans_o,       // C-AHB transfer type
  output wire  [2:0]              biu_ext_c_hhint_o,        // C-AHB hints
  output wire                     biu_ext_c_hwrite_o,       // C-AHB write not read
  output wire  [6:0]              biu_ext_c_hprot_o,        // C-AHB protection and outer memory attrs
  output wire  [4:0]              biu_ext_c_hinner_o,       // C-AHB innter memory attrs (as hprot[6:2])
  output wire                     biu_ext_c_hnonsec_o,      // C-AHB non-secure
  output wire  [2:0]              biu_ext_c_hburst_o,       // C-AHB burst
  output wire  [2:0]              biu_ext_c_hsize_o,        // C-AHB transfer size
  output wire                     biu_ext_c_hexcl_o,        // C-AHB exclusive transfer
  input  wire                     ext_biu_c_hexokay_i,      // C-AHB exclusive response
  output wire [31:0]              biu_ext_c_hwdata_o,       // C-AHB write data
  input  wire                     ext_biu_c_hready_i,       // C-AHB ready
  input  wire [31:0]              ext_biu_c_hrdata_i,       // C-AHB read data
  input  wire                     ext_biu_c_hresp_i,        // C-AHB response

  //Interface protection signals for M-BUS C-AHB
  output wire logic              biu_ext_c_htranschk_o,
  output wire logic [3:0]        biu_ext_c_haddrchk_o,
  output wire logic [3:0]        biu_ext_c_hwdatachk_o,
  output wire logic              biu_ext_c_hctrlchk1_o,
  output wire logic              biu_ext_c_hctrlchk2_o,
  output wire logic              biu_ext_c_hprotchk_o,
  output wire logic              biu_ext_c_hauserchk_o,
  input wire logic               ext_biu_c_hreadychk_i,
  input wire logic [3:0]         ext_biu_c_hrdatachk_i,
  input wire logic               ext_biu_c_hrespchk_i,

  // S-AHB
  output wire [31:0]             biu_ext_s_haddr_o,        // S-AHB address
  output wire                    biu_ext_s_hmaster_o,      // S-AHB master (core=0, debug=1)
  output wire  [1:0]             biu_ext_s_htrans_o,       // S-AHB transfer type
  output wire  [2:0]             biu_ext_s_hhint_o,        // S-AHB hints
  output wire                    biu_ext_s_hwrite_o,       // S-AHB write not read
  output wire  [6:0]             biu_ext_s_hprot_o,        // S-AHB protection and outer memory attrs
  output wire  [4:0]             biu_ext_s_hinner_o,       // S-AHB innter memory attrs (as hprot[6:2])
  output wire                    biu_ext_s_hnonsec_o,      // S-AHB non-secure
  output wire  [2:0]             biu_ext_s_hburst_o,       // S-AHB burst
  output wire  [2:0]             biu_ext_s_hsize_o,        // S-AHB transfer size
  output wire                    biu_ext_s_hexcl_o,        // S-AHB exclusive transfer
  input  wire                    ext_biu_s_hexokay_i,      // S-AHB exclusive response
  output wire [31:0]             biu_ext_s_hwdata_o,       // S-AHB write data
  input  wire                    ext_biu_s_hready_i,       // S-AHB ready
  input  wire [31:0]             ext_biu_s_hrdata_i,       // S-AHB read data
  input  wire                    ext_biu_s_hresp_i,        // S-AHB response

  //Interface protection signals for M-BUS SYS-AHB
  output wire logic              biu_ext_s_htranschk_o,
  output wire logic [3:0]        biu_ext_s_haddrchk_o,
  output wire logic [3:0]        biu_ext_s_hwdatachk_o,
  output wire logic              biu_ext_s_hctrlchk1_o,
  output wire logic              biu_ext_s_hctrlchk2_o,
  output wire logic              biu_ext_s_hprotchk_o,
  output wire logic              biu_ext_s_hauserchk_o,
  input wire logic               ext_biu_s_hreadychk_i,
  input wire logic [3:0]         ext_biu_s_hrdatachk_i,
  input wire logic               ext_biu_s_hrespchk_i,

  // Prefetcher Interface
  // To LSU
  //=============
  output wire logic               biu_lsu_pf_lu_req_m1_o,
  output wire logic [31:0]        biu_lsu_pf_lu_addr_m1_o,

  input  wire logic               lsu_biu_pf_lu_ack_m1_i,
  output wire logic               biu_lsu_pf_lu_ns_req_m1_o,
  output wire logic               biu_lsu_pf_lu_priv_m1_o,
  output wire logic               biu_lsu_pf_lu_negpri_m1_o,
  input  wire attr_t              lsu_biu_pf_lu_attrs_m2_i,
  input  wire mpu_fault_t         lsu_biu_pf_lu_mem_fault_m2_i,
  input  wire logic               lsu_biu_pf_lu_ns_attr_m2_i,
  input  wire logic               lsu_biu_pf_lu_secure_fault_m2_i
);

  // Reset signal for registers that are only reset when RAR is set
  wire rar_csysreset_n = ( RAR == 1 ) ? csysreset_n : 1'b1;

  wire                        biu_lsu_no_kill_ls2;
  wire                        no_write_alloc_mode;
  wire                        load_hazard;
  wire                        pld_hazard_writes;
  wire                        pld_hazard_lfb;

  //End automatically generated svas here

`endif

endmodule

`define ARM_UNDEFINE
`include "sva_macros.svh"
`undef ARM_UNDEFINE

