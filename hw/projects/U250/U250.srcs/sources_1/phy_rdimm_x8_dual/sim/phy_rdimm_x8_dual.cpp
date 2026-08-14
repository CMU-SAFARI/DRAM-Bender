// (c) Copyright 1995-2026 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


#include "phy_rdimm_x8_dual_sc.h"

#include "phy_rdimm_x8_dual.h"

#include "sim_ddr_v2_0.h"

#include <map>
#include <string>





#ifdef XILINX_SIMULATOR
phy_rdimm_x8_dual::phy_rdimm_x8_dual(const sc_core::sc_module_name& nm) : phy_rdimm_x8_dual_sc(nm), c0_init_calib_complete("c0_init_calib_complete"), dbg_clk("dbg_clk"), c0_sys_clk_p("c0_sys_clk_p"), c0_sys_clk_n("c0_sys_clk_n"), dbg_bus("dbg_bus"), c0_ddr4_parity("c0_ddr4_parity"), c0_ddr4_ui_clk("c0_ddr4_ui_clk"), c0_ddr4_ui_clk_sync_rst("c0_ddr4_ui_clk_sync_rst"), sys_rst("sys_rst"), rdDataEn("rdDataEn"), rdDataEnd("rdDataEnd"), per_rd_done("per_rd_done"), rmw_rd_done("rmw_rd_done"), wrDataEn("wrDataEn"), mc_ACT_n("mc_ACT_n"), mcCasSlot("mcCasSlot"), mcCasSlot2("mcCasSlot2"), mcRdCAS("mcRdCAS"), mcWrCAS("mcWrCAS"), winInjTxn("winInjTxn"), winRmw("winRmw"), gt_data_ready("gt_data_ready"), winRank("winRank"), tCWL("tCWL"), wrData("wrData"), wrDataMask("wrDataMask"), rdData("rdData"), mc_ADR("mc_ADR"), mc_BA("mc_BA"), mc_CKE("mc_CKE"), mc_CS_n("mc_CS_n"), mc_ODT("mc_ODT"), dBufAdr("dBufAdr"), rdDataAddr("rdDataAddr"), wrDataAddr("wrDataAddr"), winBuf("winBuf"), ddr4_act_n("ddr4_act_n"), ddr4_adr("ddr4_adr"), ddr4_ba("ddr4_ba"), ddr4_bg("ddr4_bg"), ddr4_par("ddr4_par"), ddr4_cke("ddr4_cke"), ddr4_odt("ddr4_odt"), ddr4_cs_n("ddr4_cs_n"), ddr4_ck_t("ddr4_ck_t"), ddr4_ck_c("ddr4_ck_c"), ddr4_reset_n("ddr4_reset_n"), ddr4_parity("ddr4_parity"), ddr4_dm_dbi_n("ddr4_dm_dbi_n"), ddr4_dq("ddr4_dq"), ddr4_dqs_c("ddr4_dqs_c"), ddr4_dqs_t("ddr4_dqs_t"), mc_BG("mc_BG")
{

  // initialize pins
  mp_impl->c0_init_calib_complete(c0_init_calib_complete);
  mp_impl->dbg_clk(dbg_clk);
  mp_impl->c0_sys_clk_p(c0_sys_clk_p);
  mp_impl->c0_sys_clk_n(c0_sys_clk_n);
  mp_impl->dbg_bus(dbg_bus);
  mp_impl->c0_ddr4_parity(c0_ddr4_parity);
  mp_impl->c0_ddr4_ui_clk(c0_ddr4_ui_clk);
  mp_impl->c0_ddr4_ui_clk_sync_rst(c0_ddr4_ui_clk_sync_rst);
  mp_impl->sys_rst(sys_rst);
  mp_impl->rdDataEn(rdDataEn);
  mp_impl->rdDataEnd(rdDataEnd);
  mp_impl->per_rd_done(per_rd_done);
  mp_impl->rmw_rd_done(rmw_rd_done);
  mp_impl->wrDataEn(wrDataEn);
  mp_impl->mc_ACT_n(mc_ACT_n);
  mp_impl->mcCasSlot(mcCasSlot);
  mp_impl->mcCasSlot2(mcCasSlot2);
  mp_impl->mcRdCAS(mcRdCAS);
  mp_impl->mcWrCAS(mcWrCAS);
  mp_impl->winInjTxn(winInjTxn);
  mp_impl->winRmw(winRmw);
  mp_impl->gt_data_ready(gt_data_ready);
  mp_impl->winRank(winRank);
  mp_impl->tCWL(tCWL);
  mp_impl->wrData(wrData);
  mp_impl->wrDataMask(wrDataMask);
  mp_impl->rdData(rdData);
  mp_impl->mc_ADR(mc_ADR);
  mp_impl->mc_BA(mc_BA);
  mp_impl->mc_CKE(mc_CKE);
  mp_impl->mc_CS_n(mc_CS_n);
  mp_impl->mc_ODT(mc_ODT);
  mp_impl->dBufAdr(dBufAdr);
  mp_impl->rdDataAddr(rdDataAddr);
  mp_impl->wrDataAddr(wrDataAddr);
  mp_impl->winBuf(winBuf);
  mp_impl->ddr4_act_n(ddr4_act_n);
  mp_impl->ddr4_adr(ddr4_adr);
  mp_impl->ddr4_ba(ddr4_ba);
  mp_impl->ddr4_bg(ddr4_bg);
  mp_impl->ddr4_par(ddr4_par);
  mp_impl->ddr4_cke(ddr4_cke);
  mp_impl->ddr4_odt(ddr4_odt);
  mp_impl->ddr4_cs_n(ddr4_cs_n);
  mp_impl->ddr4_ck_t(ddr4_ck_t);
  mp_impl->ddr4_ck_c(ddr4_ck_c);
  mp_impl->ddr4_reset_n(ddr4_reset_n);
  mp_impl->ddr4_parity(ddr4_parity);
  mp_impl->ddr4_dm_dbi_n(ddr4_dm_dbi_n);
  mp_impl->ddr4_dq(ddr4_dq);
  mp_impl->ddr4_dqs_c(ddr4_dqs_c);
  mp_impl->ddr4_dqs_t(ddr4_dqs_t);
  mp_impl->mc_BG(mc_BG);

}

