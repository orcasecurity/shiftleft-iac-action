const annotator = require("./annotator");
const core = require("@actions/core");
const filepath = require("path");
const fs = require("fs");

function readJSON(filename) {
  const rawData = fs.readFileSync(filename);
  return JSON.parse(rawData.toString());
}

function setWorkflowStatus(statusCode) {
  if (statusCode === "0") {
    return;
  }
  core.setFailed(`Orca IaC scan failed with exit code ${statusCode}`);
}

function main() {
  console.log("Processing Orca Shift-Left scan results...");
  const jsonOutput = filepath.join(process.env.OUTPUT_FOR_JSON, "iac.json");
  try {
    const parsedResults = readJSON(jsonOutput);
    annotator.annotateChangesWithResults(parsedResults);
    setWorkflowStatus(process.env.ORCA_EXIT_CODE);
  } catch (e) {
    console.error(e);
  }
}

main();
