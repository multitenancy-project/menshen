################################################################################
# Vivado Launch Script
################################################################################

JOBS=$(shell nproc)

.PHONY: clean all

all:
	@echo ""
	@echo "NetFPGA-SUME FlowBlaze project makefile"
	@echo ""
	@echo "usage:"
	@echo "------------------------------------------------------"
	@echo "make project:    Create HW project"
	@echo "make hw:         Compile HW "
	@echo "make firmware:   Create firmware project"
	@echo "make compile:    Compile firmware"
	@echo "make clean:      Remove generated files"
	@echo "make wipe:       Needed to recreate the HW project"

hw: 
	vivado -mode tcl -source tcl/make.tcl
	@cp ./TProj.runs/impl_1/top.bit tproj.bit

firmware:
	@if [ -d ./SDK_Workspace ]; then rm -rf ./SDK_Workspace ; fi
	mkdir ./SDK_Workspace
	xsdk -batch -source ./tcl/flowblaze_xsdk.tcl


# Compile Command needs to run twice to get sw compiled correctly in DEBUG mode
compile:
	@if [ -d ./SDK_Workspace ]; then \
		xsdk -batch -source ./tcl/compile_xsdk.tcl \
	else \
                echo "Firmware Workspace not found"; \
        fi
	@cp ./SDK_Workspace/flowblaze/app/Debug/app.elf firmware.elf

project: create_project run_synth run_impl

gen_bit: run_synth run_impl

create_project: 
	vivado -mode batch -source tcl/create_project.tcl

run_synth:
	vivado -mode batch -source tcl/run_synth.tcl -tclargs ${JOBS}

run_impl:
	vivado -mode batch -source tcl/run_impl.tcl -tclargs ${JOBS}

run_sim:
	vivado -mode gui -source tcl/proj_sim.tcl 

wipe:   clean	
	rm -rfv  firmware/
	rm -rfv  TProj.xpr
	rm -rfv  tproj.hdf 
	rm -rfv  TProj.srcs/
	rm -rfv  TProj.ip_user_files/
	rm -rfv  TProj.sim/ 
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
