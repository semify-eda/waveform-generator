# Waveform Generator [![Continuous Integration](https://github.com/semify-eda/waveform-generator/actions/workflows/CI.yml/badge.svg)](https://github.com/semify-eda/waveform-generator/actions/workflows/CI.yml)

This repository implements a generic Waveform Generator in SystemVerilog.

# Introduction

The generic Waveform Generator is split up into three parts:

- Stimuli
- Interconnect
- Driver

Currently the following components are available:

- wfg_core
- wfg_stim_sine
- wfg_drive_spi

# Prerequisites

You will need Python3+ and pip.

For the generation of the templates install `jinja2`:

    pip3 install jinja2

The testbench environment for the unit-tests uses `cocotb`. To install it together with the bus interfaces, run:

    pip3 install cocotb
    pip3 install cocotbext-wishbone
    pip3 install cocotbext-axi
    pip3 install cocotbext-spi

To plot the values during functional verification install `matplotlib`:

	pip3 install matplotlib
	pip3 install scipy
	pip3 install numpy

To have more information on assertion fails you can optionally install `pytest`: 

	pip3 install pytest

# LiteX

To automatically generate documentation about the SoC, install:

	pip3 install sphinx sphinxcontrib-wavedrom

To trace the simulation using `--trace` you need to install:

    pip3 install pyvcd

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
