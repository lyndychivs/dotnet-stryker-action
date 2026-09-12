#!/bin/sh
set -eu

export PATH="$PATH:/root/.dotnet/tools"

trim() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

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
  if [ -n "${INPUT_OUTPUT:-}" ] && [ -d "${INPUT_OUTPUT}" ]; then
    find "${INPUT_OUTPUT}" -type d -name reports | sort | tail -n 1
    return 0
  fi

  find . -type d -name reports -path '*/StrykerOutput/*/reports' | sort | tail -n 1
}

detect_mutation_score() {
  markdown_report="$1"
  json_report="$2"

  if [ -n "${markdown_report}" ] && [ -f "${markdown_report}" ]; then
    sed -n 's/.*final mutation score is \([0-9.][0-9.]*%\).*/\1/p' "${markdown_report}" | tail -n 1
    return 0
  fi

  if [ -n "${json_report}" ] && [ -f "${json_report}" ]; then
    score_value=$(sed -n 's/.*"mutationScore"[[:space:]]*:[[:space:]]*\([0-9.][0-9.]*\).*/\1/p' "${json_report}" | head -n 1)
    if [ -n "${score_value}" ]; then
      printf '%s%%\n' "${score_value}"
      return 0
    fi
  fi

  printf '\n'
}

detect_break_threshold() {
  markdown_report="$1"

  if [ -n "${markdown_report}" ] && [ -f "${markdown_report}" ]; then
    threshold_value=$(sed -n 's/.*Coverage Thresholds:.*break: \([0-9.][0-9.]*\).*/\1/p' "${markdown_report}" | tail -n 1)
    if [ -n "${threshold_value}" ]; then
      printf '%s\n' "${threshold_value}"
      return 0
    fi
  fi

  if [ -n "${INPUT_BREAKAT:-}" ]; then
    printf '%s\n' "${INPUT_BREAKAT}"
    return 0
  fi

  printf '\n'
}

detect_threshold_status() {
  mutation_score="$1"
  break_threshold="$2"

  if [ -z "${mutation_score}" ] || [ -z "${break_threshold}" ]; then
    printf '\n'
    return 0
  fi

  mutation_score_value=${mutation_score%\%}

  if awk "BEGIN { exit !(${mutation_score_value} >= ${break_threshold}) }"; then
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
      STRYKER_DASHBOARD_API_KEY=*)
        printf " 'STRYKER_DASHBOARD_API_KEY=[REDACTED]'"
        ;;
      *)
        printf ' %s' "$(quote_arg "${arg}")"
        ;;
    esac
  done

  printf '\n'
}

configuration_file="${INPUT_CONFIGURATIONFILE:-}"

if [ -z "${configuration_file}" ]; then
  echo "configurationFile input is required." >&2
  exit 1
fi

if [ ! -f "${configuration_file}" ]; then
  echo "Configuration file not found: ${configuration_file}" >&2
  exit 1
fi

echo "config-file: ${configuration_file}"

if [ -n "${STRYKER_DASHBOARD_API_KEY:-}" ]; then
  echo "dashboard-api-key: provided via environment"
else
  echo "dashboard-api-key: not provided"
fi

echo "dotnet-stryker-version: $(dotnet-stryker --version)"

set -- --config-file "${configuration_file}"

if [ -n "${INPUT_REPORTERS:-}" ]; then
  old_ifs=$IFS
  IFS=','
  for reporter in ${INPUT_REPORTERS}; do
    reporter_value=$(trim "${reporter}")
    if [ -n "${reporter_value}" ]; then
      set -- "$@" --reporter "${reporter_value}"
    fi
  done
  IFS=$old_ifs
fi

if [ -n "${INPUT_OUTPUT:-}" ]; then
  set -- "$@" --output "${INPUT_OUTPUT}"
fi

if [ -n "${INPUT_THRESHOLDHIGH:-}" ]; then
  set -- "$@" --threshold-high "${INPUT_THRESHOLDHIGH}"
fi

if [ -n "${INPUT_THRESHOLDLOW:-}" ]; then
  set -- "$@" --threshold-low "${INPUT_THRESHOLDLOW}"
fi

if [ -n "${INPUT_BREAKAT:-}" ]; then
  set -- "$@" --break-at "${INPUT_BREAKAT}"
fi

if [ -n "${INPUT_SINCE:-}" ]; then
  if is_true "${INPUT_SINCE}"; then
    set -- "$@" --since
  else
    set -- "$@" "--since:${INPUT_SINCE}"
  fi
fi

if [ -n "${INPUT_WITHBASELINE:-}" ]; then
  if is_true "${INPUT_WITHBASELINE}"; then
    set -- "$@" --with-baseline
  else
    set -- "$@" "--with-baseline:${INPUT_WITHBASELINE}"
  fi
fi

if [ -n "${INPUT_VERBOSITY:-}" ]; then
  set -- "$@" --verbosity "${INPUT_VERBOSITY}"
fi

if [ -n "${INPUT_CLIARGS:-}" ]; then
  # Intentionally allow shell-style splitting and quoting for advanced caller-controlled overrides.
  # shellcheck disable=SC2086
  eval "set -- \"\$@\" ${INPUT_CLIARGS}"
fi

if is_true "${INPUT_SHOWEFFECTIVECOMMAND:-false}"; then
  print_effective_command "$@"
fi

set +e
dotnet-stryker "$@"
exit_code=$?
set -e

report_dir=$(find_latest_report_dir || true)
html_report=""
json_report=""
markdown_report=""

if [ -n "${report_dir}" ]; then
  html_report=$(find_first_report "${report_dir}" '*.html')
  json_report=$(find_first_report "${report_dir}" '*.json')
  markdown_report=$(find_first_report "${report_dir}" '*.md')
fi

mutation_score=$(detect_mutation_score "${markdown_report}" "${json_report}")
break_threshold=$(detect_break_threshold "${markdown_report}")
threshold_status=$(detect_threshold_status "${mutation_score}" "${break_threshold}")

write_output "mutationScore" "${mutation_score}"
write_output "thresholdStatus" "${threshold_status}"
write_output "reportDirectory" "${report_dir}"
write_output "htmlReportPath" "${html_report}"
write_output "jsonReportPath" "${json_report}"
write_output "markdownSummaryPath" "${markdown_report}"

if is_true "${INPUT_WRITESTEPSUMMARY:-true}" && [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  append_summary "## Stryker.NET run"
  append_summary ""
  append_summary "- Exit code: \`${exit_code}\`"

  if [ -n "${mutation_score}" ]; then
    append_summary "- Mutation score: **${mutation_score}**"
  fi

  if [ -n "${threshold_status}" ]; then
    append_summary "- Threshold status: **${threshold_status}**"
  fi

  if [ -n "${report_dir}" ]; then
    append_summary "- Report directory: \`${report_dir}\`"
  fi

  if [ -n "${markdown_report}" ] && [ -f "${markdown_report}" ]; then
    append_summary ""
    append_summary "### Markdown summary report"
    append_summary ""
    cat "${markdown_report}" >> "${GITHUB_STEP_SUMMARY}"
    append_summary ""
  fi
fi

exit "${exit_code}"
