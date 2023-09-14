shinyServer(function(input, output, session) {

  updateSelectizeInput(
    session, 
    "sel_sp", 
    choices = sel_sp_choices,
    selected = 69007, # Balaenoptera musculus (blue whale)
    server = TRUE)
  
  sp_map <- eventReactive(
    input$sel_sp,
    {
      req(input$sel_sp)
      
      # input = list(sel_sp = 51720)
      sp_code <- as.integer(input$sel_sp)
      # sp_code <- 51720 # Aaptos aaptos
      # sp_code <- 69007 # Balaenoptera musculus (blue whale)
      
      sp_info <- get_sp_info(sp_code)
      message(glue("sp_info: {toJSON(sp_info, pretty=T, auto_unbox=T)}"))
      
      lgnd <- Map$addLegend(
        visParams = list(
          min     = 0, 
          max     = 100, 
          palette = c('#011de2', '#afafaf', '#3603ff', '#fff477', '#b42109')), 
        name      = "Probability",
        labFormat = labelFormat(
          suffix = "%"))
      
      im_sp_coarse <- calc_im_sp_coarse(sp_info)
      m_coarse <- qmap(
        im_sp_coarse, 
        name = "coarse",
        rng = c(0,100), opacity = 0.8)
      # m_coarse <- m_coarse |> 
      #   addControl(
      #     tags$div(HTML('Coarse (1/2°)')),
      #     position = "topleft")
      
      im_sp_fine <- calc_im_sp_fine(sp_info)
      m_fine <- qmap(
        im_sp_fine, 
        name = "fine", 
        rng = c(0,100), opacity = 0.8) +
        lgnd
      # m_fine <- m_fine |> 
      #   addControl(
      #     tags$div(HTML('Fine (1/240°)')),  # 15 sec * (1 min / 60 sec) * (1° / 60 min) = 15/(60*60)° = 1/240° = 0.004166667°
      #     position = "topright") 
      
      m <- m_coarse | m_fine
      m |> 
        addControl(
          tags$div(HTML('Coarse (1/2°)')),
          position = "topleft") |> 
        addControl(
          tags$div(HTML('Fine (1/240°)')),  # 15 sec * (1 min / 60 sec) * (1° / 60 min) = 15/(60*60)° = 1/240° = 0.004166667°
          position = "topright") 

      },
    ignoreNULL = FALSE
  )
  
  output$ee_map <- renderLeaflet({
    sp_map()
  })
  
  observeEvent(input$btn_sp_info, {
    showModal(modalDialog(
      title = "Species Parameters",
      tabsetPanel(
        tabPanel(
          "Environmental Envelope", 
          plotOutput("plot_sp_env") ),
        tabPanel(
          "Species Information",
          jsoneditOutput("view_sp_info" ) ) ),
      easyClose = T) )
  })
  
  output$view_sp_info <- renderJsonedit({
    jsonedit(sp_info)
  })

  output$plot_sp_env <- renderPlot({

    d <- sp_info$env |> 
      enframe(name = "variable") |> 
      mutate(
        probability = list(c(0,1,1,0))) |> 
      unnest(c(value, probability))
    
    g <- ggplot(d, aes(value, probability)) +
      geom_area() +
      scale_y_continuous(labels = percent) +
      theme_light() +
      facet_wrap(
        vars(variable), 
        scales = "free") +
      labs(
        title    = sp_info$sp_scientific,
        subtitle = "environmental envelope",
        x        = NULL,
        y        = "Probability")
    g
  })
  
})
