# R4DEV session 10 — chat with your data using querychat
# Run with: shiny::runApp("shiny/r4dev-querychat")
# Needs an LLM API key in your .Renviron (default: GEMINI_API_KEY)

library(querychat)

# Shiny runs apps with the app folder as working directory
songs <- readr::read_csv("../../sessions_workshop/02-plots/spotify_favorites_archive.csv")

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
