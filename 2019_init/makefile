#SHELL = /bin/csh

# run:
# 	find ./RTL -maxdepth 1 -type f \( -name "*.sv" -o -name "*.v" \) > ./RTL/demo.f &\
# 	vcs -R -f ./RTL/demo.f \
# 	    -full64 \
# 	    -debug_access+all \
# 	    +v2k\


run:
	find ./RTL -maxdepth 1 -type f \( -name "*.sv" -o -name "*.v" \) -exec realpath {} \; > ./verification/rtl_sim/demo.f
	cd ./verification && \
	vcs -R -file ./rtl_sim/demo.f \
    	-full64 \
    	-sverilog \
    	-debug_access+all\
		+define+rtl_fsdb 

dbg_rtl:
	verdi  -ssf $(firstword $(wildcard ./verification/*.fsdb)) -nologo &
# dbg_rtl:
# 	verdi  -ssf "/home/ai05/CGU_EE/DIC/hw1/verification/DCT.fsdb" -nologo &

dbg_gate:
	verdi  -ssf "/home/ai05/CGU_EE/APR/conv/verification/CONV_gate.fsdb" -nologo &


clean:
	rm -rf *.o *.cf *.daidir csrc simv simv.daidir ucli.key vc_hdrs.h DVEfiles \
	       $(DEMO_FILE) *.log *.txt *.conf *.rc


# Synthesis step
#IC contest
syn:
	cd ./_syn && \
	dc_shell -f  DC_syn.tcl | tee run_dc.txt

# Gate-level simulation step
# IC contest
gate:
	cd ./verification && \
	vcs -q -R  ../RTL/testfixture.v \
	    ../_syn/CONV_syn.v \
		/cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v \
	    -full64 \
		+notimingcheck\
		+neg_tchk \
	    -debug_access+all \
		+v2k \
	    -diag=sdf:verbose \
		+define+gate_fsdb \
	    +define+SDF | tee ./gate_sim/chip_gls.log

# U18	    
syn_u18:
	cd ./_syn && \
	dc_shell -f  DC_syn_U18.tcl | tee run_dc.txt

gate_u18:
	cd ./verification && \
	vcs -q -R  ../RTL/testfixture.v \
	    ../_syn/Netlist/CONV_syn_v1.v \
		/cad/CBDK/CBDK_UMC018_ITRI_v0.8/CIC/Verilog/U018IOCUP.v\
		/cad/CBDK/CBDK_UMC018_ITRI_v0.8/CIC/Verilog/UDVS_u018mm.v\
	    -full64 \
		-Mupdate\
		+neg_tchk \
		-neg_delay\
	    -debug_access+all \
		+v2k \
   	    +define+SDF \
	    -diag=sdf:verbose \
		+define+gate_fsdb \
		+recrem | tee ./gate_sim/chip_gls.log