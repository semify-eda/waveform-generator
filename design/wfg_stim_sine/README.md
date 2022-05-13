# Documentation

## Overview

The Sine Wave Pattern Generator serves as a data generator that provides data for the AXI streaming interface. The sine wave generator, as the name implies, generates values in the form of sine waves. The values are generated from the angular phase, which is controlled by the `inc` (increment) register. Other parameters that influence the sine wave are gain, multiplier with a range of 0 - 1.999..., and offset with a range of -2 to 1.999....

## RTL Implementation - CORDIC Algorithm

CORDIC (COordinate Rotation DIgital Computer) is a hardware-efficient iterative method that uses rotations to compute a wide range of elementary functions. The RTL uses the CORDIC algorithm as a primitive method for generating sinusoidal values from phase. The behavior of the CORDIC algorithm is controlled by the following input registers:
  - inc_val_q_i (16bit) - phase increment value
  - gain_val_q_i (16bit) - gain value (0 - 1.999..)
  - offset_val_q_i (18bit) - offset value (-2 - 1.999..)

The output is represented by the following registers:
  - sine_out (18bit) - sine value (-2 - 1.999...) calculated from the input parameters. 

Some other inputs are:
  - clk - system clock
  - rst - reset
  - ctrl_en_q_i - enable/disable data generation

The output is a 2f16 signed value with a frequency of 100*MHz*.

## Cocotb Testbench

Cocotb is used for the testbench environment. It allows the user to access all RTL signals, control them and influence their behavior. In this case, the testbench accesses and modifies the phase increment value (`inc_val_q_i`), the gain factor (`gain_val_q_i`) and the offset (`offset_val_q_i`), as well as the system clock, reset and data generation enable. On the other hand, the testbench receives sine values from RTL via the `sine_out` output line. Just as RTL performs the calculation of the sine value using the CORDIC algorithm, the Testbench can import the *sin()* function from the *math* library. With the corresponding calculation, the sine value is output in hexadecimal form. The verification of the values calculated in the testbench and the values from the CORDIC algorithm is explained in detail in the following section.