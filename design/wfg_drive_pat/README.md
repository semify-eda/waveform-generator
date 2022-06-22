# wfg_drive_pat

The module wfg_drive_pat drives a pattern onto the number of channels specified by the parameter CHANNELS. CHANNELS can range from 1 to 32.

For correct operation it needs to be connected to a wfg_core.
The signals used are *pat_sync* and *pat_subcycle_cnt*.

The input is received via an axi stream (32 bit) interface. One transaction is performed after each *pat_sync*. The lowest CHANNELS bits are used for transmission, higher bits are discarded.

The fields *begin* and *end* must be set for the channel to work correctly;
begin can be set to a value of `1` to `subcycles - 1`, while end must be set from `begin+1` to `subcycles`, where `subcycles` is to the number of subcycles at which the core puts out *pat_sync* and in the next cycle resets the count to 0.

Patselect can take values 0-3.
  - 0 corresponds to *Return to zero (RZ)*
  - 1 corresponds to *Return to one (RO)*
  - 2 corresponds to *Non return to one (NRZ)*
  - 3 corresponds to *Return to complement (RC)*

## Testbench

*WIP*

The module wfg_drive_pat is verified using a testbench written in cocotb and python.

It uses and extends standard components of cocotb.


### Testcase generation

Testcases are generated with a `TestFactory`.
It takes a list of values for each input port and creates a testcase for each of the combinations.
These values can be fixed to test certain cases, or be set to `None`, in this case they will either be randomized or use a default value.

Input data for the AXI stream is randomly generated for each testcase run.


### Output checking

A `OutputMonitor` captures all output values at each clockcycle.
A `Scoreboard` checks the equivalence of the received values to previously generated expected output.

Expected output is generated at the time the input is randomized. For each clockcycle it is calculated what the corresponding output should be based on the input and the *pat_subcycle_cnt*.



