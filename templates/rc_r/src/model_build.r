# import base package for Sys.sleep
# install.packages("base")

print("Initializing Quark Reducer")
Sys.sleep(1)
print("Placing Nano Tubes In Gravitational Wavepool")
Sys.sleep(1)
print("Measuring Particle Deviations")
Sys.sleep(1)
print("Programming Artificial Noggins")
Sys.sleep(1)
print("Beaming in Complex Materials")
Sys.sleep(1)
print("Solving Model")
Sys.sleep(1)
print("Saving Solved Model State")
Sys.sleep(1)

# write an output file
cat("{\n    'Model':'Hello from the model_build.r script!',    \n    'sort_by':'lat'\n}", file="data/model_build_outputs/model.json")

print(paste("Success: The '",getwd(),"/data/model_build_outputs/model.json' file has been saved.",sep = ""))
