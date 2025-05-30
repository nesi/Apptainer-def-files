# Coupled Model Under Apptainer
Collection of definition files for creating containerized coupled models

## Overview

The containerization of an executable, be it a coupled model or the WRF code, allows you to freely move the executable to other platforms, which may run different operating systems. In effect the containerization protects you from variations in operating systems, including future updates. 

The executable is encoded in a "container image", a file that contains the executable with its dependencies (compilers, tools, libraries and operating system). In the case of "Apptainer", this is a "sif" file, for instance "esmfenv86.sif". 

## Setup on NeSI's mahuika platform

To access the "apptainer" command, type
```
ml Apptainer/1.2.2
```

Note: some operations like `apptainer pull` will cache files, by default in your home directory. In order to avoid hitting your `$HOME` disk storage quota on NeSI platform, we recommend to
```
export APPTAINER_CACHEDIR=/nesi/nobackup/YOUR_PROJECT/tmp
```

## Building an executable using a containerized environment

These instructions assume you have cloned this repository
```
git clone git@github.com:pletzer/coupled_model_apptainer.git
```
or, alternatively,
```
git clone https://github.com/pletzer/coupled_model_apptainer.git
```
and have navigated into the `coupled_model_apptainer` directory:
```
cd coupled_model_apptainer
```

You will need to fetch a container with pre-installed compilers (Intel and MPI) and libraries (HDF5, NetCDF and 
ESMF). Different versions of ESMF can be downloaded, e.g. ESMF 8.6

```
apptainer pull esmfenv86.sif oras://ghcr.io/pletzer/coupled_model_apptainer_esmfenv86:latest
```
This could take some time as the image's size is about 5GB. 

Occasionally, you may get an error such as
```
FATAL:   While pulling image from oci registry: error fetching image to cache: unable to Download Image: unable to pull from registry: failed to copy: ...
```
Try again and it should work.

Once the image is downloaded start the container
```
apptainer shell esmfenv86.sif
```
You will now be in the container's shell -- the look and feel will be that of a simple Linux system with basic tools and 
the `vim` editor installed. 

Note: you cannot change the environment, i.e. *you cannot install anything* in the container once it has been built (although there may be ways around this). 

Some directories (`/nesi/project` etc, see below) are automatically mounted by the apptainer shell -- you can build code in these mounted directories. Naturally, any executable built by the container can only be run within the container, see section below.

You can check your environment, e.g.
```
Apptainer> mpiifort --version
ifort (IFORT) 2021.8.0 20221119
Copyright (C) 1985-2022 Intel Corporation.  All rights reserved.
```
NetCDF and other libraries are installed under `/software/lib` and the include  and Fortran module files are under `/software/include`. The ESMF libraries are installed under
```
Apptainer> ls /software/lib/libO/Linux.intel.64.intelmpi.default/
esmf.mk    libesmf.so		    libesmftrace_static.a  preload.sh
libesmf.a  libesmftrace_preload.so  libpioc.a
```
File `/software/lib/libO/Linux.intel.64.intelmpi.default/esmf.mk` will reveal ESMF version and the compiler settings used to build the library.

## Mounted directories

You will likely need to access data stored on NeSI's file system. As built, the image will mount:

 * /nesi/nobackup
 * /nesi/project
 * /home

## How to mount another directory

You can bind additional directories with
```
apptainer shell --bind DIR1,DIR2,... esmfenv86.sif
```
where DIR1, DIR2, ... is a list of comma separated directory names.

## Building the coupled model

To build the coupled atmosphere-ocean code, type 
```
Apptainer> git clone git@github.com:alenamalyarenko/pskrips
Apptainer> cd pskrips
Apptainer> git fetch --all
Apptainer> git checkout app_avx3
Apptainer> bash install_model_for_alex_pletzer.sh
```
in any of the mounted directories. The build process could take several hours. Note: you can build the coupled model in any directory. 

Branch "app_avx3" uses aggressive compiler optimization flags ("-O3" with AVX2 vectorization). 
Other branches ("app_avx2" and "app_avx") use lower optimization levels, which will make the code compile faster but run slower.
Aggressive compiler optimization flags can affect the accuracy of the simulation - reduce the optimization level if the code is known to run successively on one platform but not under Apptainer. (No such case has been encountered; however, more testing might be required.)

Compiler flags are set in 
```
./models/PWRF/configure.wrf
```
for WRF, in 
```
./models/PSKRIPS/PSKRIPSv2/utils/linux_amd64_ifort_coupled
```
for mitGCM and in
```
./models/PSKRIPS/PSKRIPSv2/coupledCode/Makefile
```
for the coupler.

The coupled model application is called `esmf_application`:
```
Apptainer> find . -name esmf_application
models/PSKRIPS/PSKRIPSv2/coupledCode/esmf_application
```
Exit the container shell with
```
Apptainer> exit
```

