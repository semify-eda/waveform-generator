.DEFAULT_GOAL := all

all: templates

TEMPLATED_FILES := design/wfg_stim_sine/rtl/wfg_stim_sine_wishbone_reg.sv \
                   design/wfg_stim_sine/rtl/wfg_stim_sine_top.sv \
                   design/wfg_drive_spi/rtl/wfg_drive_spi_top.sv \
                   design/wfg_drive_spi/rtl/wfg_drive_spi_wishbone_reg.sv \
                   design/wfg_core/rtl/wfg_core_top.sv \
                   design/wfg_core/rtl/wfg_core_wishbone_reg.sv

DATA_FILES := design/wfg_stim_sine/data/wfg_stim_sine_reg.csv \
              design/wfg_drive_spi/data/wfg_drive_spi_reg.csv \
              design/wfg_core/data/wfg_core_reg.csv

LIBRARIES := $(DATA_FILES:.csv=.json)

%.json: %.csv
	python3 templating/converter.py -i $^ -o $@

templates: ${TEMPLATED_FILES} ${LIBRARIES}
	python3 templating/generator.py --template_dir templating/templates -i ${TEMPLATED_FILES}

unit-tests:
	cd design/wfg_stim_sine/sim; make sim
	cd design/wfg_drive_spi/sim; make sim
	cd design/wfg_core/sim; make sim
	cd design/wfg_top/sim; make sim

lint:
	verible-verilog-lint --rules=-unpacked-dimensions-range-ordering design/*/*/*.sv

lint-verilator:
	verilator --lint-only -Wall design/wfg_drive_spi/rtl/*.sv

lint-autofix:
	verible-verilog-lint --rules=-unpacked-dimensions-range-ordering --autofix inplace-interactive design/*/*/*.sv

format:
	verible-verilog-format --indentation_spaces 4 --module_net_variable_alignment=preserve --case_items_alignment=preserve design/*/*/*.sv --inplace --verbose

ulx3s.json: design/*/rtl/*.sv fpga/ulx3s/ulx3s_top.sv
	yosys -ql $(basename $@)-yosys.log -p 'synth_ecp5 -top ulx3s_top -json $@' $^

ulx3s_out.config: ulx3s.json
	nextpnr-ecp5 --85k --json $< \
		--lpf fpga/ulx3s/ulx3s_v20.lpf \
		--package CABGA381 \
		--textcfg ulx3s_out.config 

ulx3s.bit: ulx3s_out.config
	ecppack ulx3s_out.config ulx3s.bit

prog_ulx3s: ulx3s.bit
	openFPGALoader --board=ulx3s ulx3s.bit

clean:
	rm -rf design/*/sim/sim_build
	rm -rf design/*/sim/*.vcd
	rm -rf design/*/sim/*.xml
	rm -f ulx3s_out.config
	rm -f ulx3s-yosys.log
	rm -f ulx3s.json
	rm -f ulx3s.bit

.PHONY: templates unit-tests lint lint-autofix format clean prog_ulx3s
