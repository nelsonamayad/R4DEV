# R4DEV — Omitted variable bias, live
# A teaching tool: story-driven scenarios with signed effects, the exact OVB
# identity (naive − adjusted = β̂ × δ̂) computed live from the data, a
# Z-gradient scatter that makes the confounding visible, the first-stage
# regression, the classic sign-of-bias 2×2, and a DAG whose omitted node is
# literally grayed out.
# Companion to: https://nelsonamayad.github.io/R4DEV/sessions_thinking/04-causal/04-causal

library(shiny)
library(bslib)
library(bsicons)
library(dplyr)
library(ggplot2)

# ---- palette (validated series pair; teal #226F7F is UI-only)
COL_NAIVE  <- "#F75431"  # short (biased) regression
COL_LONG   <- "#0B4A5E"  # long-model lines / dark end of the Z ramp
COL_Z_LOW  <- "#D7EEF4"  # light end of the Z ramp
COL_GHOST  <- "#9CA3AF"  # omitted node / edges
UI_TEAL    <- "#226F7F"

n_obs <- 1200

scenarios <- list(
  sandbox = list(
    label = "Sandbox (abstract X, Y, Z)",
    x_lab = "X", y_lab = "Y", z_lab = "Z",
    alpha = 0.5, beta = 0.6, delta = 0.6,
    story = paste(
      "Z causes both X and Y, but your regression only sees X. Whatever Z",
      "contributes to Y gets billed to X — that is omitted variable bias."),
    control_story = paste(
      "With Z in the model you compare units at the same level of Z, so X's",
      "coefficient no longer absorbs Z's work. The back door is closed.")
  ),
  schooling = list(
    label = "Wages: schooling & ability",
    x_lab = "Years of schooling", y_lab = "Wage", z_lab = "Ability",
    alpha = 0.4, beta = 0.6, delta = 0.6,
    story = paste(
      "Able people earn more at any education level, and they also stay in",
      "school longer. A naive wage-on-schooling regression hands ability's",
      "paycheck to schooling — the classic overstated 'return to education'."),
    control_story = paste(
      "Holding ability fixed, the schooling coefficient falls back toward its",
      "true value. (In real data you can't measure ability directly — which is",
      "why economists invented instruments, twins studies and panel tricks.)")
  ),
  coffee = list(
    label = "Coffee & heart disease",
    x_lab = "Cups of coffee / day", y_lab = "Heart disease risk", z_lab = "Smoking",
    alpha = 0, beta = 0.7, delta = 0.6,
    story = paste(
      "Here coffee does nothing at all (true effect = 0). But smokers drink",
      "more coffee, and smoking damages the heart — so coffee inherits",
      "smoking's harm and looks dangerous. Early epidemiology fell for",
      "exactly this."),
    control_story = paste(
      "Once smoking is measured and controlled, coffee's coefficient collapses",
      "to zero. The 'effect' was never coffee's — it was smoking's, riding in",
      "on the correlation.")
  ),
  classsize = list(
    label = "Class size & test scores",
    x_lab = "Class size", y_lab = "Test scores", z_lab = "District wealth",
    alpha = -0.2, beta = 0.7, delta = -0.6,
    story = paste(
      "Small classes help a little (true effect −0.2). Wealthy districts buy",
      "smaller classes AND higher scores through a dozen other channels.",
      "Because δ is negative, the bias is negative too: naive comparisons",
      "make class size look far more harmful than it is."),
    control_story = paste(
      "Comparing districts of equal wealth, the class-size coefficient shrinks",
      "back to its modest true value. Sign logic: β > 0 and δ < 0 make the",
      "product — the bias — negative.")
  )
)

simulate <- function(seed, alpha, beta, delta) {
  set.seed(seed)
  z <- rnorm(n_obs)
  x <- delta * z + rnorm(n_obs, sd = sqrt(max(1 - delta^2, 0.05)))
  y <- alpha * x + beta * z + rnorm(n_obs)
  tibble(x, y, z)
}

