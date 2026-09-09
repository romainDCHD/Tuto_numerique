#####################################################################################
# General config
export XRUN_stdcell=/share/Pdk/IHP/SG13S/ixc013_stdcell/verilog/ixc013_stdcell.v
export XRUN_prim=/share/Pdk/IHP/SG13S/ixc013_stdcell/verilog/ixc013_primitives.v
export ROUTED_RTL=flow/03_pnr/01_pnr_minimal/workdir/outputs/ripple_carry_4.routed.v
export TESTBENCH=dut/rtl/tb_ripple_carry_4.sv
export SDF_CMD_FILE=flow/01_simulation/02_simulation_gate_level/sdf_cmd_file
export DESIGN_PATH="/local/rduchadeau/home/tuto_numerique_romain/"

#####################################################################################
help:
	echo -e "\nAvaliables options : \n- run_sim (with gui) \n- run_sim_no_gui (no gui) \n- clean (clean /workdir) \n- run_gate_level (sim after PnR) \n "
#####################################################################################
clean: 
	rm -rf ./workdir/*


#####################################################################################
_run_sim:
	cd workdir/ && echo "running xrun in $(pwd)" && \
	xrun -64bit \
	-sv  \
	-access +rwc \
	-timescale 1ns/1ps \
	-mess \
	-f ${DESIGN_PATH}/dut/filelists/rtl.f \
	-f ${DESIGN_PATH}/dut/filelists/tb.f \
	-top tb_ripple_carry_4 \
	$(GUI_OPT)


#####################################################################################
run_sim:GUI_OPT="-gui"
run_sim:_run_sim



#####################################################################################
run_sim_no_gui:GUI_OPT=""
run_sim_no_gui:_run_sim

#####################################################################################
run_gate_level:
	xrun -64bit \
	-sv \
	-access +rwc \
	-gui \
	-timescale 1ns/1ps \
	-mess \
	${XRUN_stdcell} \
	${XRUN_prim} \
	${ROUTED_RTL} \
	${TESTBENCH} \
	-sdf_cmd_file ${SDF_CMD_FILE}
