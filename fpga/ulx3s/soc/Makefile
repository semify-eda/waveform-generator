default: build

firmware/firmware.bin:
	cd firmware; make

build: firmware/firmware.bin
	python3 ulx3s_soc.py --build

upload: build
	openFPGALoader --board=ulx3s build/radiona_ulx3s/gateware/radiona_ulx3s.bit

only-upload:
	openFPGALoader --board=ulx3s build/radiona_ulx3s/gateware/radiona_ulx3s.bit

sim:
	python3 ulx3s_soc_sim.py --rom-init=firmware_sim/firmware.bin --with-analyzer --sim-debug --gtkwave-savefile --trace --trace-fst --with-wfg

view:
	gtkwave build/sim/gateware/sim.fst --save build/sim/gateware/sim.gtkw 

.PHONY: upload build only-upload
