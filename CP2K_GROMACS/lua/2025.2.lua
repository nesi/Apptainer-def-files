-- -*- lua -*-
-- ===========================================================================
-- Lmod modulefile for the GROMACS + CP2K QM/MM Apptainer image
-- (GROMACS 2025.2, double precision + MPI; CP2K 2025.2; OpenMPI 5.0.10 + UCX)
-- ---------------------------------------------------------------------------
-- INSTALL: place on MODULEPATH as <modulepath>/gromacs-cp2k/2025.2.lua
--          then:  module load gromacs-cp2k/2025.2
-- ===========================================================================

-- Absolute path to the image (.sif file or Apptainer sandbox directory)
local sif = "/opt/nesi/containers/CP2K_GROMACS/gromacs-cp2k.sif"

-- Host OpenMPI that must match the OpenMPI built into the image. This module
-- declares a hard dependency on it (see depends_on below), so it is loaded
-- automatically whenever this module is loaded.
local host_ompi = "OpenMPI/5.0.10-GCC-15.2.0"

------------------------------------------------------------------------------
whatis("Name: gromacs-cp2k")
whatis("Version: 2025.2")
whatis("Description: GROMACS 2025.2 (double, MPI) with CP2K 2025.2 QM/MM, in an Apptainer image (OpenMPI 5.0.10 + UCX/InfiniBand)")
whatis("Provides: gmx_mpi_d, cp2k.psmp (run via apptainer exec)")

help([[
GROMACS 2025.2 (double precision, MPI) with the CP2K 2025.2 QM/MM interface.

This module sets:
  GROMACS_CP2K_SIF   path to the image (.sif or sandbox dir)
and defines convenience shell functions that call `apptainer exec`:
  gmx_mpi_d          the GROMACS launcher (m = MPI, d = double precision)
  cp2k.psmp          standalone CP2K
  cp2k               alias for cp2k.psmp

It also loads the matching host OpenMPI ()] .. "" .. [[]] .. host_ompi .. [[)
as a dependency, needed for multi-node launches.

----------------------------------------------------------------------------
INTERACTIVE / SERIAL (single rank) -- handy for setup tools
  gmx_mpi_d grompp -f qmmm.mdp -c conf.gro -p topol.top -o qmmm.tpr
  cp2k.psmp -i input.inp -o output.out

SINGLE NODE, MULTIPLE RANKS -- use the image's own mpirun:
  apptainer exec $GROMACS_CP2K_SIF \
      mpirun -np 4 gmx_mpi_d mdrun -deffnm qmmm

MULTI NODE (Slurm) -- the HOST mpirun launches one container per rank.
The matching host OpenMPI is loaded automatically as a dependency, so:
  module load gromacs-cp2k/2025.2

  mpirun -np $SLURM_NTASKS \
      apptainer exec $GROMACS_CP2K_SIF \
      gmx_mpi_d mdrun -deffnm qmmm -ntomp $SLURM_CPUS_PER_TASK

  The host PRRTE starts the ranks; each container's OpenMPI 5.0.x connects
  back over PMIx and then talks rank-to-rank over InfiniBand via UCX.

MULTI-NODE CAVEATS
  * Do NOT add --cleanenv to apptainer: PMIx/PRRTE wire-up needs the inherited
    PMIX_*/OMPI_* environment variables to be visible inside the container.
  * /dev is bind-mounted by default, so the container reaches the HCA. If your
    site uses a node-local $TMPDIR (not /tmp), add:  --bind "$TMPDIR"
----------------------------------------------------------------------------
]])

------------------------------------------------------------------------------
-- Hard dependency on the matching host OpenMPI (auto-loaded on load,
-- released on unload).
------------------------------------------------------------------------------
depends_on(host_ompi)

------------------------------------------------------------------------------
-- Make sure the image exists; warn (don't hard-fail) so `module show` works.
------------------------------------------------------------------------------
if mode() == "load" and not (isFile(sif) or isDir(sif)) then
    LmodWarning("gromacs-cp2k: image not found at '" .. sif ..
                "'. Edit `sif` in the modulefile to point at your .sif or sandbox.")
end

setenv("GROMACS_CP2K_SIF", sif)

------------------------------------------------------------------------------
-- Wrapper shell functions: <name> ...args...  ->  apptainer exec $SIF <name> ...args...
-- (bash/zsh body first, csh alias body second)
------------------------------------------------------------------------------
set_shell_function("gmx_mpi_d",
    'apptainer exec "$GROMACS_CP2K_SIF" gmx_mpi_d "$@"',
    'apptainer exec "$GROMACS_CP2K_SIF" gmx_mpi_d \\!*')

set_shell_function("cp2k.psmp",
    'apptainer exec "$GROMACS_CP2K_SIF" cp2k.psmp "$@"',
    'apptainer exec "$GROMACS_CP2K_SIF" cp2k.psmp \\!*')

set_shell_function("cp2k",
    'apptainer exec "$GROMACS_CP2K_SIF" cp2k.psmp "$@"',
    'apptainer exec "$GROMACS_CP2K_SIF" cp2k.psmp \\!*')
