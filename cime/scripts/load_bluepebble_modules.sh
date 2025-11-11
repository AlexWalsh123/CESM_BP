#!/bin/bash
# Load required modules for CESM on Blue Pebble
# Source this file before running create_test or case.setup

module purge
module load subversion/1.14.2-zx34
module load languages/python/3.8.20
module load languages/gcc/13.1.0
module load cmake/3.27.9-s6cv
module load openmpi/5.0.3-et6p
module load netcdf-c/4.9.2-abpn
module load netcdf-fortran/4.6.1-nwqu
module load parallel-netcdf/1.12.3-gcjs
module load esmf/8.6.1-5oo4
module load languages/perl/5.38.2

# Set PYTHONPATH for CIME
export CIMEROOT=/user/home/xz20153/my_cesm_sandbox/cime
export PYTHONPATH=${CIMEROOT}/scripts/Tools:${CIMEROOT}/scripts/lib:${PYTHONPATH}

echo "Loaded required modules for CESM on Blue Pebble"
module list
