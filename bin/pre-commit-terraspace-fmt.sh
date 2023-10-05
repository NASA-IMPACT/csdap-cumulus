#!/usr/bin/env bash

# This is intended to be used as a pre-commit hook, and will thus fail if any
# `*.tf` files were reformatted so that pre-commit fails.
! make fmt | grep "\.tf\s*$"
