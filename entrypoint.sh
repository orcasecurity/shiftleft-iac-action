#!/bin/bash

exit_with_err() {
  local msg="${1?}"
  echo "ERROR: ${msg}"
  exit 1
}

function run_orca_iac_scan() {
  cd "${GITHUB_WORKSPACE}" || exit_with_err "could not find GITHUB_WORKSPACE: ${GITHUB_WORKSPACE}"
  echo "Running Orca IaC scan:"
  echo orca-cli "${GLOBAL_FLAGS[@]}" iac scan "${SCAN_FLAGS[@]}"
  orca-cli "${GLOBAL_FLAGS[@]}" iac scan "${SCAN_FLAGS[@]}"
  export ORCA_EXIT_CODE=$?

  # save exit code on output
  echo "exit_code=${ORCA_EXIT_CODE}" >>"$GITHUB_OUTPUT"
}

function set_global_flags() {
  GLOBAL_FLAGS=()
  if [ "${INPUT_EXIT_CODE}" ]; then
    GLOBAL_FLAGS+=(--exit-code "${INPUT_EXIT_CODE}")
  fi
  if [ "${INPUT_NO_COLOR}" == "true" ]; then
    GLOBAL_FLAGS+=(--no-color)
  fi
  if [ "${INPUT_PROJECT_KEY}" ]; then
    GLOBAL_FLAGS+=(--project-key "${INPUT_PROJECT_KEY}")
  fi
  if [ "${INPUT_SILENT}" == "true" ]; then
    GLOBAL_FLAGS+=(--silent)
  fi
  if [ "${INPUT_CONFIG}" ]; then
    GLOBAL_FLAGS+=(--config "${INPUT_CONFIG}")
  fi
  if [ "${INPUT_BASELINE_CONTEXT_KEY}" ]; then
    GLOBAL_FLAGS+=(--baseline-context-key "${INPUT_BASELINE_CONTEXT_KEY}")
  fi
  if [ "${INPUT_DISABLE_BASELINE}" == "true" ]; then
    GLOBAL_FLAGS+=(--disable-baseline)
  fi
  if [ "${INPUT_DISABLE_ERR_REPORT}" == "true" ]; then
    GLOBAL_FLAGS+=(--disable-err-report)
  fi
  if [ "${INPUT_SYNC_BASELINE}" ]; then
    GLOBAL_FLAGS+=(--sync-baseline "${INPUT_SYNC_BASELINE}")
  fi
  if [ "${INPUT_DISPLAY_NAME}" ]; then
    GLOBAL_FLAGS+=(--display-name "${INPUT_DISPLAY_NAME}")
  fi
}

# Json format must be reported and be stored in a file for github annotations
function prepare_json_to_file_flags() {
  # Output directory must be provided to store the json results
  OUTPUT_FOR_JSON="${INPUT_OUTPUT}"
  CONSOLE_OUTPUT_FOR_JSON="${INPUT_CONSOLE_OUTPUT}"
  if [[ -z "${INPUT_OUTPUT}" ]]; then
    # Results should be printed to console in the selected format
    CONSOLE_OUTPUT_FOR_JSON="${INPUT_FORMAT:-cli}"
    # Results should also be stored in a directory
    OUTPUT_FOR_JSON="orca_results/"
  fi

  if [[ -z "${INPUT_FORMAT}" ]]; then
    # The default format should be provided together with the one we are adding
    FORMATS_FOR_JSON="cli,json"
  else
    if [[ "${INPUT_FORMAT}" == *"json"* ]]; then
      FORMATS_FOR_JSON="${INPUT_FORMAT}"
    else
      FORMATS_FOR_JSON="${INPUT_FORMAT},json"
    fi
  fi

  # Used during the annotation process
  export OUTPUT_FOR_JSON CONSOLE_OUTPUT_FOR_JSON FORMATS_FOR_JSON
}

