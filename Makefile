.DEFAULT_GOAL := all

all: templates

TEMPLATED_FILES := design/wfg_stim_sine/rtl/wfg_stim_sine_wishbone_reg.sv \
                   design/wfg_stim_sine/rtl/wfg_stim_sine_top.sv \
                   design/wfg_stim_mem/rtl/wfg_stim_mem_wishbone_reg.sv \
                   design/wfg_stim_mem/rtl/wfg_stim_mem_top.sv \
                   design/wfg_drive_spi/rtl/wfg_drive_spi_top.sv \
                   design/wfg_drive_spi/rtl/wfg_drive_spi_wishbone_reg.sv \
                   design/wfg_drive_pat/rtl/wfg_drive_pat_top.sv \
                   design/wfg_drive_pat/rtl/wfg_drive_pat_wishbone_reg.sv \
                   design/wfg_interconnect/rtl/wfg_interconnect_top.sv \
                   design/wfg_interconnect/rtl/wfg_interconnect_wishbone_reg.sv \
                   design/wfg_core/rtl/wfg_core_top.sv \
                   design/wfg_core/rtl/wfg_core_wishbone_reg.sv \
                   design/wfg_subcore/rtl/wfg_subcore_top.sv \
                   design/wfg_subcore/rtl/wfg_subcore_wishbone_reg.sv


DATA_FILES := design/wfg_stim_sine/data/wfg_stim_sine_reg.csv \
              design/wfg_stim_mem/data/wfg_stim_mem_reg.csv \
              design/wfg_drive_spi/data/wfg_drive_spi_reg.csv \
              design/wfg_drive_pat/data/wfg_drive_pat_reg.csv \
              design/wfg_interconnect/data/wfg_interconnect_reg.csv \
              design/wfg_core/data/wfg_core_reg.csv \
              design/wfg_subcore/data/wfg_subcore_reg.csv

LIBRARIES := $(DATA_FILES:.csv=.json)

%.json: %.csv
	python3 templating/converter.py -i $^ -o $@

templates: ${TEMPLATED_FILES} ${LIBRARIES}
	python3 templating/generator.py --template_dir templating/templates -i ${TEMPLATED_FILES}

tests:
	cd design/wfg_stim_sine/sim; make sim
	cd design/wfg_stim_mem/sim; make sim
	cd design/wfg_drive_spi/sim; make sim
	#cd design/wfg_drive_pat/sim; make sim # TODO fix tests
	cd design/wfg_interconnect/sim; make sim
	cd design/wfg_core/sim; make sim
	cd design/wfg_subcore/sim; make sim
	cd design/wfg_top/sim; make sim

lint:
	verible-verilog-lint --rules=-unpacked-dimensions-range-ordering design/*/*/*.sv

lint-verilator:
	verilator --lint-only -Wall design/wfg_drive_spi/rtl/*.sv

lint-autofix:
	verible-verilog-lint --rules=-unpacked-dimensions-range-ordering --autofix inplace-interactive design/*/*/*.sv

format:
	verible-verilog-format --indentation_spaces 4 --module_net_variable_alignment=preserve --case_items_alignment=preserve design/*/*/*.sv --inplace --verbose

ulx3s.json: design/*/rtl/*.sv
	yosys -ql $(basename $@)-yosys.log -p 'synth_ecp5 -top wfg_top -json $@' $^

nextpnr-view: ulx3s.json
	nextpnr-ecp5 --85k --json $< \
		--lpf-allow-unconstrained \
		--package CABGA381 \
		--textcfg ulx3s_out.config --gui 

clean:
	rm -rf design/*/sim/sim_build
	rm -rf design/*/sim/*.vcd
	rm -rf design/*/sim/*.xml
	rm -f ulx3s_out.config
	rm -f ulx3s-yosys.log
	rm -f ulx3s.json

.PHONY: templates unit-tests lint lint-autofix format clean nextpnr_view
