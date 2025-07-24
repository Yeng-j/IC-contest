#SHELL = /bin/csh

# run:
# 	find ./RTL -maxdepth 1 -type f \( -name "*.sv" -o -name "*.v" \) > ./RTL/demo.f &\
# 	vcs -R -f ./RTL/demo.f \
# 	    -full64 \
# 	    -debug_access+all \
# 	    +v2k\
	    

# run:
# 	find ./RTL -maxdepth 1 -type f \( -name "*.sv" -o -name "*.v" \) -exec realpath {} \; > ./verification/rtl_sim/demo.f
# 	cd ./verification && \
# 	vcs -R -file ./rtl_sim/demo.f \
#     	-full64 \
#     	-sverilog \
#     	-debug_access+all

run:
	
	cd ./verification && \
	vcs -R \
    	-full64 \
     -kdb \
    	-sverilog \
    	-debug_access+all ../RTL/LBP.sv ../RTL/testfixture.v\

#dbg:
#	verdi -sv -f $(FILE) -ssf $(firstword $(wildcard ./verification/rtl_sim/*.fsdb)) -nologo &
 
dbg:
	verdi -ssf $(firstword $(wildcard ./verification/rtl_sim/*.fsdb)) -nologo &



clean:
	rm -rf *.o *.cf *.daidir csrc simv simv.daidir ucli.key vc_hdrs.h DVEfiles \
	       $(DEMO_FILE) *.log *.txt *.conf *.rc


# Synthesis step
syn:
	cd ./_syn && \
	dc_shell -f  DC_syn.tcl | tee run_dc.txt

# Gate-level simulation step
# IC contest
gate:
	cd ./verification && \
	vcs -q -R  ../RTL/testfixture.v \
	    ../_syn/LBP_syn.v \
	    /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v \
	    -full64 \
		+neg_tchk \
	    -debug_access+all \
		+v2k \
	    -diag=sdf:verbose \
	    +define+SDF | tee ./gate_sim/chip_gls.log
	    

# Gate-level simulation step
# UMC_180
gate_UMC:
	cd ./verification && \
	vcs -q -R  ../RTL/testfixture.v \
	    ../_syn/Netlist/LBP_syn_v1.v \
	    /cad/CBDK/CBDK_UMC018_ITRI_v0.8/orig_lib/IO/Verilog/U018IOCUP.v\
	    -full64 \
		+neg_tchk \
	    -debug_access+all \
		+v2k \
	    -diag=sdf:verbose \
	    +define+SDF | tee ./gate_sim/chip_gls.log