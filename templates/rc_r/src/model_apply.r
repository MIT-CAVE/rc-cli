# r model apply example
print("Reading Input Data")
Sys.sleep(1)
print("Solving Dark Matter Waveforms")
Sys.sleep(1)
print("Quantum Computer is Overheating")
Sys.sleep(1)
print("Trying Alternate Measurement Cycles")
Sys.sleep(1)
print("Found a Great Solution!")
Sys.sleep(1)
print("Checking Validity")
Sys.sleep(1)
print("The Answer is 42!")
Sys.sleep(1)

# Copy in example output as the output for this algorithm
if (file.exists("data/model_apply_outputs/proposed_sequences.json")) {
  file.remove("data/model_apply_outputs/proposed_sequences.json")
}
cat("{}", file = "data/model_apply_outputs/proposed_sequences.json")

print(paste(
  "Success: The '",
  getwd(),
  "/data/model_apply_outputs/proposed_sequences.json' file has been saved.",
  sep = ""
))
print("Done!")
