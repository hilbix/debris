#!/bin/bash

. ./lib.sh

# calculate the partitions PART#SECT and partition disk
# Extended partitions (>4) not yet supported
# First partition (1) is 64 sectors shorter, due to alignment issues
partsteps
