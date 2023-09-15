shinyUI(fluidPage(
  fluidRow(
    column(
      2, 
      h4("DRAFT AquaMaps Downscaling")),
    column(
      7, 
      selectizeInput(
        "sel_sp", "Species", choices = integer(0), multiple = F, width = "100%")),
    column(
      3, 
      actionButton(
        "btn_sp_info", 
        "Parameters", 
        icon  = icon("info-circle"), 
        style = "margin-top: 25px",
        width = "100%"))),
  tags$style(type = "text/css", "#ee_map {height: calc(100vh - 100px) !important;}"),
  leafletOutput("ee_map")
  
))
