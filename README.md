# Waveform Generator

This repository implements a generic Waveform Generator in SystemVerilog.

# Introduction

The generic Waveform Generator is split up into three parts:

- Stimuli
- Interconnect
- Driver

Currently the following components are available:

- wfg_stim_sine

# Simulation

To run the individual unit tests, issue:

`make unit-test`

# Generate Templates

To generate the registers for the wishbone bus, issue:

`make templates`

## License

Copyright [semify](https://www.semify-eda.com/).

Unless otherwise specified, source code in this repository is licensed under the Apache License Version 2.0 (Apache-2.0). A copy is included in the LICENSE file.

Other licenses may be specified as well for certain files for purposes of illustration or where third-party components are used.