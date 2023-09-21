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
  raquamaps/aquamapsdata, dplyr, ggplot2, fs, glue, here, jsonlite,
  leaflet, leaflet.extras2, listviewer,
  purrr, raster, rgee, reticulate, scales, sf, 
  #shiny, 
  stringr, terra, tibble, tidyr)
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
am_spp <- get_am_spp() |> 
  arrange(SpeciesID)

# sample for export
spp_ids <- am_spp$SpeciesID[1:10]

# source(here("sp-map/functions.R"))
lst_spp_info <- lapply(spp_ids, get_sp_info)

lst_spp_coarse <- map(lst_spp_info, calc_im_sp_coarse)

im_spp <- ee$ImageCollection(lst_spp_coarse)$toBands()$rename(spp_ids)
# im_spp$bandNames()$getInfo()

prj_im       <- im_spp$projection()
# crs_im       <- im_spp$projection()$crs()$getInfo()           # "EPSG:4326"
# transform_im <- im_spp$projection()$transform()       # "PARAM_MT[\"Affine\", \n  PARAMETER[\"num_row\", 3], \n  PARAMETER[\"num_col\", 3]]"
ply_globe    <- ee$Geometry$BBox(-180,-89.9999,180,89.9999)$transform("EPSG:4326", 0.001)

ic_gebco <- ee$ImageCollection("projects/sat-io/open-datasets/gebco/gebco_sub-ice-topo")
im_am    <- ee$Image("projects/eq-am-fine/assets/sdmpredictors/am-hcaf_v1-simple")

prj_fine   <- ic_gebco$first()$projection()$getInfo()
prj_coarse <- im_am$projection()$getInfo()

# export as GeoTIFF (not cloud-optimized)
task_im_spp <- ee_image_to_gcs(
  image          = im_spp,
  description    = "im-spp10-coarse-not-cog-v03_to_gcs",
  bucket         = "sdm-env_gebco-global",
  fileNamePrefix = "im-spp10-coarse_v03",
  crs            = prj_coarse$crs(),
  scale          = prj_coarse$nominalScale()$getInfo(), # v3: with scale
  # crsTransform   = cat(prj_coarse$transform()$getInfo()),
  # https://github.com/r-spatial/rgee/blob/219d84917300ca378f395d75a4372fbbeefba73b/R/ee_download.R#L335C4-L336
  #  @param crsTransform A comma-separated string of 6 numbers describing
  #    the affine transform of the coordinate reference system of the exported
  # crsTransform  = "3,3,0.5,-180.0,-0.5,90.0",
  # list(PARAM_MT = list(
  #   Affine = list(
  #     PARAMETER = list(
  #       num_row = 3)))), 
  #          PARAMETER["num_col", 3], 
  #          PARAMETER["elt_0_0", 0.5], 
  #          PARAMETER["elt_0_2", -180.0], 
  #          PARAMETER["elt_1_1", -0.5], 
  #          PARAMETER["elt_1_2", 90.0]]
  # crsTransform   = prj_im$transform(), # v01: commented out
  maxPixels      = 1e13,
  region         = ply_globe,
  skipEmptyTiles = TRUE,
  fileFormat     = 'GeoTIFF')  # 25 min for single on EE
task_im_spp$start()
ee_monitoring(task_im_spp)
# ID: TLMWVPWDQAS5N22KXDSSWX7I
# Phase: Completed
# Runtime: 7s (started 2023-09-21 11:16:21 -0700)
# Attempted 1 time
# Batch compute usage: 4.4424 EECU-seconds


lst_spp_info <- lapply(spp_ids, get_sp_info)

lst_spp_f <- map(lst_spp_info, calc_im_sp_fine)

im_spp_f <- ee$ImageCollection(lst_spp_f)$toBands()$rename(spp_ids)
# im_spp$bandNames()$getInfo()

task_im_spp <- ee_image_to_gcs(
  image          = im_spp_f,
  description    = "im-spp10-fine-not-cog-v08_to_gcs", # without region
  bucket         = "sdm-env_gebco-global",
  fileNamePrefix = "im-spp10-fine-not-cog_v08",
  # crs            = prj_im$crs(),
  # crsTransform   = prj_fine$transform()$getInfo(), # v01: commented out
  # "PARAM_MT[\"Affine\", \n  PARAMETER[\"num_row\", 3], \n  PARAMETER[\"num_col\", 3]]"
  crs            = prj_fine$crs,
  crsTransform   = prj_fine$transform,
  # scale          = prj_coarse$nominalScale()$getInfo(), # v3: with scale
  # scale          = 111319.5/240,
  maxPixels      = 1e13,
  region         = ply_globe,
  # skipEmptyTiles = TRUE,
  fileFormat     = 'GeoTIFF')  # 25 min for single on EE
task_im_spp$start()
ee_monitoring(task_im_spp)
# im-spp10-fine-not-cog-v03_to_gcs
#   ERROR in Earth Engine servers: Unable to transform edge (360.000000, 76.000000 to 359.999802, 76.000000) from EPSG:4326 PLANAR [0.5, 0.0, 0.0, 0.0, -0.5, 0.0] to EPSG:4326.


# test gcs tifs locally -----


# gsutil -m cp \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000020736-0000062208.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000000000-0000020736.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000020736-0000020736.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000020736-0000041472.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000020736-0000000000.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000000000-0000041472.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000000000-0000062208.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000000000-0000000000.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000041472-0000041472.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000020736-0000082944.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000000000-0000082944.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000041472-0000000000.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000041472-0000020736.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000041472-0000062208.tif" \
# "gs://sdm-env_gebco-global/im-spp10-fine-not-cog_v07_2023_09_21_20_52_260000041472-0000082944.tif" \
# .

librarian::shelf(
  # gdalcubes,
  mapview, stars, terra)

dir_tif <- "/Users/bbest/Desktop/am-fine_im-dl"
tifs <- list.files(dir_tif, pattern=".tif$", full.names = TRUE)
mos <- st_mosaic(
  tifs,
  options = c("-vrtnodata", "0"))
mos
str <- read_stars(
  mos)
  # proxy = T,
  # RasterIO = list(
  #   # nXSize = 240, nYSize = 240,
  #   bands = c(1)))
d <- str[,,,1] |> # select bands
  st_downsample(200)
d_t <- rast(d) |> 
  terra::trim()
plot(d)
plet(d_t, tile='Streets')
mapView(stars::st_as_stars(d_t))