void phy_rdimm_x8_dual::before_end_of_elaboration()
{
}

#endif // XILINX_SIMULATOR




#ifdef XM_SYSTEMC
phy_rdimm_x8_dual::phy_rdimm_x8_dual(const sc_core::sc_module_name& nm) : phy_rdimm_x8_dual_sc(nm), c0_init_calib_complete("c0_init_calib_complete"), dbg_clk("dbg_clk"), c0_sys_clk_p("c0_sys_clk_p"), c0_sys_clk_n("c0_sys_clk_n"), dbg_bus("dbg_bus"), c0_ddr4_parity("c0_ddr4_parity"), c0_ddr4_ui_clk("c0_ddr4_ui_clk"), c0_ddr4_ui_clk_sync_rst("c0_ddr4_ui_clk_sync_rst"), sys_rst("sys_rst"), rdDataEn("rdDataEn"), rdDataEnd("rdDataEnd"), per_rd_done("per_rd_done"), rmw_rd_done("rmw_rd_done"), wrDataEn("wrDataEn"), mc_ACT_n("mc_ACT_n"), mcCasSlot("mcCasSlot"), mcCasSlot2("mcCasSlot2"), mcRdCAS("mcRdCAS"), mcWrCAS("mcWrCAS"), winInjTxn("winInjTxn"), winRmw("winRmw"), gt_data_ready("gt_data_ready"), winRank("winRank"), tCWL("tCWL"), wrData("wrData"), wrDataMask("wrDataMask"), rdData("rdData"), mc_ADR("mc_ADR"), mc_BA("mc_BA"), mc_CKE("mc_CKE"), mc_CS_n("mc_CS_n"), mc_ODT("mc_ODT"), dBufAdr("dBufAdr"), rdDataAddr("rdDataAddr"), wrDataAddr("wrDataAddr"), winBuf("winBuf"), ddr4_act_n("ddr4_act_n"), ddr4_adr("ddr4_adr"), ddr4_ba("ddr4_ba"), ddr4_bg("ddr4_bg"), ddr4_par("ddr4_par"), ddr4_cke("ddr4_cke"), ddr4_odt("ddr4_odt"), ddr4_cs_n("ddr4_cs_n"), ddr4_ck_t("ddr4_ck_t"), ddr4_ck_c("ddr4_ck_c"), ddr4_reset_n("ddr4_reset_n"), ddr4_parity("ddr4_parity"), ddr4_dm_dbi_n("ddr4_dm_dbi_n"), ddr4_dq("ddr4_dq"), ddr4_dqs_c("ddr4_dqs_c"), ddr4_dqs_t("ddr4_dqs_t"), mc_BG("mc_BG")
{

  // initialize pins
  mp_impl->c0_init_calib_complete(c0_init_calib_complete);
  mp_impl->dbg_clk(dbg_clk);
  mp_impl->c0_sys_clk_p(c0_sys_clk_p);
  mp_impl->c0_sys_clk_n(c0_sys_clk_n);
  mp_impl->dbg_bus(dbg_bus);
  mp_impl->c0_ddr4_parity(c0_ddr4_parity);
  mp_impl->c0_ddr4_ui_clk(c0_ddr4_ui_clk);
  mp_impl->c0_ddr4_ui_clk_sync_rst(c0_ddr4_ui_clk_sync_rst);
  mp_impl->sys_rst(sys_rst);
  mp_impl->rdDataEn(rdDataEn);
  mp_impl->rdDataEnd(rdDataEnd);
  mp_impl->per_rd_done(per_rd_done);
  mp_impl->rmw_rd_done(rmw_rd_done);
  mp_impl->wrDataEn(wrDataEn);
  mp_impl->mc_ACT_n(mc_ACT_n);
  mp_impl->mcCasSlot(mcCasSlot);
  mp_impl->mcCasSlot2(mcCasSlot2);
  mp_impl->mcRdCAS(mcRdCAS);
  mp_impl->mcWrCAS(mcWrCAS);
  mp_impl->winInjTxn(winInjTxn);
  mp_impl->winRmw(winRmw);
  mp_impl->gt_data_ready(gt_data_ready);
  mp_impl->winRank(winRank);
  mp_impl->tCWL(tCWL);
  mp_impl->wrData(wrData);
  mp_impl->wrDataMask(wrDataMask);
  mp_impl->rdData(rdData);
  mp_impl->mc_ADR(mc_ADR);
  mp_impl->mc_BA(mc_BA);
  mp_impl->mc_CKE(mc_CKE);
  mp_impl->mc_CS_n(mc_CS_n);
  mp_impl->mc_ODT(mc_ODT);
  mp_impl->dBufAdr(dBufAdr);
  mp_impl->rdDataAddr(rdDataAddr);
  mp_impl->wrDataAddr(wrDataAddr);
  mp_impl->winBuf(winBuf);
  mp_impl->ddr4_act_n(ddr4_act_n);
  mp_impl->ddr4_adr(ddr4_adr);
  mp_impl->ddr4_ba(ddr4_ba);
  mp_impl->ddr4_bg(ddr4_bg);
  mp_impl->ddr4_par(ddr4_par);
  mp_impl->ddr4_cke(ddr4_cke);
  mp_impl->ddr4_odt(ddr4_odt);
  mp_impl->ddr4_cs_n(ddr4_cs_n);
  mp_impl->ddr4_ck_t(ddr4_ck_t);
  mp_impl->ddr4_ck_c(ddr4_ck_c);
  mp_impl->ddr4_reset_n(ddr4_reset_n);
  mp_impl->ddr4_parity(ddr4_parity);
  mp_impl->ddr4_dm_dbi_n(ddr4_dm_dbi_n);
  mp_impl->ddr4_dq(ddr4_dq);
  mp_impl->ddr4_dqs_c(ddr4_dqs_c);
  mp_impl->ddr4_dqs_t(ddr4_dqs_t);
  mp_impl->mc_BG(mc_BG);

}

