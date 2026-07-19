# R4DEV — Collider bias, live
# A teaching tool: story-driven scenarios, three ways of conditioning on a
# collider (none / select / regression control), a DAG that boxes the
# conditioned node and draws the induced non-causal path, and a live
# explanation of what just went wrong.
# Companion to: https://r4dev.netlify.app/sessions_thinking/04-causal/04-causal

library(shiny)
library(bslib)
library(bsicons)
library(dplyr)
library(ggplot2)

# ---- palette (series colors validated for CVD separation; teal #226F7F is UI-only)
COL_HI    <- "#0E8CA8"  # high-Z group
COL_LO    <- "#F75431"  # low-Z group
COL_HI_LN <- "#085A73"  # within-high-Z line
COL_LO_LN <- "#C23A16"  # within-low-Z line
COL_ALL   <- "#1F2937"  # overall (naive) line
COL_BAD   <- "#DC2626"  # induced non-causal association
UI_TEAL   <- "#226F7F"

n_obs <- 800

scenarios <- list(
  sandbox = list(
    label = "Sandbox (abstract X, Y, Z)",
    x_lab = "X", y_lab = "Y", z_lab = "Z",
    xz = 0.7, yz = 0.7, xy_on = FALSE, xy = 0.4,
    story = paste(
      "X and Y each help cause Z — that makes Z a collider on the path X → Z ← Y.",
      "Unless you switch the direct effect on, X and Y are completely unrelated."),
    select_story = paste(
      "You kept only the high-Z units. Within that group, a unit with low X can only",
      "have made the cut through high Y — so X and Y become negatively related,",
      "although neither causes the other."),
    control_story = paste(
      "Putting the collider in the regression compares units with equal Z.",
      "At any fixed level of Z, low X must be compensated by high Y — the same",
      "spurious trade-off as selecting, now hidden inside a coefficient.")
  ),
  hollywood = list(
    label = "Hollywood: talent, looks, fame",
    x_lab = "Talent", y_lab = "Looks", z_lab = "Fame",
    xz = 0.7, yz = 0.7, xy_on = FALSE, xy = 0.4,
    story = paste(
      "Becoming famous takes talent or looks (or luck). In the whole population",
      "of aspiring actors, talent and looks are unrelated."),
    select_story = paste(
      "You are only watching the famous. A star short on talent almost certainly",
      "got there on looks — so among celebrities, talent and looks trade off.",
      "That is why 'beautiful actors can't act' feels true: you never see the",
      "people who had neither."),
    control_story = paste(
      "‘Controlling for fame’ compares equally famous people — and at any given",
      "level of fame, less talent must be offset by better looks. The regression",
      "manufactures the same trade-off selection did.")
  ),
  admissions = list(
    label = "Admissions: math & verbal scores",
    x_lab = "Math score", y_lab = "Verbal score", z_lab = "Admission index",
    xz = 0.7, yz = 0.7, xy_on = FALSE, xy = 0.4,
    story = paste(
      "A selective college admits on the combined score: math + verbal.",
      "In the applicant pool the two scores are unrelated."),
    select_story = paste(
      "You only observe admitted students. Anyone weak in math needed a strong",
      "verbal score to clear the bar — so on campus, math and verbal look",
      "negatively correlated. Berkson (1946) found exactly this in hospital data."),
    control_story = paste(
      "Adding the admission index to the regression compares students with the",
      "same combined score — for whom every extra math point is, by construction,",
      "one verbal point fewer. The negative slope is baked in.")
  )
)

simulate <- function(seed, xy_on, xy, xz, yz) {
  set.seed(seed)
  x <- rnorm(n_obs)
  y <- (if (xy_on) xy else 0) * x + rnorm(n_obs)
  z <- xz * x + yz * y + rnorm(n_obs, sd = 0.6)
  tibble(x, y, z) |>
    mutate(z_group = factor(if_else(z > median(z), "hi", "lo"), levels = c("lo", "hi")))
}

