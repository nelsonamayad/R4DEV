# R4DEV — Chat with your data (querychat), the deployed version
# Embedded in sessions_ai/02-llm-apps. Students run the one-liner
# querychat_app() from r4dev-querychat-app.R; this file is what that wrapper
# looks like when you build the layout yourself.
#
# Deployed demo runs on Claude via an ANTHROPIC_API_KEY set as a Connect Cloud
# environment variable -- never read from or printed into any code, log, or
# page on this site. Students following the lesson at home use their own
# GEMINI_API_KEY as taught: swap chat_anthropic() for chat_google_gemini().
#
# Why not querychat_app() here? Its $app() calls shiny::runGadget(), built
# for interactive local use: it binds its own ad-hoc port, so a host's
# start-up health check times out. The modular QueryChat$new() +
# qc$sidebar()/qc$server() pattern below builds an ordinary shinyApp().

library(shiny)
library(bslib)
library(querychat)
library(DT)
library(RSQLite) # querychat's DataFrameSource needs a database engine at runtime
library(plotly)
library(dplyr)

# Data: the CSV lives alongside app.R so the deployed bundle is self-contained
songs <- readr::read_csv("spotify_favorites_archive.csv", show_col_types = FALSE)

# One colour per artist (Okabe-Ito, colour-blind safe), fixed across queries
artists <- sort(unique(songs$artist))
artist_cols <- setNames(
  c("#E69F00", "#56B4E9", "#009E73", "#D55E00", "#0072B2", "#CC79A7", "#5C6B70", "#B8860B"),
  artists
)

greeting <- paste(
  "👋 Ask me anything about these **1,178 songs** by 8 artists, in plain language.",
  "I'll write the SQL, filter the table and chart, and show you the query so you can check my work.",
  "",
  "Try one of these:",
  "",
  "* <span class=\"suggestion\">Show only Florence + The Machine</span>",
  "* <span class=\"suggestion\">Find the five angriest songs: low valence, high energy</span>",
  "* <span class=\"suggestion\">Which artist has the happiest songs on average?</span>",
  "* <span class=\"suggestion\">Songs from albums with 'live' in the title</span>",
  sep = "\n"
)

qc <- QueryChat$new(
  songs,
  table_name = "songs",
  client = ellmer::chat_anthropic(model = "claude-sonnet-5"),
  greeting = greeting,
  data_description = paste(
    "One row per song from the discographies of 8 artists,",
    "with Spotify audio features saved before the API closed in 2024.",
    "valence (musical positiveness) and energy (intensity) run from 0 to 1.",
    "cover_url holds the album cover image address."
  )
)

