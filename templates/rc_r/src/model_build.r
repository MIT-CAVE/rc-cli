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
cat('{
  "Model": "Hello from the model_build.r script!",
  "sort_by": "lat"
}', file = "data/model_build_outputs/model.json")

print(paste(
  "Success: The '",
  getwd(),
  "/data/model_build_outputs/model.json' file has been saved.",
  sep = ""
))