# ---- DAG ---------------------------------------------------------------
dag_plot <- function(sc, xy_on, xy, xz, yz, mode) {
  nodes <- tibble(
    name = c(sc$x_lab, sc$y_lab, sc$z_lab),
    role = c("x", "y", "z"),
    x = c(0, 2, 1), y = c(0, 0, 1.35)
  )
  shrink <- 0.22
  edges <- tibble(
    from = c("x", "y", "x"), to = c("z", "z", "y"),
    alpha = c(xz, yz, if (xy_on) xy else 0),
    active = c(TRUE, TRUE, xy_on)
  ) |>
    filter(active) |>
    left_join(nodes |> select(role, x, y), by = c("from" = "role")) |>
    left_join(nodes |> select(role, x, y), by = c("to" = "role"), suffix = c("", "_end")) |>
    mutate(
      x0 = x, y0 = y, x1 = x_end, y1 = y_end,
      x     = x0 + shrink * (x1 - x0),
      y     = y0 + shrink * (y1 - y0),
      x_end = x1 - shrink * (x1 - x0),
      y_end = y1 - shrink * (y1 - y0)
    )

  conditioned <- mode != "none"
  induced <- conditioned && xz > 0 && yz > 0

  p <- ggplot() +
    geom_segment(
      data = edges,
      aes(x = x, y = y, xend = x_end, yend = y_end, alpha = alpha),
      arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
      color = UI_TEAL, linewidth = 1.1
    ) +
    scale_alpha_continuous(range = c(0.15, 1), limits = c(0, 1), guide = "none")

  if (induced) {
    p <- p +
      annotate("curve", x = 0, y = -0.18, xend = 2, yend = -0.18, curvature = 0.45,
               linetype = "dashed", color = COL_BAD, linewidth = 0.9) +
      annotate("text", x = 1, y = -0.78, label = "association induced by conditioning",
               color = COL_BAD, size = 4.2, fontface = "italic")
  }

  p +
    geom_label(
      data = nodes,
      aes(x, y, label = name),
      size = 6, fontface = "bold", fill = "white",
      color = if_else(nodes$role == "z" & conditioned, COL_BAD, UI_TEAL),
      label.size = if_else(nodes$role == "z" & conditioned, 1.1, 0),
      label.padding = unit(0.35, "lines")
    ) +
    xlim(-0.55, 2.55) + ylim(-0.95, 1.8) +
    theme_void()
}

# ---- UI ----------------------------------------------------------------
ui <- bslib::page_fillable(
  theme = bslib::bs_theme(
    bootswatch = "journal",
    base_font = bslib::font_google("Roboto Condensed"),
    primary = UI_TEAL,
    brand = FALSE
  ),
  padding = "1rem",

  tags$div(
    style = "display:flex; align-items:center; gap:10px; margin-bottom:0.4rem;",
    tags$img(src = "r4dev_logo.png", height = "32px"),
    tags$strong("R4DEV · Collider bias", style = paste0("color:", UI_TEAL, "; font-size:1.1rem;")),
    tags$a(
      "session ↗", href = "https://r4dev.netlify.app/sessions_thinking/04-causal/04-causal.html",
      target = "_blank", style = "margin-left:auto; font-size:0.85rem;"
    )
  ),

  layout_sidebar(
    sidebar = sidebar(
      width = 330,
      selectInput(
        "scenario", "Story",
        choices = setNames(names(scenarios), vapply(scenarios, `[[`, "", "label"))
      ),
      radioButtons(
        "mode", "How do you condition on the collider?",
        choices = c(
          "Not at all (leave Z alone)" = "none",
          "Select: keep only high-Z units" = "select",
          "Control: put Z in the regression" = "control"
        ),
        selected = "none"
      ),
      hr(),
      input_switch("xy_on", "True X → Y effect exists", value = FALSE),
      conditionalPanel(
        "input.xy_on",
        sliderInput("xy", NULL, min = 0, max = 1, value = 0.4, step = 0.05)
      ),
      sliderInput("xz", "X → Z strength", min = 0, max = 1, value = 0.7, step = 0.05),
      sliderInput("yz", "Y → Z strength", min = 0, max = 1, value = 0.7, step = 0.05),
      actionButton("resample", "Draw a new sample", icon = icon("dice"), class = "btn-sm"),
      accordion(
        open = FALSE,
        accordion_panel(
          "Guided tour", icon = bs_icon("signpost"),
          tags$ol(
            style = "font-size:0.83rem; padding-left:1.1rem;",
            tags$li("Start unadjusted: the cloud is round, the slope sits near the true effect (zero)."),
            tags$li("Choose ", tags$em("Select high-Z"), ": a negative slope appears out of nowhere."),
            tags$li("Switch the true X → Y effect on: conditioning now distorts a real effect instead of inventing one."),
            tags$li("Try ", tags$em("Control"), ": putting the collider in the regression is just as bad as selecting on it."),
            tags$li("Draw new samples: the bias never washes out. It is not noise."),
            tags$li("Drag either arrow to 0: the bias disappears — the collider needs both parents.")
          )
        )
      )
    ),

    layout_columns(
      col_widths = c(3, 3, 3, 3),
      fill = FALSE,
      uiOutput("true_box"),
      uiOutput("est_box"),
      uiOutput("bias_box"),
      uiOutput("n_box")
    ),

    uiOutput("explain"),

    layout_columns(
      col_widths = c(5, 7),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("The causal graph", class = "py-1"),
        bslib::card_body(
          class = "d-flex justify-content-center align-items-center p-1",
          plotOutput("dag", height = "300px", width = "100%")
        )
      ),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header(uiOutput("scatter_title", inline = TRUE), class = "py-1"),
        plotOutput("scatter", height = "360px")
      )
    )
  )
)

