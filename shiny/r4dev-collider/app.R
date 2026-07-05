# R4DEV — Collider bias, live
# Style/feature reference: https://dags.andrewheiss.com/colliders.html
# Three strength sliders, a toggleable direct effect, a live DAG with
# opacity-coded arrows, a stats readout, and a scatter plot showing the
# overall regression line against the stratified (adjusted-for-Z) one.

library(shiny)
library(bslib)
library(tidyverse)
library(broom)

n <- 600

simulate <- function(xy_exists, xy_strength, xz_strength, yz_strength) {
  set.seed(42)
  x <- rnorm(n)
  y <- (if (xy_exists) xy_strength else 0) * x + rnorm(n) # <1>
  z <- xz_strength * x + yz_strength * y + rnorm(n, sd = 0.6) # <2>

  tibble(x, y, z) |>
    mutate(
      z_group = if_else(z > median(z), "High Z", "Low Z") |> # <3>
        factor(levels = c("Low Z", "High Z"))
    )
}

dag_plot <- function(xy_exists, xy_strength, xz_strength, yz_strength, adjust_z) {
  nodes <- tibble(name = c("X", "Y", "Z"), x = c(0, 2, 1), y = c(0, 0, 1.4))
  shrink <- 0.22 # fraction to pull each segment endpoint back, so arrowheads clear the node labels
  edges <- tibble(
    from = c("X", "Y", "X"), to = c("Z", "Z", "Y"),
    alpha = c(xz_strength, yz_strength, if (xy_exists) xy_strength else 0),
    active = c(TRUE, TRUE, xy_exists)
  ) |>
    filter(active) |>
    left_join(nodes, by = c("from" = "name")) |>
    left_join(nodes, by = c("to" = "name"), suffix = c("", "_end")) |>
    mutate(
      x0 = x, y0 = y, x1 = x_end, y1 = y_end,
      x    = x0 + shrink * (x1 - x0),
      y    = y0 + shrink * (y1 - y0),
      x_end = x1 - shrink * (x1 - x0),
      y_end = y1 - shrink * (y1 - y0)
    )

  p <- ggplot()
  if (adjust_z) {
    p <- p + annotate("rect", xmin = -0.55, xmax = 2.55, ymin = -0.55, ymax = 0.55,
                       fill = "#F75431", alpha = 0.12, color = "#F75431", linewidth = 0.6, linetype = "dashed")
  }
  p +
    geom_segment(
      data = edges,
      aes(x = x, y = y, xend = x_end, yend = y_end, alpha = alpha),
      arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
      color = "#226F7F", linewidth = 1.1
    ) +
    geom_label(data = nodes, aes(x, y, label = name), size = 7, fontface = "bold",
               linewidth = 0, fill = "white", color = "#226F7F") +
    scale_alpha_continuous(range = c(0.15, 1), limits = c(0, 1), guide = "none") +
    xlim(-0.7, 2.7) + ylim(-0.7, 1.9) +
    theme_void()
}

ui <- bslib::page_fillable(
  theme = bslib::bs_theme(
    bootswatch = "journal",
    base_font = bslib::font_google("Roboto Condensed"),
    primary = "#226F7F",
    brand = FALSE
  ),
  padding = "1.5rem",

  tags$div(
    style = "display:flex; align-items:center; gap:10px; margin-bottom:0.5rem;",
    tags$img(src = "r4dev_logo.png", height = "32px"),
    tags$strong("R4DEV", style = "color:#226F7F; font-size:1.1rem;")
  ),

  layout_sidebar(
    sidebar = sidebar(
      width = 320,
      h5("Collider bias"),
      p(class = "text-muted", style = "font-size:0.85rem;",
        "Z is a collider: caused by both X and Y. Conditioning on it can invent a correlation between X and Y even when none exists."),
      hr(),
      input_switch("xy_exists", "X → Y direct effect exists", value = FALSE),
      sliderInput("xy_strength", "X → Y strength", min = 0, max = 1, value = 0.3, step = 0.05),
      sliderInput("xz_strength", "X → Z strength", min = 0, max = 1, value = 0.5, step = 0.05),
      sliderInput("yz_strength", "Y → Z strength", min = 0, max = 1, value = 0.5, step = 0.05),
      hr(),
      input_switch("adjust_z", "Adjust for Z (stratify)", value = FALSE)
    ),

    layout_columns(
      col_widths = c(3, 3, 3, 3),
      uiOutput("true_box"),
      uiOutput("overall_box"),
      uiOutput("conditional_box"),
      uiOutput("bias_box")
    ),

    layout_columns(
      col_widths = c(5, 7),
      bslib::card(
        full_screen = TRUE,
        bslib::card_body(
          class = "d-flex justify-content-center align-items-center",
          plotOutput("dag", height = "340px", width = "100%")
        )
      ),
      bslib::card(
        full_screen = TRUE,
        plotOutput("scatter", height = "420px")
      )
    )
  )
)

