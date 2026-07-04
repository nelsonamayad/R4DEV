# Packages ####
library(shiny)
library(shinydashboard)
library(shinythemes)
library(RColorBrewer)
library(tidyverse)
library(plotly)
library(ggthemes)

# Data ####

# UI ####
ui_bayes <- navbarPage(
  theme = bslib::bs_theme(bootswatch = "mintz"),
  title = "BayesApp",
  sidebarLayout(
    sidebarPanel(
      # A button that will trigger the update of the map/graph
      actionButton("update","Update data", icon = icon("refresh"))
      ,
    # Now we layout the objects to render
    mainPanel()
      )))

# Server ####
server_bayes <- function(input,output) {
  
  data <- eventReactive(input$update,{

  })
  
  observeEvent(input$update,
               {
                 leafletProxy("map") |>
                   clearMarkers() |>
                   addCircleMarkers(data = data_map(),
                                    radius = ~log(total_deaths),
                                    color = ~c("red"),
                                    label= ~paste0(country,": ",total_deaths))
               })
  

}
# Run the app ####
shinyApp(ui_covid,server_covid)