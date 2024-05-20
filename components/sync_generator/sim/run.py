#!/usr/bin/env python3
from vunit import VUnit

# create VUnit project
prj = VUnit.from_argv()

# add OSVVM library
prj.add_osvvm()
prj.add_verification_components()

# add custom libraries
prj.add_library("cwlib")

# add sources and testbenches
prj.library("cwlib").add_source_file("../../../pkg/functions.vhd")
prj.library("cwlib").add_source_file("../../../pkg/data_types.vhd")
prj.library("cwlib").add_source_file("../src/sync_generator.vhd")
prj.library("cwlib").add_source_file("../tb/tb.vhd")
prj.library("cwlib").add_source_file("../../../pkg/procedures.vhd")

# run VUnit simulation
prj.main()
