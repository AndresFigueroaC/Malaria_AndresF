# Malaria_AndresF
💡 Descripción del código
Este script en R Shiny genera una aplicación web interactiva que muestra un mapa temático de casos de malaria (falciparum y vivax) por distrito en el Perú.

La aplicación permite visualizar los casos por:

Año y semana específica (modo "Único").

Rango de años y semanas (modo "Rango").

¿Qué hace el código?
Carga un shapefile distrital y un archivo .csv con datos de malaria.

Cruza ambos conjuntos de datos mediante el código UBIGEO.

Permite seleccionar el tipo de enfermedad y el rango temporal.

Genera un mapa estático coloreado según el número de casos usando ggplot2.

Se actualiza automáticamente según la selección del usuario.

Librerías utilizadas
shiny: para la app web.

sf: para datos espaciales.

readr, dplyr: para lectura y manipulación de datos.

ggplot2: para la visualización geográfica.
