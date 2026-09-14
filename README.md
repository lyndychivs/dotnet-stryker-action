# dotnet-stryker-action

GitHub Action for mutation testing with [Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/) via Docker.

> [!NOTE]
> Runs on the .NET 10 SDK.

## Inputs

| Input | Description | Default |
| :--- | :--- | :--- |
| `configFile` | Path to the Stryker.NET config file (`--config-file`). Leave empty to use Stryker's default config discovery. | `""` |
| `strykerArgs` | Additional raw Stryker CLI arguments appended last to `dotnet-stryker`, e.g. `--reporter markdown --reporter json --threshold-high 85 --break-at 65`. | `""` |
| `writeStepSummary` | When `true`, publish a GitHub step summary from generated report artifacts when available. | `"true"` |

Everything Stryker supports beyond a config file should go through `strykerArgs`.

## Outputs

| Output | Description |
| :--- | :--- |
| `mutationScore` | Final mutation score percentage from the generated report, when available. |
| `thresholdStatus` | `passed` when `dotnet-stryker` exits `0`, `failed` otherwise. |
| `reportDirectory` | Path to the latest Stryker reports directory. |
| `htmlReportPath` | Path to the generated HTML report, when present. |
| `jsonReportPath` | Path to the generated JSON report, when present. |
| `markdownSummaryPath` | Path to the generated Markdown summary report, when present. |

## Stryker Dashboard

Pass `STRYKER_DASHBOARD_API_KEY` via workflow environment and let Stryker.NET consume it natively.

## Example

```yml
name: Run Stryker.NET

on: pull_request

jobs:
  mutation-testing:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v6

      - name: Run Stryker.NET
        uses: lyndychivs/dotnet-stryker-action@v2
        env:
          STRYKER_DASHBOARD_API_KEY: ${{ secrets.STRYKER_DASHBOARD_API_KEY }}
        with:
          configFile: "stryker-config.json"
          strykerArgs: >-
            --reporter markdown --reporter json
            --threshold-high 85 --threshold-low 70 --break-at 65
```
