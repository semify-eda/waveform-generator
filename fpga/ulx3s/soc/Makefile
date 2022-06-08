default: build

CPU_TYPE = vexriscv

firmware/firmware_sim.bin:
	cd firmware; make -f sim.make clean; make -f sim.make

firmware/firmware_build.bin:
	cd firmware; make -f build.make clean; make -f build.make

sim-prebuild:
	python3 ulx3s_soc.py --sim-debug --gtkwave-savefile --trace --trace-fst --with-wfg --simulate --cpu-type $(CPU_TYPE)

sim: firmware/firmware_sim.bin
	python3 ulx3s_soc.py --rom-init=firmware/firmware_sim.bin --sim-debug --gtkwave-savefile --trace --trace-fst --with-wfg --simulate --cpu-type $(CPU_TYPE)

build-prebuild:
	python3 ulx3s_soc.py --with-led-chaser --with-wfg --build --cpu-type $(CPU_TYPE)

build: firmware/firmware_build.bin
	python3 ulx3s_soc.py --rom-init=firmware/firmware_build.bin --with-led-chaser --with-wfg --build --cpu-type $(CPU_TYPE)

upload: build
	openFPGALoader --board=ulx3s build/radiona_ulx3s/gateware/radiona_ulx3s.bit

only-upload:
	openFPGALoader --board=ulx3s build/radiona_ulx3s/gateware/radiona_ulx3s.bit

view:
	gtkwave build/sim/gateware/sim.fst --save build/sim/gateware/sim.gtkw 

.PHONY: sim build upload only-upload view firmware/firmware_build.bin firmware/firmware_sim.bin
