-- -*- lua -*-
-- ============================================================================
-- Lmod modulefile: GROMACS + CP2K QM/MM Apptainer image
-- (GROMACS 2025.2 double+MPI+CP2K; CP2K 2025.2; OpenMPI 5.0.10 + UCX)
-- INSTALL: place on MODULEPATH as <modulepath>/GROMACS_CP2K/2025.2.lua
--          then:  module load GROMACS_CP2K/2025.2
-- ============================================================================

-- Image path (.sif file or Apptainer sandbox directory)
local sif = "/opt/nesi/containers/CP2K_GROMACS/gromacs-cp2k.sif"

-- Host OpenMPI matching the image's OpenMPI; loaded automatically (depends_on).
local host_ompi = "OpenMPI/5.0.10-GCC-15.2.0"

whatis("Name: GROMACS_CP2K")
whatis("Version: 2025.2")
whatis("Description: GROMACS 2025.2 (double, MPI) with CP2K 2025.2 QM/MM, in an Apptainer image (OpenMPI 5.0.10 + UCX/InfiniBand)")
whatis("Provides: gmx, gmx_mpi, cp2k.psmp (run via apptainer exec)")

help([[
GROMACS 2025.2 (double precision, MPI) with the CP2K 2025.2 QM/MM interface, in
an Apptainer image. MPI inside the image is OpenMPI 5.0.10 + UCX.

Loading this module:
  * sets GROMACS_CP2K_SIF to the image path,
  * loads the matching host OpenMPI (]] .. host_ompi .. [[) as a dependency,
  * refuses to load if a GROMACS or CP2K module is already loaded (conflict).

Convenience shell functions (run the in-image binaries via apptainer exec):
  gmx, gmx_mpi   the GROMACS launcher -- gmx, gmx_mpi and gmx_mpi_d are all the
                 SAME double-precision MPI CP2K binary
  cp2k.psmp      standalone CP2K
  cp2k           alias for cp2k.psmp
These wrappers are for interactive/serial use. For parallel runs, call apptainer
directly under srun/mpirun (examples below). Single- vs multi-node is decided by
the launcher, not by which name you use.

----------------------------------------------------------------------------
MULTI-NODE -- two options:
  (a) srun + PMIx (Slurm-native; does not need the host OpenMPI module, though
      this module loads it anyway for option (b)):
        srun --mpi=pmix apptainer exec $GROMACS_CP2K_SIF \
            gmx_mpi mdrun -deffnm qmmm -ntomp $SLURM_CPUS_PER_TASK
  (b) host mpirun:
        mpirun -np $SLURM_NTASKS apptainer exec $GROMACS_CP2K_SIF \
            gmx_mpi mdrun -deffnm qmmm -ntomp $SLURM_CPUS_PER_TASK

SINGLE NODE -- gmx (same binary), one node:
        srun --mpi=pmix -N1 apptainer exec $GROMACS_CP2K_SIF \
            gmx mdrun -deffnm qmmm -ntomp $SLURM_CPUS_PER_TASK
  or a single MPI rank with OpenMP threads (no launcher):
        apptainer exec $GROMACS_CP2K_SIF gmx mdrun -deffnm qmmm -ntomp $SLURM_CPUS_PER_TASK

SETUP / TOOLS:
        apptainer exec $GROMACS_CP2K_SIF gmx grompp -f qmmm.mdp -c conf.gro -p topol.top -o qmmm.tpr
Standalone CP2K:
        apptainer exec $GROMACS_CP2K_SIF cp2k.psmp -i in.inp -o out.out

NOTES
  * Do NOT add --cleanenv (PMIx/PRRTE wire-up needs inherited env vars).
  * If your site uses a node-local $TMPDIR (not /tmp), add:  --bind "$TMPDIR"
----------------------------------------------------------------------------
]])

-- Refuse to load alongside a stock GROMACS or CP2K module (abort with a message;
-- the user unloads them first). Add other names here if casing differs.
conflict("GROMACS")
conflict("CP2K")

-- Hard dependency on the matching host OpenMPI (auto-loaded on load, released on
-- unload). Needed for the host-mpirun launch path; harmless for srun.
depends_on(host_ompi)

-- Warn (don't hard-fail) if the image is missing, so `module show` still works.
if mode() == "load" and not (isFile(sif) or isDir(sif)) then
    LmodWarning("GROMACS_CP2K: image not found at '" .. sif ..
                "'. Edit `sif` in the modulefile to point at your .sif or sandbox.")
end

setenv("GROMACS_CP2K_SIF", sif)

-- Wrapper shell functions (bash/zsh body, then csh alias body).
set_shell_function("gmx",
    'apptainer exec "$GROMACS_CP2K_SIF" gmx "$@"',
    'apptainer exec "$GROMACS_CP2K_SIF" gmx \\!*')

set_shell_function("gmx_mpi",
    'apptainer exec "$GROMACS_CP2K_SIF" gmx_mpi "$@"',
    'apptainer exec "$GROMACS_CP2K_SIF" gmx_mpi \\!*')

set_shell_function("cp2k.psmp",
    'apptainer exec "$GROMACS_CP2K_SIF" cp2k.psmp "$@"',
    'apptainer exec "$GROMACS_CP2K_SIF" cp2k.psmp \\!*')

set_shell_function("cp2k",
    'apptainer exec "$GROMACS_CP2K_SIF" cp2k.psmp "$@"',
    'apptainer exec "$GROMACS_CP2K_SIF" cp2k.psmp \\!*')
