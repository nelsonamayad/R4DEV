# R4DEV session 10 — chat with your data using querychat
# Run with: shiny::runApp("shiny/r4dev-querychat")
# Deployed demo runs on Claude Sonnet 5 via an ANTHROPIC_API_KEY set as a
# Connect Cloud environment variable -- never read from or printed into any
# code, log, or page on this site. Students following the session at home use
# their own GEMINI_API_KEY as taught -- swap chat_anthropic() for
# chat_google_gemini() to match the qmd exactly.
#
# Note: querychat_app()/qc$app() calls shiny::runGadget(), built for
# interactive local use (RStudio's viewer pane) -- it binds its own ad-hoc
# port, unrelated to whatever port a hosting platform's launcher expects to
# reach. Deployed as-is, that makes Connect Cloud's startup health check time
# out waiting on a port the app never actually serves. The modular
# QueryChat$new() + qc$sidebar()/qc$server() pattern below builds a plain
# shinyApp() object instead, which Connect's launcher runs normally.

library(shiny)
library(bslib)
library(querychat)
library(DT)
library(RSQLite) # querychat's DataFrameSource needs a database engine at runtime

# CSV lives alongside app.R so the deployed bundle is self-contained
songs <- readr::read_csv("spotify_favorites_archive.csv", show_col_types = FALSE)

qc <- QueryChat$new(
  songs,
  table_name = "songs",
  client = ellmer::chat_anthropic(model = "claude-sonnet-5"),
  greeting = "Ask me anything about these 1,178 songs — in plain language.",
  data_description = paste(
    "One row per song from the discographies of 8 artists,",
    "with Spotify audio features saved before the API closed in 2024.",
    "valence and energy run from 0 to 1.",
    "cover_url holds the album cover image address."
  )
)

ui <- page_sidebar(
  title = tags$span(
    tags$img(src = "r4dev_logo.png", height = "26px", style = "margin-right:8px; vertical-align:middle;"),
    "R4DEV — Chat with your data"
  ),
  theme = bs_theme(bootswatch = "journal", primary = "#226F7F", brand = FALSE),
  sidebar = qc$sidebar(),
  DTOutput("table")
)

server <- function(input, output, session) {
  qc_vals <- qc$server()

  output$table <- renderDT({
    datatable(qc_vals$df(), options = list(scrollX = TRUE, pageLength = 10))
  })
}

shinyApp(ui, server)
