# R4DEV — BayesApp: globe-tossing prior/posterior simulator
# Run with: shiny::runApp("shiny/BayesApp")

library(shiny)
library(bslib)
library(tidyverse)

ui <- bslib::page_sidebar(
  theme = bslib::bs_theme(bootswatch = "journal"),
  title = tags$span(
    tags$img(src = "r4dev_logo.png", height = "28px", style = "margin-right:8px; vertical-align:middle;"),
    "BayesApp 🌍 — how beliefs update"
  ),
  sidebar = bslib::sidebar(
    sliderInput("waters", "Waters observed (W)", min = 0, max = 100, value = 6),
    sliderInput("tosses", "Total tosses", min = 1, max = 100, value = 9),
    sliderInput("prior_a", "Prior: shape towards water (alpha)", min = 1, max = 30, value = 1, step = 1),
    sliderInput("prior_b", "Prior: shape towards land (beta)", min = 1, max = 30, value = 1, step = 1),
    helpText("alpha = beta = 1 is the flat prior. Larger values encode stronger opinions.")
  ),
  bslib::card(plotOutput("update_plot", height = "420px"))
)

server <- function(input, output, session) {

  output$update_plot <- renderPlot({
    w <- min(input$waters, input$tosses)

    tibble(p = seq(0, 1, length.out = 400)) |>
      dplyr::mutate(
        Prior     = dbeta(p, input$prior_a, input$prior_b),
        Posterior = dbeta(p, input$prior_a + w, input$prior_b + input$tosses - w)
      ) |>
      tidyr::pivot_longer(c(Prior, Posterior), names_to = "belief", values_to = "density") |>
      dplyr::mutate(belief = factor(belief, levels = c("Prior", "Posterior"))) |>
      ggplot(aes(x = p, y = density, fill = belief)) +
      geom_area(alpha = 0.55, position = "identity") +
      geom_vline(xintercept = 0.71, linetype = "dashed", color = "#F75431") +
      scale_fill_manual(values = c(Prior = "grey65", Posterior = "#226F7F")) +
      labs(
        title = sprintf("After %d waters in %d tosses", w, input$tosses),
        subtitle = "Dashed line: the Earth's true proportion of water",
        x = "Proportion of water (p)", y = NULL, fill = NULL
      ) +
      theme_classic(base_size = 15) +
      theme(legend.position = "top")
  })
}

shinyApp(ui, server)