void phy_rdimm_x8_dual::before_end_of_elaboration()
{
}

#endif // XM_SYSTEMC




#ifdef RIVIERA
phy_rdimm_x8_dual::phy_rdimm_x8_dual(const sc_core::sc_module_name& nm) : phy_rdimm_x8_dual_sc(nm), c0_init_calib_complete("c0_init_calib_complete"), dbg_clk("dbg_clk"), c0_sys_clk_p("c0_sys_clk_p"), c0_sys_clk_n("c0_sys_clk_n"), dbg_bus("dbg_bus"), c0_ddr4_parity("c0_ddr4_parity"), c0_ddr4_ui_clk("c0_ddr4_ui_clk"), c0_ddr4_ui_clk_sync_rst("c0_ddr4_ui_clk_sync_rst"), sys_rst("sys_rst"), rdDataEn("rdDataEn"), rdDataEnd("rdDataEnd"), per_rd_done("per_rd_done"), rmw_rd_done("rmw_rd_done"), wrDataEn("wrDataEn"), mc_ACT_n("mc_ACT_n"), mcCasSlot("mcCasSlot"), mcCasSlot2("mcCasSlot2"), mcRdCAS("mcRdCAS"), mcWrCAS("mcWrCAS"), winInjTxn("winInjTxn"), winRmw("winRmw"), gt_data_ready("gt_data_ready"), winRank("winRank"), tCWL("tCWL"), wrData("wrData"), wrDataMask("wrDataMask"), rdData("rdData"), mc_ADR("mc_ADR"), mc_BA("mc_BA"), mc_CKE("mc_CKE"), mc_CS_n("mc_CS_n"), mc_ODT("mc_ODT"), dBufAdr("dBufAdr"), rdDataAddr("rdDataAddr"), wrDataAddr("wrDataAddr"), winBuf("winBuf"), ddr4_act_n("ddr4_act_n"), ddr4_adr("ddr4_adr"), ddr4_ba("ddr4_ba"), ddr4_bg("ddr4_bg"), ddr4_par("ddr4_par"), ddr4_cke("ddr4_cke"), ddr4_odt("ddr4_odt"), ddr4_cs_n("ddr4_cs_n"), ddr4_ck_t("ddr4_ck_t"), ddr4_ck_c("ddr4_ck_c"), ddr4_reset_n("ddr4_reset_n"), ddr4_parity("ddr4_parity"), ddr4_dm_dbi_n("ddr4_dm_dbi_n"), ddr4_dq("ddr4_dq"), ddr4_dqs_c("ddr4_dqs_c"), ddr4_dqs_t("ddr4_dqs_t"), mc_BG("mc_BG")
{

  // initialize pins
  mp_impl->c0_init_calib_complete(c0_init_calib_complete);
  mp_impl->dbg_clk(dbg_clk);
  mp_impl->c0_sys_clk_p(c0_sys_clk_p);
  mp_impl->c0_sys_clk_n(c0_sys_clk_n);
  mp_impl->dbg_bus(dbg_bus);
  mp_impl->c0_ddr4_parity(c0_ddr4_parity);
  mp_impl->c0_ddr4_ui_clk(c0_ddr4_ui_clk);
  mp_impl->c0_ddr4_ui_clk_sync_rst(c0_ddr4_ui_clk_sync_rst);
  mp_impl->sys_rst(sys_rst);
  mp_impl->rdDataEn(rdDataEn);
  mp_impl->rdDataEnd(rdDataEnd);
  mp_impl->per_rd_done(per_rd_done);
  mp_impl->rmw_rd_done(rmw_rd_done);
  mp_impl->wrDataEn(wrDataEn);
  mp_impl->mc_ACT_n(mc_ACT_n);
  mp_impl->mcCasSlot(mcCasSlot);
  mp_impl->mcCasSlot2(mcCasSlot2);
  mp_impl->mcRdCAS(mcRdCAS);
  mp_impl->mcWrCAS(mcWrCAS);
  mp_impl->winInjTxn(winInjTxn);
  mp_impl->winRmw(winRmw);
  mp_impl->gt_data_ready(gt_data_ready);
  mp_impl->winRank(winRank);
  mp_impl->tCWL(tCWL);
  mp_impl->wrData(wrData);
  mp_impl->wrDataMask(wrDataMask);
  mp_impl->rdData(rdData);
  mp_impl->mc_ADR(mc_ADR);
  mp_impl->mc_BA(mc_BA);
  mp_impl->mc_CKE(mc_CKE);
  mp_impl->mc_CS_n(mc_CS_n);
  mp_impl->mc_ODT(mc_ODT);
  mp_impl->dBufAdr(dBufAdr);
  mp_impl->rdDataAddr(rdDataAddr);
  mp_impl->wrDataAddr(wrDataAddr);
  mp_impl->winBuf(winBuf);
  mp_impl->ddr4_act_n(ddr4_act_n);
  mp_impl->ddr4_adr(ddr4_adr);
  mp_impl->ddr4_ba(ddr4_ba);
  mp_impl->ddr4_bg(ddr4_bg);
  mp_impl->ddr4_par(ddr4_par);
  mp_impl->ddr4_cke(ddr4_cke);
  mp_impl->ddr4_odt(ddr4_odt);
  mp_impl->ddr4_cs_n(ddr4_cs_n);
  mp_impl->ddr4_ck_t(ddr4_ck_t);
  mp_impl->ddr4_ck_c(ddr4_ck_c);
  mp_impl->ddr4_reset_n(ddr4_reset_n);
  mp_impl->ddr4_parity(ddr4_parity);
  mp_impl->ddr4_dm_dbi_n(ddr4_dm_dbi_n);
  mp_impl->ddr4_dq(ddr4_dq);
  mp_impl->ddr4_dqs_c(ddr4_dqs_c);
  mp_impl->ddr4_dqs_t(ddr4_dqs_t);
  mp_impl->mc_BG(mc_BG);

}

