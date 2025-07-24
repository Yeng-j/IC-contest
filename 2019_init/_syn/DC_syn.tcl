#Read All Files
read_sverilog "/home/host/Documents/Yan-j/IC-contest/2019_init/RTL/CONV.sv"
current_design CONV
link

#Setting Clock Constraints
source -echo -verbose CONV.sdc

#Synthesis all design
compile -map_effort high -area_effort high
compile -map_effort high -area_effort high -inc
#compile_ultra


write -format ddc     -hierarchy -output "CONV_syn.ddc"
write_sdf CONV_syn.sdf
write_file -format verilog -hierarchy -output CONV_syn.v
report_area > CONV_area.log
report_timing > CONV_timing.log
report_qor   >  CONV_syn.qor

