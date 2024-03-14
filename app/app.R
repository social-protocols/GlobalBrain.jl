library(shiny)
library(shinydashboard)
library(DBI)
library(dplyr)
library(tidyr)
library(r2d3)

source("utilities.R")
source("simulation-demo.R")
source("prototype-demo.R")

PROTOTYPE_DATABASE_PATH <- Sys.getenv("PROTOTYPE_DATABASE_PATH")
SERVICE_DATABASE_PATH <- Sys.getenv("SERVICE_DATABASE_PATH")
SIM_DATABASE_PATH <- Sys.getenv("SIM_DATABASE_PATH")

ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "Global Brain"),
  dashboardSidebar(
    sidebarMenu(
      # menuItem("Prototype", tabName = "prototype-demo"),
      menuItem("Simulation", tabName = "simulation-demo")
    )
  ),
  dashboardBody(
    # tags$head(
    #   tags$style(HTML(".content-wrapper { background-color: #FFFFFF }"))
    # ),
    tabItems(
      # tabItem(tabName = "prototype-demo", prototypeDemoUI("prototypeDemo")),
      tabItem(tabName = "simulation-demo", simulationDemoUI("simulationDemo"))
    )
  ),
)

server <- function(input, output, session) {
  simulationDemoServer("simulationDemo")
  # prototypeDemoServer("prototypeDemo")
}

shinyApp(ui, server)
