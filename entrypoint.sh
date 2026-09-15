#!/bin/sh
set -eu

export PATH="$PATH:/root/.dotnet/tools"

is_true() {
  case "${1:-}" in
    true|TRUE|True|1|yes|YES|on|ON)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

write_output() {
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    printf '%s=%s\n' "$1" "$2" >> "${GITHUB_OUTPUT}"
  fi
}

append_summary() {
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    printf '%s\n' "$1" >> "${GITHUB_STEP_SUMMARY}"
  fi
}

find_first_report() {
  report_dir="$1"
  pattern="$2"

  find "${report_dir}" -maxdepth 1 -type f -name "${pattern}" | sort | head -n 1
}

find_latest_report_dir() {
  since_marker="$1"

  find . -type d -name reports -path '*/StrykerOutput/*/reports' -newer "${since_marker}" | sort | tail -n 1
}

detect_mutation_score() {
  markdown_report="$1"
  json_report="$2"

  if [ -n "${json_report}" ] && [ -f "${json_report}" ]; then
    score_value=$(jq -r '
      [.files[].mutants[].status] as $s
      | ($s | map(select(. == "Killed" or . == "Timeout")) | length) as $detected
      | ($s | map(select(. == "Killed" or . == "Timeout" or . == "Survived" or . == "NoCoverage")) | length) as $total
      | if $total == 0 then "" else (($detected / $total * 100) * 100 | round / 100 | tostring) end
    ' "${json_report}" 2>/dev/null) || score_value=""
    if [ -n "${score_value}" ]; then
      printf '%s%%\n' "${score_value}"
      return 0
    fi
  fi

  if [ -n "${markdown_report}" ] && [ -f "${markdown_report}" ]; then
    # Stryker's markdown reporter formats the percentage using the active
    # .NET culture, which may use a comma as the decimal separator; normalize
    # to a period so the output is consistent regardless of locale.
    sed -n 's/.*final mutation score is \([0-9.,][0-9.,]*%\).*/\1/p' "${markdown_report}" | tail -n 1 | tr ',' '.'
    return 0
  fi

  printf '\n'
}

detect_threshold_status() {
  exit_code="$1"

  if [ "${exit_code}" -eq 0 ]; then
    printf 'passed\n'
  else
    printf 'failed\n'
  fi
}

# Allows tests to source this script for its functions without running the
# rest of it (which invokes dotnet-stryker and expects GitHub Actions env vars).
if [ "${ENTRYPOINT_SOURCE_ONLY:-}" = "1" ]; then
  # shellcheck disable=SC2317
  return 0 2>/dev/null || exit 0
fi

configuration_file="${INPUT_CONFIGFILE:-}"
config_missing=false

if [ -n "${configuration_file}" ]; then
  if [ ! -f "${configuration_file}" ]; then
    echo "Configuration file not found: ${configuration_file}" >&2
    config_missing=true
  else
    echo "config-file: ${configuration_file}"
  fi
else
  echo "config-file: not provided; using Stryker default configuration discovery"
fi

# Record when this run started so find_latest_report_dir can tell this run's
# report apart from a stale one left by an earlier invocation sharing this
# workspace (e.g. a workflow that calls this action more than once), even
# when this run exits early below without invoking dotnet-stryker. Unlike
# deleting leftover StrykerOutput directories, this can't destroy another
# invocation's report before it's been read.
report_marker=$(mktemp)
trap 'rm -f "${report_marker}"' EXIT

if [ "${config_missing}" = true ]; then
  exit_code=1
else
  if [ -n "${STRYKER_DASHBOARD_API_KEY:-}" ]; then
    echo "dashboard-api-key: provided via environment"
  else
    echo "dashboard-api-key: not provided"
  fi

  if [ -n "${configuration_file}" ]; then
    set -- --config-file "${configuration_file}"
  fi

  stryker_args="${INPUT_STRYKERARGS:-}"

  if [ -n "${stryker_args}" ]; then
    # Whitespace-split only (no shell quoting/expansion) so args can't inject commands.
    set -f
    # shellcheck disable=SC2086
    set -- "$@" ${stryker_args}
    set +f
  fi

  set +e
  dotnet-stryker "$@"
  exit_code=$?
  set -e
fi

report_dir=$(find_latest_report_dir "${report_marker}")
html_report=""
json_report=""
markdown_report=""

if [ -n "${report_dir}" ]; then
  html_report=$(find_first_report "${report_dir}" '*.html')
  json_report=$(find_first_report "${report_dir}" '*.json')
  markdown_report=$(find_first_report "${report_dir}" '*.md')
fi

mutation_score=$(detect_mutation_score "${markdown_report}" "${json_report}")
threshold_status=$(detect_threshold_status "${exit_code}")

write_output "mutationScore" "${mutation_score}"
write_output "thresholdStatus" "${threshold_status}"
write_output "reportDirectory" "${report_dir}"
write_output "htmlReportPath" "${html_report}"
write_output "jsonReportPath" "${json_report}"
write_output "markdownSummaryPath" "${markdown_report}"

if is_true "${INPUT_WRITESTEPSUMMARY:-true}" && [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  if [ "${threshold_status}" = "passed" ]; then
    append_summary "## Stryker.NET run ✅ Passed"
  else
    append_summary "## Stryker.NET run ❌ Failed"
  fi
  append_summary ""

  if [ -n "${mutation_score}" ]; then
    append_summary "- Mutation score: **${mutation_score}**"
  else
    append_summary "- Mutation score: _not available (no report found)_"
  fi

  append_summary "- Exit code: \`${exit_code}\`"

  if [ -n "${report_dir}" ]; then
    append_summary "- Report directory: \`${report_dir}\`"
  else
    append_summary "- Report directory: _not found_"
  fi

  if [ -n "${markdown_report}" ] && [ -f "${markdown_report}" ]; then
    append_summary ""
    append_summary "<details>"
    append_summary "<summary>Markdown summary report</summary>"
    append_summary ""
    cat "${markdown_report}" >> "${GITHUB_STEP_SUMMARY}"
    append_summary ""
    append_summary "</details>"
  fi
fi

exit "${exit_code}"
