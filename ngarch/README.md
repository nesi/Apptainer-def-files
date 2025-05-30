# NGARCH container for NVIDIA compilers

## Overview

This repo contains a definition file that allows one to build an Apptainer container. Included in the container are compilers, 
libraries and tools required to build LFRic.

## Requirements

You must have Apptainer (previously known as Singularity) installed. 

## How to build the container

Under Linux
```
apptainer build --build-arg NVHPC_VERSION="25.3" "NVIDIA_VERSION=12.6" ngarch_nvhpc.sif ngarch_nvhpc.def
```
Note: depending on your installed version of apptainer  you may need to tun the above command under `sudo`.

## Initial setup

Create a virtual environment, activate it and install Python packages
```
python3 -m venv venv
source venv/bin/activate
pip3 install Psyclone jinja2 cylc-flow cylc-uiserver cylc-rose metomi-rose
svn co https://code.metoffice.gov.uk/svn/lfric/GPL-utilities/trunk rose-picker
cd rose-picker
pip3 install -e .
cd ..
```


## How to build NGARCH

```
git clone https://github.com/pletzer/ngarch_apptainer
cd ngarch_apptainer
```

Build the container if not already done.

Start the container. On w-clim01,
```
module load Singularity CUDA
singularity shell --nv -B/opt/niwa/um_sys/,$PWD,/opt/nesi,/nesi/project/uoo03538/um/ ngarch_nvhpc.sif
```

Load the environment
```
Apptainer> source sourceme.sh
```

Cache your MOSRS password
```
Apptainer> source /usr/local/bin/mosrs-setup-gpg-agent
```

Check out `lfric` and `lfric_apps` (you must have access to MetOffice code). For instance,
```
Apptainer> cd $CODE_DIR
Apptainer> fcm co fcm:lfric_apps.x_br/dev/jorgebornemann/vn2.0.1_311_pc2_checks lfric_apps
```

Build `ngarch`
```
Apptainer> cd lfric_apps/build
Apptainer> python local_build.py -a ngarch -j 20 -v -p minimum
```

To run the NGARCH app
```
Apptainer> cd example
Apptainer> ../bin/ngarch configuration.nml
```