server <- function(input, output, session) {

  dat <- reactive({
    simulate(input$xy_exists, input$xy_strength, input$xz_strength, input$yz_strength)
  })

  true_effect <- reactive(if (input$xy_exists) input$xy_strength else 0)
  overall_slope <- reactive(broom::tidy(lm(y ~ x, data = dat())) |> filter(term == "x") |> pull(estimate))
  conditional_slope <- reactive({
    d <- dat() |> filter(z_group == "High Z")
    broom::tidy(lm(y ~ x, data = d)) |> filter(term == "x") |> pull(estimate)
  })
  shown_slope <- reactive(if (input$adjust_z) conditional_slope() else overall_slope())
  bias <- reactive(shown_slope() - true_effect())
  n_selected <- reactive(if (input$adjust_z) sum(dat()$z_group == "High Z") else nrow(dat()))

  output$dag <- renderPlot({
    dag_plot(input$xy_exists, input$xy_strength, input$xz_strength, input$yz_strength, input$adjust_z)
  }, res = 110)

  output$true_box <- renderUI({
    bslib::value_box(title = "True X → Y effect", value = round(true_effect(), 2), theme = "secondary")
  })
  output$overall_box <- renderUI({
    bslib::value_box(title = "Overall slope (unadjusted)", value = round(overall_slope(), 2),
                      theme = if (input$adjust_z) "secondary" else "primary")
  })
  output$conditional_box <- renderUI({
    bslib::value_box(title = "Slope within High Z", value = round(conditional_slope(), 2),
                      theme = if (input$adjust_z) "primary" else "secondary")
  })
  output$bias_box <- renderUI({
    bslib::value_box(
      title = "Bias (shown slope − truth)",
      value = round(bias(), 2),
      theme = if (abs(bias()) > 0.15) "danger" else "success",
      showcase = bsicons::bs_icon(if (abs(bias()) > 0.15) "exclamation-triangle" else "check-circle")
    )
  })

  output$scatter <- renderPlot({
    d <- dat() |> mutate(included = if (input$adjust_z) z_group == "High Z" else TRUE)

    p <- d |>
      ggplot(aes(x, y)) +
      geom_point(aes(color = z_group, alpha = included), size = 2.2) +
      geom_smooth(method = "lm", se = FALSE, color = "grey40", linewidth = 1, linetype = "solid") +
      scale_color_manual(values = c("Low Z" = "#F2C078", "High Z" = "#8C4A2F"), name = "Z group") +
      scale_alpha_manual(values = c(`TRUE` = 0.9, `FALSE` = 0.15), guide = "none") +
      labs(
        title = if (input$adjust_z) "Solid: overall slope. Dashed: slope within High Z only" else "Solid: overall regression line (no adjustment)",
        x = "X", y = "Y"
      ) +
      theme_minimal(base_size = 15) +
      theme(plot.title = element_text(color = "grey30"), legend.position = "top")

    if (input$adjust_z) {
      p <- p + geom_smooth(data = d |> filter(z_group == "High Z"), method = "lm", se = FALSE,
                            color = "#F75431", linewidth = 1.3, linetype = "dashed")
    }
    p
  }, res = 110)
}

shinyApp(ui, server)
