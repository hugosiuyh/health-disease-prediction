library(shiny)
library(shinythemes)
library(keras)


model_path <- "./heart_disease_model1.h5"
model <- load_model_hdf5(model_path)

# Define UI

ui <- fluidPage(
  theme = shinytheme("flatly"),
  titlePanel("Health Disease Model Prediction"),
  sidebarLayout(
    sidebarPanel(
      numericInput("age", "Age", value = 40),
      selectInput("sex", "Sex",
                  choices = c("M" = 1, "F" = 0)),
      selectInput("chestPainType", "Chest Pain Type",
                  choices = c("ATA" = 1, "NAP" = 2, "TA" = 3, "ASY"= 4)),
      numericInput("restingBP", "Resting BP", value = 140),
      numericInput("cholesterol", "Cholesterol", value = 289),
      numericInput("fastingBS", "Fasting Blood Sugar", value = 0),
      selectInput("restingECG", "Resting ECG",
                  choices = c("Normal" = 1, "ST" = 2, "LVH" = 3)),
      numericInput("maxHR", "Max HR", value = 172),
      selectInput("exerciseAngina", "Exercise Angina",
                  choices = c("Y" = 1, "N" = 0)),
      numericInput("oldpeak", "Oldpeak", value = 0.0),
      selectInput("stSlope", "ST Slope",
                  choices = c("Up" = 1, "Flat" = 2, "Down" = 3)),
      actionButton("predict", "Predict")
    ),
    mainPanel(
      textOutput("prediction")
    )
  )
)

# Means and standard deviations for numerical features

numerical_means <- c(Age = 53.5108932, RestingBP = 132.3965142,
                     Cholesterol = 198.7995643, FastingBS = 0.2331155,
                     MaxHR = 136.8093682, Oldpeak = 0.8873638)

numerical_sds <- c(Age = 9.4326165, RestingBP = 18.5141541,
                   Cholesterol = 109.3841446,
                   FastingBS = 0.4230456, MaxHR = 25.4603341,
                   Oldpeak = 1.0665702)

# Define server logic

numerical_means <- as.list(numerical_means)
numerical_sds <- as.list(numerical_sds)


server <- function(input, output) {
  observeEvent(input$predict, {
    normalized_age <- (as.numeric(input$age) -
                         numerical_means$Age) / numerical_sds$Age
    normalized_restingbp <- (as.numeric(input$restingBP) -
                               numerical_means$RestingBP) /
      numerical_sds$RestingBP
    normalized_cholesterol <- (as.numeric(input$cholesterol) -
                                 numerical_means$Cholesterol) /
      numerical_sds$Cholesterol
    normalized_fastingbs <- (as.numeric(input$fastingBS) -
                               numerical_means$FastingBS) /
      numerical_sds$FastingBS
    normalized_maxhr <- (as.numeric(input$maxHR) -
                           numerical_means$MaxHR) / numerical_sds$MaxHR
    normalized_oldpeak <- (as.numeric(input$oldpeak) -
                             numerical_means$Oldpeak) / numerical_sds$Oldpeak
    sex_input <- as.numeric(input$sex)
    chestpaintype_ata <- as.numeric(input$chestPainType == 1)
    chestpaintype_nap <- as.numeric(input$chestPainType == 2)
    chestpaintype_ta <- as.numeric(input$chestPainType == 3)
    restingecg_normal <- as.numeric(input$restingECG == 1)
    restingecg_st <- as.numeric(input$restingECG == 2)
    exerciseangina_y <- as.numeric(input$exerciseAngina)
    st_slope_flat <- as.numeric(input$stSlope == 1)
    st_slope_up <- as.numeric(input$stSlope == 2)
    
    new_data <- data.frame(
      Age = normalized_age,
      RestingBP = normalized_restingbp,
      Cholesterol = normalized_cholesterol,
      FastingBS = normalized_fastingbs,
      MaxHR = normalized_maxhr,
      Oldpeak = normalized_oldpeak,
      Sex_M = sex_input,
      chestpainType_ata = chestpaintype_ata,
      chestpainType_nap = chestpaintype_nap,
      chestpainType_ta = chestpaintype_ta,
      restingecg_normal = restingecg_normal,
      restingecg_st = restingecg_st,
      exerciseangina_y = exerciseangina_y,
      st_slope_flat = st_slope_flat,
      st_slope_up = st_slope_up
    )
    
    input_matrix <- as.matrix(new_data)
    input_matrix <- matrix(as.numeric(input_matrix), ncol = ncol(input_matrix))
    
    prediction <- model %>% predict(input_matrix)
    prediction_percentage <- round(prediction * 100, 2)
    
    likeliness <- ifelse(prediction <= 0.3, "Low likeliness of heart diseases.",
                         ifelse(prediction <= 0.7,
                                "Moderate likeliness of heart diseases.",
                                "High likeliness of heart diseases."))
    
    # Construct the final message with the disclaimer
    final_message <- paste0("Prediction: ", prediction_percentage, "%.\n", 
                            likeliness, "\n\n",
                            "Disclaimer: This model has a 96.7% validation accuracy 
                            and is intended for initial assessment only. ",
                            "Please consult a doctor for a conclusive diagnosis.")
    
    # Display the message
    output$prediction <- renderText({ 
      final_message 
    })
  })
}
# Run the app
app <- shinyApp(ui = ui, server = server)