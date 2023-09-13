Sys.setenv(
  EARTHENGINE_GCLOUD = "/usr/bin/gcloud",
  EARTHENGINE_PYTHON = "/opt/venv/rgee/bin/python",
  EARTHENGINE_ENV    = "rgee")

if (!"librarian" %in% installed.packages())
  install.packages("librarian")

# devtools::install_bitbucket("bklamer/rcrypt")  # aquamapsdata dependency

# https://stackoverflow.com/questions/71669825/leaflet-side-by-side-for-2-raster-images-in-r
lib_leaflet <- "/share/r-lib/leaflet-side-by-side-raster"
# remotes::install_github(
#   "rstudio/leaflet", 
#   ref = "joe/feature/raster-options",
#   lib = lib_leaflet)
library(leaflet, lib.loc = lib_leaflet)

librarian::shelf(
  # assertive, 
  raquamaps/aquamapsdata, dplyr, here, 
  leaflet, leaflet.extras2, 
  raster, rgee, reticulate, sf, shiny)
source(here("sp-map/functions.R"))

# download_db()  # aquamaps download (2 GB of data, approx 10 GB when unpacked)

# aquamaps database ----
am_db <- default_db("sqlite")  # ~/.config/aquamaps/am.db

# Earth Engine setup ----
ee_Initialize(
  user    = "ben@ecoquants.com",
  project = "eq-am-fine")

# spatial data ----
ic_gebco <- ee$ImageCollection("projects/sat-io/open-datasets/gebco/gebco_sub-ice-topo")
im_bo    <- ee$Image("projects/eq-am-fine/assets/sdmpredictors/bio-oracle")
fc_fao   <- ee$FeatureCollection("projects/eq-am-fine/assets/fao_areas")
im_am    <- ee$Image("projects/eq-am-fine/assets/sdmpredictors/am-hcaf_v1-simple")

# example species ----
sp_env <- list(
  name_common     = 'blue whale',
  name_scientific = 'Balaenoptera musculus',
  FAOAreas        = c(18, 21, 27, 31, 34, 41, 47, 48, 51, 57, 58, 61, 67, 71, 77, 81, 87, 88),
  Depth           = c(0, 1000, 4000, 8000),
  Temp            = c(-1.8, -1.3, 27.87, 32.07),
  Salinity        = c(3.58, 32.57, 35.49, 38.84),
  PrimProd        = c(0.1, 1.4, 16.07, 119.58),
  IceCon          = c(-0.88, 0, 0.49, 0.96) )

# setup spatial ----
im_depth      <- ic_gebco$median()$multiply(-1)
im_depth_mask <- im_depth$gte(0)
im_depth      <- im_depth$mask(im_depth_mask)$uint16()$rename('depth')
ply_globe     <- ee$Geometry$BBox(-180,-89.9999,180,89.9999)$transform('EPSG:4326', 0.001)

prj      <- ic_gebco$first()$projection()$getInfo()
scale    <- ic_gebco$first()$projection()$nominalScale()$getInfo()
im_depth <- im_depth$setDefaultProjection(prj$crs, prj$transform, NULL)