# ---- server ------------------------------------------------------------
server <- function(input, output, session) {

  sc <- reactive(scenarios[[input$scenario]])

  observeEvent(input$scenario, {
    s <- scenarios[[input$scenario]]
    updateSliderInput(session, "xz", label = sprintf("%s → %s strength", s$x_lab, s$z_lab), value = s$xz)
    updateSliderInput(session, "yz", label = sprintf("%s → %s strength", s$y_lab, s$z_lab), value = s$yz)
    update_switch("xy_on", label = sprintf("True %s → %s effect exists", s$x_lab, s$y_lab), value = s$xy_on)
  })

  seed <- reactiveVal(42)
  observeEvent(input$resample, seed(seed() + 1))

  dat <- reactive(simulate(seed(), input$xy_on, input$xy, input$xz, input$yz))

  true_effect <- reactive(if (input$xy_on) input$xy else 0)

  estimate <- reactive({
    d <- dat()
    switch(input$mode,
      none    = unname(coef(lm(y ~ x, d))["x"]),
      select  = unname(coef(lm(y ~ x, filter(d, z_group == "hi")))["x"]),
      control = unname(coef(lm(y ~ x + z, d))["x"])
    )
  })
  bias <- reactive(estimate() - true_effect())
  n_used <- reactive(if (input$mode == "select") sum(dat()$z_group == "hi") else n_obs)

  # ---- value boxes
  output$true_box <- renderUI({
    value_box(
      title = sprintf("True %s → %s effect", sc()$x_lab, sc()$y_lab),
      value = sprintf("%.2f", true_effect()), theme = "secondary"
    )
  })
  output$est_box <- renderUI({
    value_box(
      title = switch(input$mode,
        none = "Estimated slope (no adjustment)",
        select = sprintf("Slope among high-%s only", sc()$z_lab),
        control = sprintf("Coefficient with %s controlled", sc()$z_lab)),
      value = sprintf("%.2f", estimate()), theme = "primary"
    )
  })
  output$bias_box <- renderUI({
    off <- abs(bias()) > 0.1
    value_box(
      title = "Bias (estimate − truth)",
      value = sprintf("%+.2f", bias()),
      theme = if (off) "danger" else "success",
      showcase = bs_icon(if (off) "exclamation-triangle" else "check-circle")
    )
  })
  output$n_box <- renderUI({
    value_box(
      title = "Observations used",
      value = format(n_used(), big.mark = ","),
      theme = if (input$mode == "select") "warning" else "secondary"
    )
  })

  # ---- dynamic explanation
  output$explain <- renderUI({
    s <- sc()
    body <- switch(input$mode,
      none = tagList(
        tags$p(class = "mb-1", s$story),
        tags$p(class = "mb-0 text-muted",
               sprintf("Nothing is conditioned on %s, so the estimate tracks the truth. Now condition on it and watch.", s$z_lab))
      ),
      select = tagList(
        tags$p(class = "mb-1", s$select_story),
        tags$p(class = "mb-0 text-muted",
               "The dashed red path in the graph is not a causal arrow — it is the association your conditioning created.")
      ),
      control = tagList(
        tags$p(class = "mb-1", s$control_story),
        tags$p(class = "mb-0 text-muted",
               "‘Controlling for more things’ is not automatically safer — controlling for a collider opens a path that was closed.")
      )
    )
    bslib::card(class = "mb-2", style = "flex:none;",
                bslib::card_body(class = "py-2", style = "font-size:0.93rem;", body))
  })

  # ---- DAG
  output$dag <- renderPlot({
    dag_plot(sc(), input$xy_on, input$xy, input$xz, input$yz, input$mode)
  }, res = 110)

  # ---- scatter
  output$scatter_title <- renderUI({
    s <- sc()
    txt <- switch(input$mode,
      none = "Dark line: one regression through everyone",
      select = sprintf("Faded points are discarded · teal dashed line: slope within high-%s", tolower(s$z_lab)),
      control = sprintf("Dashed lines: slope within each half of %s · faint dark line: unadjusted", tolower(s$z_lab))
    )
    tags$span(txt, style = "font-size:0.85rem;")
  })

  output$scatter <- renderPlot({
    d <- dat()
    s <- sc()
    grp_cols <- c(lo = COL_LO, hi = COL_HI)
    grp_labs <- c(lo = sprintf("Low %s", tolower(s$z_lab)), hi = sprintf("High %s", tolower(s$z_lab)))

    kept <- if (input$mode == "select") d$z_group == "hi" else rep(TRUE, nrow(d))
    d$kept <- kept

    p <- ggplot(d, aes(x, y)) +
      geom_point(aes(color = z_group, alpha = kept), size = 2) +
      scale_color_manual(values = grp_cols, labels = grp_labs, name = NULL) +
      scale_alpha_manual(values = c(`TRUE` = 0.75, `FALSE` = 0.10), guide = "none") +
      guides(color = guide_legend(override.aes = list(alpha = 1, size = 3))) +
      labs(x = s$x_lab, y = s$y_lab) +
      theme_minimal(base_size = 15) +
      theme(legend.position = "top", panel.grid.minor = element_blank())

    if (input$mode == "none") {
      p <- p + geom_smooth(method = "lm", se = FALSE, formula = y ~ x,
                           color = COL_ALL, linewidth = 1.2)
    } else if (input$mode == "select") {
      p <- p +
        geom_smooth(method = "lm", se = FALSE, formula = y ~ x,
                    color = COL_ALL, linewidth = 0.8, alpha = 0.5, linetype = "solid") +
        geom_smooth(data = filter(d, z_group == "hi"), method = "lm", se = FALSE,
                    formula = y ~ x, color = COL_HI_LN, linewidth = 1.4, linetype = "dashed")
    } else {
      p <- p +
        geom_smooth(method = "lm", se = FALSE, formula = y ~ x,
                    color = COL_ALL, linewidth = 0.6, alpha = 0.4) +
        geom_smooth(data = filter(d, z_group == "hi"), method = "lm", se = FALSE,
                    formula = y ~ x, color = COL_HI_LN, linewidth = 1.3, linetype = "dashed") +
        geom_smooth(data = filter(d, z_group == "lo"), method = "lm", se = FALSE,
                    formula = y ~ x, color = COL_LO_LN, linewidth = 1.3, linetype = "dashed")
    }
    p
  }, res = 110)
}

shinyApp(ui, server)
