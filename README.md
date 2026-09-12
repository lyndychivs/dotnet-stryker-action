# dotnet-stryker-action
GitHub Action for mutation testing with [Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/) via Docker.

## GitHub Action
This action is a thin Stryker.NET wrapper with a small convenience layer for common CI scenarios.

Consumers should treat the [Stryker.NET configuration](https://stryker-mutator.io/docs/stryker-net/configuration) file as the primary source of truth, then use action inputs for common workflow overrides.

### Breaking change

`dashboardApiKey` has been removed from the action interface.

To authenticate with the Stryker dashboard, pass the native Stryker environment variable in your workflow:

```yml
env:
  STRYKER_DASHBOARD_API_KEY: ${{ secrets.STRYKER_DASHBOARD_API_KEY }}
```

*Create a configuration file:*
```
dotnet stryker init
```

## Inputs
| Input | Description | Default | Required |
| :--- | :--- | :--- | :--- |
| `configFile` | Path to the Stryker.NET config file. This matches the CLI flag `--config-file`. Leave empty to let Stryker use its default config discovery. | `""` | No |
| `configurationFile` | Deprecated alias for `configFile`. Kept for backward compatibility. | `""` | No |
| `strykerArgs` | Additional raw Stryker CLI arguments appended last to `dotnet-stryker`. | `""` | No |
| `cliArgs` | Deprecated alias for `strykerArgs`. Kept for backward compatibility. | `""` | No |
| `reporters` | Comma-separated reporters translated to repeated `--reporter` flags. | `""` | No |
| `output` | Output directory passed to `--output`. | `""` | No |
| `thresholdHigh` | Passed to `--threshold-high`. | `""` | No |
| `thresholdLow` | Passed to `--threshold-low`. | `""` | No |
| `breakAt` | Passed to `--break-at`. | `""` | No |
| `since` | Use `true` for `--since`, or provide a committish for `--since:<target>`. | `""` | No |
| `withBaseline` | Use `true` for `--with-baseline`, or provide a committish for `--with-baseline:<target>`. | `""` | No |
| `verbosity` | Passed to `--verbosity`. Supported values follow the Stryker CLI: `error`, `warning`, `info`, `debug`, `trace`. | `""` | No |
| `showEffectiveCommand` | When `true`, print the assembled `dotnet-stryker` command with secret values redacted. | `"false"` | No |
| `writeStepSummary` | When `true`, publish a GitHub step summary from generated report artifacts when available. | `"true"` | No |

## Outputs
| Output | Description |
| :--- | :--- |
| `mutationScore` | Final mutation score percentage when it could be derived from generated reports. |
| `thresholdStatus` | `passed`, `failed`, or empty when it could not be derived. |
| `reportDirectory` | Latest generated Stryker reports directory. |
| `htmlReportPath` | Generated HTML report path when present. |
| `jsonReportPath` | Generated JSON report path when present. |
| `markdownSummaryPath` | Generated Markdown summary report path when present. |

## Precedence rules

The action builds the Stryker command in this order:

1. `--config-file <configFile>` when a file path is provided
2. Curated action inputs such as thresholds, reporters, output, and verbosity
3. `strykerArgs` appended last

This means:

- the config file defines the baseline behavior when present
- convenience inputs provide common workflow overrides
- `strykerArgs` is the advanced escape hatch and final override mechanism
- when `configFile` is omitted, the action intentionally skips `--config-file` and lets Stryker use its default config discovery

## Capability matrix
| Capability | Action input | Config file | `strykerArgs` |
| :--- | :---: | :---: | :---: |
| Choose config file | Yes | No | Yes |
| Dashboard API key | No - use environment | Yes | Yes |
| Reporters | Yes | Yes | Yes |
| Thresholds | Yes | Yes | Yes |
| `since` | Yes | Yes | Yes |
| Baseline | Yes | Yes | Yes |
| Output directory | Yes | Yes | Yes |
| Advanced / newly added Stryker options | No | Sometimes | Yes |

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
          reporters: "markdown,json"
          thresholdHigh: "85"
          thresholdLow: "70"
          breakAt: "65"
          verbosity: "info"
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
          since: "origin/main"
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

- If both the config file and action inputs specify the same setting, the generated CLI arguments win.
- `strykerArgs` is appended last and therefore has the highest precedence.
- Generated outputs depend on the reports Stryker actually writes during the run.
- For the best step-summary experience, include the `markdown` reporter.
```
