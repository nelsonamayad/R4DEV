# R4DEV — BayesApp: how beliefs update
# Globe tossing (after McElreath's Statistical Rethinking): toss an inflatable
# globe, record whether your finger lands on Water or Land, and update a Beta
# prior into a Beta posterior. Embedded in sessions_thinking/06-bayes.
# Run with: shiny::runApp("shiny/BayesApp")

library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(ggplot2)

# ---- R4DEV look (shared by every app in shiny/) ------------------------------
pal <- list(
  teal = "#226F7F", orange = "#F75431", rust = "#C2401F", slate = "#5C6B70",
  cloud = "#EEF2F3", ink = "#20242A",
  s1 = "#0E8CA8", s2 = "#F75431"   # validated data-series pair (teal is UI-only)
)

r4dev_theme <- bs_theme(
  version = 5, bg = "#FFFFFF", fg = pal$ink,
  primary = pal$teal, secondary = pal$slate, info = pal$s1,
  danger = pal$rust, warning = pal$orange,
  base_font = font_google("Roboto Condensed", wght = c(400, 700)),
  code_font = font_google("Fira Code"),
  "navbar-bg" = pal$teal, "link-color" = pal$rust,
  brand = FALSE
) |>
  bs_add_rules("
    .bslib-value-box .value-box-title { font-size: .85rem; color: $secondary; }
    .bslib-value-box .value-box-value { font-weight: 700; font-size: 1.6rem; margin-bottom: 0; }
    .bslib-value-box .value-box-area { padding: .5rem .75rem; }
    .card-header { font-weight: 700; }
    .sidebar-title, .r4-section { font-size: .78rem; font-weight: 700; letter-spacing: .06em;
                                  text-transform: uppercase; color: $secondary; margin: .4rem 0 .2rem; }
    .r4-note { font-size: .85rem; color: $secondary; }
  ")

theme_r4dev <- function(base_size = 13) {
  theme_minimal(base_size = base_size, base_family = "sans") +
    theme(
      plot.title.position = "plot",
      plot.title = element_text(face = "bold", colour = pal$ink),
      plot.subtitle = element_text(colour = pal$slate),
      axis.title = element_text(colour = pal$slate),
      panel.grid.minor = element_blank(),
      legend.position = "top", legend.justification = "left",
      strip.text = element_text(face = "bold", hjust = 0)
    )
}

app_title <- function(text) {
  tags$span(
    class = "d-flex align-items-center gap-2",
    tags$img(src = "r4dev_logo.png", height = "28px", alt = "R4DEV logo"),
    text
  )
}

# ---- the model -----------------------------------------------------------------
true_p <- 0.71   # share of the Earth's surface covered by water

priors <- list(
  flat      = list(label = "Flat: anything goes",                a = 1,  b = 1),
  sceptic   = list(label = "Sceptic: it's mostly land",          a = 2,  b = 6),
  geographer = list(label = "Geographer: about 70% water",       a = 7,  b = 3),
  stubborn  = list(label = "Stubborn: 50/50 and won't budge",    a = 30, b = 30)
)
prior_choices <- c(
  setNames(names(priors), vapply(priors, `[[`, "", "label")),
  "Custom (use the sliders)" = "custom"
)

pct <- function(x) sprintf("%.0f%%", 100 * x)

# ---- UI ------------------------------------------------------------------------
ui <- page_sidebar(
  title = app_title("BayesApp · how beliefs update"),
  theme = r4dev_theme,
  fillable = TRUE,
  sidebar = sidebar(
    width = 300,
    div(class = "r4-section", "1 · The data"),
    sliderInput("tosses", "Globe tosses", min = 1, max = 100, value = 9, step = 1),
    sliderInput("waters", "…of which landed on water", min = 0, max = 9, value = 6, step = 1),
    div(
      class = "d-flex gap-2",
      actionButton("toss", "Toss once", icon = icon("earth-americas"), class = "btn-primary btn-sm flex-fill"),
      actionButton("reset", "Reset", icon = icon("rotate-left"), class = "btn-outline-secondary btn-sm")
    ),
    div(class = "r4-section", "2 · Your prior"),
    selectInput("preset", NULL, choices = prior_choices, selected = "flat"),
    sliderInput("prior_a", "Belief in water (α)", min = 1, max = 40, value = 1, step = 1),
    sliderInput("prior_b", "Belief in land (β)", min = 1, max = 40, value = 1, step = 1),
    input_switch("show_lik", "Show the data alone (likelihood)", value = TRUE)
  ),

  layout_columns(
    fill = FALSE,
    uiOutput("box_mean"),
    uiOutput("box_ci"),
    uiOutput("box_more")
  ),
  navset_card_underline(
    full_screen = TRUE,
    nav_panel(
      "Prior → posterior",
      plotOutput("update_plot", height = "100%"),
      uiOutput("explain")
    ),
    nav_panel(
      "Predict the next 10 tosses",
      plotOutput("predict_plot", height = "100%"),
      div(class = "r4-note px-2 pb-1",
          "Bayesian predictions carry all your uncertainty about p with them: ",
          "the posterior predictive is wider than any single-p binomial.")
    )
  )
)

# ---- server --------------------------------------------------------------------
server <- function(input, output, session) {

  # Keep the data coherent: you can't see more waters than tosses
  observeEvent(input$tosses, {
    updateSliderInput(session, "waters", max = input$tosses,
                      value = min(input$waters, input$tosses))
  })

  # Toss the globe once: the "real" planet is 71% water
  observeEvent(input$toss, {
    if (input$tosses >= 100) return()
    w <- rbinom(1, 1, true_p)
    updateSliderInput(session, "tosses", value = input$tosses + 1)
    updateSliderInput(session, "waters", max = input$tosses + 1, value = input$waters + w)
    showNotification(if (w == 1) "💧 Water!" else "🏔️ Land!", duration = 1.5)
  })

  observeEvent(input$reset, {
    updateSliderInput(session, "tosses", value = 9)
    updateSliderInput(session, "waters", max = 9, value = 6)
  })

  # Presets move the sliders; moving a slider by hand switches to "custom"
  observeEvent(input$preset, {
    p <- priors[[input$preset]]
    if (is.null(p)) return()
    updateSliderInput(session, "prior_a", value = p$a)
    updateSliderInput(session, "prior_b", value = p$b)
  })
  observeEvent(list(input$prior_a, input$prior_b), {
    p <- priors[[input$preset]]
    if (!is.null(p) && (p$a != input$prior_a || p$b != input$prior_b)) {
      updateSelectInput(session, "preset", selected = "custom")
    }
  }, ignoreInit = TRUE)

  # Conjugate update: Beta(a, b) prior + W waters, L lands -> Beta(a + W, b + L)
  post <- reactive({
    n <- input$tosses
    w <- min(input$waters, n)
    list(n = n, w = w,
         a0 = input$prior_a, b0 = input$prior_b,
         a = input$prior_a + w, b = input$prior_b + n - w)
  })

  output$box_mean <- renderUI({
    p <- post()
    value_box(
      title = "Best guess for p",
      value = pct(p$a / (p$a + p$b)),
      theme = "text-primary", max_height = "92px"
    )
  })
  output$box_ci <- renderUI({
    p <- post()
    value_box(
      title = "89% credible interval",
      value = sprintf("%s – %s", pct(qbeta(0.055, p$a, p$b)), pct(qbeta(0.945, p$a, p$b))),
      theme = "text-primary", max_height = "92px"
    )
  })
  output$box_more <- renderUI({
    p <- post()
    value_box(
      title = "P(more water than land)",
      value = pct(1 - pbeta(0.5, p$a, p$b)),
      theme = "text-primary", max_height = "92px"
    )
  })

  output$update_plot <- renderPlot({
    p <- post()
    grid <- tibble(p_water = seq(0, 1, length.out = 501)) |>
      mutate(
        Prior = dbeta(p_water, p$a0, p$b0),
        `Data alone` = dbeta(p_water, p$w + 1, p$n - p$w + 1),
        Posterior = dbeta(p_water, p$a, p$b)
      )
    lo <- qbeta(0.055, p$a, p$b)
    hi <- qbeta(0.945, p$a, p$b)
    curves <- grid |>
      pivot_longer(-p_water, names_to = "belief", values_to = "density") |>
      mutate(belief = factor(belief, levels = c("Prior", "Posterior", "Data alone")))
    if (!input$show_lik) curves <- filter(curves, belief != "Data alone")
    ymax <- max(curves$density[is.finite(curves$density)]) * 1.08

    ggplot(curves, aes(p_water, density)) +
      geom_area(data = filter(grid, p_water >= lo, p_water <= hi),
                aes(y = Posterior), fill = pal$s1, alpha = 0.22) +
      geom_line(aes(colour = belief, linetype = belief, linewidth = belief)) +
      geom_vline(xintercept = true_p, colour = pal$ink, linewidth = 0.4, linetype = "dotted") +
      annotate("text", x = true_p, y = ymax, label = "true share of water",
               size = 3.6, colour = pal$ink, hjust = -0.05, vjust = 1) +
      scale_colour_manual(values = c(Prior = "grey55", `Data alone` = pal$s2, Posterior = pal$s1)) +
      scale_linetype_manual(values = c(Prior = "solid", `Data alone` = "dashed", Posterior = "solid")) +
      scale_linewidth_manual(values = c(Prior = 0.9, `Data alone` = 0.9, Posterior = 1.6)) +
      scale_x_continuous(labels = scales::label_percent(), breaks = seq(0, 1, 0.25),
                         expand = expansion(mult = 0.01)) +
      scale_y_continuous(limits = c(0, ymax * 1.04), expand = expansion(mult = c(0, 0))) +
      labs(
        title = sprintf("After %d water%s in %d toss%s", p$w, if (p$w == 1) "" else "s",
                        p$n, if (p$n == 1) "" else "es"),
        subtitle = "Shaded: the 89% most plausible values of p, given prior and data",
        x = "Proportion of the globe covered by water (p)", y = "Plausibility",
        colour = NULL, linetype = NULL, linewidth = NULL
      ) +
      theme_r4dev() +
      theme(axis.text.y = element_blank(), panel.grid.major.y = element_blank())
  }, res = 96)

  output$explain <- renderUI({
    p <- post()
    pseudo <- p$a0 + p$b0 - 2
    msg <- if (pseudo == 0) {
      "Your flat prior adds no pseudo-tosses: the posterior is shaped by the data alone."
    } else {
      sprintf(
        "Your prior is worth about %d imaginary tosses; the data are %d real ones. %s",
        pseudo, p$n,
        if (pseudo > p$n) "The prior is still in charge. Toss more and watch the data take over."
        else "The data now outweigh the prior."
      )
    }
    div(class = "r4-note px-2 pb-1", msg)
  })

  output$predict_plot <- renderPlot({
    p <- post()
    k <- 0:10
    # Beta-binomial: average the binomial over every plausible p
    bb <- function(a, b) choose(10, k) * beta(k + a, 10 - k + b) / beta(a, b)
    tibble(k = k,
           Prior = bb(p$a0, p$b0),
           Posterior = bb(p$a, p$b)) |>
      pivot_longer(-k, names_to = "belief", values_to = "prob") |>
      mutate(belief = factor(belief, levels = c("Prior", "Posterior"))) |>
      ggplot(aes(factor(k), prob, fill = belief)) +
      geom_col(position = position_dodge(width = 0.8), width = 0.75) +
      scale_fill_manual(values = c(Prior = "grey75", Posterior = pal$s1)) +
      scale_y_continuous(labels = scales::label_percent(), expand = expansion(mult = c(0, 0.05))) +
      labs(title = "How many waters in the next 10 tosses?",
           subtitle = "Before the data (prior) and after it (posterior)",
           x = "Waters in the next 10 tosses", y = NULL, fill = NULL) +
      theme_r4dev() +
      theme(panel.grid.major.x = element_blank())
  }, res = 96)
}

shinyApp(ui, server)
