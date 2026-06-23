-- -*- lua -*-
-- ============================================================================
-- Lmod modulefile: GROMACS + CP2K QM/MM Apptainer image
-- (GROMACS 2025.2 double+MPI+CP2K; CP2K 2025.2; OpenMPI 5.0.10 + UCX)
-- ============================================================================

-- Image path (.sif file)
local sif    = "/opt/nesi/containers/GROMACS_CP2K/GROMACS_2025.2_CP2K_2025.2.sif"

-- Directory holding the gmx / gmx_mpi / cp2k.psmp wrapper scripts.
local bindir = "/opt/nesi/containers/GROMACS_CP2K/bin"

-- Host OpenMPI matching the image's OpenMPI; loaded automatically (depends_on).
local host_ompi = "OpenMPI/5.0.10-GCC-15.2.0"

whatis("Name: GROMACS_CP2K")
whatis("Version: 2025.2")
whatis("Description: GROMACS 2025.2 (double, MPI) with CP2K 2025.2 QM/MM, in an Apptainer image (OpenMPI 5.0.10 + UCX/InfiniBand)")
whatis("Provides: gmx, gmx_mpi, cp2k.psmp")

help([[
GROMACS 2025.2 (double precision, MPI) with the CP2K 2025.2 QM/MM interface, in
an Apptainer image. MPI inside the image is OpenMPI 5.0.10 + UCX.

After `module load GROMACS_CP2K/2025.2`, use these commands directly. They are
wrapper scripts that transparently run inside the container, so they behave like
normal programs -- interactively AND under srun / mpirun:
  gmx, gmx_mpi   GROMACS (gmx, gmx_mpi, gmx_mpi_d are all the same
                 double-precision MPI CP2K binary)
  cp2k.psmp      standalone CP2K

----------------------------------------------------------------------------
MULTI-NODE:
  srun --mpi=pmix gmx_mpi mdrun -deffnm qmmm -ntomp $SLURM_CPUS_PER_TASK
  # or with host mpirun:
  mpirun -np $SLURM_NTASKS gmx_mpi mdrun -deffnm qmmm -ntomp $SLURM_CPUS_PER_TASK

SINGLE NODE:
  srun --mpi=pmix -N1 gmx mdrun -deffnm qmmm -ntomp $SLURM_CPUS_PER_TASK
  # or a single rank with OpenMP threads (no launcher):
  gmx mdrun -deffnm qmmm -ntomp $SLURM_CPUS_PER_TASK

SETUP / TOOLS:
  gmx grompp -f qmmm.mdp -c conf.gro -p topol.top -o qmmm.tpr

STANDALONE CP2K:
  cp2k.psmp -i in.inp -o out.out

NOTES
  * `--mpi=pmix` is recommended; the image's OpenMPI 5.0.10 uses PMIx. If your
    site's default Slurm MPI is already pmix, plain `srun gmx_mpi ...` works too
    (check `srun --mpi=list`).
  * Single- vs multi-node is decided by how you launch, not by the name.
  * The wrappers auto-bind $TMPDIR and never use --cleanenv, so PMIx wire-up is
    preserved.
----------------------------------------------------------------------------
]])

-- Refuse to load alongside a stock GROMACS or CP2K module (aborts with a message
-- telling the user to unload it first).
conflict("GROMACS")
conflict("CP2K")

-- Matching host OpenMPI (auto-loaded; needed for the host-mpirun path, harmless
-- for srun).
depends_on(host_ompi)

-- Warn (don't hard-fail) if the image is missing, so `module show` still works.
if mode() == "load" and not (isFile(sif) or isDir(sif)) then
    LmodWarning("GROMACS_CP2K: image not found at '" .. sif .. "'.")
end

setenv("GROMACS_CP2K_SIF", sif)
prepend_path("PATH", bindir)
