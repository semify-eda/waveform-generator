default: build

firmware/firmware.bin:
	cd firmware; make

build: firmware/firmware.bin
	python3 ulx3s_soc.py --build

upload:
	@echo Did you build before this?
	openFPGALoader --board=ulx3s build/radiona_ulx3s/gateware/radiona_ulx3s.bit

.PHONY: upload build
