#!/bin/bash
set -e

exit_with_err() {
  local msg="${1?}"
  echo "ERROR: ${msg}"
  exit 1
}

function run_orca_iac_scan() {
  cd "$GITHUB_WORKSPACE"
  echo "Running Orca IaC scan:"
  echo orca-cli "${GLOBAL_FLAGS[@]}" iac scan "${SCAN_FLAGS[@]}"
  orca-cli "${GLOBAL_FLAGS[@]}" iac scan "${SCAN_FLAGS[@]}"
  returnCode=$?
  exit $returnCode
}

function set_global_flags() {
  GLOBAL_FLAGS=()
  if [ "$INPUT_PATH" ]; then
    SCAN_FLAGS+=(--path "$INPUT_PATH")
  fi
  if [ "$INPUT_EXIT_CODE" ]; then
    GLOBAL_FLAGS+=(--exit-code "$INPUT_EXIT_CODE")
  fi
  if [ "$INPUT_NO_COLOR" == "true" ]; then
    GLOBAL_FLAGS+=(--no-color)
  fi
  if [ "$INPUT_PROJECT_KEY" ]; then
    GLOBAL_FLAGS+=(--project-key "$INPUT_PROJECT_KEY")
  fi
}

function set_iac_scan_flags() {
  SCAN_FLAGS=()
  if [ "$INPUT_CLOUD_PROVIDER" ]; then
    SCAN_FLAGS+=(--cloud-provider "$INPUT_CLOUD_PROVIDER")
  fi
  if [ "$INPUT_EXCLUDE_PATHS" ]; then
    SCAN_FLAGS+=(--exclude-paths "$INPUT_EXCLUDE_PATHS")
  fi
  if [ "$INPUT_FORMAT" ]; then
    SCAN_FLAGS+=(--format "$INPUT_FORMAT")
  fi
  if [ "$INPUT_OUTPUT" ]; then
    SCAN_FLAGS+=(--output "$INPUT_OUTPUT")
  fi
  if [ "$INPUT_PLATFORM" ]; then
    SCAN_FLAGS+=(--platform "$INPUT_PLATFORM")
  fi
  if [ "$INPUT_TIMEOUT" ]; then
    SCAN_FLAGS+=(--timeout "$INPUT_TIMEOUT")
  fi
}

function set_env_vars() {
  if [ "$INPUT_API_TOKEN" ]; then
    export ORCA_SECURITY_API_TOKEN="$INPUT_API_TOKEN"
  fi
}

function validate_flags() {
  [[ -n "$INPUT_PATH" ]] || exit_with_err "path must be provided"
  [[ -n "$INPUT_API_TOKEN" ]] || exit_with_err "api_token must be provided"
  [[ -n "$INPUT_PROJECT_KEY" ]] || exit_with_err "project_key must be provided"
}

function main() {
  validate_flags
  set_env_vars
  set_global_flags
  set_iac_scan_flags
  run_orca_iac_scan
}

main "${@}"
