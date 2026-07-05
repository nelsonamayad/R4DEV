# R4DEV — Omitted Variable Bias, live
# Style reference: https://rpsychologist.com/descriptive-adjustment/
# Live-reactive sliders (no submit button), one plot, the bias front and center.

library(shiny)
library(bslib)
library(tidyverse)
library(broom)

ui <- bslib::page_fillable(
  theme = bslib::bs_theme(
    bootswatch = "journal",
    base_font = bslib::font_google("Roboto Condensed"),
    primary = "#226F7F"
  ),
  padding = "1.5rem",

  tags$div(
    style = "display:flex; align-items:center; gap:10px; margin-bottom:0.5rem;",
    tags$img(src = "r4dev_logo.png", height = "32px"),
    tags$strong("R4DEV", style = "color:#226F7F; font-size:1.1rem;")
  ),

  layout_sidebar(
    sidebar = sidebar(
      width = 300,
      h5("Omitted variable bias"),
      p(class = "text-muted",
        "Y is truly caused by both X and the omitted variable Z; X and Z are correlated. Drag the sliders and watch the short regression (Y ~ X alone) drift away from the truth."),
      sliderInput("alpha_in", "True effect of X on Y (α)", value = 1, min = -5, max = 5, step = 0.5),
      sliderInput("beta_in", "Effect of the omitted Z on Y (β)", value = -1, min = -5, max = 5, step = 0.5),
      sliderInput("gamma_in", "Correlation of X with Z (γ)", value = 0.5, min = -2, max = 2, step = 0.1)
    ),
    layout_columns(
      col_widths = c(4, 4, 4),
      uiOutput("bias_box"),
      uiOutput("short_box"),
      uiOutput("long_box")
    ),
    bslib::card(
      full_screen = TRUE,
      plotOutput("scatter", height = "420px")
    )
  )
)

server <- function(input, output, session) {

  fake_data <- reactive({
    set.seed(123)
    n <- 2000
    tibble(
      e_x = rnorm(n, mean = 0, sd = 1),
      e_y = rnorm(n, mean = 0, sd = 1), # independent of e_x: X and Y don't share noise
      z = rnorm(n, mean = 3, sd = 10),
      x = 10 + input$gamma_in * z + e_x,
      y = 20 + input$alpha_in * x + input$beta_in * z + e_y
    )
  })

  models <- reactive({
    d <- fake_data()
    list(
      short = lm(y ~ x, data = d),
      long  = lm(y ~ x + z, data = d)
    )
  })

  b_short <- reactive(broom::tidy(models()$short) |> filter(term == "x") |> pull(estimate))
  b_long  <- reactive(broom::tidy(models()$long)  |> filter(term == "x") |> pull(estimate))
  bias    <- reactive(round(b_short() - b_long(), 2))

  output$bias_box <- renderUI({
    bslib::value_box(
      title = "OVB = short − long",
      value = bias(),
      theme = if (abs(bias()) < 0.3) "success" else "danger",
      showcase = bsicons::bs_icon("exclamation-diamond")
    )
  })
  output$short_box <- renderUI({
    bslib::value_box(title = "Short: Y ~ X", value = round(b_short(), 2), theme = "secondary")
  })
  output$long_box <- renderUI({
    bslib::value_box(title = "Long: Y ~ X + Z (truth)", value = round(b_long(), 2), theme = "primary")
  })

  output$scatter <- renderPlot({
    d <- fake_data()
    d |>
      ggplot(aes(x = x, y = y)) +
      geom_point(alpha = 0.15, color = "grey50") +
      geom_smooth(method = "lm", se = FALSE, color = "#F75431", linewidth = 1.3) +
      annotate("text", x = min(d$x), y = max(d$y), hjust = 0, vjust = 1,
               label = sprintf("Short regression slope shown: %.2f  (true α = %.2f)", b_short(), input$alpha_in),
               color = "grey30", size = 4.5) +
      labs(title = "Y vs X, with the (biased) short regression line", x = "X", y = "Y") +
      theme_minimal(base_size = 15) +
      theme(plot.title = element_text(color = "grey30"))
  }, res = 110)
}

shinyApp(ui, server)