# ---- DAG ---------------------------------------------------------------
dag_plot <- function(sc, alpha, beta, delta, controlled) {
  nodes <- tibble(
    name = c(sc$x_lab, sc$y_lab, sc$z_lab),
    role = c("x", "y", "z"),
    x = c(0, 2, 1), y = c(0, 0, 1.35)
  )
  shrink <- 0.24
  edges <- tibble(
    from = c("z", "z", "x"), to = c("x", "y", "y"),
    coef = c(delta, beta, alpha),
    ghost = c(!controlled, !controlled, FALSE)
  ) |>
    left_join(nodes |> select(role, x, y), by = c("from" = "role")) |>
    left_join(nodes |> select(role, x, y), by = c("to" = "role"), suffix = c("", "_end")) |>
    mutate(
      x0 = x, y0 = y, x1 = x_end, y1 = y_end,
      x     = x0 + shrink * (x1 - x0),
      y     = y0 + shrink * (y1 - y0),
      x_end = x1 - shrink * (x1 - x0),
      y_end = y1 - shrink * (y1 - y0),
      mx = (x0 + x1) / 2, my = (y0 + y1) / 2
    )

  ggplot() +
    geom_segment(
      data = edges,
      aes(x = x, y = y, xend = x_end, yend = y_end,
          alpha = pmax(abs(coef), 0.12), linetype = ghost, color = ghost),
      arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
      linewidth = 1.1
    ) +
    geom_text(
      data = edges,
      aes(x = mx, y = my + if_else(from == "x", -0.22, 0.16), label = sprintf("%+.1f", coef)),
      color = "grey40", size = 4.4
    ) +
    scale_alpha_identity() +
    scale_linetype_manual(values = c(`FALSE` = "solid", `TRUE` = "dashed"), guide = "none") +
    scale_color_manual(values = c(`FALSE` = UI_TEAL, `TRUE` = COL_GHOST), guide = "none") +
    geom_label(
      data = nodes,
      aes(x, y, label = if_else(role == "z" & !controlled, paste0(name, "\n(unobserved)"), name)),
      size = 5.4, fontface = "bold", fill = "white", lineheight = 0.9,
      color = if_else(nodes$role == "z" & !controlled, COL_GHOST, UI_TEAL),
      label.size = case_when(
        nodes$role == "z" & controlled ~ 1.1,
        nodes$role == "z" ~ 0.25,
        .default = 0
      ),
      label.padding = unit(0.32, "lines")
    ) +
    xlim(-0.55, 2.55) + ylim(-0.55, 1.85) +
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
    tags$strong("R4DEV · Omitted variable bias", style = paste0("color:", UI_TEAL, "; font-size:1.1rem;")),
    tags$a(
      "session ↗", href = "https://nelsonamayad.github.io/R4DEV/sessions_thinking/04-causal/04-causal.html",
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
      sliderInput("alpha", "True effect of X on Y (α)", min = -1, max = 1, value = 0.5, step = 0.1),
      sliderInput("beta", "Effect of Z on Y (β)", min = -1, max = 1, value = 0.6, step = 0.1),
      sliderInput("delta", "How strongly Z sorts into X (δ)", min = -0.9, max = 0.9, value = 0.6, step = 0.1),
      input_switch("controlled", "Control for Z (long regression)", value = FALSE),
      actionButton("resample", "Draw a new sample", icon = icon("dice"), class = "btn-sm"),
      accordion(
        open = FALSE,
        accordion_panel(
          "Guided tour", icon = bs_icon("signpost"),
          tags$ol(
            style = "font-size:0.83rem; padding-left:1.1rem;",
            tags$li("Look at the point colors: dark points (high Z) sit to one side of X AND higher in Y. That double role is the whole problem."),
            tags$li("Check the identity card: the bias you observe equals β̂ × δ̂ exactly — not approximately."),
            tags$li("Set δ to 0: Z still causes Y, but with no sorting into X there is no bias."),
            tags$li("Set β to 0: Z sorts into X but doesn't touch Y — again no bias. It takes both."),
            tags$li("Pick the coffee story: a pure phantom effect, invented by the omitted variable."),
            tags$li("Pick class size: flip δ negative and watch the bias flip sign with it."),
            tags$li("Switch on the control and see the parallel lines: the adjusted slope is the slope at any fixed level of Z.")
          )
        )
      )
    ),

    layout_columns(
      col_widths = c(3, 3, 3, 3),
      fill = FALSE,
      uiOutput("true_box"),
      uiOutput("short_box"),
      uiOutput("long_box"),
      uiOutput("bias_box")
    ),

    uiOutput("identity_card"),
    uiOutput("explain"),

    layout_columns(
      col_widths = c(5, 7),
      tagList(
        bslib::card(
          full_screen = TRUE,
          bslib::card_header("The causal graph", class = "py-1"),
          bslib::card_body(
            class = "d-flex justify-content-center align-items-center p-1",
            plotOutput("dag", height = "250px", width = "100%")
          )
        ),
        bslib::card(
          bslib::card_header("Which way does the bias go?", class = "py-1"),
          bslib::card_body(class = "p-2", uiOutput("sign_table"))
        )
      ),
      tagList(
        bslib::card(
          full_screen = TRUE,
          bslib::card_header(uiOutput("scatter_title", inline = TRUE), class = "py-1"),
          plotOutput("scatter", height = "330px")
        ),
        bslib::card(
          full_screen = TRUE,
          bslib::card_header(uiOutput("fs_title", inline = TRUE), class = "py-1"),
          plotOutput("first_stage", height = "170px")
        )
      )
    )
  )
)

