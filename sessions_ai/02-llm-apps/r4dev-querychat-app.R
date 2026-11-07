# R4DEV · Work with AI, lesson 2 (Chat with your data) — chat with your data using querychat
# Run it: open this file in RStudio or Positron and press "Run App", or call shiny::runApp("r4dev-querychat-app.R")
# querychat_app() is for your own machine. To deploy, use the modular API instead:
# QueryChat$new() + qc$sidebar() + qc$server() inside an ordinary shinyApp().
# Needs an LLM API key in your .Renviron (default: GEMINI_API_KEY)

library(querychat)

# The Spotify snapshot from Everything in its right place, read straight from the R4DEV repo
songs <- readr::read_csv("https://raw.githubusercontent.com/nelsonamayad/R4DEV/main/sessions_workshop/02-plots/spotify_favorites_archive.csv")

querychat::querychat_app(
  songs,
  table_name = "songs",
  client = ellmer::chat_google_gemini(),
  greeting = "Ask me anything about these 1,178 songs — in plain language.",
  data_description = paste(
    "One row per song from the discographies of 8 artists,",
    "with Spotify audio features saved before the API closed in 2024.",
    "valence and energy run from 0 to 1.",
    "cover_url holds the album cover image address."
  )
)
