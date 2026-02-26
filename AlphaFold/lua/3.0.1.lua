-- -*- lua -*-
help([==[

Description
===========
AlphaFold can predict protein structures with atomic accuracy even where no similar structure is known


More information
================
 - Homepage: https://github.com/deepmind/alphafold
]==])


whatis([==[Description: AlphaFold can predict protein structures with atomic accuracy even where no similar structure is known]==])
whatis([==[Homepage: https://github.com/deepmind/alphafold]==])
whatis([==[URL: https://github.com/deepmind/alphafold]==])


local version = "3.0.1"
local alphafold_root = "/opt/nesi/containers/AlphaFold"  -- Modify this path to where your container is stored

-- Define the Apptainer binary path
local apptainer = "apptainer"

-- Set environment variables
setenv("ALPHAFOLD_ROOT", alphafold_root)
setenv("ALPHAFOLD_CONTAINER", pathJoin(alphafold_root, "alphafold3-3.0.1.aimg"))

-- Create a shell function for run_alphafold.py that automatically uses apptainer exec
set_shell_function("run_alphafold.py", 
     string.format('%s exec --nv %s python3 /app/alphafold/run_alphafold.py "$@"', 
             apptainer, 
             alphafold_root
     ))

-- Set GPU related variables (assuming you're using CUDA)
pushenv("XLA_FLAGS", "--xla_gpu_enable_triton_gemm=false")
pushenv("XLA_PYTHON_CLIENT_PREALLOCATE", "true")
pushenv("XLA_CLIENT_MEM_FRACTION", "0.95")

-- Conflict with other versions of AlphaFold if they exist
conflict("AlphaFold")
