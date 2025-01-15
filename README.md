# stryker-dotnet-action
GitHub Action for mutation testing with [Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/) via Docker.

> [!IMPORTANT]
> This Action only accepts a [Stryker Mutator .NET Configuration](https://stryker-mutator.io/docs/stryker-net/configuration) file (`.json` or `.yaml` format).
>
> The Configuration File must exist at the root level of the Repository.

## Docker
#### Example
```
docker run ghcr.io/lyndychivs/stryker-dotnet-action:latest stryker-config.json
```

## GitHub Actions
#### Inputs
`configurationFile` : The name of the Stryker.NET configuration file (must be in the root of the repository).

#### Example
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
        uses: lyndychivs/stryker-dotnet-action@master
        with:
          configurationFile: "stryker-config.json"
```
