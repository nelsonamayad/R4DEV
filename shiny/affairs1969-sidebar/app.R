# Packages needed
library(shiny)
library(viridis)
library(tidyverse)
library(bslib)

# Data #
affairs_1969 <- readr::read_csv("https://raw.githubusercontent.com/vincentarelbundock/Rdatasets/master/csv/AER/Affairs.csv") |>
  dplyr::mutate(happy = case_when(rating==1 ~ "very unhappy",
                                  rating==2 ~ "somewhat unhappy",
                                  rating==3 ~ "average",
                                  rating==4 ~ "happier than average",
                                  rating==5 ~ "very happy")) |>
  dplyr::mutate(happy = fct_reorder(happy, rating)) |>
  dplyr::mutate(cheat=factor(ifelse(affairs==0,"Faithful","Cheater"))) 
  

# Define simple  User Interface ####
ui_affair <- page_sidebar(
  # We start with the header with a title
  title = tags$span(
    tags$img(src = "r4dev_logo.png", height = "26px", style = "margin-right:8px; vertical-align:middle;"),
    "Fair's Affairs 1969"
  ),
  # Color theme for the dashboard
  theme = bslib::bs_theme(
    bootswatch = "litera"
  ),
  # Now we define the sidebar
  sidebar = sidebar(
    width = 350,
      p("A survey with 601 respondents (315 female/286 male) on extra-marital affairs"),
      plotOutput("happiness", height = "150px"),
        # Selector
        selectInput(inputId = "happy",
                    label = "Select self-evaluation of marriage:",
                    choices = unique(affairs_1969$happy),
                    selected = "average")
        ),
  # Finally we define the body of the result
  plotOutput("affairs")
  )

# Define the server function inputs and outputs ####
server_affair <- function(input, output) {

  # Plot of chose variable
  output$happiness <- renderPlot({
    
    affairs_1969 %>%
      dplyr::count(happy) |>
      ggplot(aes(y=happy,x=n,fill=happy))+
      geom_col()+
      geom_label(aes(label=n), fill="white",color="black",nudge_x = -10)+
      scale_fill_viridis_d(name = "turbo", direction=1)+
      labs(x=NULL, y=NULL)+
      theme_classic()+
      theme(legend.position = "none")
  })
  
  # Plot of chose variable
  output$affairs <- renderPlot({
    
    affairs_1969 %>%
      dplyr::filter(happy==print(input$happy)) %>%
      dplyr::group_by(gender,age) |>
      dplyr::count(cheat) |>
      ggplot(aes(x=age,y=n,fill=gender))+
      geom_col()+
      geom_label(aes(label=n), fill="black",color="white", vjust=-0.5)+
      ylim(c(0,80))+
      facet_wrap(gender~cheat)+
      scale_fill_brewer(palette = "Set1")+
      theme_classic()+
      theme(text=element_text(size=18), legend.position = "none")+
      labs(title = "Respondents by self-declared happiness, by age and gender",
           subtitle = paste("Among", input$happy, "respondents"),
           x="Respondent age",
           y="# respondents")
  })
  
  }


# Run App ####
shinyApp(ui=ui_affair, server = server_affair)
