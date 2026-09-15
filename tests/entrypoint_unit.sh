#!/bin/sh
# Unit tests for entrypoint.sh's shell functions. Run directly with `sh
# tests/entrypoint_unit.sh` (requires jq on PATH); no GitHub Actions
# environment or dotnet-stryker invocation is needed.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to run these tests" >&2
  exit 1
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT

ENTRYPOINT_SOURCE_ONLY=1
export ENTRYPOINT_SOURCE_ONLY
# shellcheck disable=SC1090
. "${script_dir}/../entrypoint.sh"

failures=0

assert_eq() {
  description="$1"
  expected="$2"
  actual="$3"

  if [ "${expected}" != "${actual}" ]; then
    echo "FAIL: ${description}: expected '${expected}', got '${actual}'" >&2
    failures=$((failures + 1))
  else
    echo "PASS: ${description}"
  fi
}

# A JSON report that doesn't match the expected `.files[].mutants[].status`
# shape makes jq fail (e.g. `.files` missing). detect_mutation_score must not
# abort the caller under `set -eu` — it should fall back to the markdown
# report (or emit an empty line if none is given).
malformed_json="${tmp_dir}/malformed.json"
printf '{"not-files": []}\n' > "${malformed_json}"

score=$(detect_mutation_score "" "${malformed_json}")
assert_eq "malformed json report with no markdown fallback yields empty score" "" "${score}"

markdown_report="${tmp_dir}/report.md"
printf 'The final mutation score is 42.5%%\n' > "${markdown_report}"

score=$(detect_mutation_score "${markdown_report}" "${malformed_json}")
assert_eq "malformed json report falls back to markdown score" "42.5%" "${score}"

# A well-formed json report should still be parsed normally.
valid_json="${tmp_dir}/valid.json"
cat > "${valid_json}" <<'EOF'
{"files":{"a.cs":{"mutants":[{"status":"Killed"},{"status":"Survived"}]}}}
EOF

score=$(detect_mutation_score "" "${valid_json}")
assert_eq "valid json report is parsed into a score" "50%" "${score}"

# is_true
for truthy in true TRUE True 1 yes YES on ON; do
  if is_true "${truthy}"; then
    echo "PASS: is_true accepts '${truthy}'"
  else
    echo "FAIL: is_true rejected '${truthy}'" >&2
    failures=$((failures + 1))
  fi
done

for falsy in false FALSE 0 no off "" maybe; do
  if is_true "${falsy}"; then
    echo "FAIL: is_true accepted '${falsy}'" >&2
    failures=$((failures + 1))
  else
    echo "PASS: is_true rejects '${falsy}'"
  fi
done

# detect_threshold_status
assert_eq "exit code 0 is a passed threshold" "passed" "$(detect_threshold_status 0)"
assert_eq "non-zero exit code is a failed threshold" "failed" "$(detect_threshold_status 1)"

if [ "${failures}" -ne 0 ]; then
  echo "${failures} test(s) failed" >&2
  exit 1
fi

echo "All entrypoint unit tests passed"
