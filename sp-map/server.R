shinyServer(function(input, output, session) {

  # sel_sp update ----
  updateSelectizeInput(
    session, 
    "sel_sp", 
    choices = sel_sp_choices,
    selected = 69007, # Balaenoptera musculus (blue whale)
    server = TRUE)
  
  # rx_sp_info ----
  rx_sp_info <- reactive({
    req(input$sel_sp)
    
    get_sp_info(input$sel_sp)
  })
  
  # ee_map ----
  output$ee_map <- renderLeaflet({
    sp_info <- rx_sp_info()
    # sp_code <- 51720 # Aaptos aaptos
    # sp_code <- 69007 # Balaenoptera musculus (blue whale)
    # sp_info <- get_sp_info(sp_code)
    message(glue("sp_info: {toJSON(sp_info, pretty=T, auto_unbox=T)}"))
    
    lgnd <- Map$addLegend(
      visParams = list(
        min     = 0, 
        max     = 100, 
        palette = c('#011de2', '#afafaf', '#3603ff', '#fff477', '#b42109')), 
      name      = "Suitability",
      labFormat = labelFormat(
        suffix = "%"))
    
    im_sp_coarse <- calc_im_sp_coarse(sp_info)
    m_coarse <- qmap(
      im_sp_coarse, 
      name = "coarse",
      rng = c(0,100), opacity = 0.8)
    
    im_sp_fine <- calc_im_sp_fine(sp_info)
    m_fine <- qmap(
      im_sp_fine, 
      name = "fine", 
      rng = c(0,100), opacity = 0.8) +
      lgnd
    
    m <- m_coarse | m_fine
    m |> 
      addControl(
        tags$div(HTML('Coarse (1/2°)')),
        position = "topleft") |> 
      addControl(
        tags$div(HTML('Fine (1/240°)')),  # 15 sec * (1 min / 60 sec) * (1° / 60 min) = 15/(60*60)° = 1/240° = 0.004166667°
        position = "topright") 
  })
  
  # btn_sp_info modal ----
  observeEvent(input$btn_sp_info, {
    # sp_info <- get_sp_info(69007) # Balaenoptera musculus (blue whale)
    sp_info <- rx_sp_info()
    
    showModal(modalDialog(
      title = "Species Parameters",
      tabsetPanel(
        tabPanel(
          "Environmental Envelope", 
          plotOutput("plot_sp_env") ),
        tabPanel(
          "Species Information",
          a(
            href   = paste0("https://aquamaps.org/preMap2.php?cache=1&SpecID=", sp_info$sp_id),
            target = "_blank",
            glue("{sp_info$sp_scientific} | AquaMaps.org")),
          # https://aquamaps.org/preMap2.php?cache=1&SpecID=W-Por-134241
          jsoneditOutput("view_sp_info" ) ) ),
      easyClose = T) )
  })
  
  # view_sp_info ----
  output$view_sp_info <- renderJsonedit({
    sp_info <- rx_sp_info()
    jsonedit(sp_info, mode = "view", modes = c("view","code"))
  })

  # plot_sp_env ----
  output$plot_sp_env <- renderPlot({

    sp_info <- rx_sp_info()
    # sp_id <- am_spp |> 
    #   filter(sp_sci == "Epinephelus striatus") |> 
    #   pull(SpeciesID)
    # sp_info <- get_sp_info(sp_id)
    
    d <- sp_info$env |> 
      enframe(name = "variable") |> 
      mutate(
        suitability = list(c(0,1,1,0))) |> 
      unnest(c(value, suitability))
    
    g <- ggplot(d, aes(value, suitability)) +
      geom_area() +
      scale_y_continuous(labels = percent) +
      facet_wrap(
        vars(variable), 
        scales = "free") +
      labs(
        title    = sp_info$sp_scientific,
        subtitle = "environmental envelope",
        x        = NULL,
        y        = "Suitability") +
      theme_gray()
    
    g
  })
  
})
