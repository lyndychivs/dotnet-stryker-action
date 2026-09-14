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

quote_arg() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
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
  find . -type d -name reports -path '*/StrykerOutput/*/reports' | sort | tail -n 1
}

detect_mutation_score() {
  markdown_report="$1"
  json_report="$2"

  if [ -n "${json_report}" ] && [ -f "${json_report}" ]; then
    score_value=$(sed -n 's/.*"mutationScore"[[:space:]]*:[[:space:]]*\([0-9.][0-9.]*\).*/\1/p' "${json_report}" | head -n 1)
    if [ -n "${score_value}" ]; then
      printf '%s%%\n' "${score_value}"
      return 0
    fi
  fi

  if [ -n "${markdown_report}" ] && [ -f "${markdown_report}" ]; then
    sed -n 's/.*final mutation score is \([0-9.][0-9.]*%\).*/\1/p' "${markdown_report}" | tail -n 1
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

print_effective_command() {
  printf 'effective-command: dotnet-stryker'
  redact_next=0

  for arg in "$@"; do
    if [ "${redact_next}" -eq 1 ]; then
      printf " '[REDACTED]'"
      redact_next=0
      continue
    fi

    case "${arg}" in
      --dashboard-api-key)
        printf " '--dashboard-api-key'"
        redact_next=1
        ;;
      --dashboard-api-key=*)
        printf " '--dashboard-api-key=[REDACTED]'"
        ;;
      *)
        printf ' %s' "$(quote_arg "${arg}")"
        ;;
    esac
  done

  printf '\n'
}

configuration_file="${INPUT_CONFIGFILE:-}"

if [ -n "${configuration_file}" ]; then
  if [ ! -f "${configuration_file}" ]; then
    echo "Configuration file not found: ${configuration_file}" >&2
    exit 1
  fi

  echo "config-file: ${configuration_file}"
else
  echo "config-file: not provided; using Stryker default configuration discovery"
fi

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
  # Intentionally allow shell-style splitting and quoting for advanced caller-controlled overrides.
  # shellcheck disable=SC2086
  eval "set -- \"\$@\" ${stryker_args}"
fi

if is_true "${INPUT_SHOWEFFECTIVECOMMAND:-false}"; then
  print_effective_command "$@"
fi

set +e
dotnet-stryker "$@"
exit_code=$?
set -e

report_dir=$(find_latest_report_dir)
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
