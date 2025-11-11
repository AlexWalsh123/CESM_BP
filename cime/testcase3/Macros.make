SUPPORTS_CXX := FALSE
ifeq ($(COMPILER),gnu)
  FFLAGS :=   -fconvert=big-endian -ffree-line-length-none -ffixed-line-length-none 
  SUPPORTS_CXX := TRUE
  CFLAGS :=  -std=gnu99 
  CXX_LINKER := FORTRAN
  FC_AUTO_R8 :=  -fdefault-real-8 
  FFLAGS_NOOPT :=  -O0 
  FIXEDFLAGS :=   -ffixed-form 
  FREEFLAGS :=  -ffree-form 
  HAS_F2008_CONTIGUOUS := FALSE
  MPICC :=  mpicc  
  MPICXX :=  mpicxx 
  MPIFC :=  mpif90 
  SCC :=  gcc 
  SCXX :=  g++ 
  SFC :=  gfortran 
endif
ifeq ($(COMPILER),gnu)
  NETCDF_C_PATH := /software/spack/linux-rocky8-broadwell/gcc-12.3.0/netcdf-c-4.9.2-abpn
  NETCDF_FORTRAN_PATH := /software/spack/linux-rocky8-broadwell/gcc-12.3.0/netcdf-fortran-4.6.1-nwqu
  PNETCDF_PATH := /software/spack/linux-rocky8-broadwell/gcc-12.3.0/parallel-netcdf-1.12.3-gcjs
endif
CPPDEFS := $(CPPDEFS)  -DCESMCOUPLED 
ifeq ($(MODEL),pop)
  CPPDEFS := $(CPPDEFS)  -D_USE_FLOW_CONTROL 
endif
ifeq ($(MODEL),ufsatm)
  CPPDEFS := $(CPPDEFS)  -DSPMD 
  FFLAGS := $(FFLAGS)  $(FC_AUTO_R8) 
endif
ifeq ($(MODEL),mom)
  FFLAGS := $(FFLAGS)  $(FC_AUTO_R8) -Duse_LARGEFILE
endif
ifeq ($(COMPILER),gnu)
  FFLAGS := $(FFLAGS)  -std=legacy -fallow-invalid-boz -fallow-argument-mismatch 
  CPPDEFS := $(CPPDEFS)  -DFORTRANUNDERSCORE -DNO_R16 -DCPRGNU
  SLIBS := $(SLIBS)  -L$(NETCDF_C_PATH)/lib64 -L$(NETCDF_FORTRAN_PATH)/lib -lnetcdff -lnetcdf -L$(PNETCDF_PATH)/lib -lpnetcdf -lblas -llapack 
  ifeq ($(compile_threaded),TRUE)
    FFLAGS := $(FFLAGS)  -fopenmp 
    CFLAGS := $(CFLAGS)  -fopenmp 
  endif
  ifeq ($(DEBUG),TRUE)
    FFLAGS := $(FFLAGS)  -g -Wall -Og -fbacktrace -ffpe-trap=zero,overflow -fcheck=bounds 
    FFLAGS := $(FFLAGS)  -std=legacy -fallow-invalid-boz -fallow-argument-mismatch 
    CFLAGS := $(CFLAGS)  -g -Wall -Og -fbacktrace -ffpe-trap=invalid,zero,overflow -fcheck=bounds 
  endif
  ifeq ($(DEBUG),FALSE)
    FFLAGS := $(FFLAGS)  -O 
    FFLAGS := $(FFLAGS)  -std=legacy -fallow-invalid-boz -fallow-argument-mismatch 
    CFLAGS := $(CFLAGS)  -O 
  endif
  ifeq ($(compile_threaded),TRUE)
    LDFLAGS := $(LDFLAGS)  -fopenmp 
  endif
endif
ifeq ($(MODEL),ufsatm)
  INCLDIR := $(INCLDIR)  -I$(EXEROOT)/atm/obj/FMS 
endif
