# R4DEV — Global earthquakes, live
# Point-based geospatial data straight from USGS's public GeoJSON feed --
# no world-boundary shapefile, no sf/terra dependency at all, so this app
# can't hit the sf -> terra GDAL build wall that broke the old covid19 app.
# Same teaching pattern as before: button-triggered reactive data feeding a
# leafletProxy map, plus a second plotly tab.

library(shiny)
library(bslib)
library(bsicons)
library(leaflet)
library(plotly)
library(tidyverse)
library(jsonlite)
library(scales)

# Data ####
# USGS updates this feed continuously; M4.5+ over the last 30 days is a
# manageable size (usually a few hundred rows) for a teaching app.
quakes_raw <- jsonlite::fromJSON("https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_month.geojson")

coords <- quakes_raw$features$geometry$coordinates
quakes_df <- tibble(
  place = quakes_raw$features$properties$place,
  mag   = quakes_raw$features$properties$mag,
  depth_km = vapply(coords, `[`, numeric(1), 3),
  lon = vapply(coords, `[`, numeric(1), 1),
  lat = vapply(coords, `[`, numeric(1), 2),
  time = as.POSIXct(quakes_raw$features$properties$time / 1000, origin = "1970-01-01", tz = "UTC")
) |>
  filter(!is.na(mag), !is.na(lon), !is.na(lat)) |>
  arrange(desc(time))

mag_pal <- colorNumeric(c("#F2C078", "#F75431", "#8C1D0E"), domain = range(quakes_df$mag))

# UI ####
ui <- page_navbar(
  theme = bs_theme(bootswatch = "quartz", primary = "#226F7F", brand = FALSE),
  title = tags$span(
    tags$img(src = "r4dev_logo.png", height = "26px", style = "margin-right:8px; vertical-align:middle;"),
    "Global Earthquakes"
  ),
  sidebar = sidebar(
    gap = "5px",
    width = 380,
    card(
      full_screen = TRUE,
      card_header(uiOutput("summary_box")),
      card_body(
        markdown("Earthquakes of magnitude 4.5+ over the last 30 days, straight from the [USGS real-time feed](https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_month.geojson) -- no world map file needed, just latitude and longitude."),
        actionButton("update", "Update data", icon = icon("refresh"), class = "btn-primary")
      )
    ),
    accordion(
      open = TRUE,
      accordion_panel(
        "Selectors:",
        sliderInput("min_mag", "Minimum magnitude",
                    min = 4.5, max = ceiling(max(quakes_df$mag)),
                    value = 4.5, step = 0.1),
        dateRangeInput("date_range", "Date range",
                       start = min(as.Date(quakes_df$time)), end = max(as.Date(quakes_df$time)),
                       min = min(as.Date(quakes_df$time)), max = max(as.Date(quakes_df$time)))
      )
    )
  ),
  nav_panel(title = "Map", icon = bsicons::bs_icon("compass"), leafletOutput("map")),
  nav_panel(title = "Magnitude over time", icon = bsicons::bs_icon("graph-up"), plotlyOutput("mag_time")),
  nav_item(input_dark_mode(id = "dark_mode", mode = "light"))
)

# Server ####
server <- function(input, output, session) {

  # ignoreNULL = FALSE so the map/plot show something immediately on load,
  # not just after the first "Update data" click.
  data_map <- eventReactive(input$update, {
    quakes_df |>
      filter(mag >= input$min_mag,
             as.Date(time) >= input$date_range[1],
             as.Date(time) <= input$date_range[2])
  }, ignoreNULL = FALSE)

  output$summary_box <- renderUI({
    d <- data_map()
    value_box(
      title = "Strongest earthquake shown",
      value = if (nrow(d) > 0) paste0("M", round(max(d$mag), 1)) else "—",
      theme = "danger",
      showcase = bsicons::bs_icon("exclamation-triangle"),
      p(paste(nrow(d), "earthquakes in range"))
    )
  })

  # Create an empty map
  output$map <- renderLeaflet({
    leaflet() |>
      addProviderTiles("Esri.WorldImagery") |>
      setView(lng = 10, lat = 20, zoom = 2)
  })

  # Overlay the selected data -- circle markers sized/colored by magnitude
  observeEvent(input$update, {
    d <- data_map()
    leafletProxy("map") |>
      clearMarkers() |>
      addCircleMarkers(
        data = d, lng = ~lon, lat = ~lat,
        radius = ~scales::rescale(mag, to = c(4, 16), from = range(quakes_df$mag)),
        color = ~mag_pal(mag), fillOpacity = 0.75, stroke = FALSE,
        label = ~paste0("M", mag, " — ", place)
      )
  }, ignoreNULL = FALSE)

  output$mag_time <- renderPlotly({
    plot_ly(
      data_map(), x = ~time, y = ~mag, type = "scatter", mode = "markers",
      color = ~depth_km, colors = c("#226F7F", "#F75431"),
      text = ~paste0("M", mag, " — ", place, "<br>depth: ", round(depth_km, 1), " km"),
      hoverinfo = "text"
    ) |>
      layout(
        xaxis = list(title = ""), yaxis = list(title = "Magnitude"),
        title = "Magnitude over time (color = depth in km)"
      )
  })
}

shinyApp(ui, server)