function set_iac_scan_flags() {
  SCAN_FLAGS=()
  if [ "${INPUT_PATH}" ]; then
    SCAN_FLAGS+=(--path "${INPUT_PATH}")
  fi
  if [ "${INPUT_CLOUD_PROVIDER}" ]; then
    SCAN_FLAGS+=(--cloud-provider "${INPUT_CLOUD_PROVIDER}")
  fi
  if [ "${INPUT_EXCLUDE_PATHS}" ]; then
    SCAN_FLAGS+=(--exclude-paths "${INPUT_EXCLUDE_PATHS}")
  fi
  if [ "${INPUT_PLATFORM}" ]; then
    SCAN_FLAGS+=(--platform "${INPUT_PLATFORM}")
  fi
  if [ "${INPUT_EXCLUDE_PLATFORM}" ]; then
    SCAN_FLAGS+=(--exclude-platform "${INPUT_EXCLUDE_PLATFORM}")
  fi
  if [ "${INPUT_CONTROL_TIMEOUT}" ]; then
    SCAN_FLAGS+=(--control_timeout "${INPUT_CONTROL_TIMEOUT}")
  fi
  if [ "${INPUT_TIMEOUT}" ]; then
    SCAN_FLAGS+=(--timeout "${INPUT_TIMEOUT}")
  fi
  if [ "${INPUT_IGNORE_FAILED_EXEC_CONTROLS}" == "true" ]; then
    SCAN_FLAGS+=(--ignore-failed-exec-controls)
  fi
  if [ "${INPUT_PREVIEW_LINES}" ]; then
    SCAN_FLAGS+=(--preview-lines "${INPUT_PREVIEW_LINES}")
  fi
  if [ "${INPUT_SHOW_FAILED_ISSUES_ONLY}" = "true" ]; then
    SCAN_FLAGS+=(--show-failed-issues-only)
  fi
  if [ "${FORMATS_FOR_JSON}" ]; then
    SCAN_FLAGS+=(--format "${FORMATS_FOR_JSON}")
  fi
  if [ "${OUTPUT_FOR_JSON}" ]; then
    SCAN_FLAGS+=(--output "${OUTPUT_FOR_JSON}")
  fi
  if [ "${CONSOLE_OUTPUT_FOR_JSON}" ]; then
    SCAN_FLAGS+=(--console-output="${CONSOLE_OUTPUT_FOR_JSON}")
  fi
  if [ "${INPUT_CUSTOM_CONTROLS}" ]; then
    SCAN_FLAGS+=(--custom-controls "${INPUT_CUSTOM_CONTROLS}")
  fi
  if [ "${INPUT_GENERATE_REGO_INPUT}" ]; then
    SCAN_FLAGS+=(--generate-rego-input "${INPUT_GENERATE_REGO_INPUT}")
  fi
  if [ "${INPUT_INCLUDE_COMPRESSED_FILES}" = "true" ]; then
    SCAN_FLAGS+=(--include-compressed-files)
  fi
  if [ "${INPUT_MAX_FILE_SIZE}" ]; then
    SCAN_FLAGS+=(--max-file-size "${INPUT_MAX_FILE_SIZE}")
  fi
  if [ "${INPUT_TERRAFORM_VARS_PATH}" ]; then
    SCAN_FLAGS+=(--terraform-vars-path "${INPUT_TERRAFORM_VARS_PATH}")
  fi
}

function set_env_vars() {
  if [ "${INPUT_API_TOKEN}" ]; then
    export ORCA_SECURITY_API_TOKEN="${INPUT_API_TOKEN}"
  fi
}

function validate_flags() {
  [[ -n "${INPUT_PATH}" ]] || exit_with_err "Path must be provided"
  [[ "${INPUT_PATH}" != /* ]] || exit_with_err "Path shouldn't be absolute. Please provide a relative path within the repository. Use '.' to scan the entire repository"
  [[ -n "${INPUT_API_TOKEN}" ]] || exit_with_err "api_token must be provided"
  [[ -n "${INPUT_PROJECT_KEY}" ]] || exit_with_err "project_key must be provided"
  [[ -z "${INPUT_OUTPUT}" ]] || [[ "${INPUT_OUTPUT}" == */ ]] || [[ -d "${INPUT_OUTPUT}" ]] || exit_with_err "Output must be a folder (end with /)"
}

annotate() {
  if [ "${INPUT_SHOW_ANNOTATIONS}" == "false" ]; then
    exit "${ORCA_EXIT_CODE}"
  fi
  mkdir -p "/app/${OUTPUT_FOR_JSON}"
  cp "${OUTPUT_FOR_JSON}/iac.json" "/app/${OUTPUT_FOR_JSON}/" || exit_with_err "error during annotations initiation"
  cd /app
  npm run build --if-present
  node dist/index.js
}

function main() {
  validate_flags
  set_env_vars
  set_global_flags
  prepare_json_to_file_flags
  set_iac_scan_flags
  run_orca_iac_scan
  annotate
}

main "${@}"
