.DEFAULT_GOAL := all

all: templates

TEMPLATED_FILES := design/wfg_stim_sine/rtl/wfg_stim_sine_wishbone_reg.sv \
                   design/wfg_stim_sine/rtl/wfg_stim_sine_top.sv

DATA_FILES := design/wfg_stim_sine/data/wfg_stim_sine_reg.csv
LIBRARIES := $(DATA_FILES:.csv=.json)

${LIBRARIES}: ${DATA_FILES}
	templating/converter.py -i $^ -o $@

templates: ${TEMPLATED_FILES} ${LIBRARIES}
	templating/generator.py --template_dir templating/templates -i ${TEMPLATED_FILES}

unit-tests:
	cd design/wfg_stim_sine/sim; make sim

.PHONY: templates unit-tests
