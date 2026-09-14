# dotnet-stryker-action
GitHub Action for mutation testing with [Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/) via Docker.

## GitHub Action
This action is a thin Stryker.NET wrapper with a small convenience layer for common CI scenarios.

Consumers should treat the [Stryker.NET configuration](https://stryker-mutator.io/docs/stryker-net/configuration) file as the primary source of truth, then use `strykerArgs` for workflow-specific overrides.

### Breaking change

Only `configFile`, `strykerArgs`, `showEffectiveCommand`, and `writeStepSummary` remain as action inputs. The curated per-flag inputs (`reporters`, `output`, `thresholdHigh`, `thresholdLow`, `breakAt`, `since`, `withBaseline`, `verbosity`) have been removed — they only translated to `dotnet-stryker` flags without adding any validation of their own, since Stryker validates its own arguments when it runs. Express them through `strykerArgs` (or your config file) instead:

```yml
# before
with:
  reporters: "markdown,json"
  thresholdHigh: "85"
  breakAt: "65"
# after
with:
  strykerArgs: "--reporter markdown --reporter json --threshold-high 85 --break-at 65"
```

`dashboardApiKey` has also been removed from the action interface.

To authenticate with the Stryker dashboard, pass the native Stryker environment variable in your workflow:

```yml
env:
  STRYKER_DASHBOARD_API_KEY: ${{ secrets.STRYKER_DASHBOARD_API_KEY }}
```

*Create a configuration file:*
```
dotnet stryker init
```

### Runtime

The action's Docker image runs on the .NET 10 SDK.

## Inputs
| Input | Description | Default |
| :--- | :--- | :--- |
| `configFile` | Path to the Stryker.NET config file. This matches the CLI flag `--config-file`. Leave empty to let Stryker use its default config discovery. | `""` |
| `strykerArgs` | Additional raw Stryker CLI arguments appended last to `dotnet-stryker`. | `""` |
| `showEffectiveCommand` | When `true`, print the assembled `dotnet-stryker` command with secret values redacted. | `"false"` |
| `writeStepSummary` | When `true`, publish a GitHub step summary from generated report artifacts when available. | `"true"` |

## Outputs
| Output | Description |
| :--- | :--- |
| `mutationScore` | Final mutation score percentage derived from the generated Stryker report when it is available. |
| `thresholdStatus` | `passed` when the `dotnet-stryker` command exits `0`, `failed` otherwise (a broken threshold, a build failure, or a test failure all count). |
| `reportDirectory` | Path to the latest Stryker reports directory generated under the configured output location. |
| `htmlReportPath` | Path to the generated HTML report when Stryker writes one. |
| `jsonReportPath` | Path to the generated JSON report when Stryker writes one. |
| `markdownSummaryPath` | Path to the generated Markdown summary report when Stryker writes one. |

## Precedence rules

The action builds the Stryker command in this order:

1. `--config-file <configFile>` when a file path is provided
2. `strykerArgs` appended last

This means:

- the config file defines the baseline behavior when present
- `strykerArgs` is the escape hatch and final override mechanism for everything else — reporters, thresholds, `since`, baseline, output directory, verbosity, and any other Stryker CLI option
- when `configFile` is omitted, the action intentionally skips `--config-file` and lets Stryker use its default config discovery
- `dotnet-stryker` itself validates all arguments and reports errors directly to the job log; the action performs no validation of its own beyond checking that a provided `configFile` path exists

## Credential handling

The safest way to authenticate is to pass `STRYKER_DASHBOARD_API_KEY` via workflow environment and let Stryker.NET consume it directly.

- The action does **not** pass the dashboard API key on the `dotnet-stryker` command line.
- The action does **not** emit secret values to outputs or the step summary.
- When `showEffectiveCommand` is enabled, secret-like dashboard arguments are redacted.

## Examples

### Example 1 - minimal config-file driven run
```yml
name: Run Stryker.NET

on: push

jobs:
  mutation-testing:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v6

      - name: Run Stryker.NET against Repository
        uses: lyndychivs/dotnet-stryker-action@v1.8
        with:
          configFile: "stryker-config.json"
```

### Example 2 - dashboard authentication via environment
Check out the [Stryker Dashboard documentation here](https://stryker-mutator.io/docs/General/dashboard/); the API key is generated from the Dashboard site.
```yml
name: Run Stryker.NET with Dashboard Reporting

on: push

jobs:
  mutation-testing:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v6

      - name: Run Stryker.NET against Repository
        uses: lyndychivs/dotnet-stryker-action@v1.8
        env:
          STRYKER_DASHBOARD_API_KEY: ${{ secrets.STRYKER_DASHBOARD_API_KEY }}
        with:
          configFile: "stryker-config.json"
```

### Example 3 - common CI overrides without editing the config file
```yml
name: Run Stryker.NET with CI overrides

on: pull_request

jobs:
  mutation-testing:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v6

      - name: Run Stryker.NET with workflow overrides
        id: stryker
        uses: lyndychivs/dotnet-stryker-action@v1.8
        with:
          configFile: "stryker-config.json"
          strykerArgs: >-
            --reporter markdown --reporter json
            --threshold-high 85 --threshold-low 70 --break-at 65
            --verbosity info
```

### Example 4 - use `since` with a Git target
```yml
name: Run incremental Stryker.NET

on: pull_request

jobs:
  mutation-testing:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: Run Stryker.NET against changes since main
        uses: lyndychivs/dotnet-stryker-action@v1.8
        with:
          configFile: "stryker-config.json"
          strykerArgs: "--since:origin/main"
```

### Example 5 - use `strykerArgs` as the escape hatch
```yml
name: Run Stryker.NET with advanced options

on: workflow_dispatch

jobs:
  mutation-testing:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v6

      - name: Run Stryker.NET with extra CLI options
        uses: lyndychivs/dotnet-stryker-action@v1.8
        with:
          configFile: "stryker-config.json"
          strykerArgs: >-
            --break-on-initial-test-failure
            --log-to-file
            --report-file-name mutation-report
```

## Notes

- If both the config file and `strykerArgs` specify the same setting, `strykerArgs` wins since it's appended last.
- Generated outputs depend on the reports Stryker actually writes during the run.
- For the best step-summary experience, include the `markdown` reporter.
```
