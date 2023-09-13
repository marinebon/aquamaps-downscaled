
# https://github.com/csaybar/shiny_rgee_template/blob/main/app.R
Sys.setenv(
  EARTHENGINE_GCLOUD = "/usr/bin/gcloud",
  EARTHENGINE_PYTHON = "/opt/venv/rgee/bin/python",
  EARTHENGINE_ENV    = "rgee")

librarian::shelf(
  leaflet, rgee, reticulate, shiny)
# source("utils.R")

# ee_install(
#   py_env = "rgee",
#   earthengine_version = ee_version(),
#   python_version = "3.8",
#   confirm = interactive())

# rgee::ee_check()
# ◉  Python version
#   ✔ [Ok] /opt/venv/rgee/bin/python v3.8
# ◉  Python packages:
#   ✔ [Ok] numpy
#   ✔ [Ok] earthengine-api

# rgee:::ee_check_init()
# $earthengine_version
# [1] "0.1.368"
#
# $ee_utils
# Module(ee_utils)

ee_Initialize(
  user          = "ben@ecoquants.com",
  project       = "eq-am-fine")
# Successfully saved authorization token.
# ✔ Initializing Google Earth Engine:  DONE!
# ✔ Earth Engine account: projects/eq-am-fine/assets/fao_areas
# ✔ Python Path: /opt/venv/rgee/bin/python

# srtm <- ee$Image("USGS/SRTMGL1_003")
#
# viz <- list(
#   max = 4000,
#   min = 0,
#   palette = c("#000000","#5AAD5A","#A9AD84","#FFFFFF"))
#
# Map$addLayer(
#   eeObject = srtm,
#   visParams =  viz,
#   name = 'SRTM')

# TODO: use Google service account
cloud_api_key = "/share/data/eq-am-fine-98c68d6f5f96.json"

# [install gcloud CLI](https://cloud.google.com/sdk/docs/install#deb)
#   sudo apt-get update
#   sudo apt-get install apt-transport-https ca-certificates gnupg curl sudo
#   echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
#   curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
#   sudo apt-get update && sudo apt-get install google-cloud-cli

# /usr/bin/gcloud init
# ben@ecoquants.com
# eq-am-fine
# Created a default .boto configuration file at [/home/admin/.boto]

# 3. DEFINE HERE YOUR APP -------------------------------------------------
ui <- fluidPage(
  leafletOutput("mymap"),
  p(),
  actionButton("recalc", "Add SRTM Global Map")
)
server <- function(input, output, session) {

  dem_map <- eventReactive(
    input$recalc,
    {
      Map$addLayer(ee$Image('srtm90_v4'), list(min = 0, max = 1000)) },
    ignoreNULL = FALSE)

  output$mymap <- renderLeaflet({
    dem_map()
  })
}
shinyApp(ui = ui, server = server)
