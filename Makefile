.PHONY: setup bootstrap run smoke test lint render clean document check snapshot pkgdown

# Allow overriding the Rscript path, e.g. on Windows:
#   make RSCRIPT="C:/Users/you/AppData/Local/Programs/R/R-4.5.1/bin/Rscript.exe" setup
RSCRIPT ?= Rscript

## Initialise the project: install packages via renv, set up pre-commit
setup: bootstrap
	$(RSCRIPT) --vanilla -e "pc <- Sys.which('pre-commit'); if (nzchar(pc)) { message('[setup] Installing pre-commit hooks...'); system2(pc, 'install') } else { message('[setup] pre-commit not found; skipping hook installation. Install via pipx/pip/conda to enable hooks.') }"

bootstrap:
	$(RSCRIPT) --vanilla -e "source('scripts/bootstrap.R')"

## Run the full pipeline
run:
	$(RSCRIPT) --vanilla -e "targets::tar_make()"

## Run a smoke test pipeline (uses CI profile)
smoke:
	$(RSCRIPT) --vanilla -e "Sys.setenv(TARGETS_PROFILE='ci'); targets::tar_make(callr_function = NULL, ask = FALSE)"

## Run unit tests
test:
	$(RSCRIPT) --vanilla -e "testthat::test_dir('tests/testthat', reporter='summary')"

## Run linters
lint:
	$(RSCRIPT) --vanilla -e "lintr::lint_package(error_on_lint = TRUE)"

## Render the Quarto report
render:
	$(RSCRIPT) --vanilla -e "quarto::quarto_render('reports/paper.qmd')"

## Clean generated data and pipeline artifacts
clean:
	$(RSCRIPT) --vanilla -e "targets::tar_destroy(confirm = FALSE); unlink(c('data/interim','data/processed','logs'), recursive = TRUE, force = TRUE)"

## Generate NAMESPACE and Rd docs via roxygen2
document:
	$(RSCRIPT) --vanilla -e "devtools::document(quiet = TRUE)"

## Run R CMD check with rcmdcheck
check:
	$(RSCRIPT) --vanilla -e "rcmdcheck::rcmdcheck(args = c('--no-manual','--as-cran'), error_on = 'warning')"

## Update renv.lock to current library state
snapshot:
	$(RSCRIPT) --vanilla -e "renv::snapshot(prompt = FALSE)"

## Build pkgdown site (optional)
pkgdown:
	$(RSCRIPT) --vanilla -e "pkgdown::build_site()"
