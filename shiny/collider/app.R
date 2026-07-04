# Packages ####
library(shiny)
library(tidyverse)
library(bslib)
library(bsicons)
library(htmlwidgets)

# UI ####
ui_collider <- fluidPage(
  theme = bslib::bs_theme(),
  h1('One Box'),
  fluidRow(
    layout_column_wrap(
      6, 
      actionButton('btn', 'Think of this button as some cool interactive element that reveals important information')
    ),
    column(4, uiOutput('click_box'))
  ),
  br(),
  h1('Another Box'),
  fluidRow(
    layout_wrap_column(
      6, 
      sliderInput(
        'slider',
        'Slider',
        min = 0,
        max = 100,
        value = c(0, 100),
        step = 1,
        width = '400px'
      )
    ),
    column(4, uiOutput('mean_box'))
  )
)
    

# Server ####
server_collider <- function(input, output) {
  
  output$click_box <- renderUI({
    bslib::value_box(
      title = 'Button clicks',
      value = input$btn,
      showcase = bs_icon('mouse'),
      p('Another info'),
      p('And another')
    )
  })
  
  output$mean_box <- renderUI({
    bslib::value_box(
      title = 'Middle point of the selected slider values',
      value = mean(input$slider),
      showcase = bs_icon('calculator'),
      theme_color = 'danger'
    )
  })
}

# Run #
shinyApp(ui_collider, server_collider)
