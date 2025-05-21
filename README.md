# dotnet-stryker-action
GitHub Action for mutation testing with [Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/) via Docker.

## GitHub Action
This Action accepts a [Stryker Mutator .NET Configuration](https://stryker-mutator.io/docs/stryker-net/configuration) file (`.json` or `.yaml` format).

*Create a configuration file:*
```
dotnet stryker init
```

### Parameters
| Argument            | Description | Default | Required |
| :---                | :---        | :---    | :---     |
| `configurationFile` | File path of the Stryker.NET configuration file. | `stryker-config.json` | Yes |
| `dashboardApiKey`   | API key for authentication with the Stryker dashboard. | — | No |
| `version`           | Version of the report.<br/>This should be filled with the branch Name, git Tag or git SHA. | — | No |

#### Example 1
```yml
name: Run Stryker.NET

on: push

jobs:
  mutation-testing:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Run Stryker.NET against Repository
        uses: lyndychivs/dotnet-stryker-action@v1.2
        with:
          configurationFile: "stryker-config.json"
```
#### Example 2 - with Dashboard API Key
Check out the [Stryker Dashboard documentation here](https://stryker-mutator.io/docs/General/dashboard/); the API key is generated from the Dashboard site.
```yml
name: Run Stryker.NET with Dashboard Reporting

on: push

jobs:
  mutation-testing:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Run Stryker.NET against Repository
        uses: lyndychivs/dotnet-stryker-action@v1.2
        with:
          configurationFile: "stryker-config.json"
          dashboardApiKey: ${{ secrets.STRYKER_DASHBOARD }} # API key saved in Secrets
          version: ${{ github.ref_name }} # example 'master' or 'main'
```
