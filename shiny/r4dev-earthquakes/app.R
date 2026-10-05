# R4DEV — Global earthquakes, live
# Point data straight from the USGS real-time GeoJSON feed, mapped with
# plotly's `scattergeo` trace. No leaflet, no sf: leaflet hard-imports sf,
# and sf pulls in terra, which fails to compile on Posit Connect Cloud and
# shinyapps.io (GDAL 3.4.1). plotly draws its own world basemap, so the app
# deploys anywhere. This is the app taught step by step in
# sessions_workshop/07-shiny, PART II -- keep the two in sync.

library(shiny)
library(bslib)
library(bsicons)
library(plotly)
library(dplyr)
library(purrr)
library(jsonlite)

# Data ####
# One function that downloads and tidies the feed, so the app can call it
# again whenever the user asks for fresh data.
read_quakes <- function(feed = "4.5_month") {
  raw <- jsonlite::fromJSON(
    paste0("https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/", feed, ".geojson")
  )
  coords <- raw$features$geometry$coordinates

  tibble::tibble(
    place    = raw$features$properties$place,
    mag      = raw$features$properties$mag,
    lon      = purrr::map_dbl(coords, 1),
    lat      = purrr::map_dbl(coords, 2),
    depth_km = purrr::map_dbl(coords, 3),
    time     = as.POSIXct(raw$features$properties$time / 1000, origin = "1970-01-01", tz = "UTC")
  ) |>
    dplyr::filter(!is.na(mag), !is.na(lon), !is.na(lat)) |>
    dplyr::arrange(dplyr::desc(time))
}

# UI ####
ui <- page_navbar(
  theme = bslib::bs_theme(bootswatch = "quartz", primary = "#226F7F", brand = FALSE),
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
        markdown("Earthquakes of magnitude 4.5+ over the last 30 days, from the [USGS real-time feed](https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php). Just latitude and longitude --no map file needed."),
        actionButton("update", "Download fresh data", icon = icon("refresh"), class = "btn-primary")
      )
    ),
    accordion(
      open = TRUE,
      accordion_panel(
        "Selectors:",
        sliderInput("min_mag", "Minimum magnitude",
                    min = 4.5, max = 8, value = 5, step = 0.1),
        dateRangeInput("date_range", "Date range",
                       start = Sys.Date() - 30, end = Sys.Date(),
                       min = Sys.Date() - 30, max = Sys.Date())
      )
    )
  ),
  nav_panel(title = "Map", icon = bsicons::bs_icon("globe"), plotlyOutput("map", height = "100%")),
  nav_panel(title = "Magnitude over time", icon = bsicons::bs_icon("graph-up"), plotlyOutput("mag_time", height = "100%")),
  nav_item(input_dark_mode(id = "dark_mode", mode = "light"))
)

# Server ####
server <- function(input, output, session) {

  # 1. Download the feed: on start-up (ignoreNULL = FALSE) and on every click
  quakes <- eventReactive(input$update, {
    read_quakes()
  }, ignoreNULL = FALSE)

  # 2. Filter it: re-runs instantly whenever a selector moves
  quakes_shown <- reactive({
    quakes() |>
      dplyr::filter(mag >= input$min_mag,
                    as.Date(time) >= input$date_range[1],
                    as.Date(time) <= input$date_range[2])
  })

  # 3. The outputs only ever read the filtered data
  output$summary_box <- renderUI({
    d <- quakes_shown()
    value_box(
      title = "Strongest earthquake shown",
      value = if (nrow(d) > 0) paste0("M", round(max(d$mag), 1)) else "—",
      theme = "danger",
      showcase = bsicons::bs_icon("exclamation-triangle"),
      p(paste(nrow(d), "earthquakes in range"))
    )
  })

  output$map <- renderPlotly({
    plot_ly(
      quakes_shown(),
      type = "scattergeo", mode = "markers",
      lon = ~lon, lat = ~lat,
      marker = list(
        size = ~4 + (mag - 4.5) * 5,
        color = ~mag, cmin = 4.5, cmax = 8,
        colorscale = list(c(0, "#F2C078"), c(0.5, "#F75431"), c(1, "#8C1D0E")),
        colorbar = list(title = "Magnitude"),
        opacity = 0.8, line = list(width = 0)
      ),
      text = ~paste0("M", mag, " — ", place,
                     "<br>", format(time, "%d %b %Y, %H:%M UTC"),
                     "<br>depth: ", round(depth_km), " km"),
      hoverinfo = "text"
    ) |>
      layout(
        geo = list(
          projection = list(type = "natural earth"),
          showland = TRUE, landcolor = "#D9D9D9",
          showocean = TRUE, oceancolor = "#EEF4F6",
          showcountries = TRUE, countrycolor = "white",
          bgcolor = "rgba(0,0,0,0)"
        ),
        paper_bgcolor = "rgba(0,0,0,0)",
        margin = list(l = 0, r = 0, t = 0, b = 0)
      )
  })

  output$mag_time <- renderPlotly({
    plot_ly(
      quakes_shown(), x = ~time, y = ~mag,
      type = "scatter", mode = "markers",
      color = ~depth_km, colors = c("#0E8CA8", "#F75431"),
      text = ~paste0("M", mag, " — ", place, "<br>depth: ", round(depth_km), " km"),
      hoverinfo = "text"
    ) |>
      layout(
        xaxis = list(title = ""), yaxis = list(title = "Magnitude"),
        title = "Magnitude over time (colour = depth in km)"
      )
  })
}

shinyApp(ui, server)