# ---- server ------------------------------------------------------------
server <- function(input, output, session) {

  sc <- reactive(scenarios[[input$scenario]])

  observeEvent(input$scenario, {
    s <- scenarios[[input$scenario]]
    updateSliderInput(session, "alpha", label = sprintf("True effect of %s on %s (α)", s$x_lab, s$y_lab), value = s$alpha)
    updateSliderInput(session, "beta",  label = sprintf("Effect of %s on %s (β)", s$z_lab, s$y_lab), value = s$beta)
    updateSliderInput(session, "delta", label = sprintf("How strongly %s sorts into %s (δ)", s$z_lab, s$x_lab), value = s$delta)
  })

  seed <- reactiveVal(123)
  observeEvent(input$resample, seed(seed() + 1))

  dat <- reactive(simulate(seed(), input$alpha, input$beta, input$delta))

  fits <- reactive({
    d <- dat()
    long <- lm(y ~ x + z, d)
    list(
      short = unname(coef(lm(y ~ x, d))["x"]),
      long_x = unname(coef(long)["x"]),
      long_z = unname(coef(long)["z"]),
      long_int = unname(coef(long)["(Intercept)"]),
      delta_hat = unname(coef(lm(z ~ x, d))["x"])
    )
  })
  bias <- reactive(fits()$short - fits()$long_x)

  # ---- value boxes
  output$true_box <- renderUI({
    value_box(title = "True α", value = sprintf("%.2f", input$alpha), theme = "secondary")
  })
  output$short_box <- renderUI({
    value_box(
      title = sprintf("Naive: %s ~ %s", sc()$y_lab, sc()$x_lab),
      value = sprintf("%.2f", fits()$short),
      theme = if (input$controlled) "secondary" else "primary"
    )
  })
  output$long_box <- renderUI({
    value_box(
      title = sprintf("Adjusted: + %s", sc()$z_lab),
      value = sprintf("%.2f", fits()$long_x),
      theme = if (input$controlled) "primary" else "secondary"
    )
  })
  output$bias_box <- renderUI({
    off <- abs(bias()) > 0.1
    value_box(
      title = "Bias (naive − adjusted)",
      value = sprintf("%+.2f", bias()),
      theme = if (off) "danger" else "success",
      showcase = bs_icon(if (off) "exclamation-triangle" else "check-circle")
    )
  })

  # ---- the exact identity
  output$identity_card <- renderUI({
    f <- fits()
    bslib::card(
      class = "mb-2", style = "flex:none;",
      bslib::card_body(
        class = "py-2 text-center",
        tags$div(
          style = "font-size:1.15rem; font-family:'Fira Code', monospace;",
          tags$span("bias = β̂ × δ̂ :   ", style = "color:grey;"),
          tags$span(sprintf("%+.2f", bias()), style = paste0("color:", COL_NAIVE, "; font-weight:bold;")),
          tags$span(" = "),
          tags$span(sprintf("%+.2f", f$long_z), style = paste0("color:", UI_TEAL, "; font-weight:bold;")),
          tags$span(" × "),
          tags$span(sprintf("%+.2f", f$delta_hat), style = paste0("color:", UI_TEAL, "; font-weight:bold;"))
        ),
        tags$div(
          class = "text-muted", style = "font-size:0.8rem;",
          sprintf("β̂ = effect of %s in the long model · δ̂ = slope of %s ~ %s. The identity is exact in every sample — not an approximation.",
                  tolower(sc()$z_lab), tolower(sc()$z_lab), tolower(sc()$x_lab))
        )
      )
    )
  })

  # ---- dynamic explanation
  output$explain <- renderUI({
    s <- sc()
    bslib::card(
      class = "mb-2", style = "flex:none;",
      bslib::card_body(
        class = "py-2", style = "font-size:0.93rem;",
        tags$p(class = "mb-0", if (input$controlled) s$control_story else s$story)
      )
    )
  })

  # ---- DAG
  output$dag <- renderPlot({
    dag_plot(sc(), input$alpha, input$beta, input$delta, input$controlled)
  }, res = 110)

  # ---- sign table
  output$sign_table <- renderUI({
    b <- input$beta; d <- input$delta
    active <- function(bp, dp) {
      if (b == 0 || d == 0) return(FALSE)
      (b > 0) == bp && (d > 0) == dp
    }
    cell <- function(bp, dp) {
      pos <- bp == dp
      tags$td(
        style = paste0(
          "padding:6px 10px; text-align:center; font-size:0.85rem; border:1px solid #dee2e6;",
          if (active(bp, dp)) paste0("background:", COL_NAIVE, "22; font-weight:bold; outline:2px solid ", COL_NAIVE, ";") else ""
        ),
        if (pos) "bias + (pushed up)" else "bias − (pushed down)"
      )
    }
    hdr_style <- "padding:6px 10px; font-size:0.8rem; color:grey; border:1px solid #dee2e6;"
    tagList(
      tags$table(
        style = "width:100%; border-collapse:collapse;",
        tags$tr(tags$th(""), tags$th("δ > 0", style = hdr_style), tags$th("δ < 0", style = hdr_style)),
        tags$tr(tags$th("β > 0", style = hdr_style), cell(TRUE, TRUE), cell(TRUE, FALSE)),
        tags$tr(tags$th("β < 0", style = hdr_style), cell(FALSE, TRUE), cell(FALSE, FALSE))
      ),
      if (b == 0 || d == 0)
        tags$div(class = "text-muted mt-1", style = "font-size:0.8rem;",
                 "β or δ is zero — no bias. It takes both to open the back door.")
    )
  })

  # ---- main scatter
  output$scatter_title <- renderUI({
    s <- sc()
    txt <- if (input$controlled) {
      sprintf("Orange: naive slope · dark lines: adjusted slope at %s = −1σ, 0, +1σ", tolower(s$z_lab))
    } else {
      sprintf("Points shaded by %s (the variable your regression can't see) · orange: naive slope", tolower(s$z_lab))
    }
    tags$span(txt, style = "font-size:0.85rem;")
  })

  output$scatter <- renderPlot({
    d <- dat()
    s <- sc()
    f <- fits()

    p <- ggplot(d, aes(x, y)) +
      geom_point(aes(color = z), alpha = 0.55, size = 1.8) +
      scale_color_gradient(low = COL_Z_LOW, high = COL_LONG, name = s$z_lab) +
      geom_smooth(method = "lm", se = FALSE, formula = y ~ x,
                  color = COL_NAIVE, linewidth = 1.4) +
      labs(x = s$x_lab, y = s$y_lab) +
      theme_minimal(base_size = 15) +
      theme(legend.position = "right", panel.grid.minor = element_blank())

    if (input$controlled) {
      zs <- c(-1, 0, 1)
      ab <- tibble(
        slope = f$long_x,
        intercept = f$long_int + f$long_z * zs,
        z_at = sprintf("%+dσ", zs)
      )
      p <- p +
        geom_abline(data = ab, aes(slope = slope, intercept = intercept),
                    color = COL_LONG, linewidth = 1, linetype = "longdash")
    }
    p
  }, res = 110)

  # ---- first stage
  output$fs_title <- renderUI({
    s <- sc()
    tags$span(sprintf("The sorting itself: %s ~ %s (slope = δ̂ = %.2f)",
                      tolower(s$z_lab), tolower(s$x_lab), fits()$delta_hat),
              style = "font-size:0.85rem;")
  })
  output$first_stage <- renderPlot({
    d <- dat()
    s <- sc()
    ggplot(d, aes(x, z)) +
      geom_point(alpha = 0.25, size = 1.1, color = "grey55") +
      geom_smooth(method = "lm", se = FALSE, formula = y ~ x, color = UI_TEAL, linewidth = 1.2) +
      scale_y_continuous(breaks = c(-2, 0, 2)) +
      labs(x = s$x_lab, y = s$z_lab) +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank())
  }, res = 110)
}

shinyApp(ui, server)
