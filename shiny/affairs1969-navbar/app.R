# R4DEV — Fair's Affairs 1969, App II: page_navbar
# The "fancier" app in sessions_workshop/08-shiny (PART I): a navbar with
# three pages, a shared filter sidebar, value boxes built on the server, a
# clickable ggiraph chart that filters a DT table, and a plotting function
# reused across a whole page. Keep the lesson's code chunk in sync.
# Run with: shiny::runApp("shiny/affairs1969-navbar")

# Packages ####
library(shiny)
library(bslib)
library(bsicons)
library(shinyWidgets)
library(dplyr)
library(ggplot2)
library(ggiraph)
library(DT)

# Data ####
affairs_1969 <- readr::read_csv(
  "https://raw.githubusercontent.com/vincentarelbundock/Rdatasets/master/csv/AER/Affairs.csv",
  show_col_types = FALSE
) |>
  dplyr::mutate(
    happy = factor(rating, levels = 1:5,
                   labels = c("Very unhappy", "Somewhat unhappy", "Average",
                              "Happier than average", "Very happy")),
    strayed = affairs > 0,
    gender = if_else(gender == "female", "Women", "Men"),
    children = if_else(children == "yes", "Yes", "No"),
    # yearsmarried codes the first year in three slices; pool them for plotting
    married = if_else(yearsmarried < 1, 0.5, yearsmarried)
  )

# Look ####
pal <- list(teal = "#226F7F", rust = "#C2401F", slate = "#5C6B70", ink = "#20242A",
            women = "#0E8CA8", men = "#F75431")   # validated series pair

r4dev_theme <- bs_theme(
  version = 5, primary = pal$teal, secondary = pal$slate, danger = pal$rust,
  base_font = font_google("Roboto Condensed", wght = c(400, 700)),
  "navbar-bg" = pal$teal,
  brand = FALSE
) |>
  bs_add_rules("
    .bslib-value-box .value-box-title { font-size: .9rem; }
    .bslib-value-box .value-box-value { font-weight: 700; }
    .card-header { font-weight: 700; }
    .btn-group .btn { font-size: .85rem; }
    .bslib-grid > * { min-width: 0; }
    .bslib-page-main { min-width: 0 !important; }   /* let narrow iframes wrap instead of scroll */
    table.dataTable { font-size: .85rem; }
    table.dataTable td { padding-top: .3rem !important; padding-bottom: .3rem !important; }
  ")

theme_r4dev <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(plot.title.position = "plot",
          axis.title = element_text(colour = pal$slate),
          panel.grid.minor = element_blank(),
          legend.position = "top", legend.justification = "left")
}

pct <- function(x) sprintf("%.0f%%", 100 * x)

# One function, three plots: the share who strayed along any variable
rate_plot <- function(data, var, x_lab, breaks = waiver(), labels = waiver()) {
  data |>
    dplyr::group_by(gender, value = .data[[var]]) |>
    dplyr::summarise(rate = mean(strayed), n = dplyr::n(), .groups = "drop") |>
    dplyr::arrange(gender, value) |>
    ggplot(aes(value, rate, colour = gender)) +
    geom_line(linewidth = 1) +
    geom_point(aes(size = n)) +
    scale_colour_manual(values = c(Women = pal$women, Men = pal$men)) +
    scale_size_area(max_size = 6, guide = "none") +
    scale_x_continuous(breaks = breaks, labels = labels) +
    scale_y_continuous(labels = scales::label_percent(), limits = c(0, NA)) +
    labs(x = x_lab, y = "Reported an affair", colour = NULL) +
    theme_r4dev()
}

