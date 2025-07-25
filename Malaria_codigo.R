library(shiny)
library(sf)
library(readr)
library(dplyr)
library(ggplot2)

# --- Leer datos una vez ---
shapefile_path <- "D:/Documents_2/LABORAL/2025/DATACHALLENGE_LAB_UPCH/data/shapefile/DISTRITOS_inei_geogpsperu_suyopomalia.shp"
csv_path <- "D:/Documents_2/LABORAL/2025/DATACHALLENGE_LAB_UPCH/data/malaria.csv"

gdf <- st_read(shapefile_path)
df <- read_csv(csv_path)

# Asegurar que UBIGEO es tipo texto
gdf$UBIGEO <- as.character(gdf$UBIGEO)
df$UBIGEO <- as.character(df$UBIGEO)

# --- Interfaz UI ---
ui <- fluidPage(
  titlePanel("Mapa Interactivo de Enfermedades - Malaria y Dengue"),
  sidebarLayout(
    sidebarPanel(
      selectInput("enfermedad", "Selecciona tipo de enfermedad:",
                  choices = c("falciparum", "vivax")),
      
      radioButtons("modo", "¿Cómo deseas filtrar?",
                   choices = c("Único" = "unico", "Rango" = "rango"),
                   selected = "unico"),
      
      # Para modo único
      conditionalPanel(
        condition = "input.modo == 'unico'",
        selectInput("ano_unico", "Selecciona un año:",
                    choices = sort(unique(df$ano))),
        selectInput("semana_unico", "Selecciona una semana:",
                    choices = sort(unique(df$semana)))
      ),
      
      # Para modo rango
      conditionalPanel(
        condition = "input.modo == 'rango'",
        sliderInput("ano_rango", "Selecciona rango de años:",
                    min = min(df$ano), max = max(df$ano),
                    value = c(min(df$ano), max(df$ano)), sep = ""),
        sliderInput("semana_rango", "Selecciona rango de semanas:",
                    min = min(df$semana), max = max(df$semana),
                    value = c(min(df$semana), max(df$semana)))
      )
    ),
    mainPanel(
      plotOutput("mapa", height = "700px")
    )
  )
)

# --- Lógica del servidor ---
server <- function(input, output, session) {
  
  datos_filtrados <- reactive({
    if (input$modo == "unico") {
      df %>%
        filter(ano == input$ano_unico, semana == input$semana_unico) %>%
        group_by(UBIGEO) %>%
        summarise(valor = sum(.data[[input$enfermedad]], na.rm = TRUE), .groups = "drop")
    } else {
      df %>%
        filter(
          ano >= input$ano_rango[1], ano <= input$ano_rango[2],
          semana >= input$semana_rango[1], semana <= input$semana_rango[2]
        ) %>%
        group_by(UBIGEO) %>%
        summarise(valor = sum(.data[[input$enfermedad]], na.rm = TRUE), .groups = "drop")
    }
  })
  
  datos_mapa <- reactive({
    gdf %>%
      left_join(datos_filtrados(), by = "UBIGEO") %>%
      mutate(valor = ifelse(is.na(valor), 0, valor))
  })
  
  output$mapa <- renderPlot({
    titulo <- if (input$modo == "unico") {
      paste("Casos de", input$enfermedad, "- Semana", input$semana_unico, "Año", input$ano_unico)
    } else {
      paste("Casos acumulados de", input$enfermedad,
            "- Años", input$ano_rango[1], "a", input$ano_rango[2],
            "- Semanas", input$semana_rango[1], "a", input$semana_rango[2])
    }
    
    ggplot(data = datos_mapa()) +
      geom_sf(aes(fill = valor), color = "gray", size = 0.1) +
      scale_fill_gradient(name = "Casos", low = "#fff5f0", high = "#99000d") +
      labs(title = titulo) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 16, face = "bold"),
        axis.text = element_blank(),
        axis.ticks = element_blank()
      )
  })
}

# --- Ejecutar App ---
shinyApp(ui, server)
