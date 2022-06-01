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
 - stim_sine    - 0x02
 - drive_spi    - 0x03

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
    
    // Sine
    wfg_set_register(0x2, 0x0, 1); // Enable

    // SPI
    wfg_set_register(0x3, 0x8, cnt); // Clock divider
    wfg_set_register(0x3, 0x4, (cpol<<0) | (lsbfirst<<1) | (dff<<2) | (sspol<<4));
    wfg_set_register(0x3, 0x0, 1); // Enable SPI
}

#endif
