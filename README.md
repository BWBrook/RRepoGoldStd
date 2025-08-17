# RRepoGoldStd

Gold-standard R repo for use with `pak`, `renv`, `targets`, `quarto` and `devtools`. Clone and use as a basis for your data analysis or simulation modelling repo using R.

This repository implements a **gold‑standard** research compendium template for quantitative ecology projects built with R.  It is intended as a starting point: clone or copy this directory, rename it for your project, and then replace the placeholder files and code with your own.  The structure emphasises reproducibility, separation of concerns, and automation.

## Structure overview

```
RRepoGoldStd/
├─ R/                     # Project functions and options
│  ├─ packages.R          # Centralised package installation/loading
│  └─ options.R           # Random seed, RNGkind, global options and logging
├─ _targets.R             # {targets} pipeline definition
├─ profiles/targets/      # Execution profiles for {targets}
│  ├─ local.R
│  └─ ci.R
├─ config/
│  └─ config.yaml         # Project configuration for data paths, profiles, etc.
├─ data/                  # Data hierarchy (raw/external/interim/processed)
│  ├─ raw/                # Immutable raw data (tracked by DVC/git‑annex)
│  ├─ external/           # Reference datasets
│  ├─ interim/            # Parquet/DuckDB caches (ignored by git)
│  └─ processed/          # Output tables/rasters ready for reports
├─ metadata/
│  ├─ data_manifest.csv   # Manifest of raw data files with checksums
│  └─ (additional EML or RO‑Crate files)
├─ reports/
│  └─ paper.qmd           # Quarto manuscript/report stub
├─ tests/testthat/        # Unit tests for functions and pipeline checks
├─ inst/containers/
│  ├─ Dockerfile          # Container specification for reproducible environment
│  └─ apptainer.def       # Apptainer/Singularity spec for HPC environments
├─ .github/workflows/ci.yml   # GitHub Actions continuous integration
├─ .pre-commit-config.yaml    # Pre‑commit hooks (styler, lintr, spell‑check, file size)
├─ .lintr                # Project linter configuration
├─ .gitignore            # Ignore logs, caches, and large intermediates
├─ .gitattributes        # Set LF line endings and diff drivers
├─ DESCRIPTION           # Research compendium metadata
├─ CITATION.cff          # Citation metadata
├─ LICENSE               # MIT license
├─ Makefile              # Conveniences: setup, run, test, lint, render, clean
└─ .env.example          # Example environment variables for secrets
```

### Quick start

After copying or cloning this repository, follow these steps:

```bash
# Initialise git and install hooks
git init
pre-commit install || echo "Pre‑commit not found; skipping hook installation"

# Set up R dependencies and lock them
make setup

# Run a smoke test of the pipeline (uses ci profile)
make smoke

# Run the full pipeline
make run
```

Raw data should live under `data/raw/` and be tracked with a large file management tool such as **git‑annex** or **DVC**; commit only the manifest and checksums.  Intermediates written by the pipeline are stored in `data/interim/` and are ignored by git.

## Windows Usage

You can use this template directly from Windows (PowerShell or cmd) without WSL2. The Makefile is shell‑agnostic and uses `Rscript`, so you can invoke GNU Make from Rtools and point it at your R installation.

- Prereqs: Install R, Rtools (provides `make.exe`), and optionally Git for Windows and Quarto.
- Rscript path: e.g. `C:\\Users\\you\\AppData\\Local\\Programs\\R\\R-4.5.1\\bin\\Rscript.exe`.
- Make path: e.g. `C:\\Rtools45\\usr\\bin\\make.exe`.

Examples from PowerShell (no PATH changes required):

```powershell
# Bootstrap deps (renv + pak), install pre-commit hooks if available
& 'C:\\Rtools45\\usr\\bin\\make.exe' RSCRIPT='C:\\Users\\you\\AppData\\Local\\Programs\\R\\R-4.5.1\\bin\\Rscript.exe' setup

# Run the full pipeline
& 'C:\\Rtools45\\usr\\bin\\make.exe' RSCRIPT='C:\\Users\\you\\AppData\\Local\\Programs\\R\\R-4.5.1\\bin\\Rscript.exe' run

# Smoke test (uses TARGETS_PROFILE=ci)
& 'C:\\Rtools45\\usr\\bin\\make.exe' RSCRIPT='C:\\Users\\you\\AppData\\Local\\Programs\\R\\R-4.5.1\\bin\\Rscript.exe' smoke
```

Optional: add R and Rtools to the PATH for the current shell session, then call `make` without full paths:

```powershell
$env:PATH = 'C:\\Rtools45\\usr\\bin;' + 'C:\\Users\\you\\AppData\\Local\\Programs\\R\\R-4.5.1\\bin;' + $env:PATH
make setup
```

Bypass Make entirely if you prefer:

```powershell
Rscript --vanilla -e "source('scripts/bootstrap.R')"
Rscript --vanilla -e "targets::tar_make()"
Rscript --vanilla -e "Sys.setenv(TARGETS_PROFILE='ci'); targets::tar_make(callr_function=NULL, ask=FALSE)"
```

## WSL2 Option

WSL2 works well if you prefer a Linux toolchain. Install R, Quarto, and GNU Make inside your Linux distro, then use the same Make targets:

```bash
sudo apt update && sudo apt install -y make
# Install R from CRAN or Posit RSPM per your distro, then:
make setup
make run
```
