shinyServer(function(input, output, session) {

  sp_map <- eventReactive(
    input$recalc,
    {
      
      im_sp_fine   <- calc_im_sp_fine(sp_env)
      im_sp_coarse <- calc_im_sp_coarse(sp_env)
      m_fine   <- qmap(
        im_sp_fine, 
        name = "fine", 
        rng = c(0,100), opacity = 0.8)
      m_coarse <- qmap(
        im_sp_coarse, 
        name = "coarse",
        rng = c(0,100), opacity = 0.8)
      
      m_coarse | m_fine
      },
    ignoreNULL = FALSE
  )
  
  output$ee_map <- renderLeaflet({
    sp_map()
  })
  
})
