# R4DEV — Global earthquakes, live
# The app built step by step in R4DEV's "Make it shine" lesson, PART II:
# https://nelsonamayad.github.io/R4DEV/sessions_workshop/08-shiny/08-shiny.html
# Run it with shiny::runApp("r4dev-earthquakes-app.R") or the Run App button.
# No API key needed: the USGS feed is free and keyless.

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
    dplyr::mutate(depth = cut(depth_km, c(-Inf, 70, 300, Inf),
                              labels = c("Shallow (< 70 km)", "Intermediate", "Deep (> 300 km)"))) |>
    dplyr::arrange(dplyr::desc(time))
}

# Colours for the plots, in light and dark mode
plot_colours <- function(mode) {
  if (identical(mode, "dark")) {
    list(land = "#2A3136", ocean = "#151A1E", border = "#3D464C", text = "#DDE3E5",
         depth = c("#F75431", "#4FB3C9", "#C9B6F2"))
  } else {
    list(land = "#E3E7E8", ocean = "#F4F8F9", border = "#FFFFFF", text = "#20242A",
         depth = c("#F75431", "#0E8CA8", "#5B3F8C"))
  }
}

# UI ####
ui <- page_sidebar(
  theme = bslib::bs_theme(
    version = 5,
    primary = "#226F7F", secondary = "#5C6B70", danger = "#C2401F",
    base_font = bslib::font_google("Roboto Condensed", wght = c(400, 700)),
    "navbar-bg" = "#226F7F",
    brand = FALSE
  ),
  title = tags$div(
    class = "d-flex align-items-center gap-2 w-100",
    "Global earthquakes, live",
    tags$div(class = "ms-auto", input_dark_mode(id = "dark_mode", mode = "light",
                                                style = "--text-1: #fff; --text-2: #fff;"))
  ),
  sidebar = sidebar(
    width = 290,
    markdown("Every earthquake of magnitude 4.5+ in the last 30 days, from the [USGS real-time feed](https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php). Just latitude and longitude: no map files needed."),
    actionButton("update", "Download fresh data", icon = icon("rotate"), class = "btn-primary"),
    textOutput("downloaded_at"),
    hr(class = "my-1"),
    sliderInput("min_mag", "Minimum magnitude",
                min = 4.5, max = 8, value = 5, step = 0.1),
    sliderInput("days", "Show the last … days",
                min = 1, max = 30, value = 30, step = 1),
    radioButtons("projection", "Map projection",
                 choices = c("Flat" = "natural earth", "Globe" = "orthographic"),
                 inline = TRUE)
  ),
  layout_columns(
    fill = FALSE,
    uiOutput("box_count"), uiOutput("box_strongest"), uiOutput("box_latest")
  ),
  navset_card_underline(
    full_screen = TRUE,
    nav_panel("Map", icon = bs_icon("globe-americas"), plotlyOutput("map")),
    nav_panel("Timeline", icon = bs_icon("graph-up"), plotlyOutput("mag_time")),
    nav_panel("Strongest 10", icon = bs_icon("list-ol"), tableOutput("strongest"))
  )
)

