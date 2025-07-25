library(shiny)
library(sf)
library(readr)
library(dplyr)
library(ggplot2)
library(plotly)

# --- Leer datos una vez ---
shapefile_path <- "D:/Documents_2/LABORAL/2025/DATACHALLENGE_LAB_UPCH/data/DISTRITOS_inei_geogpsperu_suyopomalia.shp"
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
      plotlyOutput("mapa", height = "600px"),
      plotlyOutput("serie", height = "300px")
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
  
  output$mapa <- renderPlotly({
    p <- ggplot(data = datos_mapa()) +
      geom_sf(aes(fill = valor, text = UBIGEO), color = "gray", size = 0.1) +
      scale_fill_gradient(name = "Casos", low = "#fff5f0", high = "#99000d") +
      theme_void()
    
    ggplotly(p, tooltip = "text") %>%
      layout(title = list(text = "Haz clic en un distrito para ver la serie temporal"))
  })
  
  output$serie <- renderPlotly({
    click <- event_data("plotly_click")
    if (is.null(click)) return(NULL)
    
    # Obtener el UBIGEO seleccionado
    ubigeo_seleccionado <- click$text
    
    df_sel <- df %>%
      filter(UBIGEO == ubigeo_seleccionado) %>%
      mutate(fecha = paste0(ano, "-W", sprintf("%02d", semana))) %>%
      arrange(ano, semana)
    
    plot_ly(df_sel, x = ~fecha, y = as.formula(paste0("~", input$enfermedad)),
            type = 'scatter', mode = 'lines+markers',
            name = input$enfermedad) %>%
      layout(title = paste("Serie temporal de", input$enfermedad, "en distrito", ubigeo_seleccionado),
             xaxis = list(title = "Semana"), yaxis = list(title = "Casos"))
  })
}

# --- Ejecutar App ---
shinyApp(ui, server)
