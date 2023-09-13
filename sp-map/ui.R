shinyUI(fluidPage(

  leafletOutput("ee_map"),
  p(),
  actionButton("recalc", "Add Species Map")
  
))
