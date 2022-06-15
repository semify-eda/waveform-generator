<img align="right" src="https://github.com/semify-eda/wfg/blob/main/doc/semify.png" width="100" height="100" >

*Copyright © 2021* [Semify EDA](
https://github.com/semify-eda)

## wfg_drive_spi documentation

#### Overview

The wfg_drive_spi module is a SPI master module used in the output stage of the waveform generator and is only operating in MOSI mode. The module is
triggered by the wfg_core, each sync puls starts a new transmission.
The input is received via an axi stream (32 bit) interface.
The transmission is handled entirely within the module and all SPI signals are generated automatically and are configurable.

#### Verification

A system clock with frequency f = 100 MHz and an asynchronous wfg_sync signal are defined in the cocotb testbench. 
The Python function random.randint is used to generate a list of random input values. Via a cocotb AXI-Stream master the SPI module receives a new input
at each sync pulse. The functionality is tested with a test factory that runs through all possible configuration parameters. 
The SPI module is connected to a cocotb SPI interface which decodes each successful transmission.