# User interface ####
ui <- page_navbar(
  title = tags$span(
    class = "d-flex align-items-center gap-2",
    tags$img(src = "r4dev_logo.png", height = "28px", alt = "R4DEV logo"),
    "Fair's Affairs, 1969"
  ),
  theme = r4dev_theme,
  fillable = FALSE,

  # The sidebar is shared by every page
  sidebar = sidebar(
    title = "Filter respondents",
    width = 280,
    shinyWidgets::radioGroupButtons(
      "gender", "Gender", choices = c("All", "Women", "Men"),
      justified = TRUE, status = "outline-primary"
    ),
    shinyWidgets::radioGroupButtons(
      "children", "Has children", choices = c("Any", "Yes", "No"),
      justified = TRUE, status = "outline-primary"
    ),
    sliderInput("years", "Years married", min = 0, max = 15, value = c(0, 15), step = 1),
    p(class = "small text-muted mt-2",
      "601 married readers of ", tags$em("Psychology Today"),
      " (1969). Source: Fair (1978), via the AER package.")
  ),

  # Page 1 ####
  nav_panel(
    "Overview", icon = bs_icon("heartbreak"),
    layout_column_wrap(
      width = "200px", fill = FALSE,
      uiOutput("box_n"), uiOutput("box_rate"), uiOutput("box_gap")
    ),
    layout_column_wrap(
      width = "340px",
      card(
        full_screen = TRUE, height = "440px",
        card_header("Is an unhappy marriage a warning sign?"),
        girafeOutput("by_rating"),
        card_footer(class = "small text-muted",
                    "Click one or more bars to list those respondents in the table.")
      ),
      card(
        full_screen = TRUE, height = "440px",
        card_header(textOutput("table_title", inline = TRUE)),
        DTOutput("table")
      )
    )
  ),

  # Page 2 ####
  nav_panel(
    "Who strays?", icon = bs_icon("people"),
    layout_column_wrap(
      width = "260px", heights_equal = "row",
      card(full_screen = TRUE, height = "420px", card_header("By years of marriage"), plotOutput("by_years")),
      card(full_screen = TRUE, height = "420px", card_header("By age"), plotOutput("by_age")),
      card(full_screen = TRUE, height = "420px", card_header("By religiousness"), plotOutput("by_religion"))
    ),
    p(class = "small text-muted mb-0",
      "Share of respondents reporting at least one affair in the past year. ",
      "Bigger points mean more respondents, so the estimate is less noisy.")
  ),

  # Page 3 ####
  nav_panel(
    "About the data", icon = bs_icon("info-circle"),
    card(
      card_body(
        markdown("
In 1969 the magazine *Psychology Today* surveyed its readers about sex and marriage.
Ray Fair (1978) used the 601 answers from people in their first marriage to model
*A Theory of Extramarital Affairs*. Each row is one respondent:

- **affairs**: how often they had an affair in the past year (0, 1, 2, 3, 7 = 4–10 times, 12 = monthly or more)
- **rating**: self-rated happiness of the marriage, from 1 (very unhappy) to 5 (very happy)
- **gender**, **age**, **yearsmarried**, **children**, **religiousness** (1–5), **education** (years), **occupation** (1–7)

Keep the caveats in mind: readers of one magazine are not a random sample of
married Americans, and people under-report what they'd rather hide.
")
      )
    )
  ),
  nav_spacer(),
  nav_item(tags$a(
    bs_icon("book"), "Lesson",
    href = "https://nelsonamayad.github.io/R4DEV/sessions_workshop/08-shiny/08-shiny.html",
    target = "_blank"
  ))
)

# Server ####
server <- function(input, output, session) {

  # Every output reads this one filtered data set
  filtered <- reactive({
    d <- affairs_1969 |>
      dplyr::filter(yearsmarried >= input$years[1], yearsmarried <= input$years[2])
    if (input$gender != "All") d <- dplyr::filter(d, gender == input$gender)
    if (input$children != "Any") d <- dplyr::filter(d, children == input$children)
    d
  })

  # Value boxes ####
  output$box_n <- renderUI({
    value_box(
      title = "Respondents selected",
      value = nrow(filtered()),
      theme = "primary", max_height = "100px"
    )
  })
  output$box_rate <- renderUI({
    d <- filtered()
    value_box(
      title = "Reported an affair",
      value = if (nrow(d) > 0) pct(mean(d$strayed)) else "—",
      theme = "danger", max_height = "100px"
    )
  })
  output$box_gap <- renderUI({
    d <- filtered()
    unhappy <- d$strayed[d$rating <= 2]
    happy <- d$strayed[d$rating >= 4]
    value_box(
      title = "Unhappy vs happy marriages",
      value = if (length(unhappy) > 0 && length(happy) > 0)
        paste(pct(mean(unhappy)), "vs", pct(mean(happy))) else "—",
      theme = "light", max_height = "100px"
    )
  })

  # Interactive chart: the share who strayed, by marriage rating ####
  output$by_rating <- renderGirafe({
    rates <- filtered() |>
      dplyr::group_by(happy) |>
      dplyr::summarise(rate = mean(strayed), strayed = sum(strayed), n = dplyr::n())

    gg <- ggplot(rates, aes(x = rate, y = happy)) +
      ggiraph::geom_col_interactive(
        aes(data_id = happy,
            tooltip = sprintf("%s marriages<br>%d of %d reported an affair (%s)",
                              happy, strayed, n, pct(rate))),
        fill = pal$women, width = 0.7
      ) +
      geom_text(aes(label = pct(rate)), hjust = -0.2, colour = pal$slate, size = 4.6) +
      scale_x_continuous(labels = scales::label_percent(),
                         expand = expansion(mult = c(0, 0.15))) +
      labs(x = "Reported an affair", y = NULL) +
      theme_r4dev(16) +
      theme(panel.grid.major.y = element_blank())

    ggiraph::girafe(
      ggobj = gg, width_svg = 6, height_svg = 3.6,
      options = list(
        ggiraph::opts_selection(type = "multiple", css = "fill:#F75431;"),
        ggiraph::opts_hover(css = "fill:#C2401F;cursor:pointer;"),
        ggiraph::opts_toolbar(saveaspng = FALSE),
        ggiraph::opts_sizing(rescale = TRUE)
      )
    )
  })

  # Table: the respondents behind the bars you clicked ####
  # ggiraph stores the clicked data_ids in input$<outputId>_selected
  table_data <- reactive({
    d <- filtered()
    picked <- input$by_rating_selected
    if (length(picked) > 0) d <- dplyr::filter(d, happy %in% picked)
    d
  })

  output$table_title <- renderText({
    picked <- input$by_rating_selected
    if (length(picked) == 0) {
      sprintf("All %d respondents", nrow(table_data()))
    } else {
      sprintf("%d respondents in: %s", nrow(table_data()), paste(picked, collapse = ", "))
    }
  })

  output$table <- renderDT({
    table_data() |>
      dplyr::transmute(
        Gender = gender, Age = age, `Years married` = yearsmarried,
        Children = children, Marriage = happy, Religiousness = religiousness,
        Education = education, `Affairs (past year)` = affairs
      ) |>
      DT::datatable(
        rownames = FALSE, style = "bootstrap5", class = "compact hover nowrap",
        options = list(pageLength = 7, dom = "tip", scrollX = TRUE)
      )
  })

  # Page 2: the same function, three variables ####
  output$by_years <- renderPlot({
    rate_plot(filtered(), "married", "Years married",
              breaks = c(0.5, 4, 7, 10, 15), labels = c("<1", "4", "7", "10", "15+"))
  }, res = 96)
  output$by_age <- renderPlot({
    rate_plot(filtered(), "age", "Age (years)", breaks = seq(22, 57, 10))
  }, res = 96)
  output$by_religion <- renderPlot({
    rate_plot(filtered(), "religiousness", "Religiousness",
              breaks = 1:5, labels = c("None", "2", "3", "4", "Very"))
  }, res = 96)
}

# Run the app ####
shinyApp(ui, server)
