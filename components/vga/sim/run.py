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
prj.library("cwlib").add_source_file("../src/counter.vhd")
prj.library("cwlib").add_source_file("../tb/tb.vhd")
prj.library("cwlib").add_source_file("../../../pkg/procedures.vhd")

prj.library("cwlib").test_bench("tb").test("two_full_cycles").add_config(
  name="counter_max=15",
  generics=dict(
    COUNTER_MAX_VALUE = 15))

prj.library("cwlib").test_bench("tb").test("two_full_cycles").add_config(
  name="counter_max=16",
  generics=dict(
    COUNTER_MAX_VALUE = 16))

prj.library("cwlib").test_bench("tb").test("two_full_cycles").add_config(
  name="counter_max=800",
  generics=dict(
    COUNTER_MAX_VALUE = 800))

# run VUnit simulation
prj.main()