## Running the coupled model

There are two ways to run the coupled model

### Using the host MPI

The MPI calls of the `esmf_application` can be delegated from inside the container to the host. This is required when running on multiple nodes and in order to achieve the best performance, 
since the MPI version inside the container does not know about the hardware on the host.

Below is an example of a SLURM script that runs `esmf_application` from within the container. 
```bash
#!/bin/bash -e
#SBATCH --job-name=runCase14       # job name (shows up in the queue)
#SBATCH --time=01:00:00       # Walltime (HH:MM:SS)
#SBATCH --hint=nomultithread
#SBATCH --mem-per-cpu=2g             # memory (in MB)
#SBATCH --ntasks=112         # number of tasks (e.g. MPI)
#SBATCH --cpus-per-task=1     # number of cores per task (e.g. OpenMP)
#SBATCH --output=%x-%j.out    # %x and %j are replaced by job name and ID
#SBATCH --error=%x-%j.err
#SBATCH --partition=milan

ml purge
ml Apptainer

module load intel        # load the Intel MPI
export I_MPI_FABRICS=ofi # turn off shm to allow the code to run on multiple nodes


SIF_FILE="/nesi/nobackup/pletzera/tmp/coupled_model_apptainer/esmfenv86.sif"
ESMF_APP="/nesi/nobackup/pletzera/tmp/coupled_model_apptainer/pskrips/models/PSKRIPS/PSKRIPSv2/coupledCode/esmf_application"

rm -f PET*LogFile
srun apptainer exec -B /opt/slurm/lib64/ $SIF_FILE $ESMF_APP
```
In addition, you may want to specify the number of nodes. For instance, either use
```
#SBATCH --nodes=1-3
```
or 
```
sbatch --nodes=1-3 SLURM_SCRIPT
```
to request up to 3 nodes. 

Unlike on maui, the Broadwell and Milan nodes are shared by default with other users on mahuika. 

Note that we mount `/opt/slurm/lib64/` on Mahuika. This directory contains the `libpmi2.so` library, which provides an abstraction layer to the system management stack.
Slurm comes with its own `libpmi2.so` library, which can conflict with the one installed on the system. It is recommended to `export I_MPI_PMI_LIBRARY=/path/to/slurm/lib/libpmi2.so` to prevent 
this.

### Using the Apptainer MPI

It is also possible to use the MPI library bundled with the container. This approach may be simpler in cases the attempts to use the host MPI fail. It has the drawback to limit the execution to a single node.

```bash
#!/bin/bash -e
#SBATCH --job-name=runCase14       # job name (shows up in the queue)
#SBATCH --time=01:00:00       # Walltime (HH:MM:SS)
#SBATCH --hint=nomultithread
#SBATCH --mem-per-cpu=2g             # memory (in MB)
#SBATCH --ntasks=80         # number of tasks (e.g. MPI)
#SBATCH --cpus-per-task=1     # number of cores per task (e.g. OpenMP)
#SBATCH --output=%x-%j.out    # %x and %j are replaced by job name and ID
#SBATCH --error=%x-%j.err
#SBATCH --partition=milan
#SBATCH --nodes=1-1

ml purge
ml Apptainer

SIF_FILE="/nesi/nobackup/pletzera/tmp/coupled_model_apptainer/esmfenv86.sif"
ESMF_APP="/nesi/nobackup/pletzera/tmp/coupled_model_apptainer/pskrips/models/PSKRIPS/PSKRIPSv2/coupledCode/esmf_application"

rm -f PET*LogFile
apptainer exec $SIF_FILE mpiexec -n 80 $ESMF_APP
```
In the above Slurm script, we request `--ntasks=80` processors and invoke the `mpiexec -n 80 $ESMF_APP` command inside the container, making sure that the number (80) passed to the `mpiexec` command matches the number of tasks.

*Note `--nodes=1-1`, which sets the number of nodes to one.

## Performance of the containerized coupled model

Below are some performance results for the concurrent coupling case using 48 processors for the ocean component. Column 
"sim/wallclock time" is the ratio between simulation time over execution time, the higher the better. The atmosphere component
runs about 1-1.4x slower than the ocean for the same number of MPI tasks each (48) under apptainer on mahuika milan partition.

| platform      | nodes | MPI tasks | physical cores | sim/wallclock time |
|---------------|-------|-----------|----------------|--------------------|
| maui (native) | 6     | 480       | 240            | 51x                |
| maui (native) | 1     | 80        | 40             | 30x                |
| milan (apptainer) | 1 | 80        | 80             | 53x                |
| milan (apptainer) | 2 | 112       | 112            | 41-49x             |
| milan (apptainer) --hint=multithread | 1 | 112 | 56 | 35.5x |

Note: timings will vary according to the load on the computer. 