# ---- R4DEV look --------------------------------------------------------------------
r4dev_theme <- bs_theme(
  version = 5, primary = "#226F7F", secondary = "#5C6B70", danger = "#C2401F",
  base_font = font_google("Roboto Condensed", wght = c(400, 700)),
  code_font = font_google("Fira Code"),
  "navbar-bg" = "#226F7F",
  brand = FALSE
) |>
  bs_add_rules("
    .bslib-value-box .value-box-title { font-size: .85rem; }
    .bslib-value-box .value-box-value { font-weight: 700; font-size: 1.6rem; }
    .bslib-grid > * { min-width: 0; }
    .sql-box pre { margin: 0; white-space: pre-wrap; font-size: .8rem; max-height: 6.5em; overflow-y: auto;
                   background: var(--bs-tertiary-bg); padding: .5rem .75rem; border-radius: .4rem; }
    table.dataTable { font-size: .85rem; }
    table.dataTable img { border-radius: 3px; }
  ")

ui <- page_sidebar(
  title = tags$span(
    class = "d-flex align-items-center gap-2",
    tags$img(src = "r4dev_logo.png", height = "28px", alt = "R4DEV logo"),
    "Chat with your data · 1,178 songs"
  ),
  theme = r4dev_theme,
  sidebar = qc$sidebar(width = 360),

  layout_columns(
    fill = FALSE,
    value_box("Songs shown", textOutput("n_songs"), theme = "primary", max_height = "95px"),
    value_box("Artists", textOutput("n_artists"), max_height = "95px"),
    value_box("Avg. valence", textOutput("valence"), max_height = "95px"),
    value_box("Avg. energy", textOutput("energy"), max_height = "95px")
  ),
  card(
    fill = FALSE, class = "sql-box",
    card_header(textOutput("query_title", inline = TRUE)),
    card_body(class = "py-2", uiOutput("sql"))
  ),
  navset_card_underline(
    full_screen = TRUE,
    nav_panel("Mood map", plotlyOutput("mood")),
    nav_panel("Table", DTOutput("table"))
  )
)

server <- function(input, output, session) {
  qc_vals <- qc$server()

  shown <- reactive(qc_vals$df())

  output$n_songs <- renderText(format(nrow(shown()), big.mark = ","))
  output$n_artists <- renderText({
    if ("artist" %in% names(shown())) length(unique(shown()$artist)) else "—"
  })
  output$valence <- renderText({
    if ("valence" %in% names(shown()) && nrow(shown()) > 0) sprintf("%.2f", mean(shown()$valence)) else "—"
  })
  output$energy <- renderText({
    if ("energy" %in% names(shown()) && nrow(shown()) > 0) sprintf("%.2f", mean(shown()$energy)) else "—"
  })

  output$query_title <- renderText({
    title <- qc_vals$title()
    if (is.null(title) || !nzchar(title)) "All songs (no filter yet)" else title
  })
  output$sql <- renderUI({
    sql <- qc_vals$sql()
    if (is.null(sql) || !nzchar(sql)) sql <- "SELECT * FROM songs"
    HTML(sprintf("<pre><code>%s</code></pre>", htmltools::htmlEscape(sql)))
  })

  # Energy against valence: every song in grey, the current result in colour
  output$mood <- renderPlotly({
    d <- shown()
    validate(need(all(c("valence", "energy") %in% names(d)),
                  "This query returns a summary, not songs: see the Table tab."))
    p <- plot_ly(colors = artist_cols) |>
      add_markers(data = songs, x = ~valence, y = ~energy,
                  marker = list(color = "rgba(150,160,165,0.25)", size = 6),
                  hoverinfo = "skip", showlegend = FALSE)
    if (nrow(d) > 0 && "artist" %in% names(d)) {
      p <- p |>
        add_markers(data = d, x = ~valence, y = ~energy, color = ~artist,
                    marker = list(size = 11, opacity = 0.9, line = list(width = 1, color = "#FFFFFF")),
                    text = ~paste0("<b>", track_name, "</b><br>", artist, " · ", album_name),
                    hoverinfo = "text")
    }
    p |>
      layout(
        xaxis = list(title = "Valence (sad → happy)", range = c(-0.02, 1.02), zeroline = FALSE),
        yaxis = list(title = "Energy (calm → intense)", range = c(-0.02, 1.02), zeroline = FALSE),
        legend = list(font = list(size = 11)),
        shapes = list(
          list(type = "line", x0 = 0.5, x1 = 0.5, y0 = 0, y1 = 1, line = list(dash = "dot", color = "#9CA3AF", width = 1)),
          list(type = "line", x0 = 0, x1 = 1, y0 = 0.5, y1 = 0.5, line = list(dash = "dot", color = "#9CA3AF", width = 1))
        ),
        annotations = lapply(
          list(list(0.25, 0.75, "angry · tense"), list(0.75, 0.75, "happy · euphoric"),
               list(0.25, 0.25, "sad · depressed"), list(0.75, 0.25, "calm · content")),
          function(a) list(x = a[[1]], y = a[[2]], text = a[[3]], showarrow = FALSE,
                           font = list(size = 15, color = "rgba(92,107,112,0.55)"))
        ),
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
        margin = list(t = 10)
      ) |>
      config(displaylogo = FALSE)
  })

  output$table <- renderDT({
    d <- shown()
    if ("cover_url" %in% names(d)) {
      d <- d |>
        mutate(cover = sprintf('<img src="%s" height="36" alt="">', cover_url), .before = 1) |>
        select(-cover_url)
    }
    datatable(
      d, escape = FALSE, rownames = FALSE, style = "bootstrap5",
      class = "compact hover",
      options = list(pageLength = 8, scrollX = TRUE, dom = "ftip")
    ) |>
      formatRound(intersect(c("valence", "energy"), names(d)), 2)
  })
}

shinyApp(ui, server)
