# some of the generated files have CR characters in additon to EOL characters
# which mess with our patch commands.
dos2unix XUSP3R.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_rd_en.sv
dos2unix XUSP3R.srcs/sources_1/ip/phy_ddr4_x8/rtl/cal/ddr4_v2_2_cal_rd_en.sv
dos2unix XUSP3R.srcs/sources_1/ip/phy_ddr4_x8_1R/rtl/cal/ddr4_v2_2_cal_rd_en.sv
dos2unix XUSP3R.srcs/sources_1/ip/phy_ddr4_udimm/rtl/cal/ddr4_v2_2_cal_rd_en.sv

for f in ./patches/*.patch
do
    patch -p0 < $f
done