# Server ####
server <- function(input, output, session) {

  # 1. Download the feed: on start-up (ignoreNULL = FALSE) and on every click
  quakes <- eventReactive(input$update, {
    withProgress(message = "Downloading the USGS feed…", read_quakes())
  }, ignoreNULL = FALSE)

  # 2. Filter it: re-runs instantly whenever a selector moves
  quakes_shown <- reactive({
    since <- Sys.time() - input$days * 24 * 60 * 60
    quakes() |>
      dplyr::filter(mag >= input$min_mag, time >= since)
  })

  # 3. The outputs only ever read the filtered data
  output$downloaded_at <- renderText({
    paste0("Feed downloaded at ", format(Sys.time(), "%H:%M UTC", tz = "UTC"),
           " · ", nrow(quakes()), " earthquakes")
  }) |> bindEvent(quakes())

  output$box_count <- renderUI({
    value_box(
      title = "Earthquakes shown",
      value = nrow(quakes_shown()),
      theme = "primary"
    )
  })

  output$box_strongest <- renderUI({
    d <- quakes_shown()
    top <- dplyr::slice_max(d, mag, n = 1, with_ties = FALSE)
    value_box(
      title = "Strongest",
      value = if (nrow(top) > 0) sprintf("M%.1f", top$mag) else "—",
      p(class = "small mb-0 text-truncate", if (nrow(top) > 0) top$place),
      theme = "danger"
    )
  })

  output$box_latest <- renderUI({
    d <- quakes_shown()
    hours <- if (nrow(d) > 0) as.numeric(difftime(Sys.time(), max(d$time), units = "hours"))
    value_box(
      title = "Most recent",
      value = if (is.null(hours)) "—" else if (hours < 1) "< 1 hour ago"
              else if (hours < 48) paste(round(hours), "hours ago")
              else paste(round(hours / 24), "days ago"),
      p(class = "small mb-0 text-truncate", if (nrow(d) > 0) d$place[1])
    )
  })

  output$map <- renderPlotly({
    col <- plot_colours(input$dark_mode)
    plot_ly(
      quakes_shown(),
      type = "scattergeo", mode = "markers",
      lon = ~lon, lat = ~lat,
      marker = list(
        size = ~4 + (mag - 4.5) * 6,
        color = ~mag, cmin = 4.5, cmax = 8,
        colorscale = list(c(0, "#F2C078"), c(0.5, "#F75431"), c(1, "#8C1D0E")),
        colorbar = list(title = "Magnitude", thickness = 12),
        opacity = 0.85, line = list(width = 0.5, color = "rgba(255,255,255,0.6)")
      ),
      text = ~paste0("<b>M", mag, "</b> · ", place,
                     "<br>", format(time, "%d %b %Y, %H:%M UTC"),
                     "<br>depth: ", round(depth_km), " km"),
      hoverinfo = "text"
    ) |>
      layout(
        geo = list(
          projection = list(type = input$projection),
          showland = TRUE, landcolor = col$land,
          showocean = TRUE, oceancolor = col$ocean,
          showcountries = TRUE, countrycolor = col$border,
          showcoastlines = FALSE, showframe = FALSE,
          bgcolor = "rgba(0,0,0,0)"
        ),
        font = list(color = col$text),
        paper_bgcolor = "rgba(0,0,0,0)",
        margin = list(l = 0, r = 0, t = 0, b = 0)
      ) |>
      config(displaylogo = FALSE)
  })

  output$mag_time <- renderPlotly({
    col <- plot_colours(input$dark_mode)
    plot_ly(
      quakes_shown(), x = ~time, y = ~mag,
      type = "scatter", mode = "markers",
      color = ~depth, colors = col$depth,
      marker = list(size = 8, opacity = 0.8),
      text = ~paste0("<b>M", mag, "</b> · ", place, "<br>depth: ", round(depth_km), " km"),
      hoverinfo = "text"
    ) |>
      layout(
        legend = list(orientation = "h", y = 1.08, title = list(text = "Depth: ")),
        xaxis = list(title = "", gridcolor = col$border),
        yaxis = list(title = "Magnitude", gridcolor = col$border),
        font = list(color = col$text),
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
      ) |>
      config(displaylogo = FALSE)
  })

  output$strongest <- renderTable({
    quakes_shown() |>
      dplyr::slice_max(mag, n = 10, with_ties = FALSE) |>
      dplyr::transmute(
        Magnitude = sprintf("M%.1f", mag),
        Where = place,
        `When (UTC)` = format(time, "%d %b, %H:%M"),
        `Depth (km)` = as.integer(round(depth_km))
      )
  }, striped = TRUE, hover = TRUE, width = "100%")
}

shinyApp(ui, server)
