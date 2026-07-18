# R4DEV session 10 — minimal chat app with shinychat + ellmer
# Run with: shiny::runApp("shiny/r4dev-chat")
# Needs an LLM API key in your .Renviron (default: GEMINI_API_KEY)

library(shiny)
library(bslib)
library(shinychat)

ui <- bslib::page_fillable(
  theme = bslib::bs_theme(bootswatch = "journal"),
  h4("R4DEV teaching assistant 🤖"),
  shinychat::chat_ui("chat", fill = TRUE)
)

server <- function(input, output, session) {

  chat <- ellmer::chat_google_gemini(
    system_prompt = paste(
      "You are the teaching assistant of R4DEV, a tidyverse-first R workshop.",
      "Answer questions about R with short runnable examples.",
      "Always use the native pipe |> and never suggest base R plotting."
    )
  )

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
