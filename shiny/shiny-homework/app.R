# Packages ####
library(shiny)
library(tidyverse)
library(bslib)
library(RColorBrewer)
library(shinyWidgets)
library(ggiraph)
library(fontawesome)

# Team ####
r4dev_summer <- tibble(name = c("Kate","Kerstin","Juan","Gorazd","Soohyun","Agnes","Antoine","Vita"),
                       link = c("https://kate-chalmers.com/",
                                "https://kerstins-blog-practice.netlify.app/",
                                "https://r4dev-juan.netlify.app/",
                                "https://gorazd-r4dev-practice.netlify.app/",
                                "https://r4dev-awwgeez.netlify.app/",
                                "https://agnesdev.netlify.app/",
                                "https://antoine-s-blog.netlify.app/",
                                "https://r4dev-vita.netlify.app/"
                                ))

# UI ####
ui_r4dev_hw <- page_navbar(
  title = "R4DEV homework randomizer",
  theme = bslib::bs_theme(
    bootswatch = "united",
    bg = "white",
    fg = "navy",
    success = "forestgreen",
    danger = "red",
    base_font = "News Cycle",
    font_scale = 1.7
  ),
  #nav_item(tags$a("R4DEV", href = "https://r4dev.netlify.app/"),
  #         icon = icon("head-side-brain", lib="font-awesome"),
  #         align = "right"),
  tabPanel(
    title = "Who plays today?",
        layout_column_wrap(width = 1/2,
          card(
            card_header(
              layout_column_wrap(width = 1/2,
                                 ("Today's lucky winners"),
                                 actionButton(
                                   inputId = "sampleButton",
                                   label = "Draw 3 winners!",
                                   icon = icon("dice")
                                   ))),
            card_body(
              shinyWidgets::prettyCheckboxGroup(
                inputId = "namesInput",
                label = "Select players:",
                choices = r4dev_summer$name,
                selected = r4dev_summer$name,
                animation = "jelly",
                icon = icon("check"),
                status = "success",
                fill=TRUE
              ))),
          card(
            card_header("And the winners are:"),
            card_body(
              girafeOutput("sampleOutput")
            )
          ))
    ))

# Server ####
server_r4dev_hw <- function(input, output) {
  
  sampleSizeInput <- reactive({
    
  })
  
  randomSample <- eventReactive(input$sampleButton, {
    sample(input$namesInput,
           size=3,
           replace = FALSE)
  })
  
  # Output random sample
  output$sampleOutput <- renderGirafe({
    g <- randomSample() |>
      as_tibble() |>
      dplyr::rename(name=1) |>
      dplyr::left_join(r4dev_summer, by="name") |>
      ggplot(aes(x=1,y=name, color=name))+
      geom_text_interactive(aes(label=name, 
                                data_id = name,
                                onclick = paste0('window.open("', link , '")')
                                ), 
                            size=10,
                            position=position_identity()
                            )+
      annotate("label",x=1,y=3.3, label = "1")+
      annotate("label",x=1,y=2.3, label = "2")+
      annotate("label",x=1,y=1.3, label = "3")+
      theme_void()+
      theme(legend.position = "none")
    
    ggiraph::girafe(
      ggobj = g
    )
  })
  
}

# Run the app
shinyApp(ui = ui_r4dev_hw, server = server_r4dev_hw)