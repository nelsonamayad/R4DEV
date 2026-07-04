# Packages ####
library(tidyverse)
library(quarto)

# FUNCTIONS ####
## Create function to render the report####
retractionwatch_report <- function(country_input) {
  
  quarto::quarto_render(input = paste0(getwd(),"/retractionwatch_reports.qmd"),
                        output_file = paste0(lubridate::today(),"_retractionwatch_",country_input,".html"),
                        output_format = "html",
                        execute_params = list(country = country_input))
}

## Test the function with a single country ####
retractionwatch_report(country_input = "France")

## Use a list of countries and map the function to get all reports ####
purrr::map(list("Colombia","Canada","France","Norway"), retractionwatch_report)

purrr::map(list("France","India"), retractionwatch_report)
