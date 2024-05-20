#!/usr/bin/env python3
from vunit import VUnit

# create VUnit project
prj = VUnit.from_argv()

# add OSVVM library
prj.add_osvvm()
prj.add_verification_components()

# add custom libraries
prj.add_library("rtu")
prj.add_library("rtu_test")

# add sources and testbenches
prj.library("rtu").add_source_file("../../../../rtu/pkg/functions.vhd")
prj.library("rtu").add_source_file("../../../../rtu/pkg/data_types.vhd")
prj.library("rtu").add_source_file("../src/sync_generator.vhd")
prj.library("rtu").add_source_file("../tb/tb.vhd")
prj.library("rtu_test").add_source_file("../../../../rtu_test/pkg/procedures.vhd")

# run VUnit simulation
prj.main()
