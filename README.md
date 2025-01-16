# dotnet-stryker-action
GitHub Action for mutation testing with [Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/) via Docker.

## GitHub Action
This Action only accepts a [Stryker Mutator .NET Configuration](https://stryker-mutator.io/docs/stryker-net/configuration) file (`.json` or `.yaml` format).

The Configuration File must exist at the root level of the Repository.

### Inputs
`configurationFile` (required) : The name of the Stryker.NET configuration file (must be in the root of the repository).

`dashboardApiKey` (optional) : The API key for authentication with the Stryker dashboard.

`version` (optional) : The version of the report. This should be filled with the branch name, git tag or git sha.

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
        uses: lyndychivs/dotnet-stryker-action@master
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
        uses: lyndychivs/dotnet-stryker-action@master
        with:
          configurationFile: "stryker-config.json"
          dashboardApiKey: ${{ secrets.STRYKER_DASHBOARD }} # API key saved in Secrets
          version: ${{ github.ref_name }} # example 'master' or 'main'
```
