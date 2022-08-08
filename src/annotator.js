const core = require("@actions/core");

function getDetail(controlResults, file) {
    let details = controlResults.control["details"];
    let recommendation = file["expected_value"];
    if (recommendation) {
        details = `${details}\n\nRecommendation:\n${recommendation}`
    }
    return details
}

function extractAnnotations(results) {
    let annotations = [];
    for (const controlResults of results.results) {
        for (const finding of controlResults.findings) {
            for (const file of finding.files) {
                annotations.push({
                    file: file["file_name"],
                    startLine: file["line"],
                    endLine: file["line"],
                    priority: controlResults["priority"],
                    status: controlResults["status"],
                    title: controlResults.control["title"],
                    details: getDetail(controlResults, file),
                });
            }
        }
    }
    return annotations;
}

function annotateChangesWithResults(results) {
    const annotations = extractAnnotations(results);
    annotations.forEach((annotation) => {
        let annotationProperties = {
            title: `[${annotation.priority}] ${annotation.title}`,
            startLine: annotation.startLine,
            endLine: annotation.endLine,
            file: annotation.file,
        };
        if (annotation.status === "FAILED") {
            core.error(annotation.details, annotationProperties);
        } else {
            core.warning(annotation.details, annotationProperties);
        }
    });
}

module.exports = {
    annotateChangesWithResults,
};
