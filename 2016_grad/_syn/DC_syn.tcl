#Read All Files
read_sverilog "/home/host/Documents/Yan-j/IC-contest/2016_grad/RTL/LBP.sv"
current_design LBP
link

#Setting Clock Constraints
source -echo -verbose LBP.sdc

#Synthesis all design
compile -map_effort high -area_effort high
compile -map_effort high -area_effort high -inc
#compile_ultra


write -format ddc     -hierarchy -output "LBP_syn.ddc"
write_sdf LBP_syn.sdf
write_file -format verilog -hierarchy -output LBP_syn.v
report_area > LBP_area.log
report_timing > LBP_timing.log
report_qor   >  LBP_syn.qor

