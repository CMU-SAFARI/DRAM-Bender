# some of the generated files have CR characters in additon to EOL characters
# which mess with our patch commands.
dos2unix XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_rd_en.sv

for f in ./patches/*.patch
do
    patch -p0 < $f
done

