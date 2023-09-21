os <- Sys.info()[['sysname']]
if (os == "Darwin"){
  # Ben's MacBook
  Sys.setenv(
    EARTHENGINE_GCLOUD = "/Users/bbest/google-cloud-sdk/bin/gcloud",
    # EARTHENGINE_PYTHON = "/opt/venv/rgee/bin/python",
    EARTHENGINE_ENV    = "rgee")  
} else {
  # otherwise presume on server rstudio.marinebon.app
  Sys.setenv(
    EARTHENGINE_GCLOUD = "/usr/bin/gcloud",
    EARTHENGINE_PYTHON = "/opt/venv/rgee/bin/python",
    EARTHENGINE_ENV    = "rgee")
}

if (!"librarian" %in% installed.packages())
  install.packages("librarian")

# devtools::install_bitbucket("bklamer/rcrypt")  # aquamapsdata dependency
librarian::shelf(
  raquamaps/aquamapsdata, dplyr, ggplot2, glue, here, jsonlite,
  leaflet, leaflet.extras2, listviewer,
  purrr, raster, rgee, reticulate, scales, sf, 
  #shiny, 
  stringr, tibble, tidyr)
select = dplyr::select
source(here("sp-map/functions.R"))

## On MacBook initial ----
# python:         /opt/homebrew/bin/python3
# libpython:      /opt/homebrew/opt/python@3.10/Frameworks/Python.framework/Versions/3.10/lib/python3.10/config-3.10-darwin/libpython3.10.dylib
# pythonhome:     /opt/homebrew/Cellar/python@3.10/3.10.9/Frameworks/Python.framework/Versions/3.10:/opt/homebrew/Cellar/python@3.10/3.10.9/Frameworks/Python.framework/Versions/3.10
# version:        3.10.9 (main, Dec 15 2022, 17:11:09) [Clang 14.0.0 (clang-1400.0.29.202)]
# numpy:          /opt/homebrew/lib/python3.10/site-packages/numpy
# numpy_version:  1.24.1
# ee:             /opt/homebrew/lib/python3.10/site-packages/ee
#
## On MacBook install in Terminal
# brew install pyenv
# pyenv install 3.8.6
# 
# ee_install(
#   py_env = "rgee",
#   earthengine_version = ee_version(),
#   python_version = "3.8.6",
#   confirm = interactive())


# rgee::ee_check()
# ◉  Python version
#   ✔ [Ok] /opt/venv/rgee/bin/python v3.8
# ◉  Python packages:
#   ✔ [Ok] numpy
#   ✔ [Ok] earthengine-api

# aquamaps database ----
am_db <- default_db("sqlite")  # ~/.config/aquamaps/am.db

# list of species
am_spp <- get_am_spp()

