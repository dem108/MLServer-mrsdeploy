# Demo05: R code nd model as objects (same as Demo01), but inputs/outputs as dataframes

# In this example, the code comes from an object (code = manualTransmission) 
# and the model comes from a model object (model = carsModel) as it was in example 1. 
# However, in this example, the inputs and outputs are provided in the form of dataframes.

######## Create/Test Logistic Regression Model #########

# R Server 9.0, load mrsdeploy. Later versions can skip.    
library(mrsdeploy)

# Estimate the probability of a vehicle being fitted with 
# a manual transmission based on horsepower (hp) and weight (wt)

# load the mtcars dataset
data(mtcars)

# Split the mtcars dataset into 75% train and 25% test dataset
train_ind <- sample(seq_len(nrow(mtcars)), size = floor(0.75 * nrow(mtcars)))
train <- mtcars[train_ind,]
test <- mtcars[-train_ind,]

# Create glm model with training `mtcars` dataset
carsModel <- rxLogit(formula = am ~ hp + wt, data = train)

# Create a list to pass the data column info together with the model object
carsModelInfo <- list(predictiveModel = carsModel, colInfo = rxCreateColInfo(train))

# Produce a prediction function that can use the model and column info
manualTransmission <- function(carData) {
  newdata <- rxImport(carData, colInfo = carsModelInfo$colInfo)
  rxPredict(carsModelInfo$predictiveModel, newdata, type = "response")
}

# test function locally by printing results
print(manualTransmission(test))


############# Log into Microsoft R Server ##############

# Use `remoteLogin` to authenticate with R Server.
# REMEMBER: Replace with your login details
remoteLogin("http://localhost:12800", 
            username = "admin", 
            password = "P@ssw0rd!@#$",
            session = FALSE)


############## Publish Model as a Service ##############

# Generate a unique serviceName for demos and assign to variable serviceName
serviceName <- paste0("mtService", round(as.numeric(Sys.time()), 0))

# Publish as service using publishService() function from 
# mrsdeploy package. Use the service name variable and provide
# unique version number. Assign service to the variable `api`
api <- publishService(
  serviceName,
  code = manualTransmission,
  model = carsModelInfo,
  inputs = list(carData = "data.frame"),
  outputs = list(answer = "data.frame"),
  v = "v1.0.0"
)

################## Consume Service in R ################

# Print capabilities that define the service holdings: service 
# name, version, descriptions, inputs, outputs, and the 
# name of the function to be consumed
print(api$capabilities())

# Consume service by calling function, `manualTransmission` contained in this service

# consume service using existing data frame `test`
result <- api$manualTransmission(test)
print(result$output("answer")) 

# consume service by constructing data frames with single row and multiple rows
emptyDataFrame <- data.frame(mpg = numeric(),
                             cyl = numeric(),
                             disp = numeric(),
                             hp = numeric(),
                             drat = numeric(),
                             wt = numeric(),
                             qsec = numeric(),
                             vs = numeric(),
                             am = numeric(),
                             gear = numeric(),
                             carb = numeric())

singleRowDataFrame <- rbind(emptyDataFrame, data.frame(mpg = 21.0,
                                                       cyl = 6,
                                                       disp = 160,
                                                       hp = 110,
                                                       drat = 3.90,
                                                       wt = 2.620,
                                                       qsec = 16.46,
                                                       vs = 0,
                                                       am = 1,
                                                       gear = 4,
                                                       carb = 4))
result <- api$manualTransmission(singleRowDataFrame)
print(result$output("answer"))

multipleRowsDataFrame <- rbind(emptyDataFrame, data.frame(mpg = c(21.0, 20.1),
                                                          cyl = c(6, 5),
                                                          disp = c(160, 159),
                                                          hp = c(110, 109),
                                                          drat = c(3.90, 2.94),
                                                          wt = c(2.620, 2.678),
                                                          qsec = c(16.46, 15.67),
                                                          vs = c(0, 0),
                                                          am = c(1, 1),
                                                          gear = c(4, 3),
                                                          carb = c(4, 2)))
result <- api$manualTransmission(multipleRowsDataFrame)
print(result$output("answer")) 


######### Get Swagger File for Service in R Now ########

# During this authenticated session, download the  
# Swagger-based JSON file that defines this service
swagger <- api$swagger()
cat(swagger, file = "swagger-demo05.json", append = FALSE)

# Now you can share Swagger-based JSON so others can consume it
# Check out http://editor.swagger.io/ - Try `Generate Client` 


######### Delete service version when finished #########

# User who published service or user with owner role can
# remove the service when it is no longer needed
status <- deleteService(serviceName, "v1.0.0")
status


################### Log off R Server ###################

remoteLogout()
