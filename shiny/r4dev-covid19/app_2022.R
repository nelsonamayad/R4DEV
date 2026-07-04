# Packages ####
library(rworldmap)
library(rnaturalearth)
library(leaflet)
library(leaflet.providers)
library(sp)
library(lubridate)
library(shiny)
library(shinydashboard)
library(shinythemes)
library(RColorBrewer)
library(raster)
library(rgeos)
library(tidyverse)
library(plotly)
library(ggthemes)
library(bslib)

# Data ####
covid_df <- readr::read_csv("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv") %>%
  dplyr::mutate(date = lubridate::as_date(date),
                n = row_number(),
                year = year(date)) %>%
  dplyr::select(iso_code, continent,country=location,date,deaths=total_deaths_per_million,pop=population)

# let's download the worldmap as a sp file. Look at the file in the Viewer, what is different from other data frames? ####
world_sp <- rworldmap::getMap(resolution = "low")

# Icon ####
covid_icon <- makeIcon(
  iconUrl = "https://www.un.org/sites/un2.un.org/files/2020/04/covid-19.svg",
  iconWidth = 20, iconHeight = 20
)

# UI ####
ui_covid <- page_sidebar(
  # Here we add the Quartz Bootwwatch theme
  theme = bslib::bs_theme(bootswatch = "quartz"),
  title= "COVID-19: Aftermath",
  sidebarLayout(
    sidebarPanel(
      # Some intro text
      a("Shiny App to show the evolution of Covid-related deaths around the world between March 2020 and July 2022, using the repository of OWID"),
      br(),
      br(),
      # A button that will trigger the update of the map/graph
      actionButton("update","Update data", icon = icon("refresh")),
      br(),
      br(),
      # Adding the period input
      dateRangeInput("date",
                   "Select period:",
                   start=min(covid_df$date),
                   end=max(covid_df$date)),
      br(),
      # Adding the countries input
      selectInput("country",
                "Select country:",
                choices = sort(unique(covid_df$country)),
                selected= c("France","Italy","Colombia","India","Brazil"),
                multiple = TRUE)
  ),
  # Now we layout the objects to render
  mainPanel(
    tabsetPanel(type = "tabs",
                tabPanel("Map",leafletOutput("map")),
                tabPanel("Trajectories", plotlyOutput("countries"))
    )))
  )


# Server ####
server_covid <- function(input,output) {
  
  # A data object is created so that each click of the button updates the data that is fed to the map
  data <- eventReactive(input$update,{
    covid_df %>%
      # Filer the dates and countries selected in each input
      dplyr::filter(between(date,input$date[1],input$date[2]),
                    !is.na(deaths),
                    country %in% input$country) %>%
      dplyr::group_by(iso_code,country,date) %>%
      dplyr::summarise(total_deaths = sum(deaths)) %>%
      dplyr::filter(!is.na(total_deaths))
  })
  
  # The data that goes to the map
  data_map <- reactive({
    # First create a copy of the base map
    world_sp2 <- world_sp
    
    # Then join the selected data inside of the sp object
    world_sp2@data <- world_sp2@data %>%
      dplyr::inner_join(covid_df %>%
                         dplyr::filter(between(date,input$date[1],input$date[2]),
                                       !is.na(deaths),
                                       country %in% input$country) %>%
                         dplyr::group_by(iso_code,country,date) %>%
                         dplyr::summarise(total_deaths = sum(deaths)) %>%
                         dplyr::filter(!is.na(total_deaths)), 
                       by=c("ISO3"="iso_code"))
      
  })
  
  # Create an empty map 
  output$map <- renderLeaflet({
    
    leaflet() |>
      addTiles() |>
      addProviderTiles("Esri.WorldImagery") |>
      setView(20,-30, 2)
  })
  
  # Overlay in the empty map the selected data
  observeEvent(input$update,
          {
    leafletProxy("map") |>
      clearMarkers() |>
      addMarkers(data = data_map(),
                       icon = covid_icon,
                       label= ~paste0(country,": ",as.integer(total_deaths)))
  })
  

  # Another graph with plotly in the second tab
  output$countries <- renderPlotly({
    
    p <- data() %>%
      ggplot(aes(x=date, y=total_deaths, color=country))+
      geom_path()+
      labs(x=NULL,y="Registered deaths",
           title="Progression in selected countries",
           caption = "Source: OWID")+
      scale_fill_distiller(direction=1)+
      theme(panel.background = element_rect(fill="gray85"),
            legend.position='none')
    
    ggplotly(p)
    
  })
  
}
# Run the app ####
shinyApp(ui_covid,server_covid)