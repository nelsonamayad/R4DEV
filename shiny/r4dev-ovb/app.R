# Packages needed ####
library(shiny)
library(shinydashboard)
library(RColorBrewer)
library(tidyverse)
library(bslib)
library(bsicons)
library(gtsummary)
library(gt)
library(brms)

# UI ####
ui_ovb <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "journal"),
  titlePanel("OVB Simulator"),
  sidebarLayout(
    sidebarPanel(
      numericInput("alpha_in", "Coefficient alpha", value = 1, min = -5, max = 5),
      numericInput("beta_in", "Coefficient beta", value = -1, min = -5, max = 5),
      numericInput("gamma_in", "Coefficient gamma", value = 0.5, min = -5, max = 5),
      actionButton("simulate", "Simulate")
    ),
    
    mainPanel(
      fluidRow(
        column(width = 4,uiOutput("alpha_out")),
        column(width = 4,uiOutput("beta_out")),
        column(width = 4,uiOutput("gamma_out"))
        ),
      fluidRow(column(width=12,
                      p("$$OVB = \\beta_{short} -\\beta_{long}$$"),
                      br(),
                      plotOutput("bias")
                      )
               ),
      fluidRow(
        column(width = 6,
               withMathJax(uiOutput("short_eq")),
               br(),
               gt::gt_output("short_table")),
        column(width = 6,
               withMathJax(uiOutput("long_eq")),
               br(),
               gt::gt_output("long_table"))
      )
  )
)
)

# Server ####
server_ovb <- function(input, output) {
  
  ## Simulate data ####
  fake_data <- eventReactive(input$simulate,{

    set.seed(123)
    n <- 2000
    fake_data <- tibble(
        e = rnorm(max(n),mean=0,sd=1),                   
        z = rnorm(max(n),mean=3,sd=10),                  
        x = 10 + input$gamma_in*z + e,  
        y = 20 + input$alpha_in*x + input$beta_in*z + e  
  )  
    })

  ## Parameters ####
  output$alpha_out <- renderUI({

      bslib::value_box(
        title = 'Y ~ X|Z ($$\\alpha$$)',
        value = input$alpha_in,
        showcase = bs_icon('calculator'),
        theme_color = "success"
      )
    })

  output$beta_out <- renderUI({

    bslib::value_box(
      title = 'Y ~ Z|X ($$\\beta$$)',
      value = input$beta_in,
      showcase = bs_icon('calculator'),
      theme_color = "success"
    )
  })

  output$gamma_out <- renderUI({

    bslib::value_box(
      title = 'X ~ Z ($$\\gamma$$)',
      value = input$gamma_in,
      showcase = bs_icon('calculator'),
      theme_color = "danger"
    )
  })

  ## Short equation ####
  output$short_eq <- renderUI({
    HTML("$$Y = \\alpha_0 + \\alpha1_{short}X$$")
  })
    
  ## Long equation ####
  output$long_eq <- renderUI({
    HTML("$$Y = \\beta_0 + \\beta1_{long}X + \\beta2_{long}Z$$")
  })
  
  
  ## Short table ####
  output$short_table <- render_gt({

    lm(y ~ x, data = fake_data()) |>
      gtsummary::tbl_regression(intercept = TRUE) |>
      as_gt()

  })

  ## Long table ####
  output$long_table <- render_gt({

    lm(y ~ x + z, data = fake_data()) |>
      gtsummary::tbl_regression(intercept = TRUE) |>
      as_gt()

  })

  ## Bias plot ####
  output$bias <- renderPlot({
    
    b_long <- lm(y ~ x + z, data = fake_data()) |> broom::tidy() |> dplyr::filter(term=="x") |> dplyr::select(estimate) |> as.numeric()
    b_short <- lm(y ~ x, data = fake_data()) |> broom::tidy() |> dplyr::filter(term=="x") |> dplyr::select(estimate) |> as.numeric()
    b_omitted_inc <- lm(z ~ x, data = fake_data()) |> broom::tidy() |> dplyr::filter(term=="x") |> dplyr::select(estimate) |> as.numeric()
    bias = round(b_short - b_long, digits = 1)
    
    fake_data() |>
      ggplot(aes(x=x,y=y))+
      geom_point()+
      geom_smooth(method = "lm")+
      annotate("text",x=20, y=40, label = paste0("OVB: ", bias), color="red", size=10)
  })
  
  }

# Run App ####
shinyApp(ui=ui_ovb, server = server_ovb)