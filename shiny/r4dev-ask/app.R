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
library(bsicons)
library(shinychat)
library(ragnar)

store <- ragnar_store_connect("r4dev_ragnar.duckdb", read_only = TRUE)

# Readable page titles for citations: the first "# Heading" of each page
page_titles <- local({
  docs <- DBI::dbGetQuery(store@con, "SELECT origin, text FROM documents")
  heading <- regmatches(docs$text, regexpr("(?m)^# [^\n]+", docs$text, perl = TRUE))
  has_heading <- regexpr("(?m)^# [^\n]+", docs$text, perl = TRUE) > 0
  titles <- rep(NA_character_, nrow(docs))
  titles[has_heading] <- trimws(sub("\\s+[\u2013-]\\s+R4DEV\\s*$", "", sub("^# ", "", heading)))
  fallback <- tools::file_path_sans_ext(basename(docs$origin))
  titles[is.na(titles)] <- fallback[is.na(titles)]
  setNames(titles, docs$origin)
})

track_of <- function(url) {
  dplyr::case_when(
    grepl("sessions_workshop", url) ~ "Build with R",
    grepl("sessions_ai", url) ~ "Work with AI",
    grepl("sessions_thinking", url) ~ "Think with data",
    grepl("sessions_tools", url) ~ "Tools",
    TRUE ~ "R4DEV"
  )
}

system_prompt <- paste(
  "You are 'Ask R4DEV', a chatbot that answers questions using ONLY the",
  "retrieved excerpts from the R4DEV workshop provided below each question.",
  "R4DEV teaches reproducible data analysis in R in three tracks: Build with R",
  "(Quarto, ggplot2, text analysis, animation, maps, scraping, Shiny, reports,",
  "parallel computing), Work with AI (ellmer, LLM apps, RAG, agentic coding) and",
  "Think with data (uncertainty, inference, regression, causal inference, Bayes).",
  "Rules:",
  "1. Ground every answer in the provided excerpts. Quote or paraphrase them.",
  "2. If the excerpts don't cover the question, say so plainly -- don't invent",
  "   an answer from general knowledge.",
  "3. Cite the lesson(s) you drew from as markdown links, using the lesson title",
  "   and the origin URL given with each excerpt.",
  "4. Keep answers concise and use the native pipe |> in any code you show,",
  "   matching this workshop's style."
)

build_context <- function(hits) {
  if (nrow(hits) == 0) return("(No matching excerpts found in the workshop.)")
  paste(
    sprintf("### From \"%s\" (%s)\n%s", page_titles[hits$origin], hits$origin, hits$text),
    collapse = "\n\n---\n\n"
  )
}

greeting <- paste(
  "**Hi! I answer questions about R4DEV using only its own lessons**, and I link",
  "to the lessons I used, so you can check every answer.",
  "",
  "Try one of these:",
  "",
  "* <span class=\"suggestion submit\">How do I add code annotations to a Quarto document?</span>",
  "* <span class=\"suggestion submit\">Why does the earthquakes app use plotly instead of leaflet?</span>",
  "* <span class=\"suggestion submit\">What is a collider, and why shouldn't I control for one?</span>",
  "* <span class=\"suggestion submit\">How do I extract structured data with ellmer?</span>",
  sep = "\n"
)

# ---- UI ---------------------------------------------------------------------------
ui <- page_sidebar(
  title = tags$span(
    class = "d-flex align-items-center gap-2",
    tags$img(src = "r4dev_logo.png", height = "28px", alt = "R4DEV logo"),
    "Ask R4DEV"
  ),
  theme = bs_theme(
    version = 5, primary = "#226F7F", secondary = "#5C6B70",
    base_font = font_google("Roboto Condensed", wght = c(400, 700)),
    code_font = font_google("Fira Code"),
    "navbar-bg" = "#226F7F", "link-color" = "#C2401F",
    brand = FALSE
  ) |>
    bs_add_rules("
      .r4-section { font-size: .75rem; font-weight: 700; letter-spacing: .06em;
                    text-transform: uppercase; color: $secondary; margin: .25rem 0; }
      .r4-steps { font-size: .85rem; padding-left: 1.1rem; margin-bottom: .25rem; }
      .r4-steps li { margin-bottom: .2rem; }
      .source { display: block; padding: .4rem .55rem; margin-bottom: .35rem;
                border: 1px solid var(--bs-border-color); border-radius: .4rem;
                text-decoration: none; font-size: .85rem; line-height: 1.25; }
      .source:hover { border-color: $primary; background: var(--bs-tertiary-bg); }
      .source .track { display: block; font-size: .72rem; color: $secondary; }
      .source .score { float: right; font-size: .72rem; color: $secondary; }
    "),
  sidebar = sidebar(
    width = 300,
    div(class = "r4-section", "How it works"),
    tags$ol(
      class = "r4-steps",
      tags$li("Your question is matched against ", textOutput("n_chunks", inline = TRUE),
              " excerpts from the R4DEV site with BM25 keyword search."),
      tags$li("The 5 best excerpts go to Claude, with orders to use nothing else."),
      tags$li("The answer cites its lessons. Those same excerpts are listed below.")
    ),
    div(class = "r4-section", "Sources for the last answer"),
    uiOutput("sources"),
    actionButton("new_chat", "New conversation", icon = icon("rotate-left"),
                 class = "btn-outline-secondary btn-sm mt-auto")
  ),
  chat_ui(
    "chat",
    greeting = greeting,
    placeholder = "Ask about any R4DEV lesson…",
    fill = TRUE
  )
)

# ---- server -----------------------------------------------------------------------
server <- function(input, output, session) {

  chat <- ellmer::chat_anthropic(model = "claude-sonnet-5", system_prompt = system_prompt)
  last_hits <- reactiveVal(NULL)

  output$n_chunks <- renderText({
    format(DBI::dbGetQuery(store@con, "SELECT count(*) AS n FROM chunks")$n, big.mark = ",")
  })

  observeEvent(input$chat_user_input, {
    # shinychat >= 0.5 sends a list of content parts (text, attachments): keep the text
    question <- paste(unlist(Filter(is.character, as.list(input$chat_user_input))), collapse = "\n")
    req(nzchar(question))

    hits <- ragnar_retrieve_bm25(store, question, top_k = 5)
    last_hits(hits)

    prompt <- paste0(
      "Question: ", question, "\n\n",
      "Retrieved excerpts:\n\n", build_context(hits)
    )
    chat_append("chat", chat$stream_async(prompt))
  })

  output$sources <- renderUI({
    hits <- last_hits()
    if (is.null(hits)) {
      return(p(class = "small text-muted", "Ask a question to see which excerpts were retrieved."))
    }
    if (nrow(hits) == 0) {
      return(p(class = "small text-muted", "No excerpt matched. The answer can't be grounded."))
    }
    # One entry per page, keeping its best-scoring excerpt
    hits <- hits[order(-hits$metric_value), ]
    hits <- hits[!duplicated(hits$origin), ]
    tagList(lapply(seq_len(nrow(hits)), function(i) {
      tags$a(
        class = "source", href = hits$origin[i], target = "_blank",
        tags$span(class = "score", sprintf("%.1f", hits$metric_value[i])),
        tags$span(class = "track", track_of(hits$origin[i])),
        page_titles[[hits$origin[i]]]
      )
    }))
  })

  observeEvent(input$new_chat, {
    chat$set_turns(list())
    chat_clear("chat")
    chat_append("chat", greeting)
    last_hits(NULL)
  })
}

shinyApp(ui, server)
