.PHONY: clean


run_sim:
	vivado -mode batch -source tcl/proj_sim.tcl

clean:
	rm -rfv vivado*
	rm -rfv *.log
	rm -rfv .Xil
	rm -rfv webtalk*
	rm -rfv *.*~
	rm -rfv ip_repo
	rm -rfv ip_proj
	rm -rfv *.cache
	rm -rfv *.hw
	rm -rfv *.runs
	rm -rfv SDK_Workspace
	rm -rfv  tproj.bit
	rm -rfv  firmware.elf
	rm -rfv xsim.dir
	rm -rfv xvlog.pb
	rm -rfv TProj.hbs
	rm -rfv project_sim
	rm -rfv project_synth
	rm -rfv ip_repo
