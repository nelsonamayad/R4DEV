# R4DEV — Fair's Affairs 1969, App I: page_sidebar
# The first, deliberately simple app in sessions_workshop/08-shiny (PART I):
# one input, two outputs. Keep the lesson's code chunk in sync with this file.
# Run with: shiny::runApp("shiny/affairs1969-sidebar")

# Packages ####
library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)

# Data ####
affairs_1969 <- readr::read_csv(
  "https://raw.githubusercontent.com/vincentarelbundock/Rdatasets/master/csv/AER/Affairs.csv",
  show_col_types = FALSE
) |>
  dplyr::mutate(
    happy = factor(rating, levels = 1:5,
                   labels = c("Very unhappy", "Somewhat unhappy", "Average",
                              "Happier than average", "Very happy")),
    affair = factor(if_else(affairs > 0, "Had an affair", "No affair"),
                    levels = c("No affair", "Had an affair")),
    gender = if_else(gender == "female", "Women", "Men")
  )

# Look ####
teal <- "#226F7F"; orange <- "#F75431"; slate <- "#5C6B70"

theme_r4dev <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(plot.title.position = "plot",
          plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(colour = slate),
          axis.title = element_text(colour = slate),
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          strip.text = element_text(face = "bold", size = rel(1.1), hjust = 0),
          legend.position = "top", legend.justification = "left")
}

# User interface ####
ui <- page_sidebar(
  title = tags$span(
    class = "d-flex align-items-center gap-2",
    tags$img(src = "r4dev_logo.png", height = "28px", alt = "R4DEV logo"),
    "Fair's Affairs, 1969"
  ),
  theme = bs_theme(
    version = 5, primary = teal, secondary = slate,
    base_font = font_google("Roboto Condensed", wght = c(400, 700)),
    "navbar-bg" = teal,
    brand = FALSE
  ),
  sidebar = sidebar(
    width = 320,
    p("In 1969, ", tags$em("Psychology Today"), " asked 601 married readers how happy their marriage was, ",
      "and how often they had been unfaithful in the past year."),
    selectInput(
      inputId = "happy",
      label = "Show respondents whose marriage is…",
      choices = levels(affairs_1969$happy),
      selected = "Average"
    ),
    plotOutput("happiness", height = "190px"),
    p(class = "small text-muted",
      "Source: Fair (1978), via the AER package.")
  ),
  card(
    full_screen = TRUE,
    card_header(textOutput("headline")),
    plotOutput("affairs")
  )
)

# Server ####
server <- function(input, output) {

  # How happy were the marriages? The bar you picked is highlighted
  output$happiness <- renderPlot({
    affairs_1969 |>
      dplyr::count(happy) |>
      dplyr::mutate(picked = happy == input$happy) |>
      ggplot(aes(x = n, y = happy, fill = picked)) +
      geom_col(width = 0.75) +
      geom_text(aes(label = n), hjust = -0.2, size = 3.6, colour = slate) +
      scale_fill_manual(values = c(`TRUE` = teal, `FALSE` = "#C9D3D6"), guide = "none") +
      scale_x_continuous(expand = expansion(mult = c(0, 0.3))) +
      labs(x = NULL, y = NULL, title = "Respondents by marriage rating") +
      theme_r4dev(11) +
      theme(axis.text.x = element_blank(), panel.grid = element_blank(),
            plot.title = element_text(size = 10, colour = slate))
  }, res = 96)

  # Headline for the selected group
  output$headline <- renderText({
    group <- dplyr::filter(affairs_1969, happy == input$happy)
    sprintf("%s marriages: %d of %d respondents (%.0f%%) reported an affair",
            input$happy, sum(group$affairs > 0), nrow(group),
            100 * mean(group$affairs > 0))
  })

  # Who strayed, by age and gender, within the selected group
  output$affairs <- renderPlot({
    affairs_1969 |>
      dplyr::filter(happy == input$happy) |>
      dplyr::count(gender, age, affair) |>
      ggplot(aes(x = age, y = n, fill = affair)) +
      geom_col(width = 4) +
      facet_wrap(~gender) +
      scale_fill_manual(values = c("No affair" = "#C9D3D6", "Had an affair" = orange)) +
      scale_x_continuous(breaks = c(17.5, 22, 27, 32, 37, 42, 47, 52, 57),
                         labels = c("<20", "22", "27", "32", "37", "42", "47", "52", "57")) +
      scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
      labs(title = "Respondents by age and gender",
           subtitle = "Each bar is one age group; orange marks those who reported at least one affair",
           x = "Age (years)", y = "Respondents", fill = NULL) +
      theme_r4dev()
  }, res = 96)
}

# Run the app ####
shinyApp(ui = ui, server = server)
