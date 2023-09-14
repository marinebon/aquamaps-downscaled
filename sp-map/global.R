Sys.setenv(
  EARTHENGINE_GCLOUD = "/usr/bin/gcloud",
  EARTHENGINE_PYTHON = "/opt/venv/rgee/bin/python",
  EARTHENGINE_ENV    = "rgee")

if (!"librarian" %in% installed.packages())
  install.packages("librarian")

# devtools::install_bitbucket("bklamer/rcrypt")  # aquamapsdata dependency
librarian::shelf(
  raquamaps/aquamapsdata, dplyr, ggplot2, glue, here, jsonlite,
  leaflet, leaflet.extras2, listviewer,
  purrr, raster, rgee, reticulate, scales, sf, shiny, stringr, tibble, tidyr)
select = dplyr::select
source(here("sp-map/functions.R"))

# download_db()  # aquamaps download (2 GB of data, approx 10 GB when unpacked)

# aquamaps database ----
am_db <- default_db("sqlite")  # ~/.config/aquamaps/am.db

# list of species
am_spp <- get_am_spp()
sel_sp_choices <- with(
  am_spp,
  setNames(SpecCode, sp_sci))

# Earth Engine setup ----
ee_Initialize(
  user    = "ben@ecoquants.com",
  project = "eq-am-fine")

# spatial data ----
ic_gebco <- ee$ImageCollection("projects/sat-io/open-datasets/gebco/gebco_sub-ice-topo")
im_bo    <- ee$Image("projects/eq-am-fine/assets/sdmpredictors/bio-oracle")
fc_fao   <- ee$FeatureCollection("projects/eq-am-fine/assets/fao_areas")
im_am    <- ee$Image("projects/eq-am-fine/assets/sdmpredictors/am-hcaf_v1-simple")

# TODO: Aatolana schioedtei
# ee.ee_exception.EEException: Filter.inList: Cannot filter using 'ListContains' with '71' as a left operand.
# [90mRun `reticulate::py_last_error()` for details.[39m

# setup spatial ----
im_depth      <- ic_gebco$median()$multiply(-1)
im_depth_mask <- im_depth$gte(0)
im_depth      <- im_depth$mask(im_depth_mask)$uint16()
ply_globe     <- ee$Geometry$BBox(-180,-89.9999,180,89.9999)$transform("EPSG:4326", 0.001)

prj      <- ic_gebco$first()$projection()$getInfo()
scale    <- ic_gebco$first()$projection()$nominalScale()$getInfo()
im_depth <- im_depth$setDefaultProjection(prj$crs, prj$transform, NULL)

# im_gb: image of GEBCO + Bio-Oracle
im_gb <- ee$ImageCollection(c(im_depth, im_bo))$toBands()  # im_gb$bandNames()$getInfo()
im_gb <- im_gb$rename(c("Depth", "Temp", "Salinity", "PrimProd", "IceCon"))
im_gb <- im_gb$setDefaultProjection(prj$crs, prj$transform, NULL)
