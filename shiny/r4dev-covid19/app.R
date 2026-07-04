# Packages ####
library(rworldmap)
library(rnaturalearth)
library(leaflet)
library(leaflet.providers)
library(sp)
library(lubridate)
library(shiny)
library(hrbrthemes)
library(tidyverse)
library(plotly)
library(ggthemes)
library(bslib)
library(bsicons)
library(shinyWidgets)

# Data ####
covid_df <- readr::read_csv("https://raw.githubusercontent.com/owid/covid-19-data/refs/heads/master/public/data/cases_deaths/full_data.csv") %>%
  dplyr::mutate(date = lubridate::as_date(date),
                n = row_number(),
                year = year(date)) %>%
  dplyr::mutate(iso3c = countrycode::countrycode(location, "country.name","iso3c")) |>
  dplyr::select(iso3c, country=location, date, total_deaths, new_deaths)

# let's download the worldmap as a sp file. Look at the file in the Viewer, what is different from other data frames? ####
world_sp <- rworldmap::getMap(resolution = "low")

# Icon ####
covid_icon <- leaflet::makeIcon(
  iconUrl = "https://www.un.org/sites/un2.un.org/files/2020/04/covid-19.svg",
  iconWidth = 40, iconHeight = 40
)

# UI ####
{ui_covid <- page_navbar(
  # Here we add the Quartz Bootswatch theme
  theme = bslib::bs_theme(bootswatch = "quartz"),
  title = "COVID-19: Aftermath",
  sidebar = sidebar(
    gap = "5px",
    width = 500,
    # Value box 
      card(
        full_screen = TRUE,
        card_header(
          uiOutput("total_deaths"),
        ),
        card_body(
          markdown("Shiny App to show the evolution of Covid-related deaths around the world since March 2020, using the repository of [OWID](https://github.com/owid/covid-19-data/tree/master/public/data)"),
        # A button that will trigger the update of the map/graph
        actionButton(
          inputId = "update",
          label = "Update data", 
          icon = icon("refresh"),
          class = "btn-primary"
          )),
        accordion(
          open = TRUE,
          accordion_panel(
            "Selectors:",
            # Adding the period input
            dateInput(
              inputId = "date",
              label = "Select date:",
              value = "2023-06-30",
              min=min(covid_df$date),
              max=max(covid_df$date)),
            # Adding the countries input
            selectInput(
              inputId = "country",
              label = "Select countries:",
              choices = sort(unique(covid_df$country)),
              selected = c("France","Italy","Colombia","India","Brazil","Japan","Nigeria"),
              multiple = TRUE
              ))) 
      )),
  # Now we add the tabs
    nav_panel(
      title = "Map",
      icon =  bsicons::bs_icon("compass"),
      leafletOutput("map")
      ),
    nav_panel(
      title = "Trajectories", 
      icon = bsicons::bs_icon("clock-history"),
      plotlyOutput("countries")
      ),
    nav_item(input_dark_mode(id = "dark_mode",mode = "light"))
  )
}
# Server ####
server_covid <- function(input,output) {
  
  # A data object is created so that each click of the button updates the data that is fed to the map
  data <- eventReactive(input$update,{
    covid_df %>%
      # Filter the date and countries selected in each input
      dplyr::filter(date==input$date,
                    !str_detect(iso3c,"_"),
                    !is.na(total_deaths),
                    country %in% input$country) %>%
      dplyr::group_by(iso3c,country) %>%
      dplyr::summarise(country_deaths = sum(total_deaths)) 
  })
  
  # Value boxes ####
  output$total_deaths <- renderUI({
  
    value_box(
      title = "Total COVID-19 deaths",
      value = covid_df %>%
        dplyr::filter(!str_detect(iso3c,"_")) |>
        dplyr::summarise(deaths = sum(new_deaths, na.rm = TRUE)) |>
        dplyr::transmute(deaths = deaths |> round(digit=1) |> format(big.mark = " ")) |>
        as.character(),
      theme = "danger",
      showcase = bs_icon("virus"),
      p("Source: WHO & OWID")
    )
    
  })

  # The data that goes to the map
  data_map <- reactive({
    # First create a copy of the base map
    world_sp2 <- world_sp
    
    # Then join the selected data inside of the sp object
    world_sp2@data <- world_sp2@data %>%
      dplyr::inner_join(
        covid_df %>%
          dplyr::filter(date==input$date,
                        !str_detect(iso3c,"_"),
                        !is.na(total_deaths),
                        country %in% input$country), 
        by=c("ISO3"="iso3c"))
  })
  
  # Create an empty map 
  output$map <- renderLeaflet({
    
    leaflet() |>
      addTiles() |>
      addProviderTiles("Esri.WorldImagery") |>
      setView(lng = -20, lat= 30, zoom = 3)
  })
  
  # Overlay in the empty map the selected data
  observeEvent(input$update,
          {
    leafletProxy("map") |>
      clearMarkers() |>
      addMarkers(data = data_map(),
                       icon = covid_icon,
                       label= ~paste0(country,": ",as.integer(total_deaths) |> format(big.mark = " ")))
  })
  

  # Another graph with plotly in the second tab
  output$countries <- renderPlotly({
    
    p <- covid_df %>%
      dplyr::filter(country %in% input$country) |>
      ggplot(aes(x=date, y=total_deaths, color=country))+
      geom_path(show.legend = FALSE)+
      labs(x=NULL,y="Registered deaths",
           title="Progression in selected countries",
           caption = "Source: OWID")+
      hrbrthemes::theme_ipsum()
    
    ggplotly(p)
    
  })
  
}
# Run the app ####
shinyApp(ui_covid,server_covid)