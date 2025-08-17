## Targets pipeline definition
##
## Entry point for the {targets} workflow. This script loads the package
## (installed or via pkgload), sets pipeline-wide defaults via
## `tar_option_set()`, and enumerates targets in the DAG.

## Load the local package in development, or the installed version otherwise
if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
} else {
  suppressPackageStartupMessages(library(RRepoGoldStd))
}

tar_option_set(
  packages = c(
    "dplyr","readr","purrr","tidyr","sf","terra",
    "arrow","duckdb","config","qs","vroom","lgr","progressr"
  ),
  format = "qs",
  memory = "transient",
  garbage_collection = TRUE,
  error = "stop",
  storage = "worker",
  retrieval = "main",
  cue = tar_cue(mode = "thorough"),
  resources = tryCatch(
    tar_resources(qs = tar_resources_qs(preset = "high")),
    error = function(e) NULL
  )
)

list(
  ## Configuration: read YAML into a list.  Use config::get() to
  ## select profile-specific settings (see config/config.yaml).
  tar_target(cfg, config::get(file = "config/config.yaml")),

  ## Manifest: a CSV enumerating the raw data files.  Each row should
  ## include at least a `path` column pointing to a file under
  ## data/raw/.  Add other columns as needed (id, checksum, etc.).
  tar_target(raw_manifest, "metadata/data_manifest.csv", format = "file"),
  tar_target(raw_files, readr::read_csv(raw_manifest, show_col_types = FALSE)),

  ## Ingest raw CSVs listed in the manifest.  Pattern maps over rows.
  tar_target(raw_tbl, lread(raw_files$path), pattern = map(raw_files), iteration = "list"),

  ## Validate schema early.  Here we check for required columns; replace
  ## with pointblank/validate calls for richer assertions.  Failing
  ## validations should stop the pipeline.
  tar_target(validated, {
    stopifnot(all(c("id","date","value") %in% names(raw_tbl)))
    raw_tbl
  }, pattern = map(raw_tbl), iteration = "list"),

  ## Write each validated table to a Parquet file in data/interim/ and
  ## return the file path.  Downstream tasks can read from these
  ## columnar stores.  Avoid serialising large objects into RDS files.
  tar_target(interim_parquet, {
    dir.create("data/interim", showWarnings = FALSE, recursive = TRUE)
    path <- file.path("data/interim", paste0("data_", tar_group(), ".parquet"))
    arrow::write_parquet(validated, path)
    path
  }, pattern = map(validated), format = "file"),

  ## Placeholder analysis: compute summary statistics or fit models.
  tar_target(model_fit, {
    list(n_rows = sum(vapply(validated, nrow, integer(1))))
  }),

  ## Render the Quarto report after all upstream targets.  The
  ## `tar_quarto()` function caches the output and re-runs only when
  ## inputs change.  Create `reports/paper.qmd` with your analysis.
  tar_quarto(report, path = "reports/paper.qmd")
)
