BUILD_DIR?=../build/sim/

include $(BUILD_DIR)/software/include/generated/variables.mak
include $(SOC_DIRECTORY)/software/common.mak

OBJECTS = sim_debug.o sim.o wfg.o donut.o crt0.o main.o

all: firmware_sim.bin

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
	chmod -x $@

vpath %.a $(PACKAGES:%=../%)

firmware_sim.elf: $(OBJECTS)
	$(CC) $(LDFLAGS) -T linker.ld -N -o $@ \
		$(OBJECTS) \
		$(PACKAGES:%=-L$(BUILD_DIR)/software/%) \
		-Wl,--gc-sections \
		$(LIBS:lib%=-l%)
	chmod -x $@

# pull in dependency info for *existing* .o files
-include $(OBJECTS:.o=.d)

donut.o: CFLAGS   += -w

VPATH = $(BIOS_DIRECTORY):$(BIOS_DIRECTORY)/cmds:$(CPU_DIRECTORY)

%.o: %.cpp
	$(compilexx)

%.o: %.c
	$(compile)

%.o: %.S
	$(assemble)

clean:
	$(RM) $(OBJECTS) firmware_sim.elf firmware_sim.bin .*~ *~ *.d

.PHONY: all clean
