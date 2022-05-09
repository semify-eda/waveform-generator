# Waveform Generator

This repository implements a generic Waveform Generator in SystemVerilog.

# Introduction

The generic Waveform Generator is split up into three parts:

- Stimuli
- Interconnect
- Driver

Currently the following components are available:

- wfg_stim_sine

# Prerequisites

You will need Python3+ and pip.

For the generation of the templates install `jinja2`:

    pip3 install jinja2

The testbench environment for the unit-tests uses `cocotb`. To install it together with the wishbone bus interface, run:

    pip3 install cocotb
    pip3 install cocotbext-wishbone

# Simulation

To run the individual unit tests, issue:

	make unit-test

# Template Generation

To generate the registers for the wishbone bus, issue:

	make templates

# Code Formatting

To ensure consistent formatting, [verible](https://github.com/chipsalliance/verible) is used as a SystemVerilog formatter tool.

	make format

This will format the code according to some custom flags.

# Invoke Linter

To invoke the [verible](https://github.com/chipsalliance/verible) linter, run:

	make lint

## License

Copyright [semify](https://www.semify-eda.com/).

Unless otherwise specified, source code in this repository is licensed under the Apache License Version 2.0 (Apache-2.0). A copy is included in the LICENSE file.

Other licenses may be specified as well for certain files for purposes of illustration or where third-party components are used.