void phy_rdimm_x8_dual::before_end_of_elaboration()
{
}

#endif // RIVIERA




#ifdef VCSSYSTEMC
phy_rdimm_x8_dual::phy_rdimm_x8_dual(const sc_core::sc_module_name& nm) : phy_rdimm_x8_dual_sc(nm),  c0_init_calib_complete("c0_init_calib_complete"), dbg_clk("dbg_clk"), c0_sys_clk_p("c0_sys_clk_p"), c0_sys_clk_n("c0_sys_clk_n"), dbg_bus("dbg_bus"), c0_ddr4_parity("c0_ddr4_parity"), c0_ddr4_ui_clk("c0_ddr4_ui_clk"), c0_ddr4_ui_clk_sync_rst("c0_ddr4_ui_clk_sync_rst"), sys_rst("sys_rst"), rdDataEn("rdDataEn"), rdDataEnd("rdDataEnd"), per_rd_done("per_rd_done"), rmw_rd_done("rmw_rd_done"), wrDataEn("wrDataEn"), mc_ACT_n("mc_ACT_n"), mcCasSlot("mcCasSlot"), mcCasSlot2("mcCasSlot2"), mcRdCAS("mcRdCAS"), mcWrCAS("mcWrCAS"), winInjTxn("winInjTxn"), winRmw("winRmw"), gt_data_ready("gt_data_ready"), winRank("winRank"), tCWL("tCWL"), wrData("wrData"), wrDataMask("wrDataMask"), rdData("rdData"), mc_ADR("mc_ADR"), mc_BA("mc_BA"), mc_CKE("mc_CKE"), mc_CS_n("mc_CS_n"), mc_ODT("mc_ODT"), dBufAdr("dBufAdr"), rdDataAddr("rdDataAddr"), wrDataAddr("wrDataAddr"), winBuf("winBuf"), ddr4_act_n("ddr4_act_n"), ddr4_adr("ddr4_adr"), ddr4_ba("ddr4_ba"), ddr4_bg("ddr4_bg"), ddr4_par("ddr4_par"), ddr4_cke("ddr4_cke"), ddr4_odt("ddr4_odt"), ddr4_cs_n("ddr4_cs_n"), ddr4_ck_t("ddr4_ck_t"), ddr4_ck_c("ddr4_ck_c"), ddr4_reset_n("ddr4_reset_n"), ddr4_parity("ddr4_parity"), ddr4_dm_dbi_n("ddr4_dm_dbi_n"), ddr4_dq("ddr4_dq"), ddr4_dqs_c("ddr4_dqs_c"), ddr4_dqs_t("ddr4_dqs_t"), mc_BG("mc_BG")
{
  // initialize pins
  mp_impl->c0_init_calib_complete(c0_init_calib_complete);
  mp_impl->dbg_clk(dbg_clk);
  mp_impl->c0_sys_clk_p(c0_sys_clk_p);
  mp_impl->c0_sys_clk_n(c0_sys_clk_n);
  mp_impl->dbg_bus(dbg_bus);
  mp_impl->c0_ddr4_parity(c0_ddr4_parity);
  mp_impl->c0_ddr4_ui_clk(c0_ddr4_ui_clk);
  mp_impl->c0_ddr4_ui_clk_sync_rst(c0_ddr4_ui_clk_sync_rst);
  mp_impl->sys_rst(sys_rst);
  mp_impl->rdDataEn(rdDataEn);
  mp_impl->rdDataEnd(rdDataEnd);
  mp_impl->per_rd_done(per_rd_done);
  mp_impl->rmw_rd_done(rmw_rd_done);
  mp_impl->wrDataEn(wrDataEn);
  mp_impl->mc_ACT_n(mc_ACT_n);
  mp_impl->mcCasSlot(mcCasSlot);
  mp_impl->mcCasSlot2(mcCasSlot2);
  mp_impl->mcRdCAS(mcRdCAS);
  mp_impl->mcWrCAS(mcWrCAS);
  mp_impl->winInjTxn(winInjTxn);
  mp_impl->winRmw(winRmw);
  mp_impl->gt_data_ready(gt_data_ready);
  mp_impl->winRank(winRank);
  mp_impl->tCWL(tCWL);
  mp_impl->wrData(wrData);
  mp_impl->wrDataMask(wrDataMask);
  mp_impl->rdData(rdData);
  mp_impl->mc_ADR(mc_ADR);
  mp_impl->mc_BA(mc_BA);
  mp_impl->mc_CKE(mc_CKE);
  mp_impl->mc_CS_n(mc_CS_n);
  mp_impl->mc_ODT(mc_ODT);
  mp_impl->dBufAdr(dBufAdr);
  mp_impl->rdDataAddr(rdDataAddr);
  mp_impl->wrDataAddr(wrDataAddr);
  mp_impl->winBuf(winBuf);
  mp_impl->ddr4_act_n(ddr4_act_n);
  mp_impl->ddr4_adr(ddr4_adr);
  mp_impl->ddr4_ba(ddr4_ba);
  mp_impl->ddr4_bg(ddr4_bg);
  mp_impl->ddr4_par(ddr4_par);
  mp_impl->ddr4_cke(ddr4_cke);
  mp_impl->ddr4_odt(ddr4_odt);
  mp_impl->ddr4_cs_n(ddr4_cs_n);
  mp_impl->ddr4_ck_t(ddr4_ck_t);
  mp_impl->ddr4_ck_c(ddr4_ck_c);
  mp_impl->ddr4_reset_n(ddr4_reset_n);
  mp_impl->ddr4_parity(ddr4_parity);
  mp_impl->ddr4_dm_dbi_n(ddr4_dm_dbi_n);
  mp_impl->ddr4_dq(ddr4_dq);
  mp_impl->ddr4_dqs_c(ddr4_dqs_c);
  mp_impl->ddr4_dqs_t(ddr4_dqs_t);
  mp_impl->mc_BG(mc_BG);

  // Instantiate Socket Stubs


}

void phy_rdimm_x8_dual::before_end_of_elaboration()
{
}

#endif // VCSSYSTEMC




#ifdef MTI_SYSTEMC
phy_rdimm_x8_dual::phy_rdimm_x8_dual(const sc_core::sc_module_name& nm) : phy_rdimm_x8_dual_sc(nm),  c0_init_calib_complete("c0_init_calib_complete"), dbg_clk("dbg_clk"), c0_sys_clk_p("c0_sys_clk_p"), c0_sys_clk_n("c0_sys_clk_n"), dbg_bus("dbg_bus"), c0_ddr4_parity("c0_ddr4_parity"), c0_ddr4_ui_clk("c0_ddr4_ui_clk"), c0_ddr4_ui_clk_sync_rst("c0_ddr4_ui_clk_sync_rst"), sys_rst("sys_rst"), rdDataEn("rdDataEn"), rdDataEnd("rdDataEnd"), per_rd_done("per_rd_done"), rmw_rd_done("rmw_rd_done"), wrDataEn("wrDataEn"), mc_ACT_n("mc_ACT_n"), mcCasSlot("mcCasSlot"), mcCasSlot2("mcCasSlot2"), mcRdCAS("mcRdCAS"), mcWrCAS("mcWrCAS"), winInjTxn("winInjTxn"), winRmw("winRmw"), gt_data_ready("gt_data_ready"), winRank("winRank"), tCWL("tCWL"), wrData("wrData"), wrDataMask("wrDataMask"), rdData("rdData"), mc_ADR("mc_ADR"), mc_BA("mc_BA"), mc_CKE("mc_CKE"), mc_CS_n("mc_CS_n"), mc_ODT("mc_ODT"), dBufAdr("dBufAdr"), rdDataAddr("rdDataAddr"), wrDataAddr("wrDataAddr"), winBuf("winBuf"), ddr4_act_n("ddr4_act_n"), ddr4_adr("ddr4_adr"), ddr4_ba("ddr4_ba"), ddr4_bg("ddr4_bg"), ddr4_par("ddr4_par"), ddr4_cke("ddr4_cke"), ddr4_odt("ddr4_odt"), ddr4_cs_n("ddr4_cs_n"), ddr4_ck_t("ddr4_ck_t"), ddr4_ck_c("ddr4_ck_c"), ddr4_reset_n("ddr4_reset_n"), ddr4_parity("ddr4_parity"), ddr4_dm_dbi_n("ddr4_dm_dbi_n"), ddr4_dq("ddr4_dq"), ddr4_dqs_c("ddr4_dqs_c"), ddr4_dqs_t("ddr4_dqs_t"), mc_BG("mc_BG")
{
  // initialize pins
  mp_impl->c0_init_calib_complete(c0_init_calib_complete);
  mp_impl->dbg_clk(dbg_clk);
  mp_impl->c0_sys_clk_p(c0_sys_clk_p);
  mp_impl->c0_sys_clk_n(c0_sys_clk_n);
  mp_impl->dbg_bus(dbg_bus);
  mp_impl->c0_ddr4_parity(c0_ddr4_parity);
  mp_impl->c0_ddr4_ui_clk(c0_ddr4_ui_clk);
  mp_impl->c0_ddr4_ui_clk_sync_rst(c0_ddr4_ui_clk_sync_rst);
  mp_impl->sys_rst(sys_rst);
  mp_impl->rdDataEn(rdDataEn);
  mp_impl->rdDataEnd(rdDataEnd);
  mp_impl->per_rd_done(per_rd_done);
  mp_impl->rmw_rd_done(rmw_rd_done);
  mp_impl->wrDataEn(wrDataEn);
  mp_impl->mc_ACT_n(mc_ACT_n);
  mp_impl->mcCasSlot(mcCasSlot);
  mp_impl->mcCasSlot2(mcCasSlot2);
  mp_impl->mcRdCAS(mcRdCAS);
  mp_impl->mcWrCAS(mcWrCAS);
  mp_impl->winInjTxn(winInjTxn);
  mp_impl->winRmw(winRmw);
  mp_impl->gt_data_ready(gt_data_ready);
  mp_impl->winRank(winRank);
  mp_impl->tCWL(tCWL);
  mp_impl->wrData(wrData);
  mp_impl->wrDataMask(wrDataMask);
  mp_impl->rdData(rdData);
  mp_impl->mc_ADR(mc_ADR);
  mp_impl->mc_BA(mc_BA);
  mp_impl->mc_CKE(mc_CKE);
  mp_impl->mc_CS_n(mc_CS_n);
  mp_impl->mc_ODT(mc_ODT);
  mp_impl->dBufAdr(dBufAdr);
  mp_impl->rdDataAddr(rdDataAddr);
  mp_impl->wrDataAddr(wrDataAddr);
  mp_impl->winBuf(winBuf);
  mp_impl->ddr4_act_n(ddr4_act_n);
  mp_impl->ddr4_adr(ddr4_adr);
  mp_impl->ddr4_ba(ddr4_ba);
  mp_impl->ddr4_bg(ddr4_bg);
  mp_impl->ddr4_par(ddr4_par);
  mp_impl->ddr4_cke(ddr4_cke);
  mp_impl->ddr4_odt(ddr4_odt);
  mp_impl->ddr4_cs_n(ddr4_cs_n);
  mp_impl->ddr4_ck_t(ddr4_ck_t);
  mp_impl->ddr4_ck_c(ddr4_ck_c);
  mp_impl->ddr4_reset_n(ddr4_reset_n);
  mp_impl->ddr4_parity(ddr4_parity);
  mp_impl->ddr4_dm_dbi_n(ddr4_dm_dbi_n);
  mp_impl->ddr4_dq(ddr4_dq);
  mp_impl->ddr4_dqs_c(ddr4_dqs_c);
  mp_impl->ddr4_dqs_t(ddr4_dqs_t);
  mp_impl->mc_BG(mc_BG);

  // Instantiate Socket Stubs


}

void phy_rdimm_x8_dual::before_end_of_elaboration()
{
}

#endif // MTI_SYSTEMC




phy_rdimm_x8_dual::~phy_rdimm_x8_dual()
{
}

#ifdef MTI_SYSTEMC
SC_MODULE_EXPORT(phy_rdimm_x8_dual);
#endif

#ifdef XM_SYSTEMC
XMSC_MODULE_EXPORT(phy_rdimm_x8_dual);
#endif

#ifdef RIVIERA
SC_MODULE_EXPORT(phy_rdimm_x8_dual);
SC_REGISTER_BV(576);
#endif

