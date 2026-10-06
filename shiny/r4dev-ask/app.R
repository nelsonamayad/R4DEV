# R4DEV capstone — "Ask R4DEV": a retrieval-augmented chatbot over the
# workshop's own lesson content, built with ragnar (see the Work with AI
# track, lesson 3: "Grounded in truth").
#
# The store (r4dev_ragnar.duckdb) was built OFFLINE with ragnar_store_ingest()
# using embed_ollama() -- free, local, no API key. Rebuild it from the
# published site with shiny/build_r4dev_ask_store.R. This deployed app retrieves
# with ragnar_retrieve_bm25() rather than vector search: Posit Connect Cloud
# has no route back to a local Ollama instance to embed a stranger's live
# question, and this workshop has no cloud embedding provider with usable
# quota yet. Swap in embed_google_gemini()/embed_openai() at ingestion time
# and ragnar_retrieve_vss() here the moment that changes.
#
# Deployed demo runs on ANTHROPIC_API_KEY (already provisioned for this
# account); swap chat_anthropic() for chat_google_gemini() to match the
# provider taught in "Talking to machines" if you're running this with your own key.

library(shiny)
library(bslib)
library(shinychat)
library(ragnar)

store <- ragnar_store_connect("r4dev_ragnar.duckdb", read_only = TRUE)

system_prompt <- paste(
  "You are 'Ask R4DEV', a chatbot that answers questions using ONLY the",
  "retrieved excerpts from the R4DEV workshop provided below each question.",
  "R4DEV teaches reproducible data analysis in R in three tracks: Build with R",
  "(Quarto, ggplot2, text analysis, animation, maps, scraping, Shiny, reports,",
  "parallel computing), Work with AI (ellmer, LLM apps, RAG, agentic coding) and",
  "Think with data (uncertainty, inference, regression, causal inference, Bayes).",
  "Rules:",
  "1. Ground every answer in the provided excerpts. Quote or paraphrase them.",
  "2. If the excerpts don't cover the question, say so plainly --don't invent",
  "   an answer from general knowledge.",
  "3. Always cite which lesson(s) you drew from, using the origin URL given",
  "   with each excerpt.",
  "4. Keep answers concise and use the native pipe |> in any code you show,",
  "   matching this workshop's style."
)

build_context <- function(hits) {
  if (nrow(hits) == 0) return("(No matching excerpts found in the workshop.)")
  paste(
    sprintf("### From %s\n%s", hits$origin, hits$text),
    collapse = "\n\n---\n\n"
  )
}

ui <- bslib::page_fillable(
  theme = bslib::bs_theme(bootswatch = "journal"),
  tags$div(
    style = "display:flex; align-items:center; gap:10px; margin-bottom:0.25rem;",
    tags$img(src = "r4dev_logo.png", height = "32px"),
    h4("Ask R4DEV 📉📈 — a chatbot grounded in this workshop's own content", style = "margin:0;")
  ),
  p(class = "text-muted",
    "Retrieval-augmented with ragnar: every answer is grounded in retrieved excerpts, not free recall."),
  shinychat::chat_ui("chat", fill = TRUE)
)

server <- function(input, output, session) {

  chat <- ellmer::chat_anthropic(system_prompt = system_prompt)

  observeEvent(input$chat_user_input, {
    hits <- ragnar_retrieve_bm25(store, input$chat_user_input, top_k = 5)
    context <- build_context(hits)

    prompt <- paste0(
      "Question: ", input$chat_user_input, "\n\n",
      "Retrieved excerpts:\n\n", context
    )

    stream <- chat$stream_async(prompt)
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
