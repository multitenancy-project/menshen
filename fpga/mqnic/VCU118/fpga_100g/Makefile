# # Targets
# TARGETS:=
# 
# # Subdirectories
# SUBDIRS = fpga
# SUBDIRS_CLEAN = $(patsubst %,%.clean,$(SUBDIRS))
# 
# # Rules
# .PHONY: all
# all: $(SUBDIRS) $(TARGETS)
# 
# .PHONY: $(SUBDIRS)
# $(SUBDIRS):
# 	cd $@ && $(MAKE)
# 
# .PHONY: $(SUBDIRS_CLEAN)
# $(SUBDIRS_CLEAN):
# 	cd $(@:.clean=) && $(MAKE) clean
# 
# .PHONY: clean
# clean: $(SUBDIRS_CLEAN)
# 	-rm -rf $(TARGETS)
# 
# program:
# 	#djtgcfg prog -d Atlys --index 0 --file fpga/fpga.bit
#
#
JOBS=$(shell nproc)


.PHONY: all project clean

all: project run_synth run_impl
	@echo "hh"

project:
	vivado -mode batch -source tcl/create_project.tcl

run_synth:
	vivado -mode batch -source tcl/run_synth.tcl -tclargs ${JOBS}

run_impl:
	vivado -mode batch -source tcl/run_impl.tcl -tclargs ${JOBS}

clean:
	rm -rfv project_synth
	rm -rfv vivado*
	rm -rfv xvlog*
	rm -rfv xsim.dir
	rm -rfv tb/xvlog*
	rm -rfv tb/xsim.dir
