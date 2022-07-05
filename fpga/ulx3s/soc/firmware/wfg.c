#include <stdio.h>
#include <generated/mem.h>

#ifdef WFG_BASE

int cnt = 3;
int cpol = 0;
int lsbfirst = 0;
int dff = 3;
int sspol = 0;

/*
Write to a register of the waveform generator

peripheral:
 - core         - 0x01
 - interconnect - 0x02
 - stim_sine    - 0x03
 - stim_mem     - 0x04
 - drive_spi    - 0x05
 - drive_pat    - 0x06

address:
The address of the register, can be 0-15
*/
void wfg_set_register(int peripheral, int address, int value)
{
    *(volatile int*)(WFG_BASE + (peripheral<<4) + (address & 0xF)) = value;
    
    int readback = *(volatile int*)(WFG_BASE + (peripheral<<4) + (address & 0xF));
    
    if (readback != value)
    {
        printf("Wrong value: %d != %d\n", readback, value);
    }    
}

void wfg_inc_cnt(void)
{
    cnt++;
    printf("cnt: %d\n", cnt);
    wfg_set_register(0x3, 0x8, cnt); // Clock divider
}

void wfg_dec_cnt(void)
{
    cnt--;
    printf("cnt: %d\n", cnt);
    wfg_set_register(0x3, 0x8, cnt); // Clock divider
}

void wfg_init(void)
{
    //*(volatile int*)(WFG_BASE) = 0xDEADBEEF;

    int sync_count = 16;
    int subcycle_count = 16;

    // Core
    wfg_set_register(0x1, 0x4, (sync_count << 0) | (subcycle_count << 8));
    wfg_set_register(0x1, 0x0, 1); // Enable
    
    // Interconnect
    wfg_set_register(0x2, 0x4, 0); // Driver0
    wfg_set_register(0x2, 0x8, 1); // Driver1
    wfg_set_register(0x2, 0x0, 1); // Enable
    
    // Sine
    wfg_set_register(0x3, 0x0, 1); // Enable
    
    // Mem
    wfg_set_register(0x4, 0x4, 0x4); // Start
    wfg_set_register(0x4, 0x8, 0xF); // End
    wfg_set_register(0x4, 0xC, 0x2); // Increment
    wfg_set_register(0x4, 0x0, 1); // Enable

    // SPI
    wfg_set_register(0x5, 0x8, cnt); // Clock divider
    wfg_set_register(0x5, 0x4, (cpol<<0) | (lsbfirst<<1) | (dff<<2) | (sspol<<4));
    wfg_set_register(0x5, 0x0, 1); // Enable SPI
    
    // Pattern
    wfg_set_register(0x6, 0x4, (0) | (8<<8) ); // Start:End
    wfg_set_register(0x6, 0x8, 0xFFFFFFFF); // Low bit
    wfg_set_register(0x6, 0xC, 0xFFFFFFFF); // High bit
    wfg_set_register(0x6, 0x0, 0xFFFFFFFF); // Enable all bits
}

#endif
