.DEFAULT_GOAL := all

all: templates

TEMPLATED_FILES := design/wfg_stim_sine/rtl/wfg_stim_sine_wishbone_reg.sv \
                   design/wfg_stim_sine/rtl/wfg_stim_sine_top.sv

DATA_FILES := design/wfg_stim_sine/data/wfg_stim_sine_reg.csv
LIBRARIES := $(DATA_FILES:.csv=.json)

${LIBRARIES}: ${DATA_FILES}
	python3 templating/converter.py -i $^ -o $@

templates: ${TEMPLATED_FILES} ${LIBRARIES}
	python3 templating/generator.py --template_dir templating/templates -i ${TEMPLATED_FILES}

unit-tests:
	cd design/wfg_stim_sine/sim; make sim

lint:
	verible-verilog-lint design/*/*/*.sv

lint-autofix:
	verible-verilog-lint --autofix inplace-interactive design/*/*/*.sv

clean:
	rm -rf design/*/sim/sim_build
	rm -rf design/*/sim/*.vcd
	rm -rf design/*/sim/*.xml

.PHONY: templates unit-tests clean
