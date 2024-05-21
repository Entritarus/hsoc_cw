#!/usr/bin/env python3
from vunit import VUnit

# create VUnit project
prj = VUnit.from_argv()

# add OSVVM library
prj.add_osvvm()
prj.add_vhdl_builtins()
prj.add_com()
prj.add_verification_components()
prj.add_random()

# add custom libraries
prj.add_library("cwlib")

# add sources and testbenches
prj.library("cwlib").add_source_file("../../../pkg/functions.vhd")
prj.library("cwlib").add_source_file("../../../pkg/data_types.vhd")
prj.library("cwlib").add_source_file("../../counter/src/counter.vhd")
prj.library("cwlib").add_source_file("../../sync_generator/src/sync_generator.vhd")
prj.library("cwlib").add_source_file("../src/vga.vhd")
prj.library("cwlib").add_source_file("../tb/tb.vhd")

# run VUnit simulation
prj.main()
