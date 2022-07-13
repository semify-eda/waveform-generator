# source files
SRC := $(wildcard ../rtl/*.sv)
SRC += $(wildcard ../testbench/*.sv)
SRC += $(wildcard ../../wfg_core/rtl/*.sv)
SRC += $(wildcard ../../wfg_subcore/rtl/*.sv)
SRC += $(wildcard ../../wfg_interconnect/rtl/*.sv)
SRC += $(wildcard ../../wfg_stim_sine/rtl/*.sv)
SRC += $(wildcard ../../wfg_stim_mem/rtl/*.sv)
SRC += $(wildcard ../../wfg_drive_spi/rtl/*.sv)
SRC += $(wildcard ../../wfg_drive_pat/rtl/*.sv)

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(SRC)

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = wfg_top_tb

# MODULE is the basename of the Python test file
export PYTHONPATH := $(PYTHONPATH):../testbench/
MODULE = test_wfg_top

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
